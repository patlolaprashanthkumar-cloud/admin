import { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { ArrowLeft, Save } from 'lucide-react';
import { useMockStore } from '@/hooks/useMockStore';
import { mockStore } from '@/mock-data/store';
import { Card } from '@/components/ui/Card';
import { PageHeader } from '@/components/ui/PageHeader';
import { Input, Select, Checkbox } from '@/components/ui/FormField';
import { Button } from '@/components/ui/Button';
import { generateId, generateStudentId } from '@/utils';
import { isDuplicateStudentEmail } from '@/utils/dataIntegrity';
import type { Student, AccountStatus, SubscriptionPlan, SubscriptionStatus } from '@/types';

interface FormState {
  fullName: string;
  email: string;
  phone: string;
  educationLevel: string;
  qualification: string;
  preferredCategory: string;
  enrolledCourseIds: string[];
  subscriptionPlan: SubscriptionPlan;
  accountStatus: AccountStatus;
  city: string;
}

export function AddStudentPage() {
  const store = useMockStore();
  const navigate = useNavigate();
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [submitting, setSubmitting] = useState(false);

  const [form, setForm] = useState<FormState>({
    fullName: '', email: '', phone: '', educationLevel: '', qualification: '',
    preferredCategory: '', enrolledCourseIds: [], subscriptionPlan: 'basic',
    accountStatus: 'active', city: '',
  });

  function update<K extends keyof FormState>(key: K, value: FormState[K]) {
    setForm((f) => ({ ...f, [key]: value }));
  }

  function toggleCourse(id: string) {
    setForm((f) => ({
      ...f,
      enrolledCourseIds: f.enrolledCourseIds.includes(id)
        ? f.enrolledCourseIds.filter((c) => c !== id)
        : [...f.enrolledCourseIds, id],
    }));
  }

  function validate(): boolean {
    const e: Record<string, string> = {};
    if (!form.fullName.trim()) e.fullName = 'Full name is required';
    if (!form.email.trim()) e.email = 'Email is required';
    else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email)) e.email = 'Enter a valid email address';
    else if (isDuplicateStudentEmail(form.email, store.students)) e.email = 'A student with this email address already exists';
    if (!form.phone.trim()) e.phone = 'Phone number is required';
    if (!form.educationLevel) e.educationLevel = 'Select education level';
    if (!form.qualification.trim()) e.qualification = 'Qualification is required';
    if (!form.preferredCategory) e.preferredCategory = 'Select a category';
    setErrors(e);
    return Object.keys(e).length === 0;
  }

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (submitting) return;
    if (!validate()) return;
    setSubmitting(true);
    const student: Student = {
      id: generateId('stu'),
      studentId: generateStudentId(),
      fullName: form.fullName.trim(),
      email: form.email.trim(),
      phone: form.phone.trim(),
      educationLevel: form.educationLevel,
      qualification: form.qualification.trim(),
      preferredCategory: form.preferredCategory,
      enrolledCourseIds: form.enrolledCourseIds,
      subscriptionPlan: form.subscriptionPlan,
      subscriptionStatus: form.subscriptionPlan === 'free' ? 'active' : 'pending',
      accountStatus: form.accountStatus,
      resumeUploaded: false,
      careerGuidanceStatus: 'not_started',
      createdAt: new Date().toISOString(),
      city: form.city.trim() || undefined,
      country: 'India',
    };
    mockStore.addStudent(student);
    mockStore.addActivity({
      id: generateId('act'),
      adminName: 'Dr. Priya Sharma',
      action: 'Added student',
      target: `${student.fullName} (${student.studentId})`,
      timestamp: new Date().toISOString(),
    });
    navigate(`/students/${student.id}`);
  }

  const availableCourses = store.courses.filter((c) => c.status === 'published' && (!form.preferredCategory || c.category === form.preferredCategory));

  return (
    <div>
      <PageHeader
        title="Add New Student"
        subtitle="Create a new student record"
        breadcrumbs={[{ label: 'Dashboard', to: '/dashboard' }, { label: 'Students', to: '/students' }, { label: 'Add' }]}
        actions={<Link to="/students" className="btn-secondary"><ArrowLeft size={16} /> Back</Link>}
      />

      <form onSubmit={handleSubmit} className="space-y-4 max-w-3xl">
        <Card title="Personal Information" className="p-5">
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <Input label="Full Name *" value={form.fullName} onChange={(e) => update('fullName', e.target.value)} error={errors.fullName} placeholder="e.g. Aarav Patel" />
            <Input label="Email *" type="email" value={form.email} onChange={(e) => update('email', e.target.value)} error={errors.email} placeholder="student@example.com" />
            <Input label="Phone *" value={form.phone} onChange={(e) => update('phone', e.target.value)} error={errors.phone} placeholder="+91 90000 00000" />
            <Input label="City" value={form.city} onChange={(e) => update('city', e.target.value)} placeholder="e.g. Mumbai" />
          </div>
        </Card>

        <Card title="Academic Information" className="p-5">
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <Select label="Education Level *" value={form.educationLevel} onChange={(e) => update('educationLevel', e.target.value)} error={errors.educationLevel} placeholder="Select level"
              options={[
                { value: "High School", label: "High School" },
                { value: "Diploma", label: "Diploma" },
                { value: "Bachelor's", label: "Bachelor's" },
                { value: "Master's", label: "Master's" },
                { value: "Doctorate", label: "Doctorate" },
              ]} />
            <Input label="Qualification *" value={form.qualification} onChange={(e) => update('qualification', e.target.value)} error={errors.qualification} placeholder="e.g. B.Com, MBA" />
            <Select label="Preferred Learning Category *" value={form.preferredCategory} onChange={(e) => update('preferredCategory', e.target.value)} error={errors.preferredCategory} placeholder="Select category"
              options={store.courseCategories.map((c) => ({ value: c.name, label: c.name }))} />
          </div>
        </Card>

        <Card title="Course Assignment" className="p-5">
          <p className="text-sm text-navy-500 mb-3">Select courses to assign to this student.</p>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
            {availableCourses.map((c) => (
              <label key={c.id} className="flex items-center gap-2.5 rounded-lg border border-navy-100 p-3 cursor-pointer hover:bg-navy-50/50 transition-colors">
                <input type="checkbox" checked={form.enrolledCourseIds.includes(c.id)} onChange={() => toggleCourse(c.id)} className="h-4 w-4 rounded border-navy-300 text-indigo-600" />
                <div className="min-w-0">
                  <p className="text-sm font-medium text-navy-900 truncate">{c.title}</p>
                  <p className="text-xs text-navy-500">{c.category}</p>
                </div>
              </label>
            ))}
          </div>
        </Card>

        <Card title="Subscription & Status" className="p-5">
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <Select label="Subscription Plan" value={form.subscriptionPlan} onChange={(e) => update('subscriptionPlan', e.target.value as SubscriptionPlan)}
              options={[
                { value: 'free', label: 'Free Access' },
                { value: 'basic', label: 'Basic Plan' },
                { value: 'premium', label: 'Premium Plan' },
                { value: 'enterprise', label: 'Enterprise Plan' },
              ]} />
            <Select label="Account Status" value={form.accountStatus} onChange={(e) => update('accountStatus', e.target.value as AccountStatus)}
              options={[
                { value: 'active', label: 'Active' },
                { value: 'inactive', label: 'Inactive' },
                { value: 'suspended', label: 'Suspended' },
              ]} />
          </div>
        </Card>

        <div className="flex justify-end gap-2">
          <Link to="/students" className="btn-secondary">Cancel</Link>
          <Button type="submit"><Save size={16} /> Create Student</Button>
        </div>
      </form>
    </div>
  );
}
