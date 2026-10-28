import { useState, useMemo } from 'react';
import { FolderOpen, Plus, Download, FileText, Video, Link as LinkIcon, Trash2 } from 'lucide-react';
import { useMockStore } from '@/hooks/useMockStore';
import { mockStore } from '@/mock-data/store';
import { Card } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { PageHeader } from '@/components/ui/PageHeader';
import { SearchBar, FilterBar } from '@/components/ui/SearchBar';
import { Select } from '@/components/ui/FormField';
import { EmptyState } from '@/components/ui/State';
import { Modal, Input, Textarea, Select as FormSelect } from '@/components/ui';
import { ConfirmDialog } from '@/components/ui/ConfirmDialog';
import { Pagination } from '@/components/ui/Pagination';
import { formatDate, paginate, generateId, downloadCSV } from '@/utils';
import type { Resource, ResourceType, ResourceCategory, ResourceVisibility } from '@/types';

const PER_PAGE = 9;
const typeIcons: Record<ResourceType, typeof FileText> = { pdf: FileText, document: FileText, video: Video, link: LinkIcon, image: FileText };
const categoryLabels: Record<ResourceCategory, string> = {
  study_material: 'Study Material', career: 'Career', exam_prep: 'Exam Prep', course: 'Course', government_exam: 'Government Exam',
};

export function ResourceListPage() {
  const store = useMockStore();
  const [search, setSearch] = useState('');
  const [categoryFilter, setCategoryFilter] = useState('');
  const [page, setPage] = useState(1);
  const [addOpen, setAddOpen] = useState(false);
  const [deleteTarget, setDeleteTarget] = useState<Resource | null>(null);
  const [form, setForm] = useState({ title: '', description: '', type: 'pdf' as ResourceType, category: 'study_material' as ResourceCategory, visibility: 'enrolled' as ResourceVisibility, fileSize: '' });

  const filtered = useMemo(() => store.resources.filter((r) => {
    const q = search.toLowerCase();
    const matchesSearch = !q || r.title.toLowerCase().includes(q) || r.description.toLowerCase().includes(q);
    const matchesCategory = !categoryFilter || r.category === categoryFilter;
    return matchesSearch && matchesCategory;
  }), [store.resources, search, categoryFilter]);

  const { data, total, totalPages, currentPage } = paginate(filtered, page, PER_PAGE);

  function addResource() {
    if (!form.title.trim()) return;
    const resource: Resource = {
      id: generateId('res'), title: form.title.trim(), description: form.description.trim(),
      type: form.type, category: form.category, fileSize: form.fileSize || undefined, visibility: form.visibility,
      uploadedBy: 'Dr. Priya Sharma', createdAt: new Date().toISOString(), downloadCount: 0,
    };
    mockStore.addResource(resource);
    setAddOpen(false);
    setForm({ title: '', description: '', type: 'pdf', category: 'study_material', visibility: 'enrolled', fileSize: '' });
  }

  function exportCSV() {
    downloadCSV('iiecm-resources.csv', filtered.map((r) => ({ Title: r.title, Type: r.type, Category: categoryLabels[r.category], Visibility: r.visibility, Downloads: r.downloadCount, Date: formatDate(r.createdAt) })));
  }

  return (
    <div>
      <PageHeader
        title="Resources"
        subtitle={`${store.resources.length} resources`}
        breadcrumbs={[{ label: 'Dashboard', to: '/dashboard' }, { label: 'Resources' }]}
        actions={<><button className="btn-secondary" onClick={exportCSV}><Download size={16} /> Export</button><button className="btn-primary" onClick={() => setAddOpen(true)}><Plus size={16} /> Add Resource</button></>}
      />

      <Card className="p-4 mb-4">
        <div className="flex flex-col sm:flex-row gap-3">
          <SearchBar value={search} onChange={(v) => { setSearch(v); setPage(1); }} placeholder="Search resources..." className="flex-1" />
          <FilterBar>
            <Select value={categoryFilter} onChange={(e) => { setCategoryFilter(e.target.value); setPage(1); }} placeholder="All Categories"
              options={Object.entries(categoryLabels).map(([value, label]) => ({ value, label }))} className="w-auto min-w-40" />
          </FilterBar>
        </div>
      </Card>

      {filtered.length === 0 ? (
        <Card><EmptyState icon={<FolderOpen size={26} />} title="No resources found" action={<button className="btn-primary" onClick={() => setAddOpen(true)}><Plus size={16} /> Add Resource</button>} /></Card>
      ) : (
        <>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
            {data.map((r) => {
              const Icon = typeIcons[r.type];
              return (
                <Card key={r.id} className="p-5 card-hover">
                  <div className="flex items-start justify-between">
                    <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-navy-100 text-navy-600"><Icon size={20} /></div>
                    <button className="rounded-lg p-1.5 text-red-400 hover:bg-red-50" onClick={() => setDeleteTarget(r)}><Trash2 size={14} /></button>
                  </div>
                  <h3 className="text-sm font-semibold text-navy-900 mt-3 line-clamp-1">{r.title}</h3>
                  <p className="text-xs text-navy-500 mt-1 line-clamp-2">{r.description}</p>
                  <div className="mt-3 flex items-center justify-between">
                    <Badge variant="info">{categoryLabels[r.category]}</Badge>
                    <span className="text-xs text-navy-400">{r.downloadCount} downloads</span>
                  </div>
                  <div className="mt-3 flex items-center justify-between text-xs text-navy-400">
                    <Badge variant={r.visibility === 'public' ? 'success' : r.visibility === 'enrolled' ? 'warning' : 'neutral'}>{r.visibility}</Badge>
                    {r.fileSize && <span>{r.fileSize}</span>}
                  </div>
                </Card>
              );
            })}
          </div>
          <Card className="mt-4"><Pagination currentPage={currentPage} totalPages={totalPages} onPageChange={setPage} total={total} perPage={PER_PAGE} /></Card>
        </>
      )}

      <Modal open={addOpen} onClose={() => setAddOpen(false)} title="Add Resource"
        footer={<><button className="btn-secondary" onClick={() => setAddOpen(false)}>Cancel</button><button className="btn-primary" onClick={addResource}>Add</button></>}>
        <div className="space-y-4">
          <Input label="Title *" value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} />
          <Textarea label="Description" value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} rows={2} />
          <div className="grid grid-cols-2 gap-4">
            <FormSelect label="Type" value={form.type} onChange={(e) => setForm({ ...form, type: e.target.value as ResourceType })}
              options={[{ value: 'pdf', label: 'PDF' }, { value: 'document', label: 'Document' }, { value: 'video', label: 'Video' }, { value: 'link', label: 'Link' }]} />
            <FormSelect label="Category" value={form.category} onChange={(e) => setForm({ ...form, category: e.target.value as ResourceCategory })}
              options={Object.entries(categoryLabels).map(([value, label]) => ({ value, label }))} />
            <FormSelect label="Visibility" value={form.visibility} onChange={(e) => setForm({ ...form, visibility: e.target.value as ResourceVisibility })}
              options={[{ value: 'public', label: 'Public' }, { value: 'enrolled', label: 'Enrolled Only' }, { value: 'private', label: 'Private' }]} />
            <Input label="File Size" value={form.fileSize} onChange={(e) => setForm({ ...form, fileSize: e.target.value })} placeholder="e.g. 2.5 MB" />
          </div>
        </div>
      </Modal>

      <ConfirmDialog open={!!deleteTarget} onClose={() => setDeleteTarget(null)} onConfirm={() => { if (deleteTarget) mockStore.deleteResource(deleteTarget.id); }} title="Delete Resource" message={`Delete "${deleteTarget?.title}"? This cannot be undone.`} confirmLabel="Delete" />
    </div>
  );
}
