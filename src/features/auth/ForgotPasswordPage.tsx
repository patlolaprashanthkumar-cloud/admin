import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { Mail, ArrowLeft, CheckCircle, AlertCircle } from 'lucide-react';
import { resetPassword } from '@/services/supabase/auth';
import { Logo } from '@/components/navigation/Logo';
import { Card } from '@/components/ui/Card';

export function ForgotPasswordPage() {
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [error, setError] = useState('');
  const [sent, setSent] = useState(false);
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError('');
    if (!email) { setError('Enter your email address.'); return; }
    setLoading(true);
    const result = await resetPassword(email);
    setLoading(false);
    if (result.error) { setError(result.error); return; }
    setSent(true);
  }

  return (
    <div className="min-h-screen flex flex-col bg-navy-900">
      <div className="flex-1 flex flex-col items-center justify-center px-4 py-8">
        <div className="w-full max-w-sm">
          <div className="flex flex-col items-center mb-8">
            <Logo size="lg" variant="light" />
          </div>

          <Card className="p-6">
            <Link to="/login" className="flex items-center gap-1.5 text-sm text-navy-500 hover:text-navy-700 mb-4">
              <ArrowLeft size={16} /> Back to sign in
            </Link>

            <h1 className="text-xl font-bold text-navy-900 font-display mb-1">Forgot Password</h1>
            <p className="text-sm text-navy-500 mb-5">Enter your email and we'll send you a reset link.</p>

            {error && (
              <div className="mb-4 flex items-start gap-2 rounded-lg bg-red-50 border border-red-200 px-3 py-2.5 text-sm text-red-700">
                <AlertCircle size={16} className="shrink-0 mt-0.5" />
                <span>{error}</span>
              </div>
            )}

            {sent ? (
              <div className="text-center py-4">
                <CheckCircle size={48} className="mx-auto text-teal-500 mb-3" />
                <p className="text-sm font-medium text-navy-900">Reset link sent</p>
                <p className="text-sm text-navy-500 mt-1">Check <strong>{email}</strong> for instructions to reset your password.</p>
                <button onClick={() => navigate('/login')} className="btn-primary mt-4">Back to sign in</button>
              </div>
            ) : (
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
                    />
                  </div>
                </div>
                <button type="submit" disabled={loading} className="btn-primary w-full">
                  {loading ? 'Sending...' : 'Send Reset Link'}
                </button>
              </form>
            )}
          </Card>
        </div>
      </div>
    </div>
  );
}
