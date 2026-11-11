import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Loader2, ShieldCheck } from 'lucide-react';
import { supabase, isSupabaseConfigured, initialPkceState } from '@/lib/supabase';
import { inspectUrlAuthParams, recordVerifiedFlow, ALLOWED_OTP_TYPES, type AllowedOtpType } from '@/lib/authFlow';

interface InFlightOtpVerification {
  tokenHash: string;
  type: AllowedOtpType;
  promise: Promise<{
    data: { user: any; session: any } | { user: null; session: null };
    error: any;
  }>;
}

let inFlightOtpVerification: InFlightOtpVerification | null = null;

export function AuthCallbackPage() {
  const navigate = useNavigate();
  const [statusMessage, setStatusMessage] = useState<string>('Verifying invitation link...');

  useEffect(() => {
    let isMounted = true;
    let isHandled = false;
    let activeSubscription: { unsubscribe: () => void } | null = null;
    let activeTimeout: ReturnType<typeof setTimeout> | null = null;

    async function processCallback() {
      // 1. Guard against unconfigured Supabase client
      if (!isSupabaseConfigured || !supabase) {
        isHandled = true;
        navigate('/invalid-link?code=missing_config', { replace: true });
        return;
      }

      // 2. Inspect URL search and hash for error parameters
      const inspection = inspectUrlAuthParams();

      if (inspection.hasError) {
        isHandled = true;
        const queryParams = new URLSearchParams({
          code: inspection.errorCode || 'auth_error',
          ...(inspection.errorDescription ? { desc: inspection.errorDescription } : {}),
        });
        navigate(`/invalid-link?${queryParams.toString()}`, { replace: true });
        return;
      }

      // 3. Reject visits with no genuine auth tokens, codes, or hashes
      // Stale sessions or manual visits without invitation payload must not be authorized
      const hasAuthPayload =
        inspection.hasPkceCode ||
        inspection.hasTokenHash ||
        Boolean(inspection.rawAccessToken && inspection.rawHashType);

      if (!hasAuthPayload) {
        isHandled = true;
        navigate('/invalid-link?code=no_active_flow', { replace: true });
        return;
      }

      try {
        // 4. Handle PKCE authorization code exchange (?code=...)
        // Correlated using the 6-point multi-signal verification against Supabase automatic initialization.
        // Requires: initial code presence, matching captured code, initial verifier presence, error-free
        // initialization, SDK URL code consumption, and active session with user.
        if (inspection.hasPkceCode && inspection.pkceCode) {
          if (isMounted) setStatusMessage('Exchanging authorization code...');

          // Check 1: initialPkceState.code exists
          // Check 2: Callback's captured code equals initialPkceState.code
          // Check 3: initialPkceState.hasVerifier is true
          if (
            !initialPkceState.code ||
            inspection.pkceCode !== initialPkceState.code ||
            !initialPkceState.hasVerifier
          ) {
            isHandled = true;
            navigate(
              '/invalid-link?code=exchange_failed&desc=Missing+or+invalid+authorization+verifier',
              { replace: true }
            );
            return;
          }

          // Check 4: await supabase.auth.initialize() completes without an error
          const { error: initError } = await supabase.auth.initialize();

          if (!isMounted || isHandled) return;

          if (initError) {
            isHandled = true;
            navigate(
              '/invalid-link?code=exchange_failed&desc=Authorization+code+verification+failed',
              { replace: true }
            );
            return;
          }

          // Check 5: The current URL no longer contains the 'code' query parameter
          // (Supabase automatic exchange strips 'code' via replaceState upon successful exchange)
          const currentParams = new URLSearchParams(window.location.search);
          if (currentParams.has('code')) {
            isHandled = true;
            navigate(
              '/invalid-link?code=exchange_failed&desc=Authorization+exchange+could+not+be+verified',
              { replace: true }
            );
            return;
          }

          // Check 6: await supabase.auth.getSession() returns a valid session with a user
          const { data: { session } } = await supabase.auth.getSession();

          if (!isMounted || isHandled) return;

          if (!session?.user) {
            isHandled = true;
            navigate(
              '/invalid-link?code=exchange_failed&desc=No+authenticated+session+established',
              { replace: true }
            );
            return;
          }

          // All 6 checks passed: determine flow, record verified flow, and navigate
          isHandled = true;
          const urlType =
            (new URLSearchParams(window.location.search).get('type') || '').toLowerCase() ||
            inspection.tokenType;
          const flow = urlType === 'recovery' ? 'recovery' : 'invite';
          recordVerifiedFlow(flow, session.user.id);
          navigate('/reset-password', { replace: true });
          return;
        }

        // 5. Handle token_hash verification (?token_hash=...&type=invite|recovery)
        // Explicitly validate supported callback types
        if (inspection.hasTokenHash && inspection.tokenHash) {
          if (!inspection.tokenType || !ALLOWED_OTP_TYPES.includes(inspection.tokenType)) {
            isHandled = true;
            navigate('/invalid-link?code=unsupported_flow_type', { replace: true });
            return;
          }

          if (isMounted) setStatusMessage('Verifying invitation credentials...');

          const currentTokenHash = inspection.tokenHash;
          const currentType = inspection.tokenType;

          // Deduplicate verifyOtp execution across React Strict Mode re-mounts so that
          // the single-use token is not consumed twice. Both effect invocations await the same promise.
          if (
            !inFlightOtpVerification ||
            inFlightOtpVerification.tokenHash !== currentTokenHash ||
            inFlightOtpVerification.type !== currentType
          ) {
            const rawPromise = supabase.auth.verifyOtp({
              token_hash: currentTokenHash,
              type: currentType as any,
            });

            const entry: InFlightOtpVerification = {
              tokenHash: currentTokenHash,
              type: currentType,
              promise: rawPromise,
            };
            inFlightOtpVerification = entry;

            // Start the 15-second retention timer ONLY after the promise settles (resolves or rejects)
            // to ensure the entry remains available for the full duration of pending requests.
            // Attaching .catch() ensures no unhandled rejection occurs on the settlement watcher.
            rawPromise
              .catch(() => {})
              .then(() => {
                setTimeout(() => {
                  if (inFlightOtpVerification === entry) {
                    inFlightOtpVerification = null;
                  }
                }, 15000);
              });
          }

          const { data: otpData, error: otpError } = await inFlightOtpVerification.promise;

          // Check if effect unmounted or was already handled
          if (!isMounted || isHandled) return;

          if (otpError) {
            isHandled = true;
            navigate(
              `/invalid-link?code=otp_failed&desc=${encodeURIComponent(otpError.message)}`,
              { replace: true }
            );
            return;
          }

          if (otpData?.session) {
            isHandled = true;
            recordVerifiedFlow(inspection.tokenType, otpData.session.user.id);
            navigate('/reset-password', { replace: true });
            return;
          }

          isHandled = true;
          navigate('/invalid-link?code=otp_failed&desc=No+session+established', { replace: true });
          return;
        }

        // 6. Handle implicit flow landing on callback (#access_token=...&type=invite|recovery)
        if (inspection.rawAccessToken && inspection.rawHashType) {
          const rawToken = inspection.rawAccessToken;
          const targetFlow = inspection.rawHashType === 'recovery' ? 'recovery' : 'invite';

          if (isMounted) setStatusMessage('Verifying security session...');

          // Check if detectSessionInUrl already processed this EXACT token
          const { data: { session: existingSession } } = await supabase.auth.getSession();

          // Immediately check lifecycle after async call
          if (!isMounted || isHandled) return;

          if (existingSession && existingSession.access_token === rawToken) {
            isHandled = true;
            recordVerifiedFlow(targetFlow, existingSession.user.id);
            navigate('/reset-password', { replace: true });
            return;
          }

          // Before registering an auth-state subscription, ensure current effect is still active
          if (!isMounted || isHandled) return;

          // Otherwise listen for the SIGNED_IN or PASSWORD_RECOVERY event triggered by token verification
          const { data: { subscription } } = supabase.auth.onAuthStateChange(
            (event, session) => {
              if (!isMounted || isHandled) return;

              // Strictly ignore INITIAL_SESSION from localStorage
              if (event === 'INITIAL_SESSION') return;

              if (event === 'PASSWORD_RECOVERY' && session && session.access_token === rawToken) {
                isHandled = true;
                if (activeTimeout) {
                  clearTimeout(activeTimeout);
                  activeTimeout = null;
                }
                subscription.unsubscribe();
                activeSubscription = null;
                recordVerifiedFlow('recovery', session.user.id);
                navigate('/reset-password', { replace: true });
                return;
              }

              if (event === 'SIGNED_IN' && session && session.access_token === rawToken) {
                isHandled = true;
                if (activeTimeout) {
                  clearTimeout(activeTimeout);
                  activeTimeout = null;
                }
                subscription.unsubscribe();
                activeSubscription = null;
                recordVerifiedFlow(targetFlow, session.user.id);
                navigate('/reset-password', { replace: true });
                return;
              }
            }
          );

          // Ensure subscription is not retained if effect was cleaned up concurrently
          if (!isMounted || isHandled) {
            subscription.unsubscribe();
            return;
          }

          activeSubscription = subscription;

          // Safety timeout (5 seconds)
          activeTimeout = setTimeout(() => {
            if (!isMounted || isHandled) return;
            isHandled = true;
            if (activeSubscription) {
              activeSubscription.unsubscribe();
              activeSubscription = null;
            }
            navigate('/invalid-link?code=no_active_flow', { replace: true });
          }, 5000);
          return;
        }

        // Fallback if no flow processed
        if (!isMounted || isHandled) return;
        isHandled = true;
        navigate('/invalid-link?code=no_active_flow', { replace: true });
      } catch (err: unknown) {
        if (!isMounted || isHandled) return;
        isHandled = true;
        const msg = err instanceof Error ? err.message : 'Unknown error';
        navigate(`/invalid-link?code=callback_error&desc=${encodeURIComponent(msg)}`, {
          replace: true,
        });
      }
    }

    processCallback();

    return () => {
      isMounted = false;
      isHandled = true;
      if (activeSubscription) {
        activeSubscription.unsubscribe();
        activeSubscription = null;
      }
      if (activeTimeout) {
        clearTimeout(activeTimeout);
        activeTimeout = null;
      }
    };
  }, [navigate]);

  return (
    <div className="w-full max-w-md mx-auto">
      <div className="bg-white rounded-3xl border border-navy-100/90 shadow-xl overflow-hidden p-8 text-center">
        <div className="inline-flex size-14 items-center justify-center rounded-2xl bg-forest-50 text-forest-700 mb-5">
          <Loader2 size={28} className="animate-spin text-forest-600" />
        </div>

        <div className="inline-flex items-center gap-1.5 rounded-full bg-forest-50 border border-forest-200/80 px-3 py-1 text-xs font-semibold text-forest-700 mb-3">
          <ShieldCheck size={14} className="text-forest-600" />
          Secure Verification
        </div>

        <h1 className="font-display text-xl sm:text-2xl font-bold text-navy-950 mb-2">
          {statusMessage}
        </h1>
        <p className="text-sm text-navy-600 mb-2">
          Establishing your institutional security session.
        </p>
        <p className="text-xs text-navy-400">
          You will be redirected to the password setup form automatically.
        </p>
      </div>
    </div>
  );
}
