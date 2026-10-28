import { useState, useMemo } from 'react';
import { ClipboardCheck, Plus, Award, Calendar, Users, Download, FileText } from 'lucide-react';
import { useMockStore } from '@/hooks/useMockStore';
import { mockStore } from '@/mock-data/store';
import { Card } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { StatCard } from '@/components/ui/Card';
import { PageHeader } from '@/components/ui/PageHeader';
import { SearchBar } from '@/components/ui/SearchBar';
import { Select } from '@/components/ui/FormField';
import { EmptyState } from '@/components/ui/State';
import { Modal, Input, Textarea, Select as FormSelect } from '@/components/ui';
import { Pagination } from '@/components/ui/Pagination';
import { DataTable } from '@/components/tables/DataTable';
import { formatDate, paginate, generateId, downloadCSV } from '@/utils';
import type { Assessment, AssessmentStatus, AssessmentType } from '@/types';

const PER_PAGE = 8;
const statusVariant: Record<AssessmentStatus, 'warning' | 'info' | 'success' | 'neutral'> = {
  draft: 'warning', scheduled: 'info', active: 'success', completed: 'neutral',
};

export function AssessmentListPage() {
  const store = useMockStore();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [tab, setTab] = useState<'assessments' | 'categories' | 'results' | 'questions'>('assessments');
  const [page, setPage] = useState(1);
  const [addOpen, setAddOpen] = useState(false);
  const [form, setForm] = useState({ title: '', description: '', categoryId: '', type: 'mcq' as AssessmentType, totalMarks: '20', passingMarks: '12', durationMinutes: '30' });

  const filtered = useMemo(() => store.assessments.filter((a) => {
    const q = search.toLowerCase();
    const matchesSearch = !q || a.title.toLowerCase().includes(q) || a.description.toLowerCase().includes(q);
    const matchesStatus = !statusFilter || a.status === statusFilter;
    return matchesSearch && matchesStatus;
  }), [store.assessments, search, statusFilter]);

  const { data, total, totalPages, currentPage } = paginate(filtered, page, PER_PAGE);

  function addAssessment() {
    if (!form.title.trim()) return;
    const assessment: Assessment = {
      id: generateId('asm'), title: form.title.trim(), description: form.description.trim(),
      categoryId: form.categoryId || 'acat-1', type: form.type, totalMarks: parseInt(form.totalMarks) || 20,
      passingMarks: parseInt(form.passingMarks) || 12, durationMinutes: parseInt(form.durationMinutes) || 30,
      status: 'draft', questionIds: [], assignedStudentIds: [], assignedCourseIds: [], createdBy: 'Dr. Priya Sharma',
      createdAt: new Date().toISOString(),
    };
    mockStore.addAssessment(assessment);
    setAddOpen(false);
    setForm({ title: '', description: '', categoryId: '', type: 'mcq', totalMarks: '20', passingMarks: '12', durationMinutes: '30' });
  }

  function exportResults() {
    downloadCSV('iiecm-assessment-results.csv', store.assessmentResults.map((r) => ({ Assessment: r.assessmentTitle, Student: r.studentName, Score: r.score, Total: r.totalMarks, Percentage: r.percentage, Passed: r.passed ? 'Yes' : 'No', Date: formatDate(r.completedAt) })));
  }

  return (
    <div>
      <PageHeader
        title="Assessments"
        subtitle="Manage assessments, question banks, and results"
        breadcrumbs={[{ label: 'Dashboard', to: '/dashboard' }, { label: 'Assessments' }]}
        actions={tab === 'results' ? <button className="btn-secondary" onClick={exportResults}><Download size={16} /> Export Results</button> : <button className="btn-primary" onClick={() => setAddOpen(true)}><Plus size={16} /> Create Assessment</button>}
      />

      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3 mb-5">
        <StatCard label="Assessments" value={store.assessments.length} icon={<ClipboardCheck size={20} />} accent="navy" />
        <StatCard label="Categories" value={store.assessmentCategories.length} icon={<FileText size={20} />} accent="teal" />
        <StatCard label="Questions" value={store.questions.length} icon={<Award size={20} />} accent="indigo" />
        <StatCard label="Results" value={store.assessmentResults.length} icon={<Users size={20} />} accent="cyan" />
      </div>

      <div className="flex gap-1 mb-4 overflow-x-auto pb-1">
        {(['assessments', 'categories', 'results', 'questions'] as const).map((t) => (
          <button key={t} onClick={() => setTab(t)} className={`rounded-lg px-4 py-2 text-sm font-medium whitespace-nowrap capitalize transition-colors ${tab === t ? 'bg-navy-800 text-white' : 'text-navy-600 hover:bg-navy-100'}`}>{t}</button>
        ))}
      </div>

      {tab === 'assessments' && (
        <>
          <Card className="p-4 mb-4">
            <div className="flex flex-col sm:flex-row gap-3">
              <SearchBar value={search} onChange={(v) => { setSearch(v); setPage(1); }} placeholder="Search assessments..." className="flex-1" />
              <Select value={statusFilter} onChange={(e) => { setStatusFilter(e.target.value); setPage(1); }} placeholder="All Statuses"
                options={[{ value: 'draft', label: 'Draft' }, { value: 'scheduled', label: 'Scheduled' }, { value: 'active', label: 'Active' }, { value: 'completed', label: 'Completed' }]} className="w-auto min-w-32" />
            </div>
          </Card>
          <Card>
            {filtered.length === 0 ? <EmptyState icon={<ClipboardCheck size={26} />} title="No assessments found" /> : (
              <>
                <DataTable data={data} rowKey={(a) => a.id} columns={[
                  { key: 'title', header: 'Assessment', render: (a) => { const cat = store.assessmentCategories.find((c) => c.id === a.categoryId); return <div><p className="text-sm font-medium text-navy-900">{a.title}</p><p className="text-xs text-navy-500">{cat?.name}</p></div>; } },
                  { key: 'type', header: 'Type', hideOnMobile: true, render: (a) => <span className="capitalize text-navy-600">{a.type}</span> },
                  { key: 'totalMarks', header: 'Marks', hideOnMobile: true, render: (a) => <span className="text-navy-700">{a.totalMarks}</span> },
                  { key: 'assignedStudentIds', header: 'Assigned', render: (a) => <span className="text-navy-700">{a.assignedStudentIds.length}</span> },
                  { key: 'status', header: 'Status', render: (a) => <Badge variant={statusVariant[a.status]} dot>{a.status}</Badge> },
                  { key: 'scheduledAt', header: 'Scheduled', hideOnMobile: true, render: (a) => a.scheduledAt ? <span className="text-xs text-navy-500">{formatDate(a.scheduledAt)}</span> : <span className="text-xs text-navy-400">—</span> },
                ]} />
                <Pagination currentPage={currentPage} totalPages={totalPages} onPageChange={setPage} total={total} perPage={PER_PAGE} />
              </>
            )}
          </Card>
        </>
      )}

      {tab === 'categories' && (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {store.assessmentCategories.map((cat) => (
            <Card key={cat.id} className="p-5">
              <div className="flex items-start justify-between">
                <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-indigo-100 text-indigo-600"><FileText size={20} /></div>
                <Badge variant="info">{cat.questionCount} questions</Badge>
              </div>
              <h3 className="text-sm font-semibold text-navy-900 mt-3">{cat.name}</h3>
              <p className="text-xs text-navy-500 mt-1">{cat.description}</p>
            </Card>
          ))}
        </div>
      )}

      {tab === 'results' && (
        <Card>
          {store.assessmentResults.length === 0 ? <EmptyState title="No results recorded" /> : (
            <DataTable data={store.assessmentResults} rowKey={(r) => r.id} columns={[
              { key: 'studentName', header: 'Student', render: (r) => <span className="text-sm font-medium text-navy-900">{r.studentName}</span> },
              { key: 'assessmentTitle', header: 'Assessment', hideOnMobile: true },
              { key: 'score', header: 'Score', render: (r) => <span className="text-navy-700">{r.score}/{r.totalMarks}</span> },
              { key: 'percentage', header: '%', render: (r) => <span className={`font-medium ${r.percentage >= 60 ? 'text-teal-600' : 'text-red-500'}`}>{r.percentage}%</span> },
              { key: 'passed', header: 'Result', render: (r) => <Badge variant={r.passed ? 'success' : 'danger'} dot>{r.passed ? 'Passed' : 'Failed'}</Badge> },
              { key: 'completedAt', header: 'Date', hideOnMobile: true, render: (r) => <span className="text-xs text-navy-500">{formatDate(r.completedAt)}</span> },
            ]} />
          )}
        </Card>
      )}

      {tab === 'questions' && (
        <Card>
          {store.questions.length === 0 ? <EmptyState title="No questions in bank" /> : (
            <div className="divide-y divide-navy-50">
              {store.questions.map((q) => (
                <div key={q.id} className="px-5 py-4">
                  <div className="flex items-start justify-between gap-3">
                    <div className="min-w-0 flex-1">
                      <p className="text-sm font-medium text-navy-900">{q.questionText}</p>
                      <div className="mt-2 space-y-1">
                        {q.options.map((o) => (
                          <div key={o.id} className={`text-xs flex items-center gap-1.5 ${o.isCorrect ? 'text-teal-700 font-medium' : 'text-navy-500'}`}>
                            <span className={`h-3 w-3 rounded-full ${o.isCorrect ? 'bg-teal-500' : 'bg-navy-200'}`} />{o.text}
                          </div>
                        ))}
                      </div>
                    </div>
                    <Badge variant="neutral">{q.marks} marks</Badge>
                  </div>
                </div>
              ))}
            </div>
          )}
        </Card>
      )}

      <Modal open={addOpen} onClose={() => setAddOpen(false)} title="Create Assessment"
        footer={<><button className="btn-secondary" onClick={() => setAddOpen(false)}>Cancel</button><button className="btn-primary" onClick={addAssessment}>Create</button></>}>
        <div className="space-y-4">
          <Input label="Title *" value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} />
          <Textarea label="Description" value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} rows={2} />
          <div className="grid grid-cols-2 gap-4">
            <FormSelect label="Category" value={form.categoryId} onChange={(e) => setForm({ ...form, categoryId: e.target.value })}
              options={store.assessmentCategories.map((c) => ({ value: c.id, label: c.name }))} />
            <FormSelect label="Type" value={form.type} onChange={(e) => setForm({ ...form, type: e.target.value as AssessmentType })}
              options={[{ value: 'mcq', label: 'MCQ' }, { value: 'assignment', label: 'Assignment' }, { value: 'project', label: 'Project' }, { value: 'quiz', label: 'Quiz' }]} />
            <Input label="Total Marks" type="number" value={form.totalMarks} onChange={(e) => setForm({ ...form, totalMarks: e.target.value })} />
            <Input label="Passing Marks" type="number" value={form.passingMarks} onChange={(e) => setForm({ ...form, passingMarks: e.target.value })} />
            <Input label="Duration (min)" type="number" value={form.durationMinutes} onChange={(e) => setForm({ ...form, durationMinutes: e.target.value })} />
          </div>
        </div>
      </Modal>
    </div>
  );
}
