// Supabase Edge Function: admin-create-user
// Description: Securely provisions Student, Instructor, or Admin accounts with verified role enforcement,
// links Auth users to existing database records, validates strict environment-aware redirect destinations,
// and dispatches secure password-setup invitation emails.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.38.4';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const ALLOWED_PROVISION_ROLES = ['student', 'instructor', 'admin'] as const;
type ProvisionRole = (typeof ALLOWED_PROVISION_ROLES)[number];

// Permitted password setup and auth callback paths
const VERIFIED_PATHS = new Set<string>([
  '/reset-password',
  '/auth/callback',
]);

const LOCAL_DEFAULT_REDIRECT = 'http://localhost:5173/reset-password';

interface RedirectValidationResult {
  valid: boolean;
  url?: string;
  error?: string;
  isConfigError?: boolean;
}

interface NormalizedUrlResult {
  valid: boolean;
  normalizedUrl?: string;
  parsed?: URL;
  error?: string;
}

/**
 * Determines whether the Edge Function is executing against a reliable local Supabase runtime.
 *
 * Strict Rules:
 * 1. Must have explicit, verifiable evidence that SUPABASE_URL points to a local host
 *    (localhost, 127.0.0.1, ::1, or the local docker container hostname 'kong').
 * 2. If SUPABASE_URL points to any remote host (e.g. *.supabase.co or any external domain),
 *    local mode is NEVER activated, even if ENVIRONMENT or DENO_ENV is set to 'development'.
 * 3. If explicit environment flag indicates production/staging, local mode is never activated.
 * 4. Any missing, malformed, or ambiguous case strictly defaults to production-safe mode (false).
 */
function isLocalEnvironment(supabaseUrl?: string): boolean {
  if (!supabaseUrl || typeof supabaseUrl !== 'string' || supabaseUrl.trim().length === 0) {
    return false;
  }

  // Explicit production/staging flags always force production mode
  const env = (Deno.env.get('ENVIRONMENT') || Deno.env.get('DENO_ENV') || '').trim().toLowerCase();
  if (['production', 'prod', 'staging'].includes(env)) {
    return false;
  }

  // Parse SUPABASE_URL: must be a valid URL with verified local loopback/docker host
  try {
    const parsed = new URL(supabaseUrl.trim());
    const host = parsed.hostname.toLowerCase();

    const isLocalHost =
      host === 'localhost' ||
      host === '127.0.0.1' ||
      host === '::1' ||
      host === 'kong'; // Supabase CLI local docker bridge network

    // If host is NOT local (e.g. *.supabase.co or any remote domain), local mode is NEVER activated,
    // regardless of whether ENVIRONMENT or DENO_ENV is set to 'development'.
    if (!isLocalHost) {
      return false;
    }

    return true;
  } catch {
    // Malformed URL or uncertain case: default strictly to production-safe mode
    return false;
  }
}

/**
 * Resolves the server-controlled redirect URL from environment variables based on role.
 * Role-specific configuration takes priority, falling back to general auth configuration.
 */
function getProductionConfiguredDestination(role: ProvisionRole): string | null {
  if (role === 'student') {
    const studentUrl = Deno.env.get('STUDENT_REDIRECT_URL') || Deno.env.get('STUDENT_PASSWORD_RESET_URL');
    if (studentUrl && studentUrl.trim().length > 0) return studentUrl.trim();
  } else if (role === 'instructor') {
    const instructorUrl = Deno.env.get('INSTRUCTOR_REDIRECT_URL') || Deno.env.get('INSTRUCTOR_PASSWORD_RESET_URL');
    if (instructorUrl && instructorUrl.trim().length > 0) return instructorUrl.trim();
  } else if (role === 'admin') {
    const adminUrl = Deno.env.get('ADMIN_REDIRECT_URL') || Deno.env.get('ADMIN_PASSWORD_RESET_URL');
    if (adminUrl && adminUrl.trim().length > 0) return adminUrl.trim();
  }

  const authRedirect = Deno.env.get('AUTH_REDIRECT_URL');
  if (authRedirect && authRedirect.trim().length > 0) return authRedirect.trim();

  const siteUrl = Deno.env.get('SITE_URL');
  if (siteUrl && siteUrl.trim().length > 0) return siteUrl.trim();

  // Production institutional fallback URL
  return 'https://auth.iiecm.org/auth/callback';
}

/**
 * Parses and strictly normalizes a URL.
 * Enforces allowed schemes, rejects credentials and hash fragments,
 * normalizes empty or trailing slash paths to verified institutional paths.
 */
function parseAndNormalizeUrl(rawUrl: string, allowedSchemes: string[] = ['https:']): NormalizedUrlResult {
  let parsed: URL;
  try {
    parsed = new URL(rawUrl.trim());
  } catch {
    return {
      valid: false,
      error: 'Malformed URL. Unable to parse as a valid standard URL.',
    };
  }

  // Reject embedded credentials
  if (parsed.username || parsed.password) {
    return {
      valid: false,
      error: 'Security violation: URL must not contain embedded user credentials.',
    };
  }

  // Reject URL fragments
  if (parsed.hash) {
    return {
      valid: false,
      error: 'Security violation: URL must not contain pre-set URL fragments (#).',
    };
  }

  // Verify scheme
  if (!allowedSchemes.includes(parsed.protocol)) {
    return {
      valid: false,
      error: `Unapproved URL scheme "${parsed.protocol}". Allowed schemes: ${allowedSchemes.join(', ')}.`,
    };
  }

  // Normalize path
  let pathname = parsed.pathname.trim();
  if (pathname === '' || pathname === '/') {
    pathname = '/reset-password';
  } else if (pathname.length > 1 && pathname.endsWith('/')) {
    pathname = pathname.slice(0, -1);
  }

  if (!VERIFIED_PATHS.has(pathname)) {
    return {
      valid: false,
      error: `Unapproved redirect path "${parsed.pathname}". Permitted paths are: ${Array.from(VERIFIED_PATHS).join(', ')}.`,
    };
  }

  const normalized = `${parsed.origin}${pathname}${parsed.search}`;
  return {
    valid: true,
    normalizedUrl: normalized,
    parsed,
  };
}

/**
 * Validates the password-setup redirect destination.
 *
 * Strict Security Rules:
 * 1. Resolves server-approved URL based on environment and target role.
 * 2. In production, missing or invalid server configuration returns an explicit configuration error (HTTP 500).
 * 3. Client `redirectTo` must either be omitted (in which case server-approved URL is used)
 *    or match the exact normalized server-approved URL.
 *    Matching only the origin and allowing a different path is strictly rejected (HTTP 400).
 */
function validateAndSanitizeRedirectUrl(
  requestedUrl: string | undefined,
  role: ProvisionRole,
  supabaseUrl?: string
): RedirectValidationResult {
  const isLocal = isLocalEnvironment(supabaseUrl);

  // -----------------------------------------------------------------
  // 1. Resolve Server-Approved URL
  // -----------------------------------------------------------------
  let serverApprovedUrl: string;

  if (isLocal) {
    const runtimeSiteUrl = Deno.env.get('SITE_URL');
    if (runtimeSiteUrl && runtimeSiteUrl.trim().length > 0) {
      const siteNorm = parseAndNormalizeUrl(runtimeSiteUrl, ['http:', 'https:']);
      if (siteNorm.valid) {
        const host = siteNorm.parsed!.hostname.toLowerCase();
        if (host === 'localhost' || host === '127.0.0.1' || host === '::1') {
          serverApprovedUrl = siteNorm.normalizedUrl!;
        } else {
          serverApprovedUrl = LOCAL_DEFAULT_REDIRECT;
        }
      } else {
        serverApprovedUrl = LOCAL_DEFAULT_REDIRECT;
      }
    } else {
      serverApprovedUrl = LOCAL_DEFAULT_REDIRECT;
    }
  } else {
    // Production Mode: Must be configured in environment
    const configuredRaw = getProductionConfiguredDestination(role);
    if (!configuredRaw) {
      return {
        valid: false,
        isConfigError: true,
        error: 'Server configuration error: Production invitation redirect destination is not configured. Set AUTH_REDIRECT_URL (or role-specific STUDENT_REDIRECT_URL / INSTRUCTOR_REDIRECT_URL) in Supabase Edge Function secrets before issuing invitations.',
      };
    }

    const configNorm = parseAndNormalizeUrl(configuredRaw, ['https:']);
    if (!configNorm.valid) {
      return {
        valid: false,
        isConfigError: true,
        error: `Server configuration error: Configured production redirect destination "${configuredRaw}" is invalid: ${configNorm.error}`,
      };
    }

    const configuredHost = configNorm.parsed!.hostname.toLowerCase();
    if (
      configuredHost === 'localhost' ||
      configuredHost === '127.0.0.1' ||
      configuredHost === '::1' ||
      configuredHost.endsWith('.local')
    ) {
      return {
        valid: false,
        isConfigError: true,
        error: `Server configuration error: Production redirect destination cannot use localhost or loopback address ("${configuredHost}").`,
      };
    }

    serverApprovedUrl = configNorm.normalizedUrl!;
  }

  // -----------------------------------------------------------------
  // 2. Validate Client-Supplied redirectTo
  // -----------------------------------------------------------------
  // If client supplied redirectTo, it must match the exact normalized server-approved URL.
  // Matching only origin with a different path is strictly forbidden.
  if (requestedUrl && typeof requestedUrl === 'string' && requestedUrl.trim().length > 0) {
    const allowedSchemes = isLocal ? ['http:', 'https:'] : ['https:'];
    const clientNorm = parseAndNormalizeUrl(requestedUrl, allowedSchemes);

    if (!clientNorm.valid) {
      return {
        valid: false,
        error: `Invalid client redirectTo: ${clientNorm.error}`,
        isConfigError: false,
      };
    }

    if (!isLocal) {
      const clientHost = clientNorm.parsed!.hostname.toLowerCase();
      if (
        clientHost === 'localhost' ||
        clientHost === '127.0.0.1' ||
        clientHost === '::1' ||
        clientHost.endsWith('.local')
      ) {
        return {
          valid: false,
          error: 'Security violation: Localhost loopback destinations are strictly forbidden in production invitations.',
          isConfigError: false,
        };
      }
    }

    // Exact normalized URL matching required
    if (clientNorm.normalizedUrl !== serverApprovedUrl) {
      return {
        valid: false,
        error: `Unapproved redirect destination: Client redirectTo "${clientNorm.normalizedUrl}" does not match the exact normalized server-approved destination "${serverApprovedUrl}".`,
        isConfigError: false,
      };
    }
  }

  // Client omitted redirectTo or matched exact server-approved destination
  return {
    valid: true,
    url: serverApprovedUrl,
  };
}

interface CreateUserPayload {
  email: string;
  fullName: string;
  role: ProvisionRole;
  phone?: string;
  entityId?: string; // Existing students.id or instructors.id UUID to link
  studentId?: string; // Institutional student code (e.g. IIECM20261234)
  studentIdCode?: string;
  educationLevel?: string;
  qualification?: string;
  preferredCategory?: string;
  specialization?: string;
  experienceYears?: number;
  city?: string;
  country?: string;
  redirectTo?: string; // Client callback URL for password setup
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

    if (!supabaseUrl || !serviceRoleKey) {
      return new Response(JSON.stringify({ error: 'Server configuration missing: SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // 1. Authenticate caller token
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Authorization header is required' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const token = authHeader.replace(/^Bearer\s+/i, '').trim();
    if (!token) {
      return new Response(JSON.stringify({ error: 'Bearer token is required' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const adminClient = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    // Authorize caller by verifying JWT token
    const { data: { user: callerUser }, error: callerAuthError } = await adminClient.auth.getUser(token);
    if (callerAuthError || !callerUser) {
      console.error('Caller authentication failed:', callerAuthError?.message || callerAuthError);
      return new Response(JSON.stringify({ error: 'Unauthorized: Invalid or expired authentication session' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // 2. Authorize caller via public.profiles
    const { data: callerProfile, error: profileError } = await adminClient
      .from('profiles')
      .select('id, role, full_name, email')
      .eq('id', callerUser.id)
      .single();

    if (profileError || !callerProfile || !['super_admin', 'admin'].includes(callerProfile.role)) {
      return new Response(JSON.stringify({ error: 'Forbidden: Administrative authority required to provision accounts' }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // 3. Parse and validate input payload
    const payload: CreateUserPayload = await req.json();

    if (!payload.email || typeof payload.email !== 'string' || !payload.email.includes('@')) {
      return new Response(JSON.stringify({ error: 'A valid email address is required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (!payload.fullName || typeof payload.fullName !== 'string' || payload.fullName.trim().length === 0) {
      return new Response(JSON.stringify({ error: 'fullName is required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const normalizedEmail = payload.email.trim().toLowerCase();
    const fullName = payload.fullName.trim();
    const targetRole = payload.role;

    // Validate role against allowed whitelist
    if (!targetRole || !ALLOWED_PROVISION_ROLES.includes(targetRole)) {
      return new Response(
        JSON.stringify({
          error: `Invalid role "${targetRole}". Allowed provisioning roles: student, instructor, admin.`,
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Role escalation protection: Only super_admin can create admin accounts
    if (targetRole === 'admin' && callerProfile.role !== 'super_admin') {
      return new Response(
        JSON.stringify({ error: 'Forbidden: Only Super Administrators can provision administrative accounts' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 4. Strict Server-Side Redirect URL Validation
    // Evaluates environment and ensures production destination is properly configured before mutating Auth or DB.
    const redirectValidation = validateAndSanitizeRedirectUrl(payload.redirectTo, targetRole, supabaseUrl);
    if (!redirectValidation.valid) {
      if (redirectValidation.isConfigError) {
        return new Response(
          JSON.stringify({
            error: redirectValidation.error,
            code: 'CONFIGURATION_ERROR',
          }),
          { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }
      return new Response(
        JSON.stringify({
          error: `Invalid redirectTo parameter: ${redirectValidation.error}`,
          field: 'redirectTo',
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }
    const sanitizedRedirectTo = redirectValidation.url!;

    // 5. Check for existing Auth user & prevent cross-role collisions
    let authUserId: string | null = null;
    let isExistingAuthUser = false;

    // Check public.profiles first
    const { data: existingProfile } = await adminClient
      .from('profiles')
      .select('id, role, full_name, email')
      .ilike('email', normalizedEmail)
      .maybeSingle();

    if (existingProfile) {
      isExistingAuthUser = true;
      authUserId = existingProfile.id;

      // Reject cross-role conflicting assignments
      if (existingProfile.role !== targetRole) {
        return new Response(
          JSON.stringify({
            error: `Conflict: An account with email "${normalizedEmail}" already exists with role "${existingProfile.role}". Cross-role assignment to "${targetRole}" is not permitted.`,
          }),
          { status: 409, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }
    }

    // Also proactively check auth.users directly via Admin API to catch users without a profile
    if (!isExistingAuthUser) {
      try {
        const { data: userList } = await adminClient.auth.admin.listUsers({ perPage: 1000 });
        const matchedUser = userList?.users?.find(
          (u) => u.email?.toLowerCase() === normalizedEmail
        );
        if (matchedUser) {
          authUserId = matchedUser.id;
          isExistingAuthUser = true;
          console.log(`Matched existing auth.users record: ${authUserId} for ${normalizedEmail}`);

          const existingRole = matchedUser.user_metadata?.role;
          if (existingRole && existingRole !== targetRole) {
            return new Response(
              JSON.stringify({
                error: `Conflict: An account with email "${normalizedEmail}" already exists with role "${existingRole}". Cross-role assignment to "${targetRole}" is not permitted.`,
              }),
              { status: 409, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            );
          }
        }
      } catch (listErr) {
        console.warn('Notice: Proactive listUsers check failed:', listErr);
      }
    }

    // 6. Create Auth account & dispatch secure password setup email
    let invitationSent = false;

    if (!isExistingAuthUser) {
      // Provision via Supabase Admin Invitation using sanitized redirect
      const { data: inviteData, error: inviteError } = await adminClient.auth.admin.inviteUserByEmail(
        normalizedEmail,
        {
          data: {
            email: normalizedEmail,
            full_name: fullName,
            role: targetRole,
            phone: payload.phone?.trim() || null,
          },
          redirectTo: sanitizedRedirectTo,
        }
      );

      if (inviteError || !inviteData?.user) {
        console.warn('inviteUserByEmail notice/error:', inviteError?.message, 'status:', inviteError?.status);

        // Check whether user already exists in auth.users (covers "Database error saving new user", "already registered", HTTP 422, HTTP 500)
        let resolvedUser = null;
        try {
          const { data: userList } = await adminClient.auth.admin.listUsers({ perPage: 1000 });
          resolvedUser = userList?.users?.find(
            (u) => u.email?.toLowerCase() === normalizedEmail
          );
        } catch (_) {}

        if (resolvedUser) {
          authUserId = resolvedUser.id;
          isExistingAuthUser = true;
          console.log(`Recovered existing auth user ${authUserId} after inviteUserByEmail.`);

          // Dispatch password reset email for this existing user
          const { error: resetError } = await adminClient.auth.resetPasswordForEmail(normalizedEmail, {
            redirectTo: sanitizedRedirectTo,
          });
          if (!resetError) {
            invitationSent = true;
          }
        } else {
          // Attempt fallback: admin.createUser
          console.log(`Attempting fallback admin.createUser for ${normalizedEmail}`);
          const { data: createData, error: createError } = await adminClient.auth.admin.createUser({
            email: normalizedEmail,
            email_confirm: false,
            user_metadata: {
              email: normalizedEmail,
              full_name: fullName,
              role: targetRole,
              phone: payload.phone?.trim() || null,
            },
          });

          if (createData?.user) {
            authUserId = createData.user.id;
            const { error: resetError } = await adminClient.auth.resetPasswordForEmail(normalizedEmail, {
              redirectTo: sanitizedRedirectTo,
            });
            if (!resetError) {
              invitationSent = true;
            }
          } else {
            console.error('All user creation attempts failed:', inviteError?.message, createError?.message);
            return new Response(
              JSON.stringify({
                error: `Failed to dispatch invitation email: ${inviteError?.message || createError?.message || 'Database error saving new user'}`,
              }),
              { status: 502, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            );
          }
        }
      } else {
        authUserId = inviteData.user.id;
        invitationSent = true;
      }
    } else {
      // Existing verified user re-invited or password reset requested using sanitized redirect
      const { error: resetError } = await adminClient.auth.resetPasswordForEmail(normalizedEmail, {
        redirectTo: sanitizedRedirectTo,
      });
      if (resetError) {
        console.warn('Notice: Password reset dispatch failed for existing user:', resetError.message);
      } else {
        invitationSent = true;
      }
    }

    if (!authUserId) {
      return new Response(JSON.stringify({ error: 'Failed to establish Auth user identity.' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // 7. Ensure public.profiles is synchronized
    const { error: profileUpsertError } = await adminClient
      .from('profiles')
      .upsert({
        id: authUserId,
        email: normalizedEmail,
        full_name: fullName,
        role: targetRole,
        phone: payload.phone?.trim() || null,
        updated_at: new Date().toISOString(),
      });

    if (profileUpsertError) {
      console.error('Error synchronizing profile record:', profileUpsertError);
    }

    // 8. Atomically link or create Student / Instructor record
    let linkedEntityId: string | null = null;

    if (targetRole === 'student') {
      let existingStudent: any = null;

      if (payload.entityId) {
        const { data: sById } = await adminClient
          .from('students')
          .select('*')
          .eq('id', payload.entityId)
          .maybeSingle();
        if (sById) existingStudent = sById;
      }

      if (!existingStudent) {
        const { data: sByEmail } = await adminClient
          .from('students')
          .select('*')
          .eq('email', normalizedEmail)
          .maybeSingle();
        if (sByEmail) existingStudent = sByEmail;
      }

      if (existingStudent) {
        linkedEntityId = existingStudent.id;

        // Verify this student isn't already claimed by another distinct auth user
        if (existingStudent.profile_id && existingStudent.profile_id !== authUserId) {
          return new Response(
            JSON.stringify({
              error: `Integrity Conflict: Student record "${existingStudent.student_id}" is already linked to a different profile (${existingStudent.profile_id}).`,
            }),
            { status: 409, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
          );
        }

        // Verify this auth user isn't already assigned to a DIFFERENT student record
        const { data: studentWithSameProfile } = await adminClient
          .from('students')
          .select('id, student_id')
          .eq('profile_id', authUserId)
          .maybeSingle();

        if (studentWithSameProfile && studentWithSameProfile.id !== existingStudent.id) {
          return new Response(
            JSON.stringify({
              error: `Integrity Conflict: Auth profile (${authUserId}) is already linked to student record "${studentWithSameProfile.student_id}".`,
            }),
            { status: 409, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
          );
        }

        // Atomically link profile_id to existing student record
        const { error: linkError } = await adminClient
          .from('students')
          .update({
            profile_id: authUserId,
            full_name: fullName,
            phone: payload.phone?.trim() || existingStudent.phone,
            updated_at: new Date().toISOString(),
          })
          .eq('id', existingStudent.id);

        if (linkError) {
          return new Response(
            JSON.stringify({
              error: `Auth user created (${authUserId}), but failed to link student record: ${linkError.message}`,
              partialFailure: true,
            }),
            { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
          );
        }
      } else {
        // No existing student record: create new record with profile_id populated
        const generatedStudentId =
          payload.studentId ||
          payload.studentIdCode ||
          `IIECM${new Date().getFullYear()}${Math.floor(10000 + Math.random() * 90000)}`;

        const { data: newStudent, error: insertError } = await adminClient
          .from('students')
          .insert({
            profile_id: authUserId,
            student_id: generatedStudentId,
            full_name: fullName,
            email: normalizedEmail,
            phone: payload.phone?.trim() || '+91 00000 00000',
            education_level: payload.educationLevel || 'Not specified',
            qualification: payload.qualification || 'N/A',
            preferred_category: payload.preferredCategory || 'General',
            account_status: 'active',
            subscription_plan: 'basic',
            subscription_status: 'active',
            city: payload.city?.trim() || null,
            country: payload.country?.trim() || 'India',
          })
          .select('id')
          .single();

        if (insertError) {
          return new Response(
            JSON.stringify({
              error: `Auth user created (${authUserId}), but failed to insert student record: ${insertError.message}`,
              partialFailure: true,
            }),
            { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
          );
        }

        linkedEntityId = newStudent.id;
      }
    } else if (targetRole === 'instructor') {
      let existingInstructor: any = null;

      if (payload.entityId) {
        const { data: iById } = await adminClient
          .from('instructors')
          .select('*')
          .eq('id', payload.entityId)
          .maybeSingle();
        if (iById) existingInstructor = iById;
      }

      if (!existingInstructor) {
        const { data: iByEmail } = await adminClient
          .from('instructors')
          .select('*')
          .eq('email', normalizedEmail)
          .maybeSingle();
        if (iByEmail) existingInstructor = iByEmail;
      }

      if (existingInstructor) {
        linkedEntityId = existingInstructor.id;

        // Verify this instructor isn't already claimed by another distinct auth user
        if (existingInstructor.profile_id && existingInstructor.profile_id !== authUserId) {
          return new Response(
            JSON.stringify({
              error: `Integrity Conflict: Instructor record is already linked to a different profile (${existingInstructor.profile_id}).`,
            }),
            { status: 409, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
          );
        }

        // Verify this auth user isn't already assigned to a DIFFERENT instructor record
        const { data: instructorWithSameProfile } = await adminClient
          .from('instructors')
          .select('id')
          .eq('profile_id', authUserId)
          .maybeSingle();

        if (instructorWithSameProfile && instructorWithSameProfile.id !== existingInstructor.id) {
          return new Response(
            JSON.stringify({
              error: `Integrity Conflict: Auth profile (${authUserId}) is already linked to another instructor record.`,
            }),
            { status: 409, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
          );
        }

        // Atomically link profile_id to existing instructor record
        const { error: linkError } = await adminClient
          .from('instructors')
          .update({
            profile_id: authUserId,
            full_name: fullName,
            phone: payload.phone?.trim() || existingInstructor.phone,
            updated_at: new Date().toISOString(),
          })
          .eq('id', existingInstructor.id);

        if (linkError) {
          return new Response(
            JSON.stringify({
              error: `Auth user created (${authUserId}), but failed to link instructor record: ${linkError.message}`,
              partialFailure: true,
            }),
            { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
          );
        }
      } else {
        // No existing instructor record: create new record with profile_id populated
        const { data: newInstructor, error: insertError } = await adminClient
          .from('instructors')
          .insert({
            profile_id: authUserId,
            full_name: fullName,
            email: normalizedEmail,
            phone: payload.phone?.trim() || '+91 00000 00000',
            qualifications: payload.qualification || 'N/A',
            specialization: payload.specialization || 'General',
            experience_years: payload.experienceYears || 0,
            account_status: 'active',
          })
          .select('id')
          .single();

        if (insertError) {
          return new Response(
            JSON.stringify({
              error: `Auth user created (${authUserId}), but failed to insert instructor record: ${insertError.message}`,
              partialFailure: true,
            }),
            { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
          );
        }

        linkedEntityId = newInstructor.id;
      }
    }

    // 9. Immutable Activity Audit Logging
    await adminClient.from('activity_logs').insert({
      admin_id: callerUser.id,
      admin_name: callerProfile.full_name || callerUser.email || 'Admin',
      action: isExistingAuthUser ? 'Re-provisioned/linked user account' : 'Invited new user account',
      target: `${fullName} (${normalizedEmail}) as ${targetRole}`,
      metadata: {
        role: targetRole,
        target_user_id: authUserId,
        linked_entity_id: linkedEntityId,
        method: isExistingAuthUser ? 'resetPasswordForEmail' : 'inviteUserByEmail',
        invitation_sent: invitationSent,
        redirect_to: sanitizedRedirectTo,
      },
      timestamp: new Date().toISOString(),
    });

    // 10. Structured Success Response
    return new Response(
      JSON.stringify({
        success: true,
        userId: authUserId,
        email: normalizedEmail,
        role: targetRole,
        linkedEntityId: linkedEntityId,
        invitationSent: invitationSent,
        redirectTo: sanitizedRedirectTo,
        message: isExistingAuthUser
          ? `Account already registered in Auth. Re-linked to ${targetRole} record and initiated password reset/invitation.`
          : `Account successfully provisioned. Invitation email dispatched with password setup link.`,
      }),
      {
        status: isExistingAuthUser ? 200 : 201,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Unknown internal server error';
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
