import { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { Eye, EyeOff, Lock, Mail, AlertCircle, ArrowRight, ShieldCheck, Sparkles } from 'lucide-react';
import { useAuth } from '@/hooks/useAuth';
import { Logo } from '@/components/navigation/Logo';
import heroStudentImg from '@/assets/hero-student.jpg';

export function LoginPage() {
  const { login } = useAuth();
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError('');
    if (!email || !password) {
      setError('Please enter your email and password.');
      return;
    }
    setLoading(true);
    const result = await login(email, password);
    setLoading(false);
    if (result.error) {
      setError(result.error);
      return;
    }
    navigate('/dashboard');
  }

  return (
    <div className="min-h-screen bg-[#FFFDF7] text-navy-900 flex flex-col justify-between selection:bg-peach-200 selection:text-forest-900">
      {/* Top Header Bar */}
      <header className="w-full px-6 py-4 border-b border-navy-100/70 bg-white/70 backdrop-blur-md flex items-center justify-between">
        <Logo size="md" variant="dark" />
        <div className="flex items-center gap-3">
          <a
            href="https://iiecm.org"
            target="_blank"
            rel="noreferrer"
            className="hidden sm:inline-flex items-center gap-1.5 text-xs font-semibold text-navy-600 hover:text-forest-600 transition-colors"
          >
            Visit IIECM.org <ArrowRight size={13} />
          </a>
          <span className="inline-flex items-center gap-1 rounded-full bg-forest-50 border border-forest-200/60 px-2.5 py-0.5 text-[11px] font-semibold text-forest-700">
            <ShieldCheck size={12} className="text-forest-600" /> Secure Admin Gateway
          </span>
        </div>
      </header>

      {/* Main Container: Seamless unified split layout with NO gap between hero & login */}
      <main className="flex-1 flex items-center justify-center p-4 sm:p-6 lg:p-8">
        <div className="w-full max-w-5xl bg-white rounded-3xl border border-navy-100/90 shadow-elevated overflow-hidden grid grid-cols-1 lg:grid-cols-12">
          {/* Left Hero Column: Exact IIECM.org Style */}
          <div className="lg:col-span-7 bg-gradient-to-br from-[#FFFDF7] via-[#FFF9F3] to-[#F6F0E6] p-6 sm:p-8 lg:p-10 flex flex-col justify-between relative overflow-hidden border-b lg:border-b-0 lg:border-r border-navy-100/80">
            {/* Ambient Background Glow */}
            <div className="absolute -top-24 -left-24 w-96 h-96 bg-sage-200/40 rounded-full blur-3xl pointer-events-none" />
            <div className="absolute -bottom-24 -right-24 w-96 h-96 bg-peach-100/50 rounded-full blur-3xl pointer-events-none" />

            {/* Header / Badge */}
            <div className="relative z-10">
              <div className="inline-flex items-center gap-2 rounded-full bg-saffron-50 border border-saffron-200/80 px-3.5 py-1 text-xs font-semibold text-saffron-700 w-fit mb-3.5 shadow-xs">
                <span className="h-1.5 w-1.5 rounded-full bg-saffron-500 animate-pulse" />
                LEARN · GROW · LEAD
              </div>

              <h1 className="font-display text-3xl sm:text-4xl lg:text-[2.75rem] font-bold tracking-tight text-forest-600 leading-[1.14]">
                Guidance That <br />
                <span className="text-saffron-600">Moves You Forward.</span>
              </h1>
            </div>

            {/* Visual Showcase: Student Hero & Floating Badge */}
            <div className="relative z-10 mt-6 sm:mt-8 flex items-end justify-center lg:justify-start">
              <div className="relative">
                <img
                  src={heroStudentImg}
                  alt="IIECM Scholar"
                  className="max-h-[260px] sm:max-h-[320px] w-auto object-contain drop-shadow-xl"
                />

                {/* Floating Pill Badge mimicking IIECM.org CTA */}
                <div className="absolute bottom-2 -right-2 sm:right-0 bg-white/95 backdrop-blur-md rounded-2xl border border-navy-100 p-3 shadow-elevated max-w-[210px]">
                  <div className="flex items-center gap-2">
                    <span className="flex size-7 items-center justify-center rounded-lg bg-forest-500 text-white shadow-xs">
                      <Sparkles size={14} />
                    </span>
                    <span className="inline-block rounded-md bg-forest-500 px-1.5 py-0.5 text-[9px] font-bold uppercase tracking-wider text-white">
                      INTERACTIVE
                    </span>
                  </div>
                  <p className="text-xs font-bold text-navy-900 mt-1">Career & Skill Pathways</p>
                  <p className="text-[10px] text-navy-500 leading-tight mt-0.5">Accredited programmes</p>
                </div>
              </div>
            </div>
          </div>

          {/* Right Sign-in Form Column: Directly adjacent with 0 gap */}
          <div className="lg:col-span-5 p-6 sm:p-8 lg:p-10 flex flex-col justify-center bg-white relative">
            <div className="absolute top-0 left-0 right-0 h-1.5 bg-gradient-to-r from-forest-500 via-saffron-500 to-peach-500" />

            <div className="mb-6">
              <span className="text-[10px] font-bold uppercase tracking-wider text-forest-600 bg-forest-50 px-2.5 py-1 rounded-full border border-forest-200/50">
                Administration Portal
              </span>
              <h2 className="text-2xl font-bold font-display text-navy-900 mt-2">Sign in to your account</h2>
              <p className="text-xs text-navy-500 mt-1">
                Enter your administrative credentials to access portal tools.
              </p>
            </div>

            {error && (
              <div className="mb-5 flex items-start gap-2 rounded-xl bg-red-50 border border-red-200 px-3.5 py-3 text-xs sm:text-sm text-red-700 animate-fade-in">
                <AlertCircle size={17} className="shrink-0 mt-0.5 text-red-600" />
                <span className="leading-relaxed">{error}</span>
              </div>
            )}

            <form onSubmit={handleSubmit} className="space-y-4">
              <div>
                <label className="label-base text-xs font-semibold uppercase tracking-wider text-navy-700">
                  Email Address
                </label>
                <div className="relative">
                  <Mail size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-navy-400" />
                  <input
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="admin@example.com"
                    className="input-base pl-10"
                    autoComplete="email"
                    required
                  />
                </div>
              </div>

              <div>
                <div className="flex items-center justify-between mb-1.5">
                  <label className="label-base text-xs font-semibold uppercase tracking-wider text-navy-700 mb-0">
                    Password
                  </label>
                  <Link
                    to="/forgot-password"
                    className="text-xs font-medium text-peach-600 hover:text-peach-700 transition-colors"
                  >
                    Forgot password?
                  </Link>
                </div>
                <div className="relative">
                  <Lock size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-navy-400" />
                  <input
                    type={showPassword ? 'text' : 'password'}
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="Enter your password"
                    className="input-base pl-10 pr-10"
                    autoComplete="current-password"
                    required
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword((v) => !v)}
                    className="absolute right-3.5 top-1/2 -translate-y-1/2 text-navy-400 hover:text-navy-700"
                    aria-label={showPassword ? 'Hide password' : 'Show password'}
                  >
                    {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                  </button>
                </div>
              </div>

              <button
                type="submit"
                disabled={loading}
                className="btn-primary w-full py-3 rounded-xl font-semibold text-sm shadow-sm hover:shadow transition-all mt-2 cursor-pointer"
              >
                {loading ? (
                  <span className="flex items-center justify-center gap-2">
                    <span className="h-4 w-4 animate-spin rounded-full border-2 border-white/30 border-t-white" />
                    Authenticating...
                  </span>
                ) : (
                  <span className="flex items-center justify-center gap-2">
                    Sign In <ArrowRight size={16} />
                  </span>
                )}
              </button>
            </form>

            <div className="mt-6 pt-5 border-t border-navy-100 text-center">
              <p className="text-xs text-navy-400">
                Internal institutional access only.<br />
                Managed by International Institute of E-commerce and Management.
              </p>
            </div>
          </div>
        </div>
      </main>

      {/* Footer */}
      <footer className="w-full py-4 text-center text-xs text-navy-400 border-t border-navy-100/60 bg-white/40">
        © {new Date().getFullYear()} IIECM Foundation. All rights reserved.
      </footer>
    </div>
  );
}
