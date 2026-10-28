import { useNavigate } from 'react-router-dom';
import {
  AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
  PieChart, Pie, Cell, Legend,
} from 'recharts';
import { Users, GraduationCap, BookOpen, CreditCard, MessageSquare, UserPlus, BookPlus, Award, ClipboardCheck, Calendar, TrendingUp } from 'lucide-react';
import { useMockStore } from '@/hooks/useMockStore';
import { StatCard, Card } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { Avatar } from '@/components/ui/Avatar';
import { EmptyState } from '@/components/ui/State';
import { PageHeader } from '@/components/ui/PageHeader';
import { dashboardEnrolmentChart, dashboardPaymentChart } from '@/mock-data';
import { formatCurrency, formatDate, timeAgo, formatDateTime } from '@/utils';
import { useAuth } from '@/hooks/useAuth';

export function DashboardPage() {
  const store = useMockStore();
  const navigate = useNavigate();
  const { user } = useAuth();

  const totalStudents = store.students.length;
  const activeStudents = store.students.filter((s) => s.accountStatus === 'active').length;
  const totalInstructors = store.instructors.length;
  const publishedCourses = store.courses.filter((c) => c.status === 'published').length;
  const pendingPayments = store.payments.filter((p) => p.status === 'pending').length;
  const pendingEnquiries = store.enquiries.filter((e) => e.status === 'new' || e.status === 'follow_up').length;
  const recentRegistrations = [...store.students].sort((a, b) => b.createdAt.localeCompare(a.createdAt)).slice(0, 5);
  const recentEnrolments = store.courses
    .flatMap((c) => c.enrolledStudentIds.map((sid) => ({ course: c.title, student: store.students.find((s) => s.id === sid)?.fullName ?? 'Unknown', date: c.createdAt })))
    .sort((a, b) => b.date.localeCompare(a.date))
    .slice(0, 5);
  const upcomingClasses = store.liveClasses.filter((c) => c.status === 'upcoming').slice(0, 4);
  const recentActivity = store.activityLogs.slice(0, 6);

  const quickActions = [
    { label: 'Add Student', icon: UserPlus, to: '/students/new', color: 'bg-navy-600' },
    { label: 'Create Course', icon: BookPlus, to: '/courses/new', color: 'bg-teal-600' },
    { label: 'Add Instructor', icon: GraduationCap, to: '/instructors/new', color: 'bg-indigo-600' },
    { label: 'Review Payments', icon: CreditCard, to: '/payments', color: 'bg-amber-600' },
  ];

  return (
    <div>
      <PageHeader
        title={`Welcome back, ${user?.fullName?.split(' ')[0] ?? 'Admin'}`}
        subtitle="Here's what's happening at IIECM today."
      />

      <div className="grid grid-cols-2 lg:grid-cols-3 gap-3 mb-5">
        <StatCard label="Total Students" value={totalStudents} icon={<Users size={20} />} accent="navy" to="/students" trend={{ value: '+12% this month', positive: true }} />
        <StatCard label="Active Students" value={activeStudents} icon={<TrendingUp size={20} />} accent="teal" to="/students" />
        <StatCard label="Instructors" value={totalInstructors} icon={<GraduationCap size={20} />} accent="indigo" to="/instructors" />
        <StatCard label="Published Courses" value={publishedCourses} icon={<BookOpen size={20} />} accent="cyan" to="/courses" />
        <StatCard label="Pending Payments" value={pendingPayments} icon={<CreditCard size={20} />} accent="amber" to="/payments" />
        <StatCard label="Pending Enquiries" value={pendingEnquiries} icon={<MessageSquare size={20} />} accent="red" to="/enquiries" />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4 mb-5">
        <Card title="Course Enrolments" subtitle="Monthly enrolment trend" action={<Badge variant="accent">{totalStudents} total</Badge>}>
          <div className="p-4 h-64">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={dashboardEnrolmentChart}>
                <defs>
                  <linearGradient id="enrolGrad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor="#335598" stopOpacity={0.3} />
                    <stop offset="100%" stopColor="#335598" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" vertical={false} />
                <XAxis dataKey="month" tick={{ fontSize: 12, fill: '#6b7280' }} axisLine={false} tickLine={false} />
                <YAxis tick={{ fontSize: 12, fill: '#6b7280' }} axisLine={false} tickLine={false} allowDecimals={false} />
                <Tooltip contentStyle={{ borderRadius: '0.75rem', border: '1px solid #d9e2f1', fontSize: '13px' }} />
                <Area type="monotone" dataKey="enrolments" stroke="#335598" strokeWidth={2} fill="url(#enrolGrad)" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </Card>

        <Card title="Payment Summary" subtitle="By verification status">
          <div className="p-4 h-64">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie data={dashboardPaymentChart} dataKey="value" nameKey="name" cx="50%" cy="50%" outerRadius={80} innerRadius={45}>
                  {dashboardPaymentChart.map((entry, i) => <Cell key={i} fill={entry.color} />)}
                </Pie>
                <Tooltip contentStyle={{ borderRadius: '0.75rem', border: '1px solid #d9e2f1', fontSize: '13px' }} />
                <Legend iconType="circle" wrapperStyle={{ fontSize: '12px' }} />
              </PieChart>
            </ResponsiveContainer>
          </div>
        </Card>
      </div>

      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 mb-5">
        {quickActions.map((action) => (
          <button
            key={action.label}
            onClick={() => navigate(action.to)}
            className="card card-hover p-4 flex flex-col items-center gap-2 text-center transition-all hover:scale-[1.02]"
          >
            <div className={`flex h-10 w-10 items-center justify-center rounded-lg ${action.color} text-white`}>
              <action.icon size={20} />
            </div>
            <span className="text-sm font-medium text-navy-800">{action.label}</span>
          </button>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4 mb-5">
        <Card title="Recent Registrations" action={<button onClick={() => navigate('/students')} className="text-xs font-medium text-indigo-600">View all</button>}>
          <div className="divide-y divide-navy-50">
            {recentRegistrations.map((s) => (
              <div key={s.id} className="flex items-center gap-3 px-5 py-3 hover:bg-navy-50/40 cursor-pointer" onClick={() => navigate(`/students/${s.id}`)}>
                <Avatar name={s.fullName} size="sm" />
                <div className="min-w-0 flex-1">
                  <p className="text-sm font-medium text-navy-900 truncate">{s.fullName}</p>
                  <p className="text-xs text-navy-500">{s.studentId} · {s.preferredCategory}</p>
                </div>
                <Badge variant={s.accountStatus === 'active' ? 'success' : 'neutral'} dot>{s.accountStatus}</Badge>
              </div>
            ))}
          </div>
        </Card>

        <Card title="Recent Enrolments" action={<button onClick={() => navigate('/courses')} className="text-xs font-medium text-indigo-600">View all</button>}>
          <div className="divide-y divide-navy-50">
            {recentEnrolments.map((e, i) => (
              <div key={i} className="flex items-center gap-3 px-5 py-3">
                <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-teal-100 text-teal-600">
                  <BookOpen size={16} />
                </div>
                <div className="min-w-0 flex-1">
                  <p className="text-sm font-medium text-navy-900 truncate">{e.student}</p>
                  <p className="text-xs text-navy-500 truncate">{e.course}</p>
                </div>
                <span className="text-xs text-navy-400">{formatDate(e.date)}</span>
              </div>
            ))}
          </div>
        </Card>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <Card title="Upcoming Live Classes">
          {upcomingClasses.length === 0 ? (
            <EmptyState icon={<Calendar size={24} />} title="No upcoming classes" />
          ) : (
            <div className="divide-y divide-navy-50">
              {upcomingClasses.map((c) => (
                <div key={c.id} className="flex items-center gap-3 px-5 py-3">
                  <div className="flex h-10 w-10 flex-col items-center justify-center rounded-lg bg-indigo-100 text-indigo-700 text-xs font-bold">
                    <span>{new Date(c.scheduledAt).getDate()}</span>
                    <span className="text-[9px]">{new Date(c.scheduledAt).toLocaleString('en-IN', { month: 'short' })}</span>
                  </div>
                  <div className="min-w-0 flex-1">
                    <p className="text-sm font-medium text-navy-900 truncate">{c.title}</p>
                    <p className="text-xs text-navy-500">{c.instructorName} · {c.courseName}</p>
                  </div>
                  <Badge variant="info">{new Date(c.scheduledAt).toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit' })}</Badge>
                </div>
              ))}
            </div>
          )}
        </Card>

        <Card title="Recent Activity">
          <div className="divide-y divide-navy-50">
            {recentActivity.map((a) => (
              <div key={a.id} className="flex items-start gap-3 px-5 py-3">
                <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-navy-100 text-navy-500">
                  <ClipboardCheck size={14} />
                </div>
                <div className="min-w-0 flex-1">
                  <p className="text-sm text-navy-800">
                    <span className="font-medium">{a.action}</span> — {a.target}
                  </p>
                  <p className="text-xs text-navy-400 mt-0.5">{a.adminName} · {timeAgo(a.timestamp)}</p>
                </div>
              </div>
            ))}
          </div>
        </Card>
      </div>
    </div>
  );
}
