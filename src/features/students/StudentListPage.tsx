import { useState, useMemo } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { Plus, Eye, Pencil, Ban, CheckCircle2, FileText, Users, Compass, MessageSquare } from 'lucide-react';
import { useMockStore } from '@/hooks/useMockStore';
import { DataTable } from '@/components/tables/DataTable';
import { Badge } from '@/components/ui/Badge';
import { Avatar } from '@/components/ui/Avatar';
import { Card } from '@/components/ui/Card';
import { PageHeader } from '@/components/ui/PageHeader';
import { SearchBar, FilterBar } from '@/components/ui/SearchBar';
import { Pagination } from '@/components/ui/Pagination';
import { EmptyState } from '@/components/ui/State';
import { ConfirmDialog } from '@/components/ui/ConfirmDialog';
import { Select } from '@/components/ui/FormField';
import { mockStore } from '@/mock-data/store';
import { formatDate, paginate } from '@/utils';
import type { Student } from '@/types';

const PER_PAGE = 8;

export function StudentListPage() {
  const store = useMockStore();
  const navigate = useNavigate();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [planFilter, setPlanFilter] = useState('');
  const [categoryFilter, setCategoryFilter] = useState('');
  const [page, setPage] = useState(1);
  const [confirmAction, setConfirmAction] = useState<{ student: Student; action: 'activate' | 'deactivate' } | null>(null);

  const categories = useMemo(() => [...new Set(store.students.map((s) => s.preferredCategory))].sort(), [store.students]);

  const filtered = useMemo(() => {
    return store.students.filter((s) => {
      const q = search.toLowerCase();
      const matchesSearch = !q || s.fullName.toLowerCase().includes(q) || s.email.toLowerCase().includes(q) || s.phone.includes(q) || s.studentId.toLowerCase().includes(q);
      const matchesStatus = !statusFilter || s.accountStatus === statusFilter;
      const matchesPlan = !planFilter || s.subscriptionPlan === planFilter;
      const matchesCategory = !categoryFilter || s.preferredCategory === categoryFilter;
      return matchesSearch && matchesStatus && matchesPlan && matchesCategory;
    });
  }, [store.students, search, statusFilter, planFilter, categoryFilter]);

  const { data, total, totalPages, currentPage } = paginate(filtered, page, PER_PAGE);

  function toggleStatus(student: Student) {
    const newStatus = student.accountStatus === 'active' ? 'inactive' : 'active';
    mockStore.updateStudent(student.id, { accountStatus: newStatus });
    mockStore.addActivity({
      id: `act-${Date.now()}`,
      adminName: 'Dr. Priya Sharma',
      action: newStatus === 'active' ? 'Activated student' : 'Deactivated student',
      target: `${student.fullName} (${student.studentId})`,
      timestamp: new Date().toISOString(),
    });
  }

  return (
    <div>
      <PageHeader
        title="Students"
        subtitle={`${store.students.length} total students`}
        breadcrumbs={[{ label: 'Dashboard', to: '/dashboard' }, { label: 'Students' }]}
        actions={
          <div className="flex items-center gap-2.5">
            <button
              onClick={() => navigate('/career-guidance')}
              className="btn-secondary hidden sm:inline-flex"
            >
              <Compass size={16} className="text-peach-600" />
              <span>Career Guidance ({store.careerAppointments.length})</span>
            </button>
            <button
              onClick={() => navigate('/enquiries')}
              className="btn-secondary hidden md:inline-flex"
            >
              <MessageSquare size={16} className="text-forest-600" />
              <span>Admissions CRM ({store.enquiries.length})</span>
            </button>
            <button className="btn-primary" onClick={() => navigate('/students/new')}>
              <Plus size={16} /> Add Student
            </button>
          </div>
        }
      />

      <Card className="p-4 mb-4">
        <div className="flex flex-col gap-3">
          <SearchBar value={search} onChange={(v) => { setSearch(v); setPage(1); }} placeholder="Search by name, email, phone, or student ID" />
          <FilterBar>
            <Select value={statusFilter} onChange={(e) => { setStatusFilter(e.target.value); setPage(1); }} placeholder="All Statuses"
              options={[{ value: 'active', label: 'Active' }, { value: 'inactive', label: 'Inactive' }, { value: 'suspended', label: 'Suspended' }]} className="w-auto min-w-32" />
            <Select value={planFilter} onChange={(e) => { setPlanFilter(e.target.value); setPage(1); }} placeholder="All Plans"
              options={[{ value: 'free', label: 'Free' }, { value: 'basic', label: 'Basic' }, { value: 'premium', label: 'Premium' }, { value: 'enterprise', label: 'Enterprise' }]} className="w-auto min-w-32" />
            <Select value={categoryFilter} onChange={(e) => { setCategoryFilter(e.target.value); setPage(1); }} placeholder="All Categories"
              options={categories.map((c) => ({ value: c, label: c }))} className="w-auto min-w-40" />
            {(search || statusFilter || planFilter || categoryFilter) && (
              <button onClick={() => { setSearch(''); setStatusFilter(''); setPlanFilter(''); setCategoryFilter(''); setPage(1); }} className="text-xs text-navy-500 hover:text-navy-700">Clear filters</button>
            )}
          </FilterBar>
        </div>
      </Card>

      <Card>
        {filtered.length === 0 ? (
          <EmptyState icon={<Users size={26} />} title="No students found" description="Try adjusting your search or filters, or add a new student." action={<button className="btn-primary" onClick={() => navigate('/students/new')}><Plus size={16} /> Add Student</button>} />
        ) : (
          <>
            <DataTable
              data={data}
              rowKey={(s) => s.id}
              onRowClick={(s) => navigate(`/students/${s.id}`)}
              columns={[
                {
                  key: 'fullName', header: 'Student',
                  render: (s) => (
                    <div className="flex items-center gap-3">
                      <Avatar name={s.fullName} size="sm" />
                      <div className="min-w-0">
                        <p className="font-medium text-navy-900 truncate">{s.fullName}</p>
                        <p className="text-xs text-navy-500">{s.studentId}</p>
                      </div>
                    </div>
                  ),
                },
                { key: 'email', header: 'Email', hideOnMobile: true, render: (s) => <span className="text-navy-600">{s.email}</span> },
                { key: 'preferredCategory', header: 'Category', hideOnMobile: true },
                {
                  key: 'subscriptionPlan', header: 'Plan',
                  render: (s) => <Badge variant={s.subscriptionPlan === 'enterprise' ? 'accent' : s.subscriptionPlan === 'premium' ? 'info' : s.subscriptionPlan === 'basic' ? 'default' : 'neutral'}>{s.subscriptionPlan}</Badge>,
                },
                {
                  key: 'accountStatus', header: 'Status',
                  render: (s) => <Badge variant={s.accountStatus === 'active' ? 'success' : s.accountStatus === 'suspended' ? 'danger' : 'neutral'} dot>{s.accountStatus}</Badge>,
                },
                { key: 'createdAt', header: 'Joined', hideOnMobile: true, render: (s) => <span className="text-navy-500 text-xs">{formatDate(s.createdAt)}</span> },
                {
                  key: 'actions', header: '', className: 'text-right',
                  render: (s) => (
                    <div className="flex items-center justify-end gap-1">
                      <button onClick={(e) => { e.stopPropagation(); navigate(`/students/${s.id}`); }} className="rounded-lg p-1.5 text-navy-400 hover:bg-navy-100 hover:text-navy-700" title="View"><Eye size={16} /></button>
                      <button onClick={(e) => { e.stopPropagation(); navigate(`/students/${s.id}/edit`); }} className="rounded-lg p-1.5 text-navy-400 hover:bg-navy-100 hover:text-navy-700" title="Edit"><Pencil size={16} /></button>
                      <button onClick={(e) => { e.stopPropagation(); setConfirmAction({ student: s, action: s.accountStatus === 'active' ? 'deactivate' : 'activate' }); }} className="rounded-lg p-1.5 text-navy-400 hover:bg-navy-100 hover:text-navy-700" title={s.accountStatus === 'active' ? 'Deactivate' : 'Activate'}>
                        {s.accountStatus === 'active' ? <Ban size={16} /> : <CheckCircle2 size={16} />}
                      </button>
                    </div>
                  ),
                },
              ]}
            />
            <Pagination currentPage={currentPage} totalPages={totalPages} onPageChange={setPage} total={total} perPage={PER_PAGE} />
          </>
        )}
      </Card>

      <ConfirmDialog
        open={!!confirmAction}
        onClose={() => setConfirmAction(null)}
        onConfirm={() => confirmAction ? toggleStatus(confirmAction.student) : undefined}
        title={confirmAction?.action === 'activate' ? 'Activate Student' : 'Deactivate Student'}
        message={confirmAction?.action === 'activate'
          ? `Activate ${confirmAction?.student.fullName}? They will regain access to the portal.`
          : `Deactivate ${confirmAction?.student.fullName}? They will lose access to the portal.`}
        confirmLabel={confirmAction?.action === 'activate' ? 'Activate' : 'Deactivate'}
        danger={confirmAction?.action === 'deactivate'}
      />
    </div>
  );
}
