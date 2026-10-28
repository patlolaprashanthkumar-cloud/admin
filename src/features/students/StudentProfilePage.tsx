import { useState } from 'react';
import { useParams, useNavigate, Link } from 'react-router-dom';
import { ArrowLeft, Pencil, Mail, Phone, MapPin, Calendar, FileText, Award, BookOpen, CreditCard, Compass, Save } from 'lucide-react';
import { useMockStore } from '@/hooks/useMockStore';
import { mockStore } from '@/mock-data/store';
import { Card } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { Avatar } from '@/components/ui/Avatar';
import { PageHeader } from '@/components/ui/PageHeader';
import { Button } from '@/components/ui/Button';
import { Input, Select, Checkbox } from '@/components/ui/FormField';
import { EmptyState } from '@/components/ui/State';
import { formatDate, formatCurrency } from '@/utils';
import type { Student, AccountStatus, SubscriptionPlan } from '@/types';

type Tab = 'overview' | 'courses' | 'assessments' | 'payments' | 'career';

export function StudentProfilePage() {
  const { id } = useParams<{ id: string }>();
  const store = useMockStore();
  const navigate = useNavigate();
  const [editing, setEditing] = useState(false);
  const [tab, setTab] = useState<Tab>('overview');

  const studentFound = store.students.find((s) => s.id === id);

  if (!studentFound) {
    return <EmptyState title="Student not found" description="This student may have been removed." action={<Link to="/students" className="btn-primary">Back to Students</Link>} />;
  }

  const student: Student = studentFound;

  const enrolledCourses = store.courses.filter((c) => student.enrolledCourseIds.includes(c.id));
  const studentPayments = store.payments.filter((p) => p.studentId === student.id);
  const studentResults = store.assessmentResults.filter((r) => r.studentId === student.id);
  const appointments = store.careerAppointments.filter((a) => a.studentId === student.id);
  const actionPlan = store.careerActionPlans.find((p) => p.studentId === student.id);

  const [form, setForm] = useState({
    fullName: student.fullName, email: student.email, phone: student.phone,
    educationLevel: student.educationLevel, qualification: student.qualification,
    preferredCategory: student.preferredCategory, subscriptionPlan: student.subscriptionPlan,
    accountStatus: student.accountStatus, city: student.city ?? '',
  });

  function saveEdit() {
    mockStore.updateStudent(student.id, {
      fullName: form.fullName, email: form.email, phone: form.phone,
      educationLevel: form.educationLevel, qualification: form.qualification,
      preferredCategory: form.preferredCategory, subscriptionPlan: form.subscriptionPlan,
      accountStatus: form.accountStatus, city: form.city || undefined,
    });
    setEditing(false);
  }

  const tabs: { key: Tab; label: string; icon: typeof BookOpen }[] = [
    { key: 'overview', label: 'Overview', icon: FileText },
    { key: 'courses', label: 'Courses', icon: BookOpen },
    { key: 'assessments', label: 'Assessments', icon: Award },
    { key: 'payments', label: 'Payments', icon: CreditCard },
    { key: 'career', label: 'Career', icon: Compass },
  ];

  return (
    <div>
      <PageHeader
        title={student.fullName}
        subtitle={`${student.studentId} · ${student.preferredCategory}`}
        breadcrumbs={[{ label: 'Dashboard', to: '/dashboard' }, { label: 'Students', to: '/students' }, { label: student.studentId }]}
        actions={
          <>
            <Link to="/students" className="btn-secondary"><ArrowLeft size={16} /> Back</Link>
            <button className="btn-primary" onClick={() => setEditing(true)}><Pencil size={16} /> Edit</button>
          </>
        }
      />

      <Card className="p-5 mb-4">
        <div className="flex flex-col sm:flex-row items-start gap-4">
          <Avatar name={student.fullName} size="lg" />
          <div className="flex-1 min-w-0">
            <h2 className="text-lg font-bold text-navy-900">{student.fullName}</h2>
            <p className="text-sm text-navy-500">{student.email}</p>
            <div className="mt-2 flex flex-wrap gap-2">
              <Badge variant={student.accountStatus === 'active' ? 'success' : student.accountStatus === 'suspended' ? 'danger' : 'neutral'} dot>{student.accountStatus}</Badge>
              <Badge variant="info">{student.subscriptionPlan}</Badge>
              <Badge variant={student.subscriptionStatus === 'active' ? 'success' : 'warning'}>{student.subscriptionStatus}</Badge>
            </div>
          </div>
          <div className="grid grid-cols-2 gap-4 text-center">
            <div><p className="text-2xl font-bold text-navy-900">{enrolledCourses.length}</p><p className="text-xs text-navy-500">Courses</p></div>
            <div><p className="text-2xl font-bold text-navy-900">{studentResults.length}</p><p className="text-xs text-navy-500">Assessments</p></div>
          </div>
        </div>
      </Card>

      <div className="flex gap-1 mb-4 overflow-x-auto pb-1">
        {tabs.map((t) => (
          <button
            key={t.key}
            onClick={() => setTab(t.key)}
            className={`flex items-center gap-2 rounded-lg px-4 py-2 text-sm font-medium whitespace-nowrap transition-colors ${tab === t.key ? 'bg-navy-800 text-white' : 'text-navy-600 hover:bg-navy-100'}`}
          >
            <t.icon size={16} /> {t.label}
          </button>
        ))}
      </div>

      {tab === 'overview' && (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <Card title="Contact Information">
            <dl className="divide-y divide-navy-50 px-5">
              <InfoRow icon={<Mail size={14} />} label="Email" value={student.email} />
              <InfoRow icon={<Phone size={14} />} label="Phone" value={student.phone} />
              <InfoRow icon={<MapPin size={14} />} label="City" value={student.city ?? '—'} />
              <InfoRow icon={<Calendar size={14} />} label="Joined" value={formatDate(student.createdAt)} />
            </dl>
          </Card>
          <Card title="Academic Information">
            <dl className="divide-y divide-navy-50 px-5">
              <InfoRow label="Education Level" value={student.educationLevel} />
              <InfoRow label="Qualification" value={student.qualification} />
              <InfoRow label="Preferred Category" value={student.preferredCategory} />
              <InfoRow icon={<FileText size={14} />} label="Resume" value={student.resumeUploaded ? 'Uploaded' : 'Not uploaded'} />
            </dl>
          </Card>
          <Card title="Subscription Details">
            <dl className="divide-y divide-navy-50 px-5">
              <InfoRow label="Plan" value={student.subscriptionPlan} />
              <InfoRow label="Status" value={student.subscriptionStatus} />
              <InfoRow label="Start Date" value={student.subscriptionStart ? formatDate(student.subscriptionStart) : '—'} />
              <InfoRow label="Expiry" value={student.subscriptionExpiry ? formatDate(student.subscriptionExpiry) : '—'} />
            </dl>
          </Card>
          <Card title="Career Guidance">
            <dl className="divide-y divide-navy-50 px-5">
              <InfoRow icon={<Compass size={14} />} label="Status" value={student.careerGuidanceStatus.replace('_', ' ')} />
              <InfoRow label="Appointments" value={`${appointments.length}`} />
              <InfoRow label="Action Plan" value={actionPlan ? 'Available' : 'None'} />
            </dl>
          </Card>
        </div>
      )}

      {tab === 'courses' && (
        <Card title={`Enrolled Courses (${enrolledCourses.length})`}>
          {enrolledCourses.length === 0 ? <EmptyState title="No courses enrolled" /> : (
            <div className="divide-y divide-navy-50">
              {enrolledCourses.map((c) => (
                <div key={c.id} className="flex items-center gap-3 px-5 py-3 hover:bg-navy-50/40 cursor-pointer" onClick={() => navigate(`/courses/${c.id}`)}>
                  <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-teal-100 text-teal-600"><BookOpen size={18} /></div>
                  <div className="min-w-0 flex-1"><p className="text-sm font-medium text-navy-900 truncate">{c.title}</p><p className="text-xs text-navy-500">{c.category} · {c.durationWeeks} weeks</p></div>
                  <Badge variant={c.status === 'published' ? 'success' : 'neutral'}>{c.status}</Badge>
                </div>
              ))}
            </div>
          )}
        </Card>
      )}

      {tab === 'assessments' && (
        <Card title={`Assessment History (${studentResults.length})`}>
          {studentResults.length === 0 ? <EmptyState title="No assessments taken" /> : (
            <div className="divide-y divide-navy-50">
              {studentResults.map((r) => (
                <div key={r.id} className="flex items-center gap-3 px-5 py-3">
                  <div className={`flex h-10 w-10 items-center justify-center rounded-lg ${r.passed ? 'bg-teal-100 text-teal-600' : 'bg-red-100 text-red-600'}`}><Award size={18} /></div>
                  <div className="min-w-0 flex-1"><p className="text-sm font-medium text-navy-900 truncate">{r.assessmentTitle}</p><p className="text-xs text-navy-500">Scored {r.score}/{r.totalMarks} · {r.percentage}%</p></div>
                  <Badge variant={r.passed ? 'success' : 'danger'}>{r.passed ? 'Passed' : 'Failed'}</Badge>
                </div>
              ))}
            </div>
          )}
        </Card>
      )}

      {tab === 'payments' && (
        <Card title={`Payment History (${studentPayments.length})`}>
          {studentPayments.length === 0 ? <EmptyState title="No payments recorded" /> : (
            <div className="divide-y divide-navy-50">
              {studentPayments.map((p) => (
                <div key={p.id} className="flex items-center gap-3 px-5 py-3 hover:bg-navy-50/40 cursor-pointer" onClick={() => navigate('/payments')}>
                  <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-navy-100 text-navy-600"><CreditCard size={18} /></div>
                  <div className="min-w-0 flex-1"><p className="text-sm font-medium text-navy-900">{p.transactionRef}</p><p className="text-xs text-navy-500">{p.courseName ?? 'Subscription'} · {formatDate(p.paymentDate)}</p></div>
                  <div className="text-right"><p className="text-sm font-semibold text-navy-900">{formatCurrency(p.amount)}</p><Badge variant={p.status === 'verified' ? 'success' : p.status === 'pending' ? 'warning' : p.status === 'rejected' || p.status === 'failed' ? 'danger' : 'info'}>{p.status}</Badge></div>
                </div>
              ))}
            </div>
          )}
        </Card>
      )}

      {tab === 'career' && (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <Card title="Career Appointments">
            {appointments.length === 0 ? <EmptyState title="No appointments" /> : (
              <div className="divide-y divide-navy-50">
                {appointments.map((a) => (
                  <div key={a.id} className="px-5 py-3">
                    <div className="flex justify-between"><p className="text-sm font-medium text-navy-900 capitalize">{a.type.replace('_', ' ')}</p><Badge variant={a.status === 'completed' ? 'success' : a.status === 'cancelled' || a.status === 'no_show' ? 'danger' : 'info'}>{a.status.replace('_', ' ')}</Badge></div>
                    <p className="text-xs text-navy-500 mt-1">{formatDate(a.scheduledAt)} · {a.counsellor}</p>
                    {a.notes && <p className="text-xs text-navy-400 mt-1">{a.notes}</p>}
                  </div>
                ))}
              </div>
            )}
          </Card>
          <Card title="Action Plan">
            {!actionPlan ? <EmptyState title="No action plan" /> : (
              <div className="px-5 py-3">
                <p className="text-sm font-medium text-navy-900 mb-2">Goals</p>
                <ul className="text-sm text-navy-600 list-disc pl-4 space-y-1 mb-3">{actionPlan.goals.map((g, i) => <li key={i}>{g}</li>)}</ul>
                <p className="text-sm font-medium text-navy-900 mb-2">Milestones</p>
                <div className="space-y-2">{actionPlan.milestones.map((m) => (
                  <div key={m.id} className="flex items-center gap-2 text-sm">
                    <span className={`h-4 w-4 rounded-full ${m.completed ? 'bg-teal-500' : 'bg-navy-200'}`} />
                    <span className={m.completed ? 'text-navy-400 line-through' : 'text-navy-700'}>{m.title}</span>
                  </div>
                ))}</div>
              </div>
            )}
          </Card>
        </div>
      )}

      {/* Edit Modal */}
      {editing && (
        <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center p-0 sm:p-4">
          <div className="absolute inset-0 bg-navy-950/50 backdrop-blur-sm" onClick={() => setEditing(false)} />
          <div className="relative w-full max-w-2xl bg-white rounded-t-2xl sm:rounded-2xl shadow-elevated animate-slide-up max-h-[90vh] flex flex-col">
            <div className="flex items-center justify-between border-b border-navy-100 px-5 py-4">
              <h2 className="text-base font-semibold text-navy-900">Edit Student</h2>
            </div>
            <div className="overflow-y-auto px-5 py-4 flex-1 space-y-4">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <Input label="Full Name" value={form.fullName} onChange={(e) => setForm({ ...form, fullName: e.target.value })} />
                <Input label="Email" value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} />
                <Input label="Phone" value={form.phone} onChange={(e) => setForm({ ...form, phone: e.target.value })} />
                <Input label="City" value={form.city} onChange={(e) => setForm({ ...form, city: e.target.value })} />
                <Select label="Education Level" value={form.educationLevel} onChange={(e) => setForm({ ...form, educationLevel: e.target.value })}
                  options={[{ value: "High School", label: "High School" }, { value: "Diploma", label: "Diploma" }, { value: "Bachelor's", label: "Bachelor's" }, { value: "Master's", label: "Master's" }, { value: "Doctorate", label: "Doctorate" }]} />
                <Input label="Qualification" value={form.qualification} onChange={(e) => setForm({ ...form, qualification: e.target.value })} />
                <Select label="Preferred Category" value={form.preferredCategory} onChange={(e) => setForm({ ...form, preferredCategory: e.target.value })}
                  options={store.courseCategories.map((c) => ({ value: c.name, label: c.name }))} />
                <Select label="Subscription Plan" value={form.subscriptionPlan} onChange={(e) => setForm({ ...form, subscriptionPlan: e.target.value as SubscriptionPlan })}
                  options={[{ value: 'free', label: 'Free' }, { value: 'basic', label: 'Basic' }, { value: 'premium', label: 'Premium' }, { value: 'enterprise', label: 'Enterprise' }]} />
                <Select label="Account Status" value={form.accountStatus} onChange={(e) => setForm({ ...form, accountStatus: e.target.value as AccountStatus })}
                  options={[{ value: 'active', label: 'Active' }, { value: 'inactive', label: 'Inactive' }, { value: 'suspended', label: 'Suspended' }]} />
              </div>
            </div>
            <div className="border-t border-navy-100 px-5 py-3 flex justify-end gap-2">
              <button className="btn-secondary" onClick={() => setEditing(false)}>Cancel</button>
              <Button onClick={saveEdit}><Save size={16} /> Save Changes</Button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

function InfoRow({ icon, label, value }: { icon?: React.ReactNode; label: string; value: string }) {
  return (
    <div className="py-3 flex justify-between items-center">
      <dt className="text-sm text-navy-500 flex items-center gap-1.5">{icon}{label}</dt>
      <dd className="text-sm font-medium text-navy-900 capitalize">{value}</dd>
    </div>
  );
}
