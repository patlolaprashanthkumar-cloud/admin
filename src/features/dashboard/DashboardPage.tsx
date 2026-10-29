import { useNavigate } from 'react-router-dom';
import {
  AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
  PieChart, Pie, Cell, Legend,
} from 'recharts';
import {
  Users, GraduationCap, BookOpen, CreditCard, MessageSquare,
  UserPlus, BookPlus, Award, ClipboardCheck, Calendar, ArrowRight,
  Sparkles, Compass, FolderOpen, Bell, ArrowUpRight, Plus,
  FileSpreadsheet, IndianRupee, Layers, ShieldCheck, Tag,
} from 'lucide-react';
import { useMockStore } from '@/hooks/useMockStore';
import { StatCard, Card } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { Avatar } from '@/components/ui/Avatar';
import { EmptyState } from '@/components/ui/State';
import { PageHeader } from '@/components/ui/PageHeader';
import { Modal } from '@/components/ui/Modal';
import { Button } from '@/components/ui/Button';
import { calculateMonthlyMetrics } from '@/mock-data';
import { useMemo, useState } from 'react';
import { formatDate, timeAgo, generateId, formatCurrency } from '@/utils';
import { useAuth } from '@/hooks/useAuth';

export function DashboardPage() {
  const store = useMockStore();
  const navigate = useNavigate();
  const { user } = useAuth();

  // Category modal states
  const [isCategoryModalOpen, setCategoryModalOpen] = useState(false);
  const [categoryName, setCategoryName] = useState('');
  const [categoryDesc, setCategoryDesc] = useState('');
  const [categoryColor, setCategoryColor] = useState('#064B3E');

  const [editModalOpen, setEditModalOpen] = useState(false);
  const [editCategoryId, setEditCategoryId] = useState('');
  const [editCategoryName, setEditCategoryName] = useState('');
  const [editCategoryDesc, setEditCategoryDesc] = useState('');
  const [editCategoryColor, setEditCategoryColor] = useState('#064B3E');

  // Core metrics
  const totalStudents = store.students.length;
  const activeStudents = store.students.filter((s) => s.accountStatus === 'active').length;
  const totalInstructors = store.instructors.length;
  const publishedCourses = store.courses.filter((c) => c.status === 'published').length;
  const pendingPayments = store.payments.filter((p) => p.status === 'pending').length;
  const verifiedPaymentsRevenue = store.payments
    .filter((p) => p.status === 'verified')
    .reduce((sum, p) => sum + p.amount, 0);

  const pendingEnquiries = store.enquiries.filter((e) => e.status === 'new' || e.status === 'follow_up').length;
  const activeAssessments = store.assessments.filter((a) => a.status === 'active' || a.status === 'scheduled').length;
  const scheduledAppointments = store.careerAppointments.filter((c) => c.status === 'scheduled').length;
  const unreadNotifications = store.notifications.filter((n) => !n.read).length;

  const recentRegistrations = [...store.students].sort((a, b) => b.createdAt.localeCompare(a.createdAt)).slice(0, 5);
  const recentEnrolments = store.courses
    .flatMap((c) => c.enrolledStudentIds.map((sid) => ({
      course: c.title,
      student: store.students.find((s) => s.id === sid)?.fullName ?? 'Unknown',
      date: c.createdAt,
    })))
    .sort((a, b) => b.date.localeCompare(a.date))
    .slice(0, 5);
  const upcomingClasses = store.liveClasses.filter((c) => c.status === 'upcoming').slice(0, 4);
  const recentActivity = store.activityLogs.slice(0, 6);

  const paymentStatusConfig: Record<string, { label: string; color: string }> = {
    verified: { label: 'Verified', color: '#064B3E' },
    pending: { label: 'Pending', color: '#FF8E53' },
    rejected: { label: 'Rejected', color: '#DC2626' },
    failed: { label: 'Failed', color: '#991B1B' },
    refunded: { label: 'Refunded', color: '#829AB1' },
  };

  const paymentChartData = useMemo(() => {
    const counts: Record<string, number> = {};
    store.payments.forEach((p) => {
      counts[p.status] = (counts[p.status] || 0) + 1;
    });
    return Object.entries(counts).map(([status, value]) => ({
      name: paymentStatusConfig[status]?.label ?? status,
      value,
      color: paymentStatusConfig[status]?.color ?? '#6b7280',
    }));
  }, [store.payments]);

  const monthlyMetrics = useMemo(() => calculateMonthlyMetrics(store.students, store.payments), [store.students, store.payments]);

  const quickActions = [
    { label: 'Add Student', icon: UserPlus, to: '/students/new', color: 'bg-navy-800' },
    { label: 'Create Course', icon: BookPlus, to: '/courses/new', color: 'bg-forest-600' },
    { label: 'Add Instructor', icon: GraduationCap, to: '/instructors/new', color: 'bg-forest-700' },
    { label: 'Review Payments', icon: CreditCard, to: '/payments', color: 'bg-peach-600' },
  ];

  // Handler to add a new course category
  const handleAddCategory = () => {
    if (!categoryName.trim()) return;
    store.addCategory({
      id: generateId('cat'),
      name: categoryName.trim(),
      description: categoryDesc.trim(),
      color: categoryColor,
      courseCount: 0,
    });
    store.addActivity({
      id: generateId('act'),
      adminName: user?.fullName ?? 'Admin',
      action: 'Added category',
      target: categoryName.trim(),
      timestamp: new Date().toISOString(),
    });
    setCategoryName('');
    setCategoryDesc('');
    setCategoryColor('#064B3E');
    setCategoryModalOpen(false);
  };

  return (
    <div className="space-y-7">
      {/* Executive Welcome & Institutional Header */}
      <div className="relative overflow-hidden rounded-3xl bg-gradient-to-br from-[#0B1D30] via-[#091828] to-[#061320] p-6 sm:p-8 text-white shadow-2xl border border-navy-800/80">
        <div className="absolute top-0 right-0 -mr-16 -mt-16 w-80 h-80 rounded-full bg-forest-500/20 blur-3xl pointer-events-none" />
        <div className="absolute bottom-0 left-1/3 -mb-20 w-80 h-80 rounded-full bg-peach-500/15 blur-3xl pointer-events-none" />

        <div className="relative z-10 flex flex-col md:flex-row md:items-center justify-between gap-6">
          <div className="space-y-2">
            <div className="flex items-center gap-2">
              <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-[11px] font-bold tracking-wider uppercase bg-forest-500/20 text-peach-300 border border-peach-500/30 shadow-xs">
                <Sparkles size={12} className="text-peach-400" />
                IIECM Institutional Administration
              </span>
              <span className="hidden sm:inline text-xs text-navy-400">·</span>
              <span className="hidden sm:inline text-xs text-navy-300 font-medium">Academic Session 2026-2027</span>
            </div>
            <h1 className="text-2xl sm:text-3xl lg:text-4xl font-extrabold font-display tracking-tight text-white">
              Institutional Command Hub
            </h1>
            <p className="text-sm text-navy-200 max-w-2xl leading-relaxed">
              Welcome back, <span className="font-semibold text-white">{user?.fullName ?? 'Administrator'}</span>. Oversight of academic curricula, faculty coordination, student assessments, and revenue reconciliation.
            </p>
          </div>

          <div className="flex flex-wrap items-center gap-3">
            <a
              href="#academic-hubs"
              className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-white/10 hover:bg-white/20 text-white text-xs sm:text-sm font-semibold backdrop-blur-md border border-white/15 transition-all shadow-sm hover:-translate-y-0.5"
            >
              <Layers size={16} className="text-peach-300" />
              <span>Explore Management Hubs ↓</span>
            </a>
            <button
              onClick={() => navigate('/students/new')}
              className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-gradient-to-r from-forest-500 to-forest-600 hover:from-forest-600 hover:to-forest-700 text-white text-xs sm:text-sm font-bold transition-all shadow-lg shadow-forest-950/40 border-t border-forest-400/40 hover:-translate-y-0.5"
            >
              <UserPlus size={16} />
              <span>Register Student</span>
            </button>
          </div>
        </div>
      </div>

      {/* 3D Core Institutional KPI Stat Cards */}
      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-3.5 sm:gap-4">
        <StatCard
          label="Total Students"
          value={totalStudents}
          icon={<Users size={20} />}
          trend={{ value: `${activeStudents} active`, positive: true }}
          accent="navy"
          to="/students"
        />
        <StatCard
          label="Faculty Members"
          value={totalInstructors}
          icon={<GraduationCap size={20} />}
          accent="forest"
          to="/instructors"
        />
        <StatCard
          label="Published Curriculums"
          value={publishedCourses}
          icon={<BookOpen size={20} />}
          accent="teal"
          to="/courses"
        />
        <StatCard
          label="Verified Revenue"
          value={formatCurrency(verifiedPaymentsRevenue)}
          icon={<IndianRupee size={20} />}
          accent="sage"
          to="/payments"
        />
        <StatCard
          label="Pending Payments"
          value={pendingPayments}
          icon={<CreditCard size={20} />}
          trend={{ value: 'Review required', positive: false }}
          accent="warning"
          to="/payments"
        />
        <StatCard
          label="Admissions Leads"
          value={pendingEnquiries}
          icon={<MessageSquare size={20} />}
          trend={{ value: 'Active pipeline', positive: true }}
          accent="peach"
          to="/enquiries"
        />
      </div>

      {/* Analytics & Financial Visualizations */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-5">
        <div className="lg:col-span-2">
          <Card title="Monthly Enrolment & Revenue Trends" subtitle="Rolling 6-month institutional performance telemetry">
            <div className="h-64 sm:h-72 p-2">
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={monthlyMetrics}>
                  <defs>
                    <linearGradient id="colorEnrolments" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#064B3E" stopOpacity={0.35} />
                      <stop offset="95%" stopColor="#064B3E" stopOpacity={0.0} />
                    </linearGradient>
                    <linearGradient id="colorRevenue" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#FF8E53" stopOpacity={0.35} />
                      <stop offset="95%" stopColor="#FF8E53" stopOpacity={0.0} />
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" stroke="#e9ecef" vertical={false} />
                  <XAxis dataKey="month" stroke="#829ab1" fontSize={12} tickLine={false} />
                  <YAxis yAxisId="left" stroke="#829ab1" fontSize={12} tickLine={false} axisLine={false} />
                  <YAxis yAxisId="right" orientation="right" stroke="#829ab1" fontSize={12} tickLine={false} axisLine={false} />
                  <Tooltip
                    contentStyle={{
                      backgroundColor: 'rgba(255, 255, 255, 0.95)',
                      backdropFilter: 'blur(8px)',
                      borderRadius: '0.875rem',
                      border: '1px solid #d9e2ec',
                      boxShadow: '0 10px 25px -3px rgba(16, 42, 67, 0.1)',
                      fontSize: '12px',
                      fontWeight: 600,
                    }}
                  />
                  <Area
                    yAxisId="left"
                    type="monotone"
                    dataKey="enrolments"
                    stroke="#064B3E"
                    strokeWidth={2.5}
                    fillOpacity={1}
                    fill="url(#colorEnrolments)"
                    name="New Students"
                  />
                  <Area
                    yAxisId="right"
                    type="monotone"
                    dataKey="revenue"
                    stroke="#FF8E53"
                    strokeWidth={2.5}
                    fillOpacity={1}
                    fill="url(#colorRevenue)"
                    name="Revenue (₹)"
                  />
                </AreaChart>
              </ResponsiveContainer>
            </div>
          </Card>
        </div>

        <Card title="Payment Status Breakdown" subtitle="Distribution across all student transactions">
          <div className="h-64 sm:h-72 flex items-center justify-center p-2">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={paymentChartData}
                  cx="50%"
                  cy="50%"
                  innerRadius={55}
                  outerRadius={80}
                  paddingAngle={3}
                  dataKey="value"
                >
                  {paymentChartData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} strokeWidth={2} stroke="#fff" />
                  ))}
                </Pie>
                <Tooltip
                  contentStyle={{
                    backgroundColor: 'rgba(255, 255, 255, 0.95)',
                    backdropFilter: 'blur(8px)',
                    borderRadius: '0.875rem',
                    border: '1px solid #d9e2ec',
                    fontSize: '12px',
                    fontWeight: 600,
                  }}
                />
                <Legend iconType="circle" wrapperStyle={{ fontSize: '11px', fontWeight: 600 }} />
              </PieChart>
            </ResponsiveContainer>
          </div>
        </Card>
      </div>

      {/* ================================================================ */}
      {/* ACADEMIC & OPERATIONAL MANAGEMENT HUBS (In-Page Specialized Suites) */}
      {/* ================================================================ */}
      <section id="academic-hubs" className="space-y-4 pt-2">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 border-b border-navy-100 pb-3">
          <div>
            <div className="flex items-center gap-2">
              <div className="flex h-6 w-6 items-center justify-center rounded-lg bg-forest-600 text-white shadow-2xs">
                <Layers size={14} />
              </div>
              <h2 className="text-xl sm:text-2xl font-bold font-display text-navy-950 tracking-tight">
                Academic & Operational Management Hubs
              </h2>
            </div>
            <p className="text-xs sm:text-sm text-navy-500 mt-1">
              Direct access to specialized institutional suites — assessments, curriculum taxonomies, student guidance, and resources.
            </p>
          </div>
          <span className="self-start sm:self-center px-3 py-1 rounded-full text-xs font-bold text-forest-700 bg-forest-50 border border-forest-200 shadow-2xs">
            6 Management Suites
          </span>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-5">
          {/* Hub 1: Assessments & Examination Portal */}
          <div
            onClick={() => navigate('/assessments')}
            className="card-3d card-hover group p-5 flex flex-col justify-between cursor-pointer border-t-4 border-t-forest-600 relative overflow-hidden"
          >
            <div className="absolute top-0 right-0 w-28 h-28 bg-forest-50/70 rounded-full blur-2xl pointer-events-none group-hover:bg-forest-100/70 transition-colors" />
            <div>
              <div className="flex items-center justify-between mb-3">
                <div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-forest-600 text-white shadow-sm transition-transform duration-200 group-hover:scale-110">
                  <ClipboardCheck size={22} />
                </div>
                <span className="text-[11px] font-bold px-2.5 py-1 rounded-full bg-forest-50 text-forest-700 border border-forest-200">
                  {store.assessments.length} Tests Configured
                </span>
              </div>
              <h3 className="text-base font-bold text-navy-950 font-display group-hover:text-forest-700 transition-colors">
                Assessments & Examinations
              </h3>
              <p className="text-xs text-navy-600 line-clamp-2 mt-1.5 leading-relaxed">
                Configure question banks, launch cohort examinations, monitor candidate submissions, and publish academic grading evaluations.
              </p>
            </div>
            <div className="mt-4 pt-3 border-t border-navy-50 flex items-center justify-between">
              <span className="text-[11px] font-semibold text-navy-500">
                {activeAssessments} Active / Scheduled Tests
              </span>
              <span className="text-xs font-bold text-forest-600 flex items-center gap-1 group-hover:translate-x-1 transition-transform">
                Open Portal <ArrowRight size={13} />
              </span>
            </div>
          </div>

          {/* Hub 2: Course Taxonomy & Categories */}
          <div
            onClick={() => navigate('/categories')}
            className="card-3d card-hover group p-5 flex flex-col justify-between cursor-pointer border-t-4 border-t-saffron-600 relative overflow-hidden"
          >
            <div className="absolute top-0 right-0 w-28 h-28 bg-saffron-50/70 rounded-full blur-2xl pointer-events-none group-hover:bg-saffron-100/70 transition-colors" />
            <div>
              <div className="flex items-center justify-between mb-3">
                <div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-saffron-600 text-white shadow-sm transition-transform duration-200 group-hover:scale-110">
                  <Tag size={22} />
                </div>
                <span className="text-[11px] font-bold px-2.5 py-1 rounded-full bg-saffron-50 text-saffron-700 border border-saffron-200">
                  {store.courseCategories.length} Categories
                </span>
              </div>
              <h3 className="text-base font-bold text-navy-950 font-display group-hover:text-saffron-700 transition-colors">
                Curriculum Taxonomies
              </h3>
              <p className="text-xs text-navy-600 line-clamp-2 mt-1.5 leading-relaxed">
                Organize curriculum taxonomies, subject streams, category visual themes, and cross-department course classifications.
              </p>
            </div>
            <div className="mt-4 pt-3 border-t border-navy-50 flex items-center justify-between">
              <span className="text-[11px] font-semibold text-navy-500">
                {store.courses.length} Courses Assigned
              </span>
              <span className="text-xs font-bold text-saffron-600 flex items-center gap-1 group-hover:translate-x-1 transition-transform">
                Manage Taxonomy <ArrowRight size={13} />
              </span>
            </div>
          </div>

          {/* Hub 3: Career Guidance & Mentorship */}
          <div
            onClick={() => navigate('/career-guidance')}
            className="card-3d card-hover group p-5 flex flex-col justify-between cursor-pointer border-t-4 border-t-peach-500 relative overflow-hidden"
          >
            <div className="absolute top-0 right-0 w-28 h-28 bg-peach-50/70 rounded-full blur-2xl pointer-events-none group-hover:bg-peach-100/70 transition-colors" />
            <div>
              <div className="flex items-center justify-between mb-3">
                <div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-peach-500 text-white shadow-sm transition-transform duration-200 group-hover:scale-110">
                  <Compass size={22} />
                </div>
                <span className="text-[11px] font-bold px-2.5 py-1 rounded-full bg-peach-50 text-peach-700 border border-peach-200">
                  {store.careerAppointments.length} Mentorships
                </span>
              </div>
              <h3 className="text-base font-bold text-navy-950 font-display group-hover:text-peach-700 transition-colors">
                Career Guidance & Pathways
              </h3>
              <p className="text-xs text-navy-600 line-clamp-2 mt-1.5 leading-relaxed">
                Facilitate 1-on-1 career advising sessions, track student progress roadmaps, and craft personalized milestone action plans.
              </p>
            </div>
            <div className="mt-4 pt-3 border-t border-navy-50 flex items-center justify-between">
              <span className="text-[11px] font-semibold text-navy-500">
                {scheduledAppointments} Scheduled Sessions
              </span>
              <span className="text-xs font-bold text-peach-600 flex items-center gap-1 group-hover:translate-x-1 transition-transform">
                Open Advisory Hub <ArrowRight size={13} />
              </span>
            </div>
          </div>

          {/* Hub 4: Digital Resource Library */}
          <div
            onClick={() => navigate('/resources')}
            className="card-3d card-hover group p-5 flex flex-col justify-between cursor-pointer border-t-4 border-t-[#102A43] relative overflow-hidden"
          >
            <div className="absolute top-0 right-0 w-28 h-28 bg-navy-50/70 rounded-full blur-2xl pointer-events-none group-hover:bg-navy-100/70 transition-colors" />
            <div>
              <div className="flex items-center justify-between mb-3">
                <div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-[#102A43] text-white shadow-sm transition-transform duration-200 group-hover:scale-110">
                  <FolderOpen size={22} />
                </div>
                <span className="text-[11px] font-bold px-2.5 py-1 rounded-full bg-navy-50 text-navy-700 border border-navy-200">
                  {store.resources.length} Assets
                </span>
              </div>
              <h3 className="text-base font-bold text-navy-950 font-display group-hover:text-navy-700 transition-colors">
                Digital Resource Library
              </h3>
              <p className="text-xs text-navy-600 line-clamp-2 mt-1.5 leading-relaxed">
                Institutional repository hosting digital syllabus documents, lecture slide decks, datasets, and course study materials.
              </p>
            </div>
            <div className="mt-4 pt-3 border-t border-navy-50 flex items-center justify-between">
              <span className="text-[11px] font-semibold text-navy-500">
                Centralized Academic Library
              </span>
              <span className="text-xs font-bold text-navy-700 flex items-center gap-1 group-hover:translate-x-1 transition-transform">
                Explore Library <ArrowRight size={13} />
              </span>
            </div>
          </div>

          {/* Hub 5: Admissions & Enquiries CRM */}
          <div
            onClick={() => navigate('/enquiries')}
            className="card-3d card-hover group p-5 flex flex-col justify-between cursor-pointer border-t-4 border-t-forest-700 relative overflow-hidden"
          >
            <div className="absolute top-0 right-0 w-28 h-28 bg-forest-50/70 rounded-full blur-2xl pointer-events-none group-hover:bg-forest-100/70 transition-colors" />
            <div>
              <div className="flex items-center justify-between mb-3">
                <div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-forest-700 text-white shadow-sm transition-transform duration-200 group-hover:scale-110">
                  <MessageSquare size={22} />
                </div>
                <span className="text-[11px] font-bold px-2.5 py-1 rounded-full bg-forest-50 text-forest-700 border border-forest-200">
                  {pendingEnquiries} Active Leads
                </span>
              </div>
              <h3 className="text-base font-bold text-navy-950 font-display group-hover:text-forest-700 transition-colors">
                Admissions CRM & Inquiries
              </h3>
              <p className="text-xs text-navy-600 line-clamp-2 mt-1.5 leading-relaxed">
                Multi-channel prospect inquiry pipeline, counseling conversations, follow-up scheduling, and admission conversion tracking.
              </p>
            </div>
            <div className="mt-4 pt-3 border-t border-navy-50 flex items-center justify-between">
              <span className="text-[11px] font-semibold text-navy-500">
                {store.enquiries.length} Total Registered Inquiries
              </span>
              <span className="text-xs font-bold text-forest-600 flex items-center gap-1 group-hover:translate-x-1 transition-transform">
                Open CRM Pipeline <ArrowRight size={13} />
              </span>
            </div>
          </div>

          {/* Hub 6: Campus Broadcasts & Alerts */}
          <div
            onClick={() => navigate('/notifications')}
            className="card-3d card-hover group p-5 flex flex-col justify-between cursor-pointer border-t-4 border-t-peach-600 relative overflow-hidden"
          >
            <div className="absolute top-0 right-0 w-28 h-28 bg-peach-50/70 rounded-full blur-2xl pointer-events-none group-hover:bg-peach-100/70 transition-colors" />
            <div>
              <div className="flex items-center justify-between mb-3">
                <div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-peach-600 text-white shadow-sm transition-transform duration-200 group-hover:scale-110">
                  <Bell size={22} />
                </div>
                <span className="text-[11px] font-bold px-2.5 py-1 rounded-full bg-peach-50 text-peach-700 border border-peach-200">
                  {unreadNotifications} Unread Notices
                </span>
              </div>
              <h3 className="text-base font-bold text-navy-950 font-display group-hover:text-peach-700 transition-colors">
                Campus Broadcasts & Alerts
              </h3>
              <p className="text-xs text-navy-600 line-clamp-2 mt-1.5 leading-relaxed">
                Dispatch institutional alerts, semester schedules, emergency notifications, and tailored broadcast updates to cohorts.
              </p>
            </div>
            <div className="mt-4 pt-3 border-t border-navy-50 flex items-center justify-between">
              <span className="text-[11px] font-semibold text-navy-500">
                {store.notifications.length} Total Broadcasts
              </span>
              <span className="text-xs font-bold text-peach-600 flex items-center gap-1 group-hover:translate-x-1 transition-transform">
                Manage Broadcasts <ArrowRight size={13} />
              </span>
            </div>
          </div>
        </div>
      </section>

      {/* 3D Tactile Operational Actions Bar */}
      <div className="grid grid-cols-2 sm:grid-cols-5 gap-3.5">
        {quickActions.map((action) => (
          <button
            key={action.label}
            onClick={() => navigate(action.to)}
            className="card-3d card-hover p-4 sm:p-5 flex flex-col items-center gap-2.5 text-center group cursor-pointer"
          >
            <div
              className={`flex h-11 w-11 items-center justify-center rounded-2xl ${action.color} text-white shadow-sm transition-transform duration-200 group-hover:scale-110 group-hover:-translate-y-0.5`}
            >
              <action.icon size={20} />
            </div>
            <span className="text-xs sm:text-sm font-bold text-navy-800 group-hover:text-forest-700 transition-colors">
              {action.label}
            </span>
          </button>
        ))}

        <button
          onClick={() => setCategoryModalOpen(true)}
          className="card-3d card-hover p-4 sm:p-5 flex flex-col items-center gap-2.5 text-center group cursor-pointer"
        >
          <div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-saffron-600 text-white shadow-sm transition-transform duration-200 group-hover:scale-110 group-hover:-translate-y-0.5">
            <Award size={20} />
          </div>
          <span className="text-xs sm:text-sm font-bold text-navy-800 group-hover:text-forest-700 transition-colors">
            Add Category
          </span>
        </button>
      </div>

      {/* Recent Registrations and Enrolments */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
        <Card
          title="Recent Registrations"
          action={
            <button
              onClick={() => navigate('/students')}
              className="text-xs font-bold text-forest-600 hover:text-forest-700 flex items-center gap-1 group"
            >
              View all
              <ArrowRight size={12} className="transition-transform group-hover:translate-x-0.5" />
            </button>
          }
        >
          <div className="divide-y divide-navy-50">
            {recentRegistrations.map((s) => (
              <div
                key={s.id}
                className="flex items-center gap-3.5 px-5 py-3.5 hover:bg-forest-50/30 transition-colors cursor-pointer"
                onClick={() => navigate(`/students/${s.id}`)}
              >
                <Avatar name={s.fullName} size="sm" />
                <div className="min-w-0 flex-1">
                  <p className="text-sm font-semibold text-navy-900 truncate">{s.fullName}</p>
                  <p className="text-xs text-navy-500 font-medium">
                    {s.studentId} · {s.preferredCategory}
                  </p>
                </div>
                <Badge variant={s.accountStatus === 'active' ? 'success' : 'neutral'} dot>
                  {s.accountStatus}
                </Badge>
              </div>
            ))}
          </div>
        </Card>

        <Card
          title="Recent Enrolments"
          action={
            <button
              onClick={() => navigate('/courses')}
              className="text-xs font-bold text-forest-600 hover:text-forest-700 flex items-center gap-1 group"
            >
              View all
              <ArrowRight size={12} className="transition-transform group-hover:translate-x-0.5" />
            </button>
          }
        >
          <div className="divide-y divide-navy-50">
            {recentEnrolments.map((e, i) => (
              <div key={i} className="flex items-center gap-3.5 px-5 py-3.5 hover:bg-forest-50/30 transition-colors">
                <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-forest-100 text-forest-700 shadow-xs">
                  <BookOpen size={16} />
                </div>
                <div className="min-w-0 flex-1">
                  <p className="text-sm font-semibold text-navy-900 truncate">{e.student}</p>
                  <p className="text-xs text-navy-500 truncate">{e.course}</p>
                </div>
                <span className="text-xs text-navy-400 font-medium">{formatDate(e.date)}</span>
              </div>
            ))}
          </div>
        </Card>
      </div>

      {/* Upcoming Classes and Recent Activity */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
        <Card title="Upcoming Live Classes">
          {upcomingClasses.length === 0 ? (
            <EmptyState icon={<Calendar size={24} />} title="No upcoming classes" />
          ) : (
            <div className="divide-y divide-navy-50">
              {upcomingClasses.map((c) => (
                <div key={c.id} className="flex items-center gap-3.5 px-5 py-3.5 hover:bg-forest-50/30 transition-colors">
                  <div className="flex h-11 w-11 flex-col items-center justify-center rounded-xl bg-forest-100 text-forest-800 text-xs font-bold shadow-xs">
                    <span>{new Date(c.scheduledAt).getDate()}</span>
                    <span className="text-[9px] uppercase font-semibold text-forest-600">
                      {new Date(c.scheduledAt).toLocaleString('en-IN', { month: 'short' })}
                    </span>
                  </div>
                  <div className="min-w-0 flex-1">
                    <p className="text-sm font-semibold text-navy-900 truncate">{c.title}</p>
                    <p className="text-xs text-navy-500 font-medium">
                      {c.instructorName} · {c.courseName}
                    </p>
                  </div>
                  <Badge variant="info">
                    {new Date(c.scheduledAt).toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit' })}
                  </Badge>
                </div>
              ))}
            </div>
          )}
        </Card>

        <Card title="Recent Activity">
          <div className="divide-y divide-navy-50">
            {recentActivity.map((a) => (
              <div key={a.id} className="flex items-start gap-3.5 px-5 py-3.5 hover:bg-navy-50/50 transition-colors">
                <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-xl bg-navy-100 text-navy-600 shadow-2xs mt-0.5">
                  <ClipboardCheck size={14} />
                </div>
                <div className="min-w-0 flex-1">
                  <p className="text-xs sm:text-sm text-navy-800 font-medium">
                    <span className="font-bold text-navy-900">{a.action}</span> — {a.target}
                  </p>
                  <p className="text-[11px] text-navy-400 mt-0.5 font-medium">
                    {a.adminName} · {timeAgo(a.timestamp)}
                  </p>
                </div>
              </div>
            ))}
          </div>
        </Card>
      </div>

      {/* Add Category Modal */}
      <Modal
        open={isCategoryModalOpen}
        onClose={() => setCategoryModalOpen(false)}
        title="Add Course Category"
        footer={
          <div className="flex justify-end gap-2.5">
            <Button variant="secondary" onClick={() => setCategoryModalOpen(false)}>
              Cancel
            </Button>
            <Button variant="primary" onClick={handleAddCategory}>
              Add Category
            </Button>
          </div>
        }
      >
        <div className="space-y-4">
          <div>
            <label className="label-base">Category Name</label>
            <input
              type="text"
              placeholder="e.g. E-Commerce Strategy"
              value={categoryName}
              onChange={(e) => setCategoryName(e.target.value)}
              className="input-base"
            />
          </div>
          <div>
            <label className="label-base">Description</label>
            <textarea
              placeholder="Brief description of courses in this category"
              value={categoryDesc}
              onChange={(e) => setCategoryDesc(e.target.value)}
              className="input-base min-h-[80px]"
            />
          </div>
          <div>
            <label className="label-base">Color Theme</label>
            <div className="flex items-center gap-3">
              <input
                type="color"
                value={categoryColor}
                onChange={(e) => setCategoryColor(e.target.value)}
                className="h-10 w-14 p-1 border border-navy-200 rounded-xl cursor-pointer"
              />
              <span className="text-xs font-mono text-navy-600 uppercase font-semibold">{categoryColor}</span>
            </div>
          </div>
        </div>
      </Modal>

      {/* Edit Category Modal */}
      <Modal
        open={editModalOpen}
        onClose={() => setEditModalOpen(false)}
        title="Edit Category"
        footer={
          <div className="flex justify-end gap-2.5">
            <Button variant="secondary" onClick={() => setEditModalOpen(false)}>
              Cancel
            </Button>
            <Button
              variant="primary"
              onClick={() => {
                if (!editCategoryName.trim()) return;
                store.updateCategory(editCategoryId, {
                  name: editCategoryName.trim(),
                  description: editCategoryDesc.trim(),
                  color: editCategoryColor,
                });
                store.addActivity({
                  id: generateId('act'),
                  adminName: user?.fullName ?? 'Admin',
                  action: 'Edited category',
                  target: editCategoryName.trim(),
                  timestamp: new Date().toISOString(),
                });
                setEditModalOpen(false);
              }}
            >
              Save Changes
            </Button>
          </div>
        }
      >
        <div className="space-y-4">
          <div>
            <label className="label-base">Category Name</label>
            <input
              type="text"
              placeholder="Category name"
              value={editCategoryName}
              onChange={(e) => setEditCategoryName(e.target.value)}
              className="input-base"
            />
          </div>
          <div>
            <label className="label-base">Description</label>
            <textarea
              placeholder="Description"
              value={editCategoryDesc}
              onChange={(e) => setEditCategoryDesc(e.target.value)}
              className="input-base min-h-[80px]"
            />
          </div>
          <div>
            <label className="label-base">Color Theme</label>
            <div className="flex items-center gap-3">
              <input
                type="color"
                value={editCategoryColor}
                onChange={(e) => setEditCategoryColor(e.target.value)}
                className="h-10 w-14 p-1 border border-navy-200 rounded-xl cursor-pointer"
              />
              <span className="text-xs font-mono text-navy-600 uppercase font-semibold">{editCategoryColor}</span>
            </div>
          </div>
        </div>
      </Modal>
    </div>
  );
}
