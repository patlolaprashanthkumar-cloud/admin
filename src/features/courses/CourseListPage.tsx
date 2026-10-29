import { useState, useMemo } from 'react';
import { useNavigate } from 'react-router-dom';
import { Plus, BookOpen, Users, Clock, Pencil, Archive, Eye, Award, Tag } from 'lucide-react';
import { useMockStore } from '@/hooks/useMockStore';
import { mockStore } from '@/mock-data/store';
import { Card } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { PageHeader } from '@/components/ui/PageHeader';
import { SearchBar, FilterBar } from '@/components/ui/SearchBar';
import { Select } from '@/components/ui/FormField';
import { EmptyState } from '@/components/ui/State';
import { Modal, Input, Textarea, Select as FormSelect } from '@/components/ui';
import { Button } from '@/components/ui/Button';
import { generateId, formatCurrency, paginate } from '@/utils';
import { Pagination } from '@/components/ui/Pagination';
import type { Course, CourseStatus, LearningFormat } from '@/types';

const PER_PAGE = 8;

export function CourseListPage() {
  const store = useMockStore();
  const navigate = useNavigate();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [categoryFilter, setCategoryFilter] = useState('');
  const [page, setPage] = useState(1);
  const [addOpen, setAddOpen] = useState(false);
  const [form, setForm] = useState({
    title: '', description: '', category: '', instructorId: '', durationWeeks: '8', fee: '4999', format: 'hybrid' as LearningFormat,
  });
  const [errors, setErrors] = useState<Record<string, string>>({});

  const filtered = useMemo(() => store.courses.filter((c) => {
    const q = search.toLowerCase();
    const matchesSearch = !q || c.title.toLowerCase().includes(q) || c.description.toLowerCase().includes(q);
    const matchesStatus = !statusFilter || c.status === statusFilter;
    const matchesCategory = !categoryFilter || c.category === categoryFilter;
    return matchesSearch && matchesStatus && matchesCategory;
  }), [store.courses, search, statusFilter, categoryFilter]);

  const { data, total, totalPages, currentPage } = paginate(filtered, page, PER_PAGE);

  function validate() {
    const e: Record<string, string> = {};
    if (!form.title.trim()) e.title = 'Title required';
    if (!form.description.trim()) e.description = 'Description required';
    if (!form.category) e.category = 'Category required';
    setErrors(e);
    return Object.keys(e).length === 0;
  }

  function addCourse() {
    if (!validate()) return;
    const course: Course = {
      id: generateId('crs'),
      title: form.title.trim(), description: form.description.trim(), category: form.category,
      instructorId: form.instructorId || undefined, durationWeeks: parseInt(form.durationWeeks) || 8,
      fee: parseInt(form.fee) || 0, learningObjectives: [], prerequisites: [], modules: [],
      format: form.format, status: 'draft', enrolledStudentIds: [], createdAt: new Date().toISOString(),
    };
    mockStore.addCourse(course);
    mockStore.addActivity({ id: generateId('act'), adminName: 'Dr. Priya Sharma', action: 'Created course', target: course.title, timestamp: new Date().toISOString() });
    setAddOpen(false);
    setForm({ title: '', description: '', category: '', instructorId: '', durationWeeks: '8', fee: '4999', format: 'hybrid' });
    navigate(`/courses/${course.id}`);
  }

  return (
    <div>
      <PageHeader
        title="Courses"
        subtitle={`${store.courses.length} courses · ${store.courses.filter((c) => c.status === 'published').length} published`}
        breadcrumbs={[{ label: 'Dashboard', to: '/dashboard' }, { label: 'Courses' }]}
        actions={
          <div className="flex items-center gap-2.5">
            <button
              className="btn-secondary"
              onClick={() => navigate('/categories')}
            >
              <Award size={16} className="text-saffron-600" />
              <span>Taxonomies ({store.courseCategories.length})</span>
            </button>
            <button className="btn-primary" onClick={() => setAddOpen(true)}>
              <Plus size={16} /> Create Course
            </button>
          </div>
        }
      />

      <Card className="p-4 mb-4">
        <div className="flex flex-col sm:flex-row gap-3">
          <SearchBar value={search} onChange={(v) => { setSearch(v); setPage(1); }} placeholder="Search courses..." className="flex-1" />
          <FilterBar>
            <Select value={statusFilter} onChange={(e) => { setStatusFilter(e.target.value); setPage(1); }} placeholder="All Statuses"
              options={[{ value: 'draft', label: 'Draft' }, { value: 'published', label: 'Published' }, { value: 'archived', label: 'Archived' }]} className="w-auto min-w-32" />
            <Select value={categoryFilter} onChange={(e) => { setCategoryFilter(e.target.value); setPage(1); }} placeholder="All Categories"
              options={store.courseCategories.map((c) => ({ value: c.name, label: c.name }))} className="w-auto min-w-40" />
          </FilterBar>
        </div>
      </Card>

      <Card>
        {filtered.length === 0 ? (
          <EmptyState icon={<BookOpen size={26} />} title="No courses found" description="Try adjusting filters or create a new course." action={<button className="btn-primary" onClick={() => setAddOpen(true)}><Plus size={16} /> Create Course</button>} />
        ) : (
          <>
            <div className="divide-y divide-navy-50">
              {data.map((c) => {
                const instructor = store.instructors.find((i) => i.id === c.instructorId);
                return (
                  <div key={c.id} className="flex items-center gap-3 px-5 py-4 hover:bg-navy-50/40 cursor-pointer" onClick={() => navigate(`/courses/${c.id}`)}>
                    <div className="flex h-12 w-12 items-center justify-center rounded-lg bg-navy-100 text-navy-600"><BookOpen size={22} /></div>
                    <div className="min-w-0 flex-1">
                      <p className="text-sm font-medium text-navy-900 truncate">{c.title}</p>
                      <p className="text-xs text-navy-500 truncate">{c.category} · {instructor?.fullName ?? 'Unassigned'}</p>
                      <div className="flex items-center gap-3 mt-1 text-xs text-navy-400">
                        <span className="flex items-center gap-1"><Clock size={12} />{c.durationWeeks}w</span>
                        <span className="flex items-center gap-1"><Users size={12} />{c.enrolledStudentIds.length}</span>
                        <span>{formatCurrency(c.fee)}</span>
                      </div>
                    </div>
                    <Badge variant={c.status === 'published' ? 'success' : c.status === 'archived' ? 'neutral' : 'warning'} dot>{c.status}</Badge>
                  </div>
                );
              })}
            </div>
            <Pagination currentPage={currentPage} totalPages={totalPages} onPageChange={setPage} total={total} perPage={PER_PAGE} />
          </>
        )}
      </Card>

      <Modal open={addOpen} onClose={() => setAddOpen(false)} title="Create New Course" size="lg"
        footer={<><button className="btn-secondary" onClick={() => setAddOpen(false)}>Cancel</button><button className="btn-primary" onClick={addCourse}><Plus size={16} /> Create</button></>}
      >
        <div className="space-y-4">
          <Input label="Course Title *" value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} error={errors.title} />
          <Textarea label="Description *" value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} error={errors.description} rows={3} />
          <div className="grid grid-cols-2 gap-4">
            <FormSelect label="Category *" value={form.category} onChange={(e) => setForm({ ...form, category: e.target.value })} error={errors.category} placeholder="Select category"
              options={store.courseCategories.map((c) => ({ value: c.name, label: c.name }))} />
            <FormSelect label="Instructor" value={form.instructorId} onChange={(e) => setForm({ ...form, instructorId: e.target.value })} placeholder="Select instructor"
              options={store.instructors.map((i) => ({ value: i.id, label: i.fullName }))} />
            <Input label="Duration (Weeks)" type="number" value={form.durationWeeks} onChange={(e) => setForm({ ...form, durationWeeks: e.target.value })} />
            <Input label="Fee (INR)" type="number" value={form.fee} onChange={(e) => setForm({ ...form, fee: e.target.value })} />
            <FormSelect label="Format" value={form.format} onChange={(e) => setForm({ ...form, format: e.target.value as LearningFormat })}
              options={[{ value: 'live', label: 'Live' }, { value: 'recorded', label: 'Recorded' }, { value: 'hybrid', label: 'Hybrid' }]} />
          </div>
        </div>
      </Modal>
    </div>
  );
}
