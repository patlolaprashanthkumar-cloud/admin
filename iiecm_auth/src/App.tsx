import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { ShieldCheck } from 'lucide-react';
import { SetPasswordPage } from '@/pages/SetPasswordPage';
import { AuthCallbackPage } from '@/pages/AuthCallbackPage';
import { SuccessPage } from '@/pages/SuccessPage';
import { InvalidLinkPage } from '@/pages/InvalidLinkPage';
import iiecmLogo from '@/assets/logo.png';

export default function App() {
  return (
    <BrowserRouter>
      <div className="min-h-screen flex flex-col justify-between bg-[#FFFDF7] text-navy-900 selection:bg-saffron-100 selection:text-forest-900 relative overflow-hidden">
        {/* Soft Ambient Background Orbs */}
        <div className="absolute -top-32 -left-32 w-96 h-96 bg-forest-100/50 rounded-full blur-3xl pointer-events-none" />
        <div className="absolute -bottom-32 -right-32 w-96 h-96 bg-saffron-100/50 rounded-full blur-3xl pointer-events-none" />

        {/* Institutional Header */}
        <header className="relative z-10 w-full px-4 sm:px-8 py-4 border-b border-navy-100/80 bg-white/80 backdrop-blur-md flex items-center justify-between">
          <div className="flex items-center gap-3">
            {/* IIECM Official Emblem */}
            <img
              src={iiecmLogo}
              alt="IIECM Official Emblem"
              className="size-11 sm:size-12 object-contain shrink-0 drop-shadow-sm"
            />
            <div>
              <span className="font-display text-lg sm:text-xl font-bold tracking-tight text-navy-950 block leading-tight">
                IIECM
              </span>
              <span className="text-[10px] sm:text-xs font-semibold tracking-wider uppercase text-navy-500 block">
                International Institute of E-commerce & Management
              </span>
            </div>
          </div>

          <div className="flex items-center gap-2">
            <span className="inline-flex items-center gap-1.5 rounded-full bg-forest-50 border border-forest-200/70 px-3 py-1 text-xs font-semibold text-forest-700">
              <ShieldCheck size={14} className="text-forest-600" />
              <span className="hidden sm:inline">Secure Gateway</span>
            </span>
          </div>
        </header>

        {/* Content Area */}
        <main className="relative z-10 flex-1 flex items-center justify-center p-4 sm:p-6 lg:p-8">
          <Routes>
            <Route path="/reset-password" element={<SetPasswordPage />} />
            <Route path="/auth/callback" element={<AuthCallbackPage />} />
            <Route path="/success" element={<SuccessPage />} />
            <Route path="/invalid-link" element={<InvalidLinkPage />} />
            <Route path="*" element={<Navigate to="/reset-password" replace />} />
          </Routes>
        </main>

        {/* Institutional Footer */}
        <footer className="relative z-10 w-full px-4 sm:px-8 py-4 border-t border-navy-100/80 bg-white/60 backdrop-blur-xs text-center text-xs text-navy-500">
          <p>© {new Date().getFullYear()} International Institute of E-commerce and Management (IIECM). All rights reserved.</p>
          <p className="text-[11px] text-navy-400 mt-0.5">
            Dedicated Authentication Service · <span className="font-mono">auth.iiecm.org</span>
          </p>
        </footer>
      </div>
    </BrowserRouter>
  );
}

