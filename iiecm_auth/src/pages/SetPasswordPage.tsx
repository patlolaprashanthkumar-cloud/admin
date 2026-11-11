import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Lock, Eye, EyeOff, ShieldCheck, ArrowRight, Loader2, AlertCircle, KeyRound, UserCheck } from 'lucide-react';
import { supabase, isSupabaseConfigured } from '@/lib/supabase';
import {
  inspectUrlAuthParams,
  recordVerifiedFlow,
  getVerifiedFlow,
  clearVerifiedFlow,
  isSessionExpiredError,
  sanitizeUpdatePasswordError,
  type AuthFlowType,
} from '@/lib/authFlow';

interface ActiveUserInfo {
  email?: string;
  role?: string;
  fullName?: string;
}

export function SetPasswordPage() {
  const navigate = useNavigate();

  // Verification & Loading State
  const [isVerifying, setIsVerifying] = useState<boolean>(true);
  const [isValidSession, setIsValidSession] = useState<boolean>(false);
  const [userInfo, setUserInfo] = useState<ActiveUserInfo | null>(null);
  const [flowType, setFlowType] = useState<AuthFlowType>('invite');

  // Form Fields & Visibility
  const [password, setPassword] = useState<string>('');
  const [confirmPassword, setConfirmPassword] = useState<string>('');
  const [showPassword, setShowPassword] = useState<boolean>(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState<boolean>(false);

  // Submission State
  const [error, setError] = useState<string>('');
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);

  useEffect(() => {
    let isMounted = true;
    let isAuthorized = false;

    async function verifySessionAndFlow() {
      // 1. Guard against unconfigured Supabase client
      if (!isSupabaseConfigured || !supabase) {
        navigate('/invalid-link?code=missing_config', { replace: true });
        return;
      }

      // 2. Synchronously inspect URL for error parameters
      const inspection = inspectUrlAuthParams();
      if (inspection.hasError) {
        const queryParams = new URLSearchParams({
          code: inspection.errorCode || 'auth_error',
          ...(inspection.errorDescription ? { desc: inspection.errorDescription } : {}),
        });
        navigate(`/invalid-link?${queryParams.toString()}`, { replace: true });
        return;
      }

      // 3. Check for existing tab-verified flow (e.g. redirected from AuthCallbackPage)
      const existingFlow = getVerifiedFlow();
      if (existingFlow && isMounted) {
        setFlowType(existingFlow.flowType);
      }

      // Helper to grant access to the password setup form
      function grantAccess(
        session: { user: { id: string; email?: string; user_metadata?: Record<string, any> } },
        flow: AuthFlowType
      ) {
        if (!isMounted || isAuthorized) return;
        isAuthorized = true;
        recordVerifiedFlow(flow, session.user.id);
        setFlowType(flow);
        setUserInfo({
          email: session.user.email,
          role: session.user.user_metadata?.role,
          fullName: session.user.user_metadata?.full_name,
        });
        setIsValidSession(true);
        setIsVerifying(false);

        // Clean sensitive hash fragment from the URL bar once verified
        if (window.location.hash) {
          try {
            window.history.replaceState(null, '', window.location.pathname + window.location.search);
          } catch {
            // Ignore history errors
          }
        }
      }

      // 4. Reliable event-driven auth listener
      // Cryptographically authorized ONLY via:
      // a) Native PASSWORD_RECOVERY event
      // b) SIGNED_IN where session.access_token matches the URL hash's raw access_token
      // c) Active session matching an existing flow verified by AuthCallbackPage (verified.userId === session.user.id)
      // STRICTLY REJECT INITIAL_SESSION: Stored sessions in localStorage cannot authorize invitation acceptance
      const { data: { subscription } } = supabase.auth.onAuthStateChange(
        (event, session) => {
          if (!isMounted || isAuthorized) return;

          // Native Supabase Password Recovery Event
          if (event === 'PASSWORD_RECOVERY' && session?.user) {
            grantAccess(session, 'recovery');
            return;
          }

          // Strictly ignore INITIAL_SESSION — existing localStorage session must NOT authorize invitation
          if (event === 'INITIAL_SESSION') {
            return;
          }

          // Invitation Sign-In with verified hash token from the URL
          if (event === 'SIGNED_IN' && session?.user) {
            // Check if this SIGNED_IN event corresponds to the raw access_token from the URL hash
            if (
              inspection.rawAccessToken &&
              session.access_token === inspection.rawAccessToken
            ) {
              const flow = inspection.rawHashType === 'recovery' ? 'recovery' : 'invite';
              grantAccess(session, flow);
              return;
            }

            // Or check if this session matches a tab flow already verified by AuthCallbackPage
            const currentVerified = getVerifiedFlow();
            if (currentVerified && currentVerified.userId === session.user.id) {
              grantAccess(session, currentVerified.flowType);
              return;
            }
          }
        }
      );

      // 5. Check if session was already established with verified flow
      try {
        const { data: { session } } = await supabase.auth.getSession();

        if (session?.user && !isAuthorized) {
          // Check if session was verified by AuthCallbackPage during this tab session
          const currentVerified = getVerifiedFlow();
          if (currentVerified && currentVerified.userId === session.user.id) {
            grantAccess(session, currentVerified.flowType);
            subscription.unsubscribe();
            return;
          }

          // Check if session access_token matches the raw token from the URL hash
          // (meaning detectSessionInUrl already verified it before or during mount)
          if (
            inspection.rawAccessToken &&
            session.access_token === inspection.rawAccessToken
          ) {
            const flow = inspection.rawHashType === 'recovery' ? 'recovery' : 'invite';
            grantAccess(session, flow);
            subscription.unsubscribe();
            return;
          }

          // An ordinary pre-existing session in localStorage does NOT match!
          // We do NOT call grantAccess!
        }

        // 6. Safety timer (5 seconds) to wait for detectSessionInUrl parsing on cellular networks
        setTimeout(() => {
          if (!isMounted) return;
          if (!isAuthorized) {
            subscription.unsubscribe();
            navigate('/invalid-link?code=no_active_flow', { replace: true });
          } else {
            setIsVerifying(false);
          }
        }, 5000);
      } catch {
        if (!isMounted || isAuthorized) return;
        subscription.unsubscribe();
        navigate('/invalid-link?code=no_active_flow', { replace: true });
      }
    }

    verifySessionAndFlow();

    return () => {
      isMounted = false;
    };
  }, [navigate]);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError('');

    // Client-side Validation
    if (!password || !confirmPassword) {
      setError('Please fill in both password fields.');
      return;
    }

    if (password.length < 8) {
      setError('Password must be at least 8 characters in length.');
      return;
    }

    if (password !== confirmPassword) {
      setError('Passwords do not match. Please verify your input.');
      return;
    }

    if (!supabase) {
      setError('Authentication client is not available.');
      return;
    }

    setIsSubmitting(true);

    try {
      // Direct password update through Supabase Auth
      const { data, error: updateError } = await supabase.auth.updateUser({
        password: password,
      });

      if (updateError) {
        setIsSubmitting(false);

        // Check if failure is due to expired or invalid session
        if (isSessionExpiredError(updateError.message)) {
          // Clear sensitive inputs and state
          setPassword('');
          setConfirmPassword('');
          clearVerifiedFlow();
          await supabase.auth.signOut().catch(() => {});
          navigate('/invalid-link?code=session_expired', { replace: true });
          return;
        }

        setError(sanitizeUpdatePasswordError(updateError.message));
        return;
      }

      // Password successfully set. Clear inputs and flow verification state.
      setPassword('');
      setConfirmPassword('');
      clearVerifiedFlow();

      // Navigate to success screen with role and account context
      navigate('/success', {
        replace: true,
        state: {
          email: data.user?.email || userInfo?.email,
          role: data.user?.user_metadata?.role || userInfo?.role,
          fullName: data.user?.user_metadata?.full_name || userInfo?.fullName,
          flowType: flowType,
        },
      });
    } catch (err: unknown) {
      setIsSubmitting(false);
      const msg = err instanceof Error ? err.message : 'Failed to update password';

      if (isSessionExpiredError(msg)) {
        setPassword('');
        setConfirmPassword('');
        clearVerifiedFlow();
        await supabase.auth.signOut().catch(() => {});
        navigate('/invalid-link?code=session_expired', { replace: true });
        return;
      }

      setError(sanitizeUpdatePasswordError(msg));
    }
  }

  // 1. Initial Verification Loader
  if (isVerifying) {
    return (
      <div className="w-full max-w-md mx-auto">
        <div className="bg-white rounded-3xl border border-navy-100/90 shadow-xl overflow-hidden p-8 text-center">
          <div className="inline-flex size-14 items-center justify-center rounded-2xl bg-forest-50 text-forest-700 mb-5">
            <Loader2 size={28} className="animate-spin text-forest-600" />
          </div>
          <h1 className="font-display text-xl font-bold text-navy-950 mb-2">
            Verifying Invitation Session
          </h1>
          <p className="text-sm text-navy-600">
            Please wait while we establish your secure institutional session...
          </p>
        </div>
      </div>
    );
  }

  // 2. Fallback if session is missing
  if (!isValidSession) {
    return null;
  }

  // Determine role title label
  const roleLabel =
    userInfo?.role === 'student'
      ? 'Student Account Setup'
      : userInfo?.role === 'instructor'
      ? 'Instructor Account Setup'
      : userInfo?.role === 'admin'
      ? 'Admin Account Setup'
      : flowType === 'recovery'
      ? 'Reset Your Password'
      : 'Institutional Account Setup';

  return (
    <div className="w-full max-w-md mx-auto">
      <div className="bg-white rounded-3xl border border-navy-100/90 shadow-xl overflow-hidden">
        {/* Decorative Top Accent Bar */}
        <div className="h-2 bg-gradient-to-r from-forest-700 via-saffron-500 to-forest-600" />

        <div className="p-6 sm:p-8">
          {/* Badge */}
          <div className="inline-flex items-center gap-1.5 rounded-full bg-forest-50 border border-forest-200/80 px-3 py-1 text-xs font-semibold text-forest-700 mb-4">
            <ShieldCheck size={14} className="text-forest-600" />
            {roleLabel}
          </div>

          <h1 className="font-display text-2xl sm:text-3xl font-bold text-navy-950 tracking-tight mb-2">
            {flowType === 'recovery' ? 'Reset Your Password' : 'Create Your Password'}
          </h1>
          <p className="text-sm text-navy-600 leading-relaxed mb-5">
            {flowType === 'recovery'
              ? 'Enter a new secure password for your IIECM account.'
              : 'Welcome to IIECM. Please establish a secure password to activate your account.'}
          </p>

          {/* User Account Context Banner */}
          {userInfo?.email && (
            <div className="rounded-2xl bg-navy-50/80 border border-navy-100 p-3.5 mb-5 flex items-center gap-3">
              <div className="size-9 rounded-xl bg-forest-100 flex items-center justify-center text-forest-700 shrink-0">
                <UserCheck size={18} />
              </div>
              <div className="min-w-0">
                <p className="text-[11px] font-semibold uppercase tracking-wider text-navy-500">
                  Account Email
                </p>
                <p className="text-xs font-bold text-navy-900 truncate">
                  {userInfo.email}
                </p>
              </div>
            </div>
          )}

          {/* Error Banner */}
          {error && (
            <div className="mb-5 flex items-start gap-2.5 rounded-xl bg-red-50 border border-red-200 p-3.5 text-xs sm:text-sm text-red-700">
              <AlertCircle size={18} className="shrink-0 mt-0.5 text-red-600" />
              <span className="leading-relaxed">{error}</span>
            </div>
          )}

          {/* Password Setup Form */}
          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label
                htmlFor="new-password"
                className="block text-xs font-semibold uppercase tracking-wider text-navy-700 mb-1.5"
              >
                New Password
              </label>
              <div className="relative">
                <Lock
                  size={16}
                  className="absolute left-3.5 top-1/2 -translate-y-1/2 text-navy-400"
                />
                <input
                  id="new-password"
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  disabled={isSubmitting}
                  placeholder="At least 8 characters"
                  autoComplete="new-password"
                  required
                  className="w-full rounded-xl border border-navy-200 bg-white pl-10 pr-10 py-2.5 text-sm text-navy-900 placeholder:text-navy-400 focus:border-forest-600 focus:outline-none focus:ring-2 focus:ring-forest-100 disabled:bg-navy-50 disabled:cursor-not-allowed"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword((prev) => !prev)}
                  tabIndex={-1}
                  aria-label={showPassword ? 'Hide password' : 'Show password'}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-navy-400 hover:text-navy-700 transition-colors p-1"
                >
                  {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                </button>
              </div>
              <p className="text-[11px] text-navy-500 mt-1">
                Must be at least 8 characters.
              </p>
            </div>

            <div>
              <label
                htmlFor="confirm-password"
                className="block text-xs font-semibold uppercase tracking-wider text-navy-700 mb-1.5"
              >
                Confirm New Password
              </label>
              <div className="relative">
                <KeyRound
                  size={16}
                  className="absolute left-3.5 top-1/2 -translate-y-1/2 text-navy-400"
                />
                <input
                  id="confirm-password"
                  type={showConfirmPassword ? 'text' : 'password'}
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  disabled={isSubmitting}
                  placeholder="Re-enter your password"
                  autoComplete="new-password"
                  required
                  className="w-full rounded-xl border border-navy-200 bg-white pl-10 pr-10 py-2.5 text-sm text-navy-900 placeholder:text-navy-400 focus:border-forest-600 focus:outline-none focus:ring-2 focus:ring-forest-100 disabled:bg-navy-50 disabled:cursor-not-allowed"
                />
                <button
                  type="button"
                  onClick={() => setShowConfirmPassword((prev) => !prev)}
                  tabIndex={-1}
                  aria-label={showConfirmPassword ? 'Hide password' : 'Show password'}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-navy-400 hover:text-navy-700 transition-colors p-1"
                >
                  {showConfirmPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                </button>
              </div>
            </div>

            <button
              type="submit"
              disabled={isSubmitting}
              className="w-full rounded-xl bg-forest-800 hover:bg-forest-900 active:bg-forest-950 px-4 py-3 text-sm font-semibold text-white shadow-md hover:shadow-lg transition-all flex items-center justify-center gap-2 disabled:opacity-60 disabled:cursor-not-allowed mt-2"
            >
              {isSubmitting ? (
                <>
                  <Loader2 size={16} className="animate-spin" />
                  <span>Saving Password...</span>
                </>
              ) : (
                <>
                  <span>
                    {flowType === 'recovery'
                      ? 'Update Password'
                      : 'Set Password & Activate Account'}
                  </span>
                  <ArrowRight size={16} />
                </>
              )}
            </button>
          </form>

          <p className="text-center text-xs text-navy-500 mt-6">
            Need assistance? Contact IIECM Support at{' '}
            <span className="font-semibold text-navy-700">support@iiecm.org</span>
          </p>
        </div>
      </div>
    </div>
  );
}
