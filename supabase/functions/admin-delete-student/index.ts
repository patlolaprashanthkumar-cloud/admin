// Supabase Edge Function: admin-delete-student
// Description: Securely performs administrative permanent deletion of an eligible student record
// and their associated Supabase Auth credentials.
// Strict Security:
// 1. Authenticates caller via JWT session.
// 2. Authoritatively verifies caller has the 'super_admin' role in public.profiles.
// 3. Executes check_student_deletion_eligibility RPC immediately prior to deletion.
// 4. Safely sequences database deletion before Auth deletion to guarantee non-atomic dual-store failure recovery.
// 5. Writes an immutable audit trail entry to public.activity_logs.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.38.4';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

interface DeleteStudentPayload {
  studentId: string;
}

interface EligibilityRpcResult {
  exists: boolean;
  student_id?: string;
  student_code?: string;
  full_name?: string;
  email?: string;
  account_status?: string;
  profile_id?: string | null;
  is_eligible: boolean;
  reasons: string[];
  counts: Record<string, number>;
  blocking_dependencies: Record<string, boolean>;
  recommendation?: string;
}

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  // Accept only POST requests
  if (req.method !== 'POST') {
    return new Response(
      JSON.stringify({ error: `Method ${req.method} not allowed. Use POST.` }),
      {
        status: 405,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  }

  try {
    // -------------------------------------------------------------------------
    // 1. Environment & Configuration Validation
    // -------------------------------------------------------------------------
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

    if (!supabaseUrl || !serviceRoleKey) {
      console.error('Server configuration missing: SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY');
      return new Response(
        JSON.stringify({ error: 'Internal server configuration error.' }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    // -------------------------------------------------------------------------
    // 2. Caller Authentication via JWT
    // -------------------------------------------------------------------------
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Authorization header is required.' }),
        {
          status: 401,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    const token = authHeader.replace(/^Bearer\s+/i, '').trim();
    if (!token) {
      return new Response(
        JSON.stringify({ error: 'Bearer token is required.' }),
        {
          status: 401,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    // Create service_role admin client strictly for internal server-side operations
    const adminClient = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    // Create caller-context client for authenticated RPC invocations
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? serviceRoleKey;
    const callerClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
      auth: { persistSession: false, autoRefreshToken: false },
    });

    // Authorize caller session
    const {
      data: { user: callerUser },
      error: callerAuthError,
    } = await adminClient.auth.getUser(token);

    if (callerAuthError || !callerUser) {
      console.warn('Caller authentication failed:', callerAuthError?.message);
      return new Response(
        JSON.stringify({ error: 'Unauthorized: Invalid or expired authentication session.' }),
        {
          status: 401,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    // -------------------------------------------------------------------------
    // 3. Authoritative Role Verification (Super Admin Only)
    // -------------------------------------------------------------------------
    // Query public.profiles directly in the database. Never trust client metadata or JWT claims alone.
    const { data: callerProfile, error: profileError } = await adminClient
      .from('profiles')
      .select('id, role, full_name, email')
      .eq('id', callerUser.id)
      .single();

    if (profileError || !callerProfile) {
      console.warn(`Profile lookup failed for caller user ${callerUser.id}:`, profileError?.message);
      return new Response(
        JSON.stringify({ error: 'Forbidden: Caller profile could not be verified.' }),
        {
          status: 403,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    if (callerProfile.role !== 'super_admin') {
      console.warn(`Unauthorized deletion attempt by user ${callerUser.id} with role "${callerProfile.role}".`);
      return new Response(
        JSON.stringify({
          error: 'Forbidden: Super Admin authority is strictly required to permanently delete student records.',
        }),
        {
          status: 403,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    // -------------------------------------------------------------------------
    // 4. Request Body Parsing & Validation
    // -------------------------------------------------------------------------
    let payload: DeleteStudentPayload;
    try {
      payload = await req.json();
    } catch {
      return new Response(
        JSON.stringify({ error: 'Invalid JSON request payload.' }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    const { studentId } = payload;
    if (!studentId || typeof studentId !== 'string' || !UUID_REGEX.test(studentId.trim())) {
      return new Response(
        JSON.stringify({
          error: 'Invalid studentId. A valid UUID string is required.',
          field: 'studentId',
        }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    const normalizedStudentId = studentId.trim().toLowerCase();

    // -------------------------------------------------------------------------
    // 5. Target Student Inspection & Self-Deletion Protection
    // -------------------------------------------------------------------------
    const { data: studentRecord, error: studentFetchError } = await adminClient
      .from('students')
      .select('id, profile_id, student_id, full_name, email, account_status')
      .eq('id', normalizedStudentId)
      .maybeSingle();

    if (studentFetchError) {
      console.error('Database error retrieving student:', studentFetchError);
      return new Response(
        JSON.stringify({ error: 'Database error fetching student record.' }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    if (!studentRecord) {
      return new Response(
        JSON.stringify({
          error: 'Student record does not exist or has already been removed.',
          studentId: normalizedStudentId,
          code: 'STUDENT_NOT_FOUND',
        }),
        {
          status: 404,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    // Prevent Super Admin from deleting their own account via student deletion
    if (studentRecord.profile_id && studentRecord.profile_id === callerUser.id) {
      return new Response(
        JSON.stringify({
          error: 'Safety violation: Super Administrators cannot delete their own linked student profile.',
        }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    // -------------------------------------------------------------------------
    // 6. Pre-Deletion Eligibility RPC Verification
    // -------------------------------------------------------------------------
    // Invoke public.check_student_deletion_eligibility(p_student_id UUID) immediately prior to deletion.
    let eligibility: EligibilityRpcResult | null = null;

    // Caller client carries the authenticated caller's JWT, satisfying public.is_admin_or_super()
    const { data: callerRpcData, error: callerRpcError } = await callerClient.rpc(
      'check_student_deletion_eligibility',
      { p_student_id: normalizedStudentId }
    );

    if (callerRpcError) {
      console.warn('Caller-context RPC returned error, attempting adminClient fallback:', callerRpcError.message);
      const { data: adminRpcData, error: adminRpcError } = await adminClient.rpc(
        'check_student_deletion_eligibility',
        { p_student_id: normalizedStudentId }
      );

      if (adminRpcError) {
        console.error('All eligibility RPC checks failed:', adminRpcError.message);
        return new Response(
          JSON.stringify({
            error: `Eligibility evaluation failed: ${adminRpcError.message || callerRpcError.message}`,
          }),
          {
            status: 500,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          }
        );
      }
      eligibility = adminRpcData as EligibilityRpcResult;
    } else {
      eligibility = callerRpcData as EligibilityRpcResult;
    }

    if (!eligibility || eligibility.exists === false) {
      return new Response(
        JSON.stringify({
          error: 'Student record does not exist or has already been removed.',
          studentId: normalizedStudentId,
          code: 'STUDENT_NOT_FOUND',
        }),
        {
          status: 404,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    if (eligibility.is_eligible !== true) {
      console.warn(`Student ${normalizedStudentId} is not eligible for deletion:`, eligibility.reasons);
      return new Response(
        JSON.stringify({
          error: 'Student is not eligible for permanent deletion due to existing dependent records.',
          code: 'STUDENT_NOT_ELIGIBLE',
          studentId: normalizedStudentId,
          studentCode: studentRecord.student_id,
          fullName: studentRecord.full_name,
          reasons: eligibility.reasons,
          counts: eligibility.counts,
          blockingDependencies: eligibility.blocking_dependencies,
          recommendation: eligibility.recommendation || 'DEACTIVATE_OR_SUSPEND',
        }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    // -------------------------------------------------------------------------
    // 7. Safe Dual-Store Deletion Sequencing & Failure Recovery
    // -------------------------------------------------------------------------
    // Critical Architecture:
    // Auth Admin API operations and PostgreSQL table mutations do NOT execute in a single
    // distributed atomic transaction.
    //
    // Ordering Strategy:
    // 1. Delete public.students FIRST.
    //    If database deletion fails (e.g. concurrent payment inserted triggering ON DELETE RESTRICT,
    //    or concurrent enrollment), the operation aborts cleanly.
    //    The student's Auth user and public.profiles remain 100% UNTOUCHED, allowing the account
    //    to remain consistent and accessible.
    // 2. Delete auth.users SECOND (if linked).
    //    Deleting auth.users automatically triggers ON DELETE CASCADE on public.profiles(id).
    //    If auth.users deletion encounters a network or transient error after public.students is
    //    already deleted, we perform explicit fallback profile cleanup and document the partial
    //    state in the audit log and API response.

    const linkedProfileId = studentRecord.profile_id;
    const studentSnapshot = {
      id: studentRecord.id,
      studentCode: studentRecord.student_id,
      fullName: studentRecord.full_name,
      email: studentRecord.email,
      profileId: linkedProfileId,
    };

    // Step A: Delete public.students record
    const { error: studentDeleteError } = await adminClient
      .from('students')
      .delete()
      .eq('id', normalizedStudentId);

    if (studentDeleteError) {
      console.error('Failed to delete student database record:', studentDeleteError);
      return new Response(
        JSON.stringify({
          error: `Failed to delete student database record: ${studentDeleteError.message}`,
          code: 'STUDENT_DELETE_FAILED',
        }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    // Step B: Delete Supabase Auth account & associated profile
    let authDeleted = false;
    let profileDeleted = false;
    let authWarning: string | null = null;

    if (linkedProfileId) {
      const { error: authDeleteError } = await adminClient.auth.admin.deleteUser(linkedProfileId);

      if (authDeleteError) {
        console.error(`Auth user deletion failed for profile ID ${linkedProfileId}:`, authDeleteError);
        authWarning = `Student database record was deleted, but Auth account removal failed: ${authDeleteError.message}`;

        // Fallback cleanup: Ensure public.profiles does not remain orphaned if Auth API failed
        const { error: profileDeleteError } = await adminClient
          .from('profiles')
          .delete()
          .eq('id', linkedProfileId);

        if (!profileDeleteError) {
          profileDeleted = true;
        } else {
          console.warn('Fallback profile deletion also encountered error:', profileDeleteError.message);
        }
      } else {
        authDeleted = true;
        profileDeleted = true; // Handled by PostgreSQL foreign key CASCADE on auth.users(id)
      }
    }

    // -------------------------------------------------------------------------
    // 8. Immutable Audit Trail Logging
    // -------------------------------------------------------------------------
    const clientIp =
      req.headers.get('x-forwarded-for')?.split(',')[0]?.trim() ||
      req.headers.get('cf-connecting-ip') ||
      req.headers.get('x-real-ip') ||
      'unknown';

    const auditEntry = {
      admin_id: callerUser.id,
      admin_name: callerProfile.full_name || callerUser.email || 'Super Administrator',
      action: 'PERMANENT_DELETE_STUDENT',
      target: `Student: ${studentSnapshot.fullName} (${studentSnapshot.studentCode})`,
      ip_address: clientIp,
      metadata: {
        student_uuid: studentSnapshot.id,
        student_code: studentSnapshot.studentCode,
        full_name: studentSnapshot.fullName,
        email: studentSnapshot.email,
        profile_id: studentSnapshot.profileId,
        deleted_by_admin_id: callerUser.id,
        deleted_by_admin_email: callerUser.email,
        auth_user_deleted: authDeleted,
        profile_deleted: profileDeleted,
        warning: authWarning,
        audit_timestamp: new Date().toISOString(),
      },
      timestamp: new Date().toISOString(),
    };

    const { error: auditError } = await adminClient
      .from('activity_logs')
      .insert(auditEntry);

    if (auditError) {
      // Log failure to server console but do not fail the completed deletion
      console.error('Notice: Failed to insert audit log for student deletion:', auditError.message);
    }

    // -------------------------------------------------------------------------
    // 9. Structured Success Response
    // -------------------------------------------------------------------------
    return new Response(
      JSON.stringify({
        success: true,
        message: `Student "${studentSnapshot.fullName}" (${studentSnapshot.studentCode}) has been permanently deleted.`,
        deletedStudent: studentSnapshot,
        authDeleted,
        profileDeleted,
        warning: authWarning,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  } catch (err: unknown) {
    const errorMessage = err instanceof Error ? err.message : 'Unknown server error occurred.';
    console.error('Unhandled exception in admin-delete-student:', errorMessage);
    return new Response(
      JSON.stringify({ error: errorMessage }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  }
});
