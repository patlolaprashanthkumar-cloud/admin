import { useState, useMemo } from 'react';
import { useNavigate } from 'react-router-dom';
import { Plus, Eye, Star, BookOpen, Users as UsersIcon, Pencil } from 'lucide-react';
import { useMockStore } from '@/hooks/useMockStore';
import { mockStore } from '@/mock-data/store';
import { Card } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { Avatar } from '@/components/ui/Avatar';
import { PageHeader } from '@/components/ui/PageHeader';
import { SearchBar, FilterBar } from '@/components/ui/SearchBar';
import { Select } from '@/components/ui/FormField';
import { EmptyState } from '@/components/ui/State';
import { Modal, Input, Textarea } from '@/components/ui';
import { generateId, formatDate } from '@/utils';
import type { Instructor, AccountStatus } from '@/types';

export function InstructorListPage() {
  const store = useMockStore();
  const navigate = useNavigate();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [addOpen, setAddOpen] = useState(false);
  const [selected, setSelected] = useState<Instructor | null>(null);
  const [form, setForm] = useState({
    fullName: '', email: '', phone: '', qualifications: '', specialization: '', experienceYears: '0', bio: '',
  });
  const [errors, setErrors] = useState<Record<string, string>>({});

  const filtered = useMemo(() => store.instructors.filter((i) => {
    const q = search.toLowerCase();
    const matchesSearch = !q || i.fullName.toLowerCase().includes(q) || i.email.toLowerCase().includes(q) || i.specialization.toLowerCase().includes(q);
    const matchesStatus = !statusFilter || i.accountStatus === statusFilter;
    return matchesSearch && matchesStatus;
  }), [store.instructors, search, statusFilter]);

  function validate() {
    const e: Record<string, string> = {};
    if (!form.fullName.trim()) e.fullName = 'Name required';
    if (!form.email.trim()) e.email = 'Email required';
    else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email)) e.email = 'Invalid email';
    if (!form.phone.trim()) e.phone = 'Phone required';
    if (!form.specialization.trim()) e.specialization = 'Specialization required';
    setErrors(e);
    return Object.keys(e).length === 0;
  }

  function addInstructor() {
    if (!validate()) return;
    const instructor: Instructor = {
      id: generateId('ins'),
      fullName: form.fullName.trim(), email: form.email.trim(), phone: form.phone.trim(),
      qualifications: form.qualifications.trim() || 'N/A',
      specialization: form.specialization.trim(),
      experienceYears: parseInt(form.experienceYears) || 0,
      assignedCourseIds: [], accountStatus: 'active',
      bio: form.bio.trim() || undefined, createdAt: new Date().toISOString(),
      rating: 0, totalStudents: 0, totalClasses: 0,
    };
    mockStore.addInstructor(instructor);
    mockStore.addActivity({ id: generateId('act'), adminName: 'Dr. Priya Sharma', action: 'Added instructor', target: instructor.fullName, timestamp: new Date().toISOString() });
    setAddOpen(false);
    setForm({ fullName: '', email: '', phone: '', qualifications: '', specialization: '', experienceYears: '0', bio: '' });
  }

  function toggleStatus(instructor: Instructor) {
    const newStatus: AccountStatus = instructor.accountStatus === 'active' ? 'inactive' : 'active';
    mockStore.updateInstructor(instructor.id, { accountStatus: newStatus });
    mockStore.addActivity({ id: generateId('act'), adminName: 'Dr. Priya Sharma', action: newStatus === 'active' ? 'Activated instructor' : 'Deactivated instructor', target: instructor.fullName, timestamp: new Date().toISOString() });
    setSelected(null);
  }

  return (
    <div>
      <PageHeader
        title="Instructors"
        subtitle={`${store.instructors.length} instructors`}
        breadcrumbs={[{ label: 'Dashboard', to: '/dashboard' }, { label: 'Instructors' }]}
        actions={<button className="btn-primary" onClick={() => setAddOpen(true)}><Plus size={16} /> Add Instructor</button>}
      />

      <Card className="p-4 mb-4">
        <div className="flex flex-col sm:flex-row gap-3">
          <SearchBar value={search} onChange={setSearch} placeholder="Search by name, email, or specialization" className="flex-1" />
          <Select value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)} placeholder="All Statuses"
            options={[{ value: 'active', label: 'Active' }, { value: 'inactive', label: 'Inactive' }]} className="w-auto min-w-32" />
        </div>
      </Card>

      {filtered.length === 0 ? (
        <Card><EmptyState icon={<UsersIcon size={26} />} title="No instructors found" description="Try adjusting your search or add a new instructor." action={<button className="btn-primary" onClick={() => setAddOpen(true)}><Plus size={16} /> Add Instructor</button>} /></Card>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {filtered.map((ins) => {
            const courses = store.courses.filter((c) => c.instructorId === ins.id);
            return (
              <Card key={ins.id} className="p-5 card-hover">
                <div className="flex items-start gap-3">
                  <Avatar name={ins.fullName} size="md" />
                  <div className="min-w-0 flex-1">
                    <h3 className="text-sm font-semibold text-navy-900 truncate">{ins.fullName}</h3>
                    <p className="text-xs text-navy-500">{ins.specialization}</p>
                    <div className="mt-1 flex items-center gap-2">
                      <Badge variant={ins.accountStatus === 'active' ? 'success' : 'neutral'} dot>{ins.accountStatus}</Badge>
                      {ins.rating ? <span className="flex items-center gap-0.5 text-xs text-amber-600"><Star size={12} fill="currentColor" />{ins.rating}</span> : null}
                    </div>
                  </div>
                </div>
                <p className="text-xs text-navy-500 mt-3 line-clamp-2">{ins.bio}</p>
                <div className="grid grid-cols-3 gap-2 mt-4 text-center">
                  <div><p className="text-lg font-bold text-navy-900">{courses.length}</p><p className="text-[10px] text-navy-500">Courses</p></div>
                  <div><p className="text-lg font-bold text-navy-900">{ins.totalStudents ?? 0}</p><p className="text-[10px] text-navy-500">Students</p></div>
                  <div><p className="text-lg font-bold text-navy-900">{ins.experienceYears}</p><p className="text-[10px] text-navy-500">Years</p></div>
                </div>
                <div className="flex gap-2 mt-4">
                  <button className="btn-secondary flex-1" onClick={() => setSelected(ins)}><Eye size={14} /> View</button>
                  <button className="btn-ghost" onClick={() => toggleStatus(ins)}>{ins.accountStatus === 'active' ? 'Deactivate' : 'Activate'}</button>
                </div>
              </Card>
            );
          })}
        </div>
      )}

      <Modal open={addOpen} onClose={() => setAddOpen(false)} title="Add New Instructor"
        footer={<><button className="btn-secondary" onClick={() => setAddOpen(false)}>Cancel</button><button className="btn-primary" onClick={addInstructor}><Plus size={16} /> Add</button></>}
      >
        <div className="space-y-4">
          <Input label="Full Name *" value={form.fullName} onChange={(e) => setForm({ ...form, fullName: e.target.value })} error={errors.fullName} />
          <div className="grid grid-cols-2 gap-4">
            <Input label="Email *" value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} error={errors.email} />
            <Input label="Phone *" value={form.phone} onChange={(e) => setForm({ ...form, phone: e.target.value })} error={errors.phone} />
          </div>
          <Input label="Qualifications" value={form.qualifications} onChange={(e) => setForm({ ...form, qualifications: e.target.value })} placeholder="e.g. PhD, MBA" />
          <Input label="Specialization *" value={form.specialization} onChange={(e) => setForm({ ...form, specialization: e.target.value })} error={errors.specialization} />
          <Input label="Experience (Years)" type="number" value={form.experienceYears} onChange={(e) => setForm({ ...form, experienceYears: e.target.value })} />
          <Textarea label="Bio" value={form.bio} onChange={(e) => setForm({ ...form, bio: e.target.value })} rows={3} placeholder="Brief professional biography" />
        </div>
      </Modal>

      <Modal open={!!selected} onClose={() => setSelected(null)} title="Instructor Details" size="lg">
        {selected && (() => {
          const courses = store.courses.filter((c) => c.instructorId === selected.id);
          const classes = store.liveClasses.filter((l) => l.instructorId === selected.id);
          return (
            <div className="space-y-4">
              <div className="flex items-center gap-4">
                <Avatar name={selected.fullName} size="lg" />
                <div><h3 className="text-lg font-bold text-navy-900">{selected.fullName}</h3><p className="text-sm text-navy-500">{selected.specialization}</p><p className="text-xs text-navy-400 mt-0.5">{selected.email} · {selected.phone}</p></div>
              </div>
              <div className="rounded-lg bg-navy-50 p-4 text-sm text-navy-600">{selected.bio}</div>
              <div className="grid grid-cols-2 gap-4">
                <div><p className="text-xs text-navy-500 uppercase">Qualifications</p><p className="text-sm font-medium text-navy-900">{selected.qualifications}</p></div>
                <div><p className="text-xs text-navy-500 uppercase">Experience</p><p className="text-sm font-medium text-navy-900">{selected.experienceYears} years</p></div>
                <div><p className="text-xs text-navy-500 uppercase">Joined</p><p className="text-sm font-medium text-navy-900">{formatDate(selected.createdAt)}</p></div>
                <div><p className="text-xs text-navy-500 uppercase">Rating</p><p className="text-sm font-medium text-navy-900 flex items-center gap-1"><Star size={14} className="text-amber-500" fill="currentColor" />{selected.rating ?? 'N/A'}</p></div>
              </div>
              <div>
                <p className="text-sm font-semibold text-navy-900 mb-2">Assigned Courses ({courses.length})</p>
                <div className="space-y-2">{courses.length === 0 ? <p className="text-sm text-navy-400">No courses assigned</p> : courses.map((c) => (
                  <div key={c.id} className="flex items-center gap-2 rounded-lg border border-navy-100 p-3 cursor-pointer hover:bg-navy-50/50" onClick={() => { setSelected(null); navigate(`/courses/${c.id}`); }}>
                    <BookOpen size={16} className="text-navy-400" /><span className="text-sm text-navy-700 flex-1">{c.title}</span><Badge variant={c.status === 'published' ? 'success' : 'neutral'}>{c.status}</Badge>
                  </div>
                ))}</div>
              </div>
              <div>
                <p className="text-sm font-semibold text-navy-900 mb-2">Upcoming Classes ({classes.filter((c) => c.status === 'upcoming').length})</p>
                <div className="space-y-2">{classes.length === 0 ? <p className="text-sm text-navy-400">No classes scheduled</p> : classes.map((c) => (
                  <div key={c.id} className="flex items-center gap-2 rounded-lg border border-navy-100 p-3">
                    <Calendar size={16} className="text-navy-400" /><span className="text-sm text-navy-700 flex-1">{c.title}</span><span className="text-xs text-navy-500">{formatDate(c.scheduledAt)}</span>
                  </div>
                ))}</div>
              </div>
              <div className="flex justify-end gap-2 pt-2">
                <button className="btn-secondary" onClick={() => { setSelected(null); }}>Close</button>
                <button className={selected.accountStatus === 'active' ? 'btn-danger' : 'btn-primary'} onClick={() => toggleStatus(selected)}>{selected.accountStatus === 'active' ? 'Deactivate' : 'Activate'}</button>
              </div>
            </div>
          );
        })()}
      </Modal>
    </div>
  );
}

import { Calendar } from 'lucide-react';
