import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '@/hooks/useAuth';
import { updatePassword as updatePasswordFromAuth } from '@/services/supabase/auth';
import { Avatar } from '@/components/ui/Avatar';
import { Card } from '@/components/ui/Card';
import { PageHeader } from '@/components/ui/PageHeader';
import { Badge } from '@/components/ui/Badge';
import { Modal, Input, Button } from '@/components/ui';
import { roleLabel } from '@/utils/permissions';
import { formatDate, formatDateTime } from '@/utils';

export function ProfilePage() {
  const { user, updateUser, demoMode } = useAuth();
  const navigate = useNavigate();
  const [editOpen, setEditOpen] = useState(false);
  const [passwordOpen, setPasswordOpen] = useState(false);
  const [fullName, setFullName] = useState(user?.fullName ?? '');
  const [phone, setPhone] = useState(user?.phone ?? '');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  if (!user) return null;

  function saveProfile() {
    if (!fullName.trim()) { setError('Name cannot be empty.'); return; }
    updateUser({ fullName: fullName.trim(), phone: phone.trim() });
    setEditOpen(false);
    setError('');
    setSuccess('Profile updated successfully.');
    setTimeout(() => setSuccess(''), 3000);
  }

  async function changePassword() {
    setError('');
    if (newPassword.length < 8) { setError('Password must be at least 8 characters.'); return; }
    if (newPassword !== confirmPassword) { setError('Passwords do not match.'); return; }
    const result = await updatePasswordFromAuth(newPassword);
    if (result.error) { setError(result.error); return; }
    setPasswordOpen(false);
    setNewPassword('');
    setConfirmPassword('');
    setSuccess('Password changed successfully.');
    setTimeout(() => setSuccess(''), 3000);
  }

  return (
    <div>
      <PageHeader
        title="My Profile"
        breadcrumbs={[{ label: 'Settings', to: '/settings' }, { label: 'Profile' }]}
        actions={
          <button className="btn-primary" onClick={() => { setFullName(user.fullName); setPhone(user.phone ?? ''); setEditOpen(true); }}>
            Edit Profile
          </button>
        }
      />

      {success && (
        <div className="mb-4 rounded-lg bg-teal-50 border border-teal-200 px-4 py-3 text-sm text-teal-700 animate-slide-down">
          {success}
        </div>
      )}

      <div className="grid gap-4 md:grid-cols-3">
        <Card className="md:col-span-1 p-6 text-center">
          <Avatar name={user.fullName} size="lg" className="mx-auto" />
          <h2 className="mt-4 text-lg font-semibold text-navy-900">{user.fullName}</h2>
          <p className="text-sm text-navy-500">{user.email}</p>
          <div className="mt-2 flex justify-center">
            <Badge variant="info">{roleLabel(user.role)}</Badge>
          </div>
          <button onClick={() => setPasswordOpen(true)} className="btn-secondary w-full mt-4">
            Change Password
          </button>
        </Card>

        <Card className="md:col-span-2" title="Administrator Details">
          <dl className="divide-y divide-navy-50">
            <div className="px-5 py-3 flex justify-between">
              <dt className="text-sm text-navy-500">Full Name</dt>
              <dd className="text-sm font-medium text-navy-900">{user.fullName}</dd>
            </div>
            <div className="px-5 py-3 flex justify-between">
              <dt className="text-sm text-navy-500">Email</dt>
              <dd className="text-sm font-medium text-navy-900">{user.email}</dd>
            </div>
            <div className="px-5 py-3 flex justify-between">
              <dt className="text-sm text-navy-500">Phone</dt>
              <dd className="text-sm font-medium text-navy-900">{user.phone ?? '—'}</dd>
            </div>
            <div className="px-5 py-3 flex justify-between">
              <dt className="text-sm text-navy-500">Role</dt>
              <dd className="text-sm font-medium text-navy-900">{roleLabel(user.role)}</dd>
            </div>
            <div className="px-5 py-3 flex justify-between">
              <dt className="text-sm text-navy-500">Member Since</dt>
              <dd className="text-sm font-medium text-navy-900">{formatDate(user.createdAt)}</dd>
            </div>
            <div className="px-5 py-3 flex justify-between">
              <dt className="text-sm text-navy-500">Last Login</dt>
              <dd className="text-sm font-medium text-navy-900">{user.lastLoginAt ? formatDateTime(user.lastLoginAt) : '—'}</dd>
            </div>
          </dl>
        </Card>
      </div>

      {demoMode && (
        <div className="mt-4 rounded-lg bg-cyan-50 border border-cyan-200 px-4 py-3 text-sm text-cyan-800">
          <strong>Demo Mode:</strong> Profile changes are stored locally and will be lost when you clear browser data. Connect Supabase for persistent profiles.
        </div>
      )}

      <Modal open={editOpen} onClose={() => setEditOpen(false)} title="Edit Profile"
        footer={<><button className="btn-secondary" onClick={() => setEditOpen(false)}>Cancel</button><button className="btn-primary" onClick={saveProfile}>Save</button></>}
      >
        <div className="space-y-4">
          {error && <p className="text-sm text-red-600">{error}</p>}
          <Input label="Full Name" value={fullName} onChange={(e) => setFullName(e.target.value)} />
          <Input label="Phone" value={phone} onChange={(e) => setPhone(e.target.value)} placeholder="+91 98765 43210" />
        </div>
      </Modal>

      <Modal open={passwordOpen} onClose={() => setPasswordOpen(false)} title="Change Password"
        footer={<><button className="btn-secondary" onClick={() => setPasswordOpen(false)}>Cancel</button><button className="btn-primary" onClick={changePassword}>Update</button></>}
      >
        <div className="space-y-4">
          {error && <p className="text-sm text-red-600">{error}</p>}
          <Input label="New Password" type="password" value={newPassword} onChange={(e) => setNewPassword(e.target.value)} placeholder="At least 8 characters" />
          <Input label="Confirm Password" type="password" value={confirmPassword} onChange={(e) => setConfirmPassword(e.target.value)} placeholder="Re-enter password" />
        </div>
      </Modal>
    </div>
  );
}
