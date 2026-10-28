import { useState } from 'react';
import { BarChart3, Download, Users, BookOpen, CreditCard, TrendingUp, Award, MessageSquare, CheckCircle } from 'lucide-react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, LineChart, Line } from 'recharts';
import { useMockStore } from '@/hooks/useMockStore';
import { Card } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { PageHeader } from '@/components/ui/PageHeader';
import { Select, Input } from '@/components/ui/FormField';
import { downloadCSV, formatCurrency, formatDate } from '@/utils';
import { dashboardEnrolmentChart } from '@/mock-data';

export function ReportsPage() {
  const store = useMockStore();
  const [reportType, setReportType] = useState('student_registrations');
  const [fromDate, setFromDate] = useState('');
  const [toDate, setToDate] = useState('');

  const reports = [
    { value: 'student_registrations', label: 'Student Registrations', icon: Users },
    { value: 'course_enrolments', label: 'Course Enrolments', icon: BookOpen },
    { value: 'instructor_activity', label: 'Instructor Activity', icon: TrendingUp },
    { value: 'payment_summaries', label: 'Payment Summaries', icon: CreditCard },
    { value: 'subscription_status', label: 'Subscription Status', icon: CheckCircle },
    { value: 'assessment_performance', label: 'Assessment Performance', icon: Award },
    { value: 'enquiry_conversion', label: 'Enquiry Conversion', icon: MessageSquare },
    { value: 'course_completion', label: 'Course Completion', icon: BookOpen },
  ];

  function handleExport() {
    switch (reportType) {
      case 'student_registrations':
        downloadCSV('student-registrations.csv', store.students.map((s) => ({ StudentID: s.studentId, Name: s.fullName, Email: s.email, Plan: s.subscriptionPlan, Status: s.accountStatus, Date: formatDate(s.createdAt) })));
        break;
      case 'course_enrolments':
        downloadCSV('course-enrolments.csv', store.courses.map((c) => ({ Course: c.title, Category: c.category, Enrolled: c.enrolledStudentIds.length, Fee: c.fee, Status: c.status })));
        break;
      case 'payment_summaries':
        downloadCSV('payment-summaries.csv', store.payments.map((p) => ({ Reference: p.transactionRef, Student: p.studentName, Amount: p.amount, Method: p.paymentMethod, Status: p.status, Date: formatDate(p.paymentDate) })));
        break;
      case 'instructor_activity':
        downloadCSV('instructor-activity.csv', store.instructors.map((i) => ({ Name: i.fullName, Specialization: i.specialization, Courses: store.courses.filter((c) => c.instructorId === i.id).length, Students: i.totalStudents ?? 0, Rating: i.rating ?? 0 })));
        break;
      case 'subscription_status':
        downloadCSV('subscription-status.csv', store.students.map((s) => ({ StudentID: s.studentId, Name: s.fullName, Plan: s.subscriptionPlan, Status: s.subscriptionStatus, Start: s.subscriptionStart ?? '—', Expiry: s.subscriptionExpiry ?? '—' })));
        break;
      case 'assessment_performance':
        downloadCSV('assessment-performance.csv', store.assessmentResults.map((r) => ({ Student: r.studentName, Assessment: r.assessmentTitle, Score: r.score, Total: r.totalMarks, Percentage: r.percentage, Passed: r.passed ? 'Yes' : 'No' })));
        break;
      case 'enquiry_conversion':
        downloadCSV('enquiry-conversion.csv', store.enquiries.map((e) => ({ ID: e.enquiryId, Name: e.studentName, Status: e.status, Source: e.source, Counsellor: e.assignedCounsellor, Date: formatDate(e.createdAt) })));
        break;
      case 'course_completion':
        downloadCSV('course-completion.csv', store.courses.map((c) => ({ Course: c.title, Enrolled: c.enrolledStudentIds.length, Modules: c.modules.length, Status: c.status })));
        break;
    }
  }

  return (
    <div>
      <PageHeader
        title="Reports"
        subtitle="Export and analyze institutional data"
        breadcrumbs={[{ label: 'Dashboard', to: '/dashboard' }, { label: 'Reports' }]}
        actions={<button className="btn-primary" onClick={handleExport}><Download size={16} /> Export CSV</button>}
      />

      <Card className="p-4 mb-4">
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <Select label="Report Type" value={reportType} onChange={(e) => setReportType(e.target.value)}
            options={reports.map((r) => ({ value: r.value, label: r.label }))} />
          <Input label="From Date" type="date" value={fromDate} onChange={(e) => setFromDate(e.target.value)} />
          <Input label="To Date" type="date" value={toDate} onChange={(e) => setToDate(e.target.value)} />
        </div>
      </Card>

      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 mb-4">
        {reports.map((r) => (
          <button key={r.value} onClick={() => setReportType(r.value)}
            className={`card p-4 flex flex-col items-center gap-2 text-center transition-all ${reportType === r.value ? 'border-indigo-400 bg-indigo-50/50 ring-2 ring-indigo-500/20' : 'card-hover'}`}>
            <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-navy-100 text-navy-700"><r.icon size={20} /></div>
            <span className="text-xs font-medium text-navy-800">{r.label}</span>
          </button>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <Card title="Enrolment Trend" subtitle="Monthly enrolments and revenue">
          <div className="p-4 h-64">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={dashboardEnrolmentChart}>
                <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" vertical={false} />
                <XAxis dataKey="month" tick={{ fontSize: 12, fill: '#6b7280' }} axisLine={false} tickLine={false} />
                <YAxis tick={{ fontSize: 12, fill: '#6b7280' }} axisLine={false} tickLine={false} allowDecimals={false} />
                <Tooltip contentStyle={{ borderRadius: '0.75rem', border: '1px solid #d9e2f1', fontSize: '13px' }} />
                <Bar dataKey="enrolments" fill="#335598" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </Card>

        <Card title="Revenue Trend" subtitle="Monthly revenue (INR)">
          <div className="p-4 h-64">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={dashboardEnrolmentChart}>
                <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" vertical={false} />
                <XAxis dataKey="month" tick={{ fontSize: 12, fill: '#6b7280' }} axisLine={false} tickLine={false} />
                <YAxis tick={{ fontSize: 12, fill: '#6b7280' }} axisLine={false} tickLine={false} />
                <Tooltip contentStyle={{ borderRadius: '0.75rem', border: '1px solid #d9e2f1', fontSize: '13px' }} formatter={(v) => [formatCurrency(Number(v)), 'Revenue']} />
                <Line type="monotone" dataKey="revenue" stroke="#0d9488" strokeWidth={2} dot={{ fill: '#0d9488', r: 4 }} />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </Card>
      </div>

      <Card title="Quick Summary" className="mt-4">
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-4 p-5">
          <SummaryItem label="Total Students" value={store.students.length} />
          <SummaryItem label="Total Revenue" value={formatCurrency(store.payments.filter((p) => p.status === 'verified').reduce((s, p) => s + p.amount, 0))} />
          <SummaryItem label="Active Courses" value={store.courses.filter((c) => c.status === 'published').length} />
          <SummaryItem label="Conversion Rate" value={`${Math.round((store.enquiries.filter((e) => e.status === 'converted').length / store.enquiries.length) * 100)}%`} />
        </div>
      </Card>
    </div>
  );
}

function SummaryItem({ label, value }: { label: string; value: string | number }) {
  return <div><p className="text-xs text-navy-500 uppercase">{label}</p><p className="text-lg font-bold text-navy-900 mt-0.5">{value}</p></div>;
}
