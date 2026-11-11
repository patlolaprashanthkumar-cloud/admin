import { useSearchParams, Link } from 'react-router-dom';
import { AlertTriangle, Mail, ArrowLeft, ShieldAlert, ExternalLink } from 'lucide-react';
import { mapAuthError } from '@/lib/authFlow';

export function InvalidLinkPage() {
  const [searchParams] = useSearchParams();
  const errorCode = searchParams.get('code') || undefined;
  const errorDesc = searchParams.get('desc') || undefined;

  const { title, message } = mapAuthError(errorCode, errorDesc);

  return (
    <div className="w-full max-w-md mx-auto">
      <div className="bg-white rounded-3xl border border-navy-100/90 shadow-xl overflow-hidden p-6 sm:p-8 text-center">
        {/* Warning Icon */}
        <div className="inline-flex size-16 items-center justify-center rounded-3xl bg-amber-50 text-amber-600 mb-5 border border-amber-100 shadow-sm">
          <AlertTriangle size={36} className="text-amber-600" />
        </div>

        {/* Badge */}
        <div className="inline-flex items-center gap-1.5 rounded-full bg-amber-50 border border-amber-200/80 px-3 py-1 text-xs font-semibold text-amber-800 mb-3">
          <ShieldAlert size={14} className="text-amber-700" />
          Link Verification Failed
        </div>

        <h1 className="font-display text-2xl sm:text-3xl font-bold text-navy-950 mb-2">
          {title}
        </h1>
        <p className="text-sm text-navy-600 mb-6 leading-relaxed">
          {message}
        </p>

        {/* Administrative Guidance Card */}
        <div className="rounded-2xl bg-navy-50/90 border border-navy-100 p-4 mb-6 text-left">
          <div className="flex items-center gap-2 mb-2">
            <Mail size={17} className="text-forest-700" />
            <h2 className="text-xs font-bold uppercase tracking-wider text-navy-900">
              Need a New Invitation?
            </h2>
          </div>
          <p className="text-xs text-navy-600 leading-relaxed mb-3">
            Institutional invitation links can only be used once and expire for your protection.
            Please reach out to the IIECM administration desk to request a fresh activation link.
          </p>
          <a
            href="mailto:support@iiecm.org?subject=IIECM%20Account%20Activation%20Link%20Request"
            className="inline-flex items-center gap-1.5 text-xs font-bold text-forest-700 hover:text-forest-800 transition-colors"
          >
            <span>Email Administration: support@iiecm.org</span>
            <ExternalLink size={12} />
          </a>
        </div>

        {/* Action Links */}
        <div className="border-t border-navy-100/80 pt-4 flex items-center justify-between text-xs">
          <Link
            to="/reset-password"
            className="inline-flex items-center gap-1.5 font-semibold text-navy-600 hover:text-navy-900 transition-colors"
          >
            <ArrowLeft size={14} />
            <span>Try setup again</span>
          </Link>

          <a
            href="https://iiecm.org"
            target="_blank"
            rel="noreferrer"
            className="font-semibold text-forest-700 hover:text-forest-800 transition-colors"
          >
            IIECM Website
          </a>
        </div>
      </div>
    </div>
  );
}
