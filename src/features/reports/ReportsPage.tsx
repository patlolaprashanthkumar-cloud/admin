import { useState } from 'react';
import { Download, Users, BookOpen, CreditCard, TrendingUp, Award, MessageSquare, CheckCircle, FileText } from 'lucide-react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, LineChart, Line } from 'recharts';
import { useMockStore } from '@/hooks/useMockStore';
import { Card } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { PageHeader } from '@/components/ui/PageHeader';
import { Select, Input } from '@/components/ui/FormField';
import { downloadCSV, formatCurrency, formatDate } from '@/utils';
import { exportStudentRosterPDF, exportFinancialReportPDF } from '@/utils/pdfExport';
import { dashboardEnrolmentChart } from '@/mock-data';

export function ReportsPage() {
  const store = useMockStore();
  const [reportType, setReportType] = useState('student_registrations');
  const [fromDate, setFromDate] = useState('');
  const [toDate, setToDate] = useState('');
  const [pdfLoading, setPdfLoading] = useState(false);

  const dateRange = fromDate ? { from: fromDate, to: toDate || new Date().toISOString().slice(0, 10) } : undefined;

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

  const pdfSupportedReports = ['student_registrations', 'payment_summaries'];

  function handleExportCSV() {
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

  function handleExportPDF() {
    setPdfLoading(true);
    try {
      if (reportType === 'student_registrations') {
        exportStudentRosterPDF(
          store.students.map((s) => ({
            studentId: s.studentId, fullName: s.fullName, email: s.email, phone: s.phone,
            subscriptionPlan: s.subscriptionPlan, subscriptionStatus: s.subscriptionStatus,
            accountStatus: s.accountStatus, preferredCategory: s.preferredCategory, createdAt: s.createdAt,
          })),
          dateRange,
        );
      } else if (reportType === 'payment_summaries') {
        exportFinancialReportPDF(
          store.payments.map((p) => ({
            transactionRef: p.transactionRef, studentName: p.studentName, courseName: p.courseName,
            amount: p.amount, paymentMethod: p.paymentMethod, status: p.status, paymentDate: p.paymentDate,
            subscriptionPlan: p.subscriptionPlan,
          })),
          dateRange,
        );
      }
    } finally {
      setPdfLoading(false);
    }
  }

  const activeReport = reports.find((r) => r.value === reportType);

  return (
    <div>
      <PageHeader
        title="Reports"
        subtitle="Export and analyze institutional data"
        breadcrumbs={[{ label: 'Dashboard', to: '/dashboard' }, { label: 'Reports' }]}
        actions={
          <div className="flex items-center gap-2">
            <button className="btn-secondary" onClick={handleExportCSV}><Download size={16} /> Export CSV</button>
            {pdfSupportedReports.includes(reportType) && (
              <button className="btn-primary" onClick={handleExportPDF} disabled={pdfLoading}>
                {pdfLoading ? (
                  <><span className="h-4 w-4 animate-spin rounded-full border-2 border-white/30 border-t-white" /> Generating...</>
                ) : (
                  <><FileText size={16} /> Export PDF</>
                )}
              </button>
            )}
          </div>
        }
      />

      <Card className="p-4 mb-4">
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <Select label="Report Type" value={reportType} onChange={(e) => setReportType(e.target.value)}
            options={reports.map((r) => ({ value: r.value, label: r.label }))} />
          <Input label="From Date" type="date" value={fromDate} onChange={(e) => setFromDate(e.target.value)} />
          <Input label="To Date" type="date" value={toDate} onChange={(e) => setToDate(e.target.value)} />
        </div>
        {pdfSupportedReports.includes(reportType) && (
          <div className="mt-3 flex items-center gap-2 rounded-lg bg-indigo-50 border border-indigo-100 px-3 py-2">
            <FileText size={14} className="text-indigo-600" />
            <p className="text-xs text-indigo-700">
              PDF export is available for this report. The PDF includes a formatted header, summary cards, and a styled data table.
            </p>
          </div>
        )}
      </Card>

      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 mb-4">
        {reports.map((r) => (
          <button key={r.value} onClick={() => setReportType(r.value)}
            className={`card p-4 flex flex-col items-center gap-2 text-center transition-all ${reportType === r.value ? 'border-indigo-400 bg-indigo-50/50 ring-2 ring-indigo-500/20' : 'card-hover'}`}>
            <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-navy-100 text-navy-700"><r.icon size={20} /></div>
            <span className="text-xs font-medium text-navy-800">{r.label}</span>
            {pdfSupportedReports.includes(r.value) && (
              <Badge variant="info" size="sm">PDF</Badge>
            )}
          </button>
        ))}
      </div>

      {/* PDF Preview Card */}
      {pdfSupportedReports.includes(reportType) && (
        <Card className="mb-4 p-5" title="PDF Export Preview" subtitle={`What will be included in the ${activeReport?.label} PDF`}>
          <div className="space-y-3">
            <div className="flex items-center gap-3 rounded-lg bg-navy-900 px-4 py-3">
              <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-indigo-600 text-white text-xs font-bold">IIECM</div>
              <div className="text-white">
                <p className="text-sm font-semibold">{activeReport?.label} Report</p>
                <p className="text-xs text-navy-300">International Institute of E-commerce and Management</p>
              </div>
              <div className="ml-auto text-right text-navy-300">
                <p className="text-xs">{dateRange ? `${formatDate(dateRange.from)} — ${formatDate(dateRange.to)}` : 'All time'}</p>
                <p className="text-[10px]">Generated: {formatDate(new Date().toISOString())}</p>
              </div>
            </div>
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
              {reportType === 'student_registrations' && (
                <>
                  <PreviewStat label="Total Students" value={dateRange ? store.students.filter((s) => new Date(s.createdAt) >= new Date(dateRange.from) && new Date(s.createdAt) <= new Date(dateRange.to)).length : store.students.length} />
                  <PreviewStat label="Active" value={store.students.filter((s) => s.accountStatus === 'active').length} />
                  <PreviewStat label="Premium" value={store.students.filter((s) => s.subscriptionPlan === 'premium').length} />
                  <PreviewStat label="Enterprise" value={store.students.filter((s) => s.subscriptionPlan === 'enterprise').length} />
                </>
              )}
              {reportType === 'payment_summaries' && (
                <>
                  <PreviewStat label="Total Revenue" value={formatCurrency(store.payments.filter((p) => p.status === 'verified').reduce((s, p) => s + p.amount, 0))} />
                  <PreviewStat label="Pending" value={formatCurrency(store.payments.filter((p) => p.status === 'pending').reduce((s, p) => s + p.amount, 0))} />
                  <PreviewStat label="Refunded" value={formatCurrency(store.payments.filter((p) => p.status === 'refunded').reduce((s, p) => s + p.amount, 0))} />
                  <PreviewStat label="Transactions" value={store.payments.length} />
                </>
              )}
            </div>
            <div className="rounded-lg border border-navy-100 overflow-hidden">
              <table className="w-full">
                <thead>
                  <tr className="bg-navy-900 text-white">
                    {reportType === 'student_registrations' && (
                      <>
                        <th className="px-3 py-2 text-left text-[10px] font-semibold uppercase">Student ID</th>
                        <th className="px-3 py-2 text-left text-[10px] font-semibold uppercase">Name</th>
                        <th className="px-3 py-2 text-left text-[10px] font-semibold uppercase hidden sm:table-cell">Plan</th>
                        <th className="px-3 py-2 text-left text-[10px] font-semibold uppercase">Status</th>
                        <th className="px-3 py-2 text-left text-[10px] font-semibold uppercase hidden sm:table-cell">Joined</th>
                      </>
                    )}
                    {reportType === 'payment_summaries' && (
                      <>
                        <th className="px-3 py-2 text-left text-[10px] font-semibold uppercase">Reference</th>
                        <th className="px-3 py-2 text-left text-[10px] font-semibold uppercase">Student</th>
                        <th className="px-3 py-2 text-left text-[10px] font-semibold uppercase hidden sm:table-cell">Amount</th>
                        <th className="px-3 py-2 text-left text-[10px] font-semibold uppercase">Status</th>
                        <th className="px-3 py-2 text-left text-[10px] font-semibold uppercase hidden sm:table-cell">Date</th>
                      </>
                    )}
                  </tr>
                </thead>
                <tbody className="divide-y divide-navy-50">
                  {(reportType === 'student_registrations' ? store.students : store.payments).slice(0, 5).map((item) => (
                    <tr key={(item as { id: string }).id} className="text-xs">
                      {reportType === 'student_registrations' && (
                        <>
                          <td className="px-3 py-2 text-navy-700">{(item as { studentId: string }).studentId}</td>
                          <td className="px-3 py-2 font-medium text-navy-900">{(item as { fullName: string }).fullName}</td>
                          <td className="px-3 py-2 text-navy-600 hidden sm:table-cell">{(item as { subscriptionPlan: string }).subscriptionPlan}</td>
                          <td className="px-3 py-2"><Badge variant="neutral" size="sm">{(item as { accountStatus: string }).accountStatus}</Badge></td>
                          <td className="px-3 py-2 text-navy-500 hidden sm:table-cell">{formatDate((item as { createdAt: string }).createdAt)}</td>
                        </>
                      )}
                      {reportType === 'payment_summaries' && (
                        <>
                          <td className="px-3 py-2 font-mono text-navy-700">{(item as { transactionRef: string }).transactionRef}</td>
                          <td className="px-3 py-2 font-medium text-navy-900">{(item as { studentName: string }).studentName}</td>
                          <td className="px-3 py-2 font-semibold text-navy-900 hidden sm:table-cell">{formatCurrency((item as { amount: number }).amount)}</td>
                          <td className="px-3 py-2"><Badge variant="neutral" size="sm">{(item as { status: string }).status}</Badge></td>
                          <td className="px-3 py-2 text-navy-500 hidden sm:table-cell">{formatDate((item as { paymentDate: string }).paymentDate)}</td>
                        </>
                      )}
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            <p className="text-xs text-navy-400 text-center">
              Showing preview of first 5 records · Full PDF will include all {(reportType === 'student_registrations' ? store.students.length : store.payments.length)} records
            </p>
          </div>
        </Card>
      )}

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

function PreviewStat({ label, value }: { label: string; value: string | number }) {
  return (
    <div className="rounded-lg bg-navy-50 border border-navy-100 px-3 py-2.5">
      <p className="text-[10px] text-navy-500 uppercase tracking-wide">{label}</p>
      <p className="text-base font-bold text-navy-900 mt-0.5">{value}</p>
    </div>
  );
}
