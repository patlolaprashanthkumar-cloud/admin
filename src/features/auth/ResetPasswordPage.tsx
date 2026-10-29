import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { Lock, Eye, EyeOff, ArrowLeft, CheckCircle, AlertCircle } from 'lucide-react';
import { updatePassword } from '@/services/supabase/auth';
import { Logo } from '@/components/navigation/Logo';
import { Card } from '@/components/ui/Card';

export function ResetPasswordPage() {
  const navigate = useNavigate();
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState(false);
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError('');
    if (password.length < 8) { setError('Password must be at least 8 characters.'); return; }
    if (password !== confirmPassword) { setError('Passwords do not match.'); return; }
    setLoading(true);
    const result = await updatePassword(password);
    setLoading(false);
    if (result.error) { setError(result.error); return; }
    setSuccess(true);
    setTimeout(() => navigate('/login'), 2000);
  }

  return (
    <div className="min-h-screen flex flex-col bg-navy-900">
      <div className="flex-1 flex flex-col items-center justify-center px-4 py-8">
        <div className="w-full max-w-sm">
          <div className="flex flex-col items-center mb-8">
            <Logo size="lg" variant="light" />
          </div>

          <Card className="p-6 shadow-elevated">
            <Link to="/login" className="flex items-center gap-1.5 text-sm text-navy-500 hover:text-forest-600 transition-colors mb-4">
              <ArrowLeft size={16} /> Back to sign in
            </Link>

            <h1 className="text-xl font-bold text-navy-900 font-display mb-1">Set New Password</h1>
            <p className="text-sm text-navy-500 mb-5">Enter your new password below.</p>

            {error && (
              <div className="mb-4 flex items-start gap-2 rounded-lg bg-red-50 border border-red-200 px-3 py-2.5 text-sm text-red-700">
                <AlertCircle size={16} className="shrink-0 mt-0.5" />
                <span>{error}</span>
              </div>
            )}

            {success ? (
              <div className="text-center py-4">
                <CheckCircle size={48} className="mx-auto text-forest-600 mb-3" />
                <p className="text-sm font-medium text-navy-900">Password updated</p>
                <p className="text-sm text-navy-500 mt-1">Redirecting you to sign in...</p>
              </div>
            ) : (
              <form onSubmit={handleSubmit} className="space-y-4">
                <div>
                  <label className="label-base">New Password</label>
                  <div className="relative">
                    <Lock size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-navy-400" />
                    <input
                      type={showPassword ? 'text' : 'password'}
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      placeholder="At least 8 characters"
                      className="input-base pl-10 pr-10"
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

                <div>
                  <label className="label-base">Confirm Password</label>
                  <div className="relative">
                    <Lock size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-navy-400" />
                    <input
                      type={showPassword ? 'text' : 'password'}
                      value={confirmPassword}
                      onChange={(e) => setConfirmPassword(e.target.value)}
                      placeholder="Confirm your password"
                      className="input-base pl-10"
                    />
                  </div>
                </div>

                <button type="submit" disabled={loading} className="btn-primary w-full">
                  {loading ? 'Updating...' : 'Update Password'}
                </button>
              </form>
            )}
          </Card>
        </div>
      </div>
    </div>
  );
}
