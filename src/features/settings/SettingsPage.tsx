import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Building2, CreditCard, Bell, Shield, Info, User, LogOut } from 'lucide-react';
import { useMockStore } from '@/hooks/useMockStore';
import { useAuth } from '@/hooks/useAuth';
import { Card } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { PageHeader } from '@/components/ui/PageHeader';
import { Input, Textarea, Select, Checkbox } from '@/components/ui/FormField';
import { Button } from '@/components/ui/Button';
import { ConfirmDialog } from '@/components/ui/ConfirmDialog';
import { formatCurrency } from '@/utils';

type SettingsTab = 'institute' | 'categories' | 'plans' | 'notifications' | 'profile' | 'app';

export function SettingsPage() {
  const store = useMockStore();
  const { user, logout, demoMode } = useAuth();
  const navigate = useNavigate();
  const [tab, setTab] = useState<SettingsTab>('institute');
  const [confirmLogout, setConfirmLogout] = useState(false);

  const tabs: { key: SettingsTab; label: string; icon: typeof Building2 }[] = [
    { key: 'institute', label: 'Institute Profile', icon: Building2 },
    { key: 'categories', label: 'Course Categories', icon: Info },
    { key: 'plans', label: 'Subscription Plans', icon: CreditCard },
    { key: 'notifications', label: 'Notifications', icon: Bell },
    { key: 'profile', label: 'Admin Profile', icon: User },
    { key: 'app', label: 'Application', icon: Shield },
  ];

  return (
    <div>
      <PageHeader title="Settings" subtitle="Manage institute and application settings" breadcrumbs={[{ label: 'Dashboard', to: '/dashboard' }, { label: 'Settings' }]} />

      <div className="grid grid-cols-1 lg:grid-cols-4 gap-4">
        <Card className="p-2 lg:col-span-1 h-fit">
          <nav className="space-y-1">
            {tabs.map((t) => (
              <button key={t.key} onClick={() => setTab(t.key)}
                className={`flex items-center gap-3 w-full rounded-lg px-3 py-2.5 text-sm font-medium transition-colors ${tab === t.key ? 'bg-navy-800 text-white' : 'text-navy-600 hover:bg-navy-100'}`}>
                <t.icon size={16} /> {t.label}
              </button>
            ))}
          </nav>
        </Card>

        <div className="lg:col-span-3 space-y-4">
          {tab === 'institute' && (
            <Card title="Institute Profile" className="p-5">
              <div className="space-y-4">
                <div className="flex items-center gap-4">
                  <div className="flex h-16 w-16 items-center justify-center rounded-xl bg-indigo-600 text-white"><Building2 size={28} /></div>
                  <div><p className="text-sm font-semibold text-navy-900">IIECM</p><p className="text-xs text-navy-500">International Institute of E-commerce and Management</p></div>
                </div>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <Input label="Institute Name" defaultValue="IIECM" />
                  <Input label="Email" defaultValue="contact@iiecm.org" />
                  <Input label="Phone" defaultValue="+91 98765 43210" />
                  <Input label="Website" defaultValue="https://iiecm.org" />
                </div>
                <Textarea label="Address" defaultValue="123 Education Hub, Mumbai, Maharashtra 400001" rows={2} />
                <div className="flex justify-end"><Button>Save Changes</Button></div>
              </div>
            </Card>
          )}

          {tab === 'categories' && (
            <Card title="Course Categories" subtitle={`${store.courseCategories.length} categories`}>
              <div className="divide-y divide-navy-50">
                {store.courseCategories.map((c) => (
                  <div key={c.id} className="flex items-center gap-3 px-5 py-3">
                    <div className="h-8 w-8 rounded-lg" style={{ backgroundColor: c.color }} />
                    <div className="flex-1 min-w-0"><p className="text-sm font-medium text-navy-900">{c.name}</p><p className="text-xs text-navy-500">{c.description}</p></div>
                    <Badge variant="info">{store.courses.filter((course) => course.category === c.name).length} courses</Badge>
                  </div>
                ))}
              </div>
            </Card>
          )}

          {tab === 'plans' && (
            <Card title="Subscription Plans" subtitle={`${store.subscriptionPlans.length} plans`}>
              <div className="divide-y divide-navy-50">
                {store.subscriptionPlans.map((p) => (
                  <div key={p.id} className="px-5 py-4">
                    <div className="flex items-center justify-between">
                      <div><p className="text-sm font-semibold text-navy-900">{p.name}</p><p className="text-xs text-navy-500">{p.durationMonths > 0 ? `${p.durationMonths} months` : 'Unlimited'}</p></div>
                      <div className="text-right"><p className="text-sm font-bold text-navy-900">{formatCurrency(p.price)}</p><Badge variant={p.isActive ? 'success' : 'neutral'} dot>{p.isActive ? 'Active' : 'Inactive'}</Badge></div>
                    </div>
                    <ul className="mt-2 text-xs text-navy-600 list-disc pl-4 grid grid-cols-1 sm:grid-cols-2 gap-0.5">{p.features.map((f, i) => <li key={i}>{f}</li>)}</ul>
                  </div>
                ))}
              </div>
            </Card>
          )}

          {tab === 'notifications' && (
            <Card title="Notification Preferences" className="p-5">
              <div className="space-y-3">
                <Checkbox label="Email notifications for new student registrations" defaultChecked />
                <Checkbox label="Email notifications for new payment submissions" defaultChecked />
                <Checkbox label="Email notifications for new enquiries" defaultChecked />
                <Checkbox label="Push notifications for upcoming live classes" defaultChecked />
                <Checkbox label="Weekly summary report via email" />
                <Checkbox label="In-app notification for assessment completions" defaultChecked />
              </div>
              <div className="mt-4 flex justify-end"><Button>Save Preferences</Button></div>
            </Card>
          )}

          {tab === 'profile' && (
            <Card title="Administrator Profile">
              <div className="p-5">
                <div className="flex items-center gap-4 mb-4">
                  <div className="flex h-14 w-14 items-center justify-center rounded-full bg-navy-600 text-white font-semibold">{user?.fullName?.split(' ').map((n) => n[0]).join('')}</div>
                  <div><p className="text-sm font-semibold text-navy-900">{user?.fullName}</p><p className="text-xs text-navy-500">{user?.email}</p></div>
                </div>
                <button className="btn-primary" onClick={() => navigate('/profile')}>Edit Profile</button>
              </div>
            </Card>
          )}

          {tab === 'app' && (
            <div className="space-y-4">
              <Card title="Application Information" className="p-5">
                <dl className="space-y-3 text-sm">
                  <div className="flex justify-between"><dt className="text-navy-500">App Name</dt><dd className="font-medium text-navy-900">IIECM Admin</dd></div>
                  <div className="flex justify-between"><dt className="text-navy-500">Version</dt><dd className="font-medium text-navy-900">1.0.0</dd></div>
                  <div className="flex justify-between"><dt className="text-navy-500">Platform</dt><dd className="font-medium text-navy-900">Web + Android (Capacitor)</dd></div>
                  <div className="flex justify-between"><dt className="text-navy-500">Mode</dt><dd className="font-medium text-navy-900">{demoMode ? 'Demo (no backend)' : 'Connected to Supabase'}</dd></div>
                </dl>
              </Card>
              <Card title="Privacy and Security" className="p-5">
                <p className="text-sm text-navy-600 mb-3">Administrator accounts are provisioned through a controlled internal process. Role-based access control is enforced at the navigation level in the frontend. Production authorization must be enforced through Supabase Row Level Security policies and server-side operations.</p>
                <div className="space-y-2">
                  <div className="flex items-center gap-2 text-sm text-navy-700"><Shield size={16} className="text-teal-500" /> RLS policies required on all database tables</div>
                  <div className="flex items-center gap-2 text-sm text-navy-700"><Shield size={16} className="text-teal-500" /> Server-side payment verification required</div>
                  <div className="flex items-center gap-2 text-sm text-navy-700"><Shield size={16} className="text-teal-500" /> No API keys or secrets exposed in frontend</div>
                </div>
              </Card>
              <Card className="p-5">
                <button onClick={() => setConfirmLogout(true)} className="flex items-center gap-2 text-sm font-medium text-red-600 hover:text-red-700"><LogOut size={16} /> Sign out of admin account</button>
              </Card>
            </div>
          )}
        </div>
      </div>

      <ConfirmDialog open={confirmLogout} onClose={() => setConfirmLogout(false)} onConfirm={async () => { await logout(); navigate('/login'); }} title="Sign out" message="Are you sure you want to sign out?" confirmLabel="Sign out" danger={false} />
    </div>
  );
}
