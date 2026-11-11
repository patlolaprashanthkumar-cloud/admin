import { useEffect, useState } from 'react';
import { useLocation } from 'react-router-dom';
import { CheckCircle2, Smartphone, ExternalLink, ShieldCheck, LogOut } from 'lucide-react';
import { supabase } from '@/lib/supabase';

interface SuccessLocationState {
  email?: string;
  role?: string;
  fullName?: string;
  flowType?: string;
}

export function SuccessPage() {
  const location = useLocation();
  const state = (location.state as SuccessLocationState) || {};

  const [email, setEmail] = useState<string | undefined>(state.email);
  const [role, setRole] = useState<string | undefined>(state.role);
  const [isSignedOut, setIsSignedOut] = useState<boolean>(false);

  useEffect(() => {
    // If state wasn't passed via router navigation (e.g. direct refresh), inspect session
    if (!email && supabase) {
      supabase.auth.getUser().then(({ data: { user } }) => {
        if (user) {
          setEmail(user.email);
          setRole(user.user_metadata?.role);
        }
      });
    }
  }, [email]);

  async function handleSignOut() {
    if (supabase) {
      await supabase.auth.signOut();
      setIsSignedOut(true);
    }
  }

  // Determine role-specific instructions
  const isStudent = role === 'student';
  const isInstructor = role === 'instructor';
  const isAdmin = role === 'admin';

  return (
    <div className="w-full max-w-md mx-auto">
      <div className="bg-white rounded-3xl border border-navy-100/90 shadow-xl overflow-hidden p-6 sm:p-8 text-center">
        {/* Success Icon */}
        <div className="inline-flex size-16 items-center justify-center rounded-3xl bg-forest-50 text-forest-600 mb-5 border border-forest-100 shadow-sm">
          <CheckCircle2 size={38} className="text-forest-600" />
        </div>

        {/* Badge */}
        <div className="inline-flex items-center gap-1.5 rounded-full bg-forest-50 border border-forest-200/80 px-3 py-1 text-xs font-semibold text-forest-700 mb-3">
          <ShieldCheck size={14} className="text-forest-600" />
          {isStudent
            ? 'Student Account Activated'
            : isInstructor
            ? 'Instructor Account Activated'
            : isAdmin
            ? 'Admin Account Verified'
            : 'Password Confirmed'}
        </div>

        <h1 className="font-display text-2xl sm:text-3xl font-bold text-navy-950 mb-2">
          Password Set Successfully
        </h1>
        <p className="text-sm text-navy-600 mb-6 leading-relaxed">
          Your credentials have been securely registered with IIECM Institutional Auth.
        </p>

        {/* Role-Specific Mobile App Guidance */}
        <div className="rounded-2xl bg-navy-50/90 border border-navy-100 p-4 mb-6 text-left">
          <div className="flex items-center gap-2 mb-2">
            <Smartphone size={18} className="text-forest-700" />
            <h2 className="text-xs font-bold uppercase tracking-wider text-navy-900">
              {isStudent
                ? 'Open the IIECM Student App'
                : isInstructor
                ? 'Open the IIECM Instructor App'
                : 'Open Your Mobile App'}
            </h2>
          </div>
          <p className="text-xs text-navy-600 leading-relaxed">
            {isStudent && (
              <>
                Please launch the <strong>IIECM Student App</strong> installed on your mobile device.
                Sign in using your registered email{email ? ` (${email})` : ''} and your newly set password.
              </>
            )}
            {isInstructor && (
              <>
                Please launch the <strong>IIECM Instructor App</strong> installed on your mobile device.
                Sign in using your registered email{email ? ` (${email})` : ''} and your newly set password.
              </>
            )}
            {!isStudent && !isInstructor && (
              <>
                Please launch the <strong>IIECM Student App</strong> or <strong>IIECM Instructor App</strong> on your mobile device.
                Sign in using your registered email{email ? ` (${email})` : ''} and your newly set password.
              </>
            )}
          </p>
        </div>

        {/* Browser Session Security Notice */}
        <div className="border-t border-navy-100/80 pt-5 mt-2 flex flex-col items-center gap-3">
          {!isSignedOut ? (
            <button
              type="button"
              onClick={handleSignOut}
              className="inline-flex items-center gap-1.5 text-xs font-medium text-navy-500 hover:text-navy-800 transition-colors"
            >
              <LogOut size={13} />
              <span>Sign out of web browser session</span>
            </button>
          ) : (
            <span className="text-xs text-forest-700 font-medium">
              Web browser session signed out securely.
            </span>
          )}

          <a
            href="https://iiecm.org"
            target="_blank"
            rel="noreferrer"
            className="inline-flex items-center gap-1.5 text-xs font-semibold text-forest-700 hover:text-forest-800 transition-colors"
          >
            <span>Visit IIECM Official Website</span>
            <ExternalLink size={13} />
          </a>
        </div>
      </div>
    </div>
  );
}
