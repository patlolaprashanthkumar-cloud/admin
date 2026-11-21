// Supabase Edge Function: admin-delete-student
// Description: Securely performs administrative permanent deletion of an eligible student record
// and their associated Supabase Auth credentials with a durable, idempotent recovery mechanism.
//
// Strict Backend Corrections (Phase 1B.2A):
// 1. Mandatory authenticated JWT verification of caller session.
// 2. Authoritative Super Admin role check directly against public.profiles in database.
// 3. Executes public.safe_delete_student RPC with transaction-level advisory locking (pg_advisory_xact_lock)
//    and row-level FOR UPDATE locking.
// 4. Disposes of disposable junction records (student_categories) and personal notifications inside the transaction.
// 5. Enforces physical database foreign key constraints (ON DELETE RESTRICT) preventing race-condition deletion
//    of payments, course enrollments, assessment results, subscriptions, or career records.
// 6. Durable pre-deletion recovery tracking via public.student_deletion_records.
// 7. Supabase Auth deletion with exponential backoff retries.
// 8. Eliminates dangerous independent public.profiles deletion fallback.
// 9. Fully idempotent and safely retryable if Auth deletion encounters timeouts or transient errors.
// 10. Immutable audit logging into public.activity_logs.

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

    // Server-side service_role admin client for internal operations
    const adminClient = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    // Caller-context client carrying caller's JWT token for SECURITY DEFINER RPC verification
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
    // Query public.profiles directly. Never trust user_metadata or request body.
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
    // 5. Concurrency & Idempotency Check: Determine if Initial Deletion or Recovery Retry
    // -------------------------------------------------------------------------
    // Check if public.students row exists
    const { data: studentRecord, error: studentFetchError } = await adminClient
      .from('students')
      .select('id, profile_id, student_id, full_name, email, account_status')
      .eq('id', normalizedStudentId)
      .maybeSingle();

    if (studentFetchError) {
      console.error('Database error retrieving student record:', studentFetchError);
      return new Response(
        JSON.stringify({ error: 'Database error fetching student record.' }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    let deletionRecordId: string | null = null;
    let targetProfileId: string | null = null;
    let targetStudentCode: string = '';
    let targetFullName: string = '';
    let targetEmail: string = '';
    let isRecoveryRetry = false;

    if (!studentRecord) {
      // Student row does NOT exist. Check if a durable recovery record exists for this student.
      const { data: recoveryData, error: recoveryError } = await callerClient.rpc(
        'get_student_deletion_recovery_record',
        { p_student_id: normalizedStudentId }
      );

      if (recoveryError) {
        console.error('Error querying student deletion recovery record:', recoveryError);
      }

      if (!recoveryData || recoveryData.exists === false) {
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

      // If recovery record is already marked completed, return success idempotently
      if (recoveryData.status === 'completed') {
        return new Response(
          JSON.stringify({
            success: true,
            status: 'completed',
            message: `Student "${recoveryData.full_name}" (${recoveryData.student_code}) permanent deletion is already fully completed.`,
            deletedStudent: {
              id: normalizedStudentId,
              studentCode: recoveryData.student_code,
              fullName: recoveryData.full_name,
              email: recoveryData.email,
              profileId: recoveryData.profile_id,
            },
            deletionRecordId: recoveryData.id,
            authDeleted: true,
            idempotent: true,
          }),
          {
            status: 200,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          }
        );
      }

      // Recovery record exists and needs Auth completion ('db_deleted' or 'failed_auth')
      isRecoveryRetry = true;
      deletionRecordId = recoveryData.id;
      targetProfileId = recoveryData.profile_id;
      targetStudentCode = recoveryData.student_code;
      targetFullName = recoveryData.full_name;
      targetEmail = recoveryData.email;
      console.log(`Resuming incomplete Auth deletion for student ${normalizedStudentId} (Recovery record: ${deletionRecordId})`);
    } else {
      // Student row exists. Enforce self-deletion check
      if (studentRecord.profile_id && studentRecord.profile_id === callerUser.id) {
        return new Response(
          JSON.stringify({
            error: 'Safety violation: Super Administrators cannot delete their own linked student profile.',
            code: 'SELF_DELETION_PROHIBITED',
          }),
          {
            status: 400,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          }
        );
      }

      // -----------------------------------------------------------------------
      // 6. Atomic Safe Database Deletion via RPC (public.safe_delete_student)
      // -----------------------------------------------------------------------
      // Invokes safe_delete_student which:
      // - Acquires pg_advisory_xact_lock
      // - Locks student row FOR UPDATE
      // - Re-verifies all 9 protected dependency classes (rejects if payments/enrollments exist)
      // - Creates durable entry in public.student_deletion_records
      // - Safely cleans up student_categories and personal notifications
      // - Deletes public.students row (guarded by physical ON DELETE RESTRICT on dependent tables)
      let dbDeleteResult: any = null;

      const { data: callerRpcData, error: callerRpcError } = await callerClient.rpc(
        'safe_delete_student',
        { p_student_id: normalizedStudentId }
      );

      if (callerRpcError) {
        console.warn('Caller-context safe_delete_student error, attempting adminClient fallback:', callerRpcError.message);
        const { data: adminRpcData, error: adminRpcError } = await adminClient.rpc(
          'safe_delete_student',
          { p_student_id: normalizedStudentId }
        );

        if (adminRpcError) {
          console.error('All safe_delete_student RPC attempts failed:', adminRpcError.message);
          return new Response(
            JSON.stringify({
              error: `Database safe deletion RPC failed: ${adminRpcError.message || callerRpcError.message}`,
              code: 'DATABASE_DELETION_FAILED',
            }),
            {
              status: 500,
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            }
          );
        }
        dbDeleteResult = adminRpcData;
      } else {
        dbDeleteResult = callerRpcData;
      }

      if (!dbDeleteResult || dbDeleteResult.success === false) {
        console.warn('safe_delete_student rejected deletion:', dbDeleteResult?.message || dbDeleteResult?.error_code);
        return new Response(
          JSON.stringify({
            success: false,
            error: dbDeleteResult?.message || 'Student is not eligible for permanent deletion.',
            code: dbDeleteResult?.error_code || 'STUDENT_NOT_ELIGIBLE',
            studentId: normalizedStudentId,
            counts: dbDeleteResult?.counts || {},
          }),
          {
            status: 400,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          }
        );
      }

      deletionRecordId = dbDeleteResult.deletion_record_id;
      targetProfileId = dbDeleteResult.profile_id;
      targetStudentCode = dbDeleteResult.student_code;
      targetFullName = dbDeleteResult.full_name;
      targetEmail = dbDeleteResult.email;
    }

    // -------------------------------------------------------------------------
    // 7. Supabase Auth Deletion with Resilient Retry Loop
    // -------------------------------------------------------------------------
    let authDeleted = false;
    let authErrorMsg: string | null = null;

    if (targetProfileId) {
      const maxAttempts = 3;
      const backoffDelays = [250, 750, 1500];

      for (let attempt = 1; attempt <= maxAttempts; attempt++) {
        try {
          const { error: authErr } = await adminClient.auth.admin.deleteUser(targetProfileId);

          if (!authErr) {
            authDeleted = true;
            console.log(`Auth user ${targetProfileId} successfully deleted on attempt ${attempt}`);
            break;
          }

          // If user was already deleted in GoTrue (HTTP 404 or "user not found"), treat as success
          const errMsg = (authErr.message || '').toLowerCase();
          if (errMsg.includes('not found') || (authErr as any).status === 404) {
            console.log(`Auth user ${targetProfileId} already purged or not found in Auth store. Marking as deleted.`);
            authDeleted = true;
            break;
          }

          authErrorMsg = authErr.message;
          console.warn(`Auth deletion attempt ${attempt} for user ${targetProfileId} failed:`, authErr.message);

          if (attempt < maxAttempts) {
            await new Promise((resolve) => setTimeout(resolve, backoffDelays[attempt - 1]));
          }
        } catch (callEx) {
          authErrorMsg = callEx instanceof Error ? callEx.message : String(callEx);
          console.warn(`Auth deletion network exception on attempt ${attempt}:`, authErrorMsg);
          if (attempt < maxAttempts) {
            await new Promise((resolve) => setTimeout(resolve, backoffDelays[attempt - 1]));
          }
        }
      }
    } else {
      // Student had no linked Auth user (profile_id was NULL)
      authDeleted = true;
    }

    // -------------------------------------------------------------------------
    // 8. Update Durable Deletion Record & Write Immutable Audit Trail
    // -------------------------------------------------------------------------
    const clientIp =
      req.headers.get('x-forwarded-for')?.split(',')[0]?.trim() ||
      req.headers.get('cf-connecting-ip') ||
      req.headers.get('x-real-ip') ||
      'unknown';

    if (authDeleted) {
      // A. Update durable recovery record status to 'completed'
      if (deletionRecordId) {
        await callerClient.rpc('update_student_deletion_status', {
          p_record_id: deletionRecordId,
          p_status: 'completed',
          p_error_message: null,
        });
      }

      // B. Write success audit log to public.activity_logs
      await adminClient.from('activity_logs').insert({
        admin_id: callerUser.id,
        admin_name: callerProfile.full_name || callerUser.email || 'Super Administrator',
        action: isRecoveryRetry ? 'PERMANENT_DELETE_STUDENT_RECOVERED' : 'PERMANENT_DELETE_STUDENT_COMPLETED',
        target: `Student: ${targetFullName} (${targetStudentCode})`,
        ip_address: clientIp,
        metadata: {
          student_uuid: normalizedStudentId,
          student_code: targetStudentCode,
          full_name: targetFullName,
          email: targetEmail,
          profile_id: targetProfileId,
          deletion_record_id: deletionRecordId,
          deleted_by_admin_id: callerUser.id,
          deleted_by_admin_email: callerUser.email,
          auth_user_deleted: true,
          status: 'completed',
          is_recovery_retry: isRecoveryRetry,
          audit_timestamp: new Date().toISOString(),
        },
        timestamp: new Date().toISOString(),
      });

      // C. Return structured complete success
      return new Response(
        JSON.stringify({
          success: true,
          status: 'completed',
          message: `Student "${targetFullName}" (${targetStudentCode}) database records and Auth credentials have been permanently deleted.`,
          deletedStudent: {
            id: normalizedStudentId,
            studentCode: targetStudentCode,
            fullName: targetFullName,
            email: targetEmail,
            profileId: targetProfileId,
          },
          deletionRecordId,
          authDeleted: true,
          isRecoveryRetry,
        }),
        {
          status: 200,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    } else {
      // Auth deletion failed after all retries
      // DO NOT delete public.profiles independently (strictly prohibited)

      // A. Update durable recovery record status to 'failed_auth'
      if (deletionRecordId) {
        await callerClient.rpc('update_student_deletion_status', {
          p_record_id: deletionRecordId,
          p_status: 'failed_auth',
          p_error_message: authErrorMsg,
        });
      }

      // B. Write partial failure audit log to public.activity_logs
      await adminClient.from('activity_logs').insert({
        admin_id: callerUser.id,
        admin_name: callerProfile.full_name || callerUser.email || 'Super Administrator',
        action: 'PERMANENT_DELETE_STUDENT_PARTIAL_FAILURE',
        target: `Student: ${targetFullName} (${targetStudentCode})`,
        ip_address: clientIp,
        metadata: {
          student_uuid: normalizedStudentId,
          student_code: targetStudentCode,
          full_name: targetFullName,
          email: targetEmail,
          profile_id: targetProfileId,
          deletion_record_id: deletionRecordId,
          deleted_by_admin_id: callerUser.id,
          deleted_by_admin_email: callerUser.email,
          auth_user_deleted: false,
          auth_error: authErrorMsg,
          status: 'failed_auth',
          is_recovery_retry: isRecoveryRetry,
          audit_timestamp: new Date().toISOString(),
        },
        timestamp: new Date().toISOString(),
      });

      // C. Return structured partial failure response with recovery diagnostics
      return new Response(
        JSON.stringify({
          success: false,
          partialFailure: true,
          status: 'failed_auth',
          error: `Student database records were permanently deleted, but Supabase Auth account removal failed: ${authErrorMsg}. A durable deletion recovery record has been created.`,
          code: 'AUTH_DELETION_FAILED',
          studentId: normalizedStudentId,
          studentCode: targetStudentCode,
          profileId: targetProfileId,
          email: targetEmail,
          deletionRecordId,
          recoveryInstruction: 'Re-invoking deletion with this studentId will automatically verify the recovery record and complete Auth cleanup.',
        }),
        {
          status: 502,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }
  } catch (err: unknown) {
    const errorMessage = err instanceof Error ? err.message : 'Unknown server error occurred.';
    console.error('Unhandled exception in admin-delete-student:', errorMessage);
    return new Response(
      JSON.stringify({ error: errorMessage, code: 'INTERNAL_SERVER_ERROR' }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  }
});
