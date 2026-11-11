/**
 * IIECM Authentication Website — Auth Flow & Callback Helper
 *
 * Responsibilities:
 * 1. Synchronously inspects URL search and hash fragments to detect genuine invitation, recovery,
 *    and PKCE callback parameters before the Supabase SDK strips them.
 * 2. Strictly ignores spoofed query parameters (such as a bare ?type=invite).
 * 3. Enforces that password setup cannot be accessed through an ordinary pre-existing session;
 *    it must originate from a verified Supabase invitation or password recovery event.
 * 4. Never displays, persists, or logs raw authentication tokens.
 * 5. Maps Supabase error codes to human-readable institutional messages.
 */

export type AuthFlowType = 'invite' | 'recovery';

const FLOW_STORAGE_KEY = 'iiecm_auth_verified_flow';

export const ALLOWED_OTP_TYPES = ['invite', 'recovery'] as const;
export type AllowedOtpType = (typeof ALLOWED_OTP_TYPES)[number];

export interface UrlInspectionResult {
  hasError: boolean;
  errorCode?: string;
  errorDescription?: string;
  // Raw token strings captured synchronously from hash fragment for cryptographic comparison
  rawAccessToken?: string;
  rawHashType?: string;
  // hashFlowType is an unverified hint; caller MUST verify with Supabase before granting access
  hashFlowType?: AuthFlowType;
  hasPkceCode: boolean;
  pkceCode?: string;
  hasTokenHash: boolean;
  tokenHash?: string;
  tokenType?: AllowedOtpType;
}

/**
 * Synchronously parses search parameters and hash fragments from current window.location.
 * Bare query parameters such as `?type=invite` without tokens or codes are strictly ignored.
 */
function parseCurrentUrlParams(): UrlInspectionResult {
  if (typeof window === 'undefined') {
    return {
      hasError: false,
      hasPkceCode: false,
      hasTokenHash: false,
    };
  }

  const searchParams = new URLSearchParams(window.location.search);
  const rawHash = window.location.hash.startsWith('#')
    ? window.location.hash.substring(1)
    : window.location.hash;
  const hashParams = new URLSearchParams(rawHash);

  // Check for error parameters in either search or hash
  const error = searchParams.get('error') || hashParams.get('error');
  const errorCode = searchParams.get('error_code') || hashParams.get('error_code');
  const errorDescription =
    searchParams.get('error_description') || hashParams.get('error_description');

  if (error || errorCode) {
    return {
      hasError: true,
      errorCode: errorCode || error || 'auth_error',
      errorDescription: errorDescription || undefined,
      hasPkceCode: false,
      hasTokenHash: false,
    };
  }

  // Extract raw unverified hash parameters
  const rawAccessToken = hashParams.get('access_token') || undefined;
  const rawHashType = (hashParams.get('type') || '').toLowerCase() || undefined;

  let hashFlowType: AuthFlowType | undefined;
  if (rawAccessToken && (rawHashType === 'invite' || rawHashType === 'recovery')) {
    hashFlowType = rawHashType as AuthFlowType;
  }

  // Check for PKCE authorization code (?code=...)
  const pkceCode = searchParams.get('code') || undefined;

  // Check for token_hash / OTP link flow (?token_hash=...&type=invite|recovery)
  const tokenHash = searchParams.get('token_hash') || undefined;
  const rawTokenType = (searchParams.get('type') || '').toLowerCase();
  let tokenType: AllowedOtpType | undefined;
  if (tokenHash && (rawTokenType === 'invite' || rawTokenType === 'recovery')) {
    tokenType = rawTokenType as AllowedOtpType;
  }

  return {
    hasError: false,
    rawAccessToken,
    rawHashType,
    hashFlowType,
    hasPkceCode: Boolean(pkceCode),
    pkceCode,
    hasTokenHash: Boolean(tokenHash && tokenType),
    tokenHash,
    tokenType,
  };
}

// Synchronously capture parameters on module load before Supabase client or React Router strips them
let capturedInitialPathname = '';
let capturedInitialParams: UrlInspectionResult | null = null;
try {
  if (typeof window !== 'undefined') {
    capturedInitialPathname = window.location.pathname;
    capturedInitialParams = parseCurrentUrlParams();
  }
} catch {
  // Non-browser or SSR fallback
}

/**
 * Inspects search parameters and hash fragments for genuine Supabase auth payloads or errors.
 * Preserves initial URL tokens even if the Supabase SDK stripped them during detectSessionInUrl initialization.
 */
export function inspectUrlAuthParams(): UrlInspectionResult {
  const current = parseCurrentUrlParams();
  if (current.hasError || current.rawAccessToken || current.hasPkceCode || current.hasTokenHash) {
    return current;
  }
  // Fallback to synchronously captured landing parameters on the same route
  if (
    capturedInitialParams &&
    typeof window !== 'undefined' &&
    window.location.pathname === capturedInitialPathname &&
    (capturedInitialParams.hasError ||
      capturedInitialParams.rawAccessToken ||
      capturedInitialParams.hasPkceCode ||
      capturedInitialParams.hasTokenHash)
  ) {
    return capturedInitialParams;
  }
  return current;
}

/**
 * Persists verified flow type into sessionStorage for navigation coordination within the tab.
 * Note: sessionStorage is only navigation state; cryptographic verification is handled by Supabase.
 */
export function recordVerifiedFlow(flowType: AuthFlowType, userId?: string): void {
  try {
    sessionStorage.setItem(
      FLOW_STORAGE_KEY,
      JSON.stringify({
        flowType,
        userId: userId || null,
        timestamp: Date.now(),
      })
    );
  } catch {
    // SessionStorage may be restricted in private browsing mode
  }
}

/**
 * Retrieves the verified flow type if recent (within 30 minutes).
 */
export function getVerifiedFlow(): { flowType: AuthFlowType; userId?: string } | null {
  try {
    const raw = sessionStorage.getItem(FLOW_STORAGE_KEY);
    if (!raw) return null;
    const parsed = JSON.parse(raw);
    if (Date.now() - parsed.timestamp > 30 * 60 * 1000) {
      clearVerifiedFlow();
      return null;
    }
    return { flowType: parsed.flowType, userId: parsed.userId || undefined };
  } catch {
    return null;
  }
}

/**
 * Clears the verified flow from sessionStorage.
 */
export function clearVerifiedFlow(): void {
  try {
    sessionStorage.removeItem(FLOW_STORAGE_KEY);
  } catch {
    // Ignore storage errors
  }
}

/**
 * Maps Supabase error codes or descriptions to user-friendly institutional messages.
 */
export function mapAuthError(errorCode?: string, errorDescription?: string): {
  title: string;
  message: string;
} {
  const code = (errorCode || '').toLowerCase();
  const desc = (errorDescription || '').toLowerCase();

  if (code.includes('otp_expired') || desc.includes('expired')) {
    return {
      title: 'Activation Link Expired',
      message:
        'This invitation link has expired. For institutional security, activation links remain valid for a limited time. Please contact your administrator to dispatch a fresh invitation.',
    };
  }

  if (desc.includes('already') || code.includes('already_used')) {
    return {
      title: 'Link Already Used',
      message:
        'This invitation link has already been used to set up an account. If you have already set your password, please open the IIECM Student or Instructor App to log in.',
    };
  }

  if (code === 'session_expired') {
    return {
      title: 'Session Expired',
      message:
        'Your setup session has timed out. Please click the invitation link in your email again or request a new invitation from your administrator.',
    };
  }

  if (code === 'no_active_flow') {
    return {
      title: 'No Active Setup Session',
      message:
        'No active invitation or recovery session was detected. To set or reset your password, please open the secure link sent to your registered email address.',
    };
  }

  if (code === 'unsupported_flow_type') {
    return {
      title: 'Invalid Link Type',
      message:
        'This authentication link is not supported by the account setup gateway. Please contact your IIECM administrator.',
    };
  }

  if (code === 'missing_config') {
    return {
      title: 'Service Not Configured',
      message:
        'The authentication gateway has not been provided with valid runtime configuration. Please notify your institution administrator.',
    };
  }

  if (code === 'access_denied') {
    return {
      title: 'Access Denied',
      message:
        'The authentication link could not be verified by the institutional security server. Please request a new invitation from your administrator.',
    };
  }

  return {
    title: 'Unable to Verify Link',
    message:
      'We were unable to complete verification for this invitation link. Please request a new invitation from your IIECM administrator.',
  };
}

/**
 * Checks whether an update password error is caused by session expiration or invalid session.
 */
export function isSessionExpiredError(rawMessage?: string): boolean {
  if (!rawMessage) return false;
  const lower = rawMessage.toLowerCase();
  return (
    lower.includes('auth session missing') ||
    lower.includes('jwt expired') ||
    lower.includes('session expired') ||
    lower.includes('token has expired') ||
    lower.includes('not logged in')
  );
}

/**
 * Sanitizes errors returned by supabase.auth.updateUser() to avoid technical disclosures.
 */
export function sanitizeUpdatePasswordError(rawMessage?: string): string {
  if (!rawMessage) return 'An unexpected error occurred while updating your password. Please try again.';
  const lower = rawMessage.toLowerCase();

  if (lower.includes('same password')) {
    return 'New password must be different from your previously used password.';
  }
  if (lower.includes('at least') || lower.includes('characters')) {
    return 'Password must be at least 8 characters in length.';
  }
  if (isSessionExpiredError(rawMessage)) {
    return 'Your setup session has expired. Please request a new invitation link.';
  }

  return 'Unable to update password. Please ensure your password meets the complexity requirements and try again.';
}
