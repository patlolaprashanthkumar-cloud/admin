import { useState } from 'react';
import { useParams, useNavigate, Link } from 'react-router-dom';
import { ArrowLeft, BookOpen, Users, Clock, DollarSign, Layers, PlayCircle, FileText, HelpCircle as QuizIcon, Plus, Trash2, Pencil, Archive, CheckCircle2 } from 'lucide-react';
import { useMockStore } from '@/hooks/useMockStore';
import { mockStore } from '@/mock-data/store';
import { Card } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { PageHeader } from '@/components/ui/PageHeader';
import { EmptyState } from '@/components/ui/State';
import { Modal, Input, Textarea, Select, Button } from '@/components/ui';
import { ConfirmDialog } from '@/components/ui/ConfirmDialog';
import { formatCurrency, formatDate, generateId } from '@/utils';
import type { Course, CourseStatus, Module, Lesson } from '@/types';

type Tab = 'overview' | 'modules' | 'enrolments' | 'live-classes';

export function CourseDetailPage() {
  const { id } = useParams<{ id: string }>();
  const store = useMockStore();
  const navigate = useNavigate();
  const [tab, setTab] = useState<Tab>('overview');
  const [moduleOpen, setModuleOpen] = useState(false);
  const [lessonOpen, setLessonOpen] = useState<string | null>(null);
  const [editOpen, setEditOpen] = useState(false);
  const [confirmArchive, setConfirmArchive] = useState(false);
  const [moduleForm, setModuleForm] = useState({ title: '', description: '' });
  const [lessonForm, setLessonForm] = useState({ title: '', durationMinutes: '30', type: 'video' as Lesson['type'] });

  const courseFound = store.courses.find((c) => c.id === id);
  if (!courseFound) return <EmptyState title="Course not found" action={<Link to="/courses" className="btn-primary">Back to Courses</Link>} />;
  const course: Course = courseFound;

  const instructor = store.instructors.find((i) => i.id === course.instructorId);
  const enrolledStudents = store.students.filter((s) => course.enrolledStudentIds.includes(s.id));
  const liveClasses = store.liveClasses.filter((l) => l.courseId === course.id);

  function changeStatus(status: CourseStatus) {
    mockStore.updateCourse(course.id, { status, publishedAt: status === 'published' ? new Date().toISOString() : course.publishedAt });
    mockStore.addActivity({ id: generateId('act'), adminName: 'Dr. Priya Sharma', action: `${status === 'published' ? 'Published' : status === 'archived' ? 'Archived' : 'Set to draft'} course`, target: course.title, timestamp: new Date().toISOString() });
  }

  function addModule() {
    if (!moduleForm.title.trim()) return;
    const module: Module = { id: generateId('mod'), title: moduleForm.title.trim(), description: moduleForm.description.trim(), lessons: [], order: course.modules.length + 1 };
    mockStore.updateCourse(course.id, { modules: [...course.modules, module] });
    setModuleOpen(false);
    setModuleForm({ title: '', description: '' });
  }

  function addLesson(moduleId: string) {
    const mod = course.modules.find((m) => m.id === moduleId);
    if (!mod || !lessonForm.title.trim()) return;
    const lesson: Lesson = { id: generateId('les'), title: lessonForm.title.trim(), durationMinutes: parseInt(lessonForm.durationMinutes) || 0, type: lessonForm.type, order: mod.lessons.length + 1 };
    const updatedModules = course.modules.map((m) => m.id === moduleId ? { ...m, lessons: [...m.lessons, lesson] } : m);
    mockStore.updateCourse(course.id, { modules: updatedModules });
    setLessonOpen(null);
    setLessonForm({ title: '', durationMinutes: '30', type: 'video' });
  }

  function deleteModule(moduleId: string) {
    mockStore.updateCourse(course.id, { modules: course.modules.filter((m) => m.id !== moduleId) });
  }

  const tabs: { key: Tab; label: string }[] = [
    { key: 'overview', label: 'Overview' },
    { key: 'modules', label: `Modules (${course.modules.length})` },
    { key: 'enrolments', label: `Enrolments (${enrolledStudents.length})` },
    { key: 'live-classes', label: `Live Classes (${liveClasses.length})` },
  ];

  const lessonIcons = { video: PlayCircle, reading: FileText, quiz: QuizIcon, assignment: FileText };

  return (
    <div>
      <PageHeader
        title={course.title}
        subtitle={course.category}
        breadcrumbs={[{ label: 'Dashboard', to: '/dashboard' }, { label: 'Courses', to: '/courses' }, { label: course.title.slice(0, 20) + (course.title.length > 20 ? '...' : '') }]}
        actions={
          <>
            <Link to="/courses" className="btn-secondary"><ArrowLeft size={16} /> Back</Link>
            <button className="btn-secondary" onClick={() => setEditOpen(true)}><Pencil size={16} /> Edit</button>
            {course.status === 'published' ? (
              <button className="btn-secondary" onClick={() => setConfirmArchive(true)}><Archive size={16} /> Archive</button>
            ) : (
              <button className="btn-primary" onClick={() => changeStatus('published')}><CheckCircle2 size={16} /> Publish</button>
            )}
          </>
        }
      />

      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 mb-4">
        <Card className="p-3"><div className="flex items-center gap-2"><Clock size={18} className="text-navy-400" /><div><p className="text-xs text-navy-500">Duration</p><p className="text-sm font-semibold text-navy-900">{course.durationWeeks} weeks</p></div></div></Card>
        <Card className="p-3"><div className="flex items-center gap-2"><DollarSign size={18} className="text-teal-500" /><div><p className="text-xs text-navy-500">Fee</p><p className="text-sm font-semibold text-navy-900">{formatCurrency(course.fee)}</p></div></div></Card>
        <Card className="p-3"><div className="flex items-center gap-2"><Users size={18} className="text-indigo-500" /><div><p className="text-xs text-navy-500">Enrolled</p><p className="text-sm font-semibold text-navy-900">{course.enrolledStudentIds.length}</p></div></div></Card>
        <Card className="p-3"><div className="flex items-center gap-2"><BookOpen size={18} className="text-cyan-500" /><div><p className="text-xs text-navy-500">Format</p><p className="text-sm font-semibold text-navy-900 capitalize">{course.format}</p></div></div></Card>
      </div>

      <div className="flex gap-1 mb-4 overflow-x-auto pb-1">
        {tabs.map((t) => (
          <button key={t.key} onClick={() => setTab(t.key)}
            className={`rounded-lg px-4 py-2 text-sm font-medium whitespace-nowrap transition-colors ${tab === t.key ? 'bg-navy-800 text-white' : 'text-navy-600 hover:bg-navy-100'}`}>
            {t.label}
          </button>
        ))}
      </div>

      {tab === 'overview' && (
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <Card title="Description" className="md:col-span-2 p-5">
            <p className="text-sm text-navy-700">{course.description}</p>
            <div className="mt-4">
              <p className="text-sm font-semibold text-navy-900 mb-2">Learning Objectives</p>
              {course.learningObjectives.length > 0 ? <ul className="text-sm text-navy-600 list-disc pl-4 space-y-1">{course.learningObjectives.map((o, i) => <li key={i}>{o}</li>)}</ul> : <p className="text-sm text-navy-400">No objectives defined</p>}
            </div>
            <div className="mt-4">
              <p className="text-sm font-semibold text-navy-900 mb-2">Prerequisites</p>
              {course.prerequisites.length > 0 ? <ul className="text-sm text-navy-600 list-disc pl-4 space-y-1">{course.prerequisites.map((p, i) => <li key={i}>{p}</li>)}</ul> : <p className="text-sm text-navy-400">None</p>}
            </div>
          </Card>
          <Card title="Course Info" className="p-5">
            <dl className="space-y-3 text-sm">
              <div><dt className="text-navy-500">Instructor</dt><dd className="font-medium text-navy-900">{instructor?.fullName ?? 'Unassigned'}</dd></div>
              <div><dt className="text-navy-500">Status</dt><dd><Badge variant={course.status === 'published' ? 'success' : course.status === 'archived' ? 'neutral' : 'warning'} dot>{course.status}</Badge></dd></div>
              <div><dt className="text-navy-500">Published</dt><dd className="font-medium text-navy-900">{course.publishedAt ? formatDate(course.publishedAt) : '—'}</dd></div>
              <div><dt className="text-navy-500">Created</dt><dd className="font-medium text-navy-900">{formatDate(course.createdAt)}</dd></div>
              <div><dt className="text-navy-500">Modules</dt><dd className="font-medium text-navy-900">{course.modules.length}</dd></div>
            </dl>
          </Card>
        </div>
      )}

      {tab === 'modules' && (
        <Card title="Course Modules" action={<button className="btn-primary text-xs px-3 py-2" onClick={() => setModuleOpen(true)}><Plus size={14} /> Add Module</button>}>
          {course.modules.length === 0 ? <EmptyState icon={<Layers size={24} />} title="No modules yet" description="Add modules to structure your course content." action={<button className="btn-primary" onClick={() => setModuleOpen(true)}><Plus size={16} /> Add Module</button>} /> : (
            <div className="divide-y divide-navy-50">
              {course.modules.map((m) => (
                <div key={m.id} className="px-5 py-4">
                  <div className="flex items-center justify-between">
                    <div><p className="text-sm font-semibold text-navy-900">{m.order}. {m.title}</p>{m.description && <p className="text-xs text-navy-500 mt-0.5">{m.description}</p>}</div>
                    <div className="flex items-center gap-1">
                      <button className="btn-ghost text-xs" onClick={() => setLessonOpen(m.id)}><Plus size={14} /> Lesson</button>
                      <button className="rounded-lg p-1.5 text-red-400 hover:bg-red-50" onClick={() => deleteModule(m.id)}><Trash2 size={14} /></button>
                    </div>
                  </div>
                  {m.lessons.length > 0 && (
                    <div className="mt-2 space-y-1.5">
                      {m.lessons.map((l) => {
                        const Icon = lessonIcons[l.type];
                        return (
                          <div key={l.id} className="flex items-center gap-2 rounded-lg bg-navy-50/60 px-3 py-2">
                            <Icon size={16} className="text-navy-400" />
                            <span className="text-sm text-navy-700 flex-1">{l.title}</span>
                            <span className="text-xs text-navy-400 capitalize">{l.type}</span>
                            {l.durationMinutes > 0 && <span className="text-xs text-navy-400">{l.durationMinutes}m</span>}
                          </div>
                        );
                      })}
                    </div>
                  )}
                </div>
              ))}
            </div>
          )}
        </Card>
      )}

      {tab === 'enrolments' && (
        <Card title={`Enrolled Students (${enrolledStudents.length})`}>
          {enrolledStudents.length === 0 ? <EmptyState title="No students enrolled" /> : (
            <div className="divide-y divide-navy-50">
              {enrolledStudents.map((s) => (
                <div key={s.id} className="flex items-center gap-3 px-5 py-3 hover:bg-navy-50/40 cursor-pointer" onClick={() => navigate(`/students/${s.id}`)}>
                  <div className="flex h-8 w-8 items-center justify-center rounded-full bg-navy-100 text-xs font-semibold text-navy-700">{s.fullName.split(' ').map((n) => n[0]).join('')}</div>
                  <div className="min-w-0 flex-1"><p className="text-sm font-medium text-navy-900 truncate">{s.fullName}</p><p className="text-xs text-navy-500">{s.studentId}</p></div>
                  <Badge variant={s.accountStatus === 'active' ? 'success' : 'neutral'} dot>{s.accountStatus}</Badge>
                </div>
              ))}
            </div>
          )}
        </Card>
      )}

      {tab === 'live-classes' && (
        <Card title={`Live Classes (${liveClasses.length})`}>
          {liveClasses.length === 0 ? <EmptyState title="No live classes scheduled" /> : (
            <div className="divide-y divide-navy-50">
              {liveClasses.map((l) => (
                <div key={l.id} className="flex items-center gap-3 px-5 py-3">
                  <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-indigo-100 text-indigo-600"><PlayCircle size={18} /></div>
                  <div className="min-w-0 flex-1"><p className="text-sm font-medium text-navy-900">{l.title}</p><p className="text-xs text-navy-500">{l.instructorName} · {formatDate(l.scheduledAt)}</p></div>
                  <Badge variant={l.status === 'upcoming' ? 'info' : l.status === 'completed' ? 'neutral' : 'danger'}>{l.status}</Badge>
                </div>
              ))}
            </div>
          )}
        </Card>
      )}

      <Modal open={moduleOpen} onClose={() => setModuleOpen(false)} title="Add Module"
        footer={<><button className="btn-secondary" onClick={() => setModuleOpen(false)}>Cancel</button><button className="btn-primary" onClick={addModule}>Add</button></>}>
        <div className="space-y-4">
          <Input label="Module Title *" value={moduleForm.title} onChange={(e) => setModuleForm({ ...moduleForm, title: e.target.value })} />
          <Textarea label="Description" value={moduleForm.description} onChange={(e) => setModuleForm({ ...moduleForm, description: e.target.value })} rows={2} />
        </div>
      </Modal>

      <Modal open={!!lessonOpen} onClose={() => setLessonOpen(null)} title="Add Lesson"
        footer={<><button className="btn-secondary" onClick={() => setLessonOpen(null)}>Cancel</button><button className="btn-primary" onClick={() => lessonOpen && addLesson(lessonOpen)}>Add</button></>}>
        <div className="space-y-4">
          <Input label="Lesson Title *" value={lessonForm.title} onChange={(e) => setLessonForm({ ...lessonForm, title: e.target.value })} />
          <div className="grid grid-cols-2 gap-4">
            <Select label="Type" value={lessonForm.type} onChange={(e) => setLessonForm({ ...lessonForm, type: e.target.value as Lesson['type'] })}
              options={[{ value: 'video', label: 'Video' }, { value: 'reading', label: 'Reading' }, { value: 'quiz', label: 'Quiz' }, { value: 'assignment', label: 'Assignment' }]} />
            <Input label="Duration (min)" type="number" value={lessonForm.durationMinutes} onChange={(e) => setLessonForm({ ...lessonForm, durationMinutes: e.target.value })} />
          </div>
        </div>
      </Modal>

      <Modal open={editOpen} onClose={() => setEditOpen(false)} title="Edit Course" size="lg"
        footer={<><button className="btn-secondary" onClick={() => setEditOpen(false)}>Cancel</button><Button onClick={() => setEditOpen(false)}>Save</Button></>}>
        <EditCourseForm course={course} />
      </Modal>

      <ConfirmDialog open={confirmArchive} onClose={() => setConfirmArchive(false)} onConfirm={() => { changeStatus('archived'); }} title="Archive Course" message={`Archive "${course.title}"? It will no longer be visible to students.`} confirmLabel="Archive" />
    </div>
  );
}

function EditCourseForm({ course }: { course: Course }) {
  const store = useMockStore();
  const [title, setTitle] = useState(course.title);
  const [description, setDescription] = useState(course.description);
  const [category, setCategory] = useState(course.category);
  const [instructorId, setInstructorId] = useState(course.instructorId ?? '');
  const [fee, setFee] = useState(String(course.fee));
  const [durationWeeks, setDurationWeeks] = useState(String(course.durationWeeks));

  function save() {
    mockStore.updateCourse(course.id, { title, description, category, instructorId: instructorId || undefined, fee: parseInt(fee) || 0, durationWeeks: parseInt(durationWeeks) || 1 });
  }

  return (
    <div className="space-y-4">
      <Input label="Title" value={title} onChange={(e) => setTitle(e.target.value)} />
      <Textarea label="Description" value={description} onChange={(e) => setDescription(e.target.value)} rows={3} />
      <div className="grid grid-cols-2 gap-4">
        <Select label="Category" value={category} onChange={(e) => setCategory(e.target.value)} options={store.courseCategories.map((c) => ({ value: c.name, label: c.name }))} />
        <Select label="Instructor" value={instructorId} onChange={(e) => setInstructorId(e.target.value)} placeholder="Unassigned" options={store.instructors.map((i) => ({ value: i.id, label: i.fullName }))} />
        <Input label="Fee" type="number" value={fee} onChange={(e) => setFee(e.target.value)} />
        <Input label="Duration (weeks)" type="number" value={durationWeeks} onChange={(e) => setDurationWeeks(e.target.value)} />
      </div>
      <button className="btn-primary w-full" onClick={save}>Save Changes</button>
    </div>
  );
}
