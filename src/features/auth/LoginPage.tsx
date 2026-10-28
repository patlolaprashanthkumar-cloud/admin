import { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { Eye, EyeOff, Lock, Mail, AlertCircle, Info } from 'lucide-react';
import { useAuth } from '@/hooks/useAuth';
import { Logo } from '@/components/navigation/Logo';
import { DEMO_CREDENTIALS } from '@/services/supabase/auth';
import { Card } from '@/components/ui/Card';

export function LoginPage() {
  const { login, demoMode } = useAuth();
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError('');
    if (!email || !password) { setError('Please enter your email and password.'); return; }
    setLoading(true);
    const result = await login(email, password);
    setLoading(false);
    if (result.error) { setError(result.error); return; }
    navigate('/dashboard');
  }

  function fillDemo() {
    setEmail(DEMO_CREDENTIALS.email);
    setPassword(DEMO_CREDENTIALS.password);
  }

  return (
    <div className="min-h-screen flex flex-col bg-navy-900">
      <div className="flex-1 flex flex-col items-center justify-center px-4 py-8">
        <div className="w-full max-w-sm">
          <div className="flex flex-col items-center mb-8">
            <div className="flex items-center justify-center rounded-2xl bg-indigo-600 text-white p-3 mb-3">
              <Logo size="lg" variant="light" />
            </div>
            <p className="text-navy-300 text-sm text-center mt-2">
              International Institute of E-commerce and Management
            </p>
          </div>

          <Card className="p-6">
            <h1 className="text-xl font-bold text-navy-900 font-display mb-1">Admin Sign In</h1>
            <p className="text-sm text-navy-500 mb-5">Enter your credentials to access the admin portal.</p>

            {error && (
              <div className="mb-4 flex items-start gap-2 rounded-lg bg-red-50 border border-red-200 px-3 py-2.5 text-sm text-red-700">
                <AlertCircle size={16} className="shrink-0 mt-0.5" />
                <span>{error}</span>
              </div>
            )}

            {demoMode && (
              <div className="mb-4 flex items-start gap-2 rounded-lg bg-cyan-50 border border-cyan-200 px-3 py-2.5 text-sm text-cyan-800">
                <Info size={16} className="shrink-0 mt-0.5" />
                <div>
                  <p className="font-medium">Demo Mode — no backend connected</p>
                  <p className="text-xs mt-0.5">Email: <strong>{DEMO_CREDENTIALS.email}</strong> · Password: <strong>{DEMO_CREDENTIALS.password}</strong></p>
                  <button onClick={fillDemo} className="text-xs font-semibold text-cyan-700 underline mt-1">Fill demo credentials</button>
                </div>
              </div>
            )}

            <form onSubmit={handleSubmit} className="space-y-4">
              <div>
                <label className="label-base">Email Address</label>
                <div className="relative">
                  <Mail size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-navy-400" />
                  <input
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="admin@iiecm.org"
                    className="input-base pl-10"
                    autoComplete="email"
                  />
                </div>
              </div>

              <div>
                <label className="label-base">Password</label>
                <div className="relative">
                  <Lock size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-navy-400" />
                  <input
                    type={password ? 'text' : 'text'}
                    {...(showPassword ? {} : { type: 'password' })}
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="Enter your password"
                    className="input-base pl-10 pr-10"
                    autoComplete="current-password"
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword((v) => !v)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-navy-400 hover:text-navy-700"
                  >
                    {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                  </button>
                </div>
              </div>

              <div className="flex justify-end">
                <Link to="/forgot-password" className="text-sm font-medium text-indigo-600 hover:text-indigo-700">
                  Forgot password?
                </Link>
              </div>

              <button type="submit" disabled={loading} className="btn-primary w-full">
                {loading ? (
                  <span className="flex items-center gap-2">
                    <span className="h-4 w-4 animate-spin rounded-full border-2 border-white/30 border-t-white" />
                    Signing in...
                  </span>
                ) : 'Sign In'}
              </button>
            </form>
          </Card>

          <p className="text-center text-xs text-navy-400 mt-6">
            Administrator accounts are provisioned internally.<br />
            Contact your system administrator for access.
          </p>
        </div>
      </div>
    </div>
  );
}
