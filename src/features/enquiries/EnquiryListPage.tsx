import { useState, useMemo } from 'react';
import { useNavigate } from 'react-router-dom';
import { MessageSquare, Plus, Phone, Mail, ArrowRight, Calendar, User } from 'lucide-react';
import { useMockStore } from '@/hooks/useMockStore';
import { mockStore } from '@/mock-data/store';
import { Card } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { StatCard } from '@/components/ui/Card';
import { PageHeader } from '@/components/ui/PageHeader';
import { SearchBar, FilterBar } from '@/components/ui/SearchBar';
import { Select, Textarea, Input } from '@/components/ui/FormField';
import { EmptyState } from '@/components/ui/State';
import { Modal } from '@/components/ui';
import { ConfirmDialog } from '@/components/ui/ConfirmDialog';
import { Pagination } from '@/components/ui/Pagination';
import { DataTable } from '@/components/tables/DataTable';
import { formatDate, paginate, generateId, generateEnquiryId, downloadCSV } from '@/utils';
import type { Enquiry, EnquiryStatus, EnquirySource, LearningMode, FollowUpEntry } from '@/types';
import { Download } from 'lucide-react';

const PER_PAGE = 8;

const statusVariant: Record<EnquiryStatus, 'info' | 'warning' | 'accent' | 'success' | 'neutral'> = {
  new: 'info', contacted: 'warning', follow_up: 'accent', converted: 'success', closed: 'neutral',
};

export function EnquiryListPage() {
  const store = useMockStore();
  const navigate = useNavigate();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [page, setPage] = useState(1);
  const [selected, setSelected] = useState<Enquiry | null>(null);
  const [addFollowUp, setAddFollowUp] = useState<Enquiry | null>(null);
  const [confirmConvert, setConfirmConvert] = useState<Enquiry | null>(null);
  const [followUpNote, setFollowUpNote] = useState('');
  const [followUpOutcome, setFollowUpOutcome] = useState<FollowUpEntry['outcome']>('interested');
  const [newEnquiryOpen, setNewEnquiryOpen] = useState(false);
  const [enqForm, setEnqForm] = useState({ studentName: '', email: '', phone: '', preferredService: '', source: 'website' as EnquirySource, preferredMode: 'online' as LearningMode, notes: '' });

  const filtered = useMemo(() => store.enquiries.filter((e) => {
    const q = search.toLowerCase();
    const matchesSearch = !q || e.studentName.toLowerCase().includes(q) || e.email.toLowerCase().includes(q) || e.enquiryId.toLowerCase().includes(q);
    const matchesStatus = !statusFilter || e.status === statusFilter;
    return matchesSearch && matchesStatus;
  }), [store.enquiries, search, statusFilter]);

  const { data, total, totalPages, currentPage } = paginate(filtered, page, PER_PAGE);

  const newCount = store.enquiries.filter((e) => e.status === 'new').length;
  const convertedCount = store.enquiries.filter((e) => e.status === 'converted').length;
  const followUpCount = store.enquiries.filter((e) => e.status === 'follow_up').length;

  function addFollowUpEntry() {
    if (!addFollowUp || !followUpNote.trim()) return;
    const entry: FollowUpEntry = { id: generateId('fu'), date: new Date().toISOString(), note: followUpNote.trim(), by: 'Dr. Priya Sharma', outcome: followUpOutcome };
    const newStatus: EnquiryStatus = followUpOutcome === 'converted' ? 'converted' : followUpOutcome === 'not_interested' ? 'closed' : 'follow_up';
    mockStore.updateEnquiry(addFollowUp.id, { status: newStatus, followUpHistory: [...addFollowUp.followUpHistory, entry] });
    setAddFollowUp(null);
    setFollowUpNote('');
    setFollowUpOutcome('interested');
    setSelected({ ...addFollowUp, status: newStatus, followUpHistory: [...addFollowUp.followUpHistory, entry] });
  }

  function convertEnquiry(enquiry: Enquiry) {
    mockStore.updateEnquiry(enquiry.id, { status: 'converted' });
    const student = {
      id: generateId('stu'), studentId: `IIECM${new Date().getFullYear()}${Math.floor(10000 + Math.random() * 90000)}`,
      fullName: enquiry.studentName, email: enquiry.email, phone: enquiry.phone,
      educationLevel: enquiry.educationLevel, qualification: 'From enquiry',
      preferredCategory: enquiry.careerInterests[0] ?? 'General', assignedCourseIds: [], enrolledCourseIds: [],
      subscriptionPlan: 'free' as const, subscriptionStatus: 'pending' as const, accountStatus: 'active' as const,
      resumeUploaded: false, careerGuidanceStatus: 'not_started' as const, createdAt: new Date().toISOString(), country: 'India',
    };
    mockStore.addStudent(student);
    mockStore.addActivity({ id: generateId('act'), adminName: 'Dr. Priya Sharma', action: 'Converted enquiry to student', target: `${enquiry.enquiryId} — ${enquiry.studentName}`, timestamp: new Date().toISOString() });
    setConfirmConvert(null);
    setSelected(null);
    navigate(`/students/${student.id}`);
  }

  function createEnquiry() {
    if (!enqForm.studentName.trim() || !enqForm.email.trim()) return;
    const enquiry: Enquiry = {
      id: generateId('enq'), enquiryId: generateEnquiryId(), studentName: enqForm.studentName.trim(),
      email: enqForm.email.trim(), phone: enqForm.phone.trim(), educationLevel: 'Not specified',
      careerInterests: [], preferredService: enqForm.preferredService || 'Basic Plan',
      budgetMin: 0, budgetMax: 10000, preferredMode: enqForm.preferredMode, source: enqForm.source,
      assignedCounsellor: 'Dr. Priya Sharma', followUpDate: new Date(Date.now() + 7 * 86400000).toISOString().slice(0, 10),
      status: 'new', notes: enqForm.notes, followUpHistory: [], createdAt: new Date().toISOString(),
    };
    mockStore.addEnquiry(enquiry);
    setNewEnquiryOpen(false);
    setEnqForm({ studentName: '', email: '', phone: '', preferredService: '', source: 'website', preferredMode: 'online', notes: '' });
  }

  function exportCSV() {
    downloadCSV('iiecm-enquiries.csv', filtered.map((e) => ({ ID: e.enquiryId, Name: e.studentName, Email: e.email, Phone: e.phone, Status: e.status, Service: e.preferredService, Source: e.source, Date: formatDate(e.createdAt) })));
  }

  return (
    <div>
      <PageHeader
        title="Student Enquiries"
        subtitle={`${store.enquiries.length} enquiries`}
        breadcrumbs={[{ label: 'Dashboard', to: '/dashboard' }, { label: 'Enquiries' }]}
        actions={<><button className="btn-secondary" onClick={exportCSV}><Download size={16} /> Export</button><button className="btn-primary" onClick={() => setNewEnquiryOpen(true)}><Plus size={16} /> New Enquiry</button></>}
      />

      <div className="grid grid-cols-3 gap-3 mb-5">
        <StatCard label="New" value={newCount} icon={<MessageSquare size={20} />} accent="info" />
        <StatCard label="Follow-up" value={followUpCount} icon={<Calendar size={20} />} accent="amber" />
        <StatCard label="Converted" value={convertedCount} icon={<User size={20} />} accent="teal" />
      </div>

      <Card className="p-4 mb-4">
        <div className="flex flex-col sm:flex-row gap-3">
          <SearchBar value={search} onChange={(v) => { setSearch(v); setPage(1); }} placeholder="Search by name, email, or enquiry ID..." className="flex-1" />
          <FilterBar>
            <Select value={statusFilter} onChange={(e) => { setStatusFilter(e.target.value); setPage(1); }} placeholder="All Statuses"
              options={[{ value: 'new', label: 'New' }, { value: 'contacted', label: 'Contacted' }, { value: 'follow_up', label: 'Follow-up' }, { value: 'converted', label: 'Converted' }, { value: 'closed', label: 'Closed' }]} className="w-auto min-w-32" />
          </FilterBar>
        </div>
      </Card>

      <Card>
        {filtered.length === 0 ? (
          <EmptyState icon={<MessageSquare size={26} />} title="No enquiries found" />
        ) : (
          <>
            <DataTable
              data={data}
              rowKey={(e) => e.id}
              onRowClick={(e) => setSelected(e)}
              columns={[
                { key: 'studentName', header: 'Student', render: (e) => <div><p className="text-sm font-medium text-navy-900">{e.studentName}</p><p className="text-xs text-navy-500">{e.enquiryId}</p></div> },
                { key: 'preferredService', header: 'Service', hideOnMobile: true },
                { key: 'source', header: 'Source', hideOnMobile: true, render: (e) => <span className="capitalize text-navy-600">{e.source.replace('_', ' ')}</span> },
                { key: 'followUpDate', header: 'Follow-up', render: (e) => <span className="text-xs text-navy-500">{formatDate(e.followUpDate)}</span> },
                { key: 'status', header: 'Status', render: (e) => <Badge variant={statusVariant[e.status]} dot>{e.status.replace('_', ' ')}</Badge> },
              ]}
            />
            <Pagination currentPage={currentPage} totalPages={totalPages} onPageChange={setPage} total={total} perPage={PER_PAGE} />
          </>
        )}
      </Card>

      <Modal open={!!selected} onClose={() => setSelected(null)} title="Enquiry Details" size="lg"
        footer={selected && selected.status !== 'converted' && selected.status !== 'closed' ? (
          <>
            <button className="btn-secondary" onClick={() => setAddFollowUp(selected)}><Plus size={16} /> Add Follow-up</button>
            <button className="btn-primary" onClick={() => setConfirmConvert(selected)}><ArrowRight size={16} /> Convert to Student</button>
          </>
        ) : <button className="btn-secondary" onClick={() => setSelected(null)}>Close</button>}
      >
        {selected && (
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <div><h3 className="text-lg font-bold text-navy-900">{selected.studentName}</h3><p className="text-sm text-navy-500">{selected.enquiryId}</p></div>
              <Badge variant={statusVariant[selected.status]} dot size="md">{selected.status.replace('_', ' ')}</Badge>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <Field icon={<Mail size={14} />} label="Email" value={selected.email} />
              <Field icon={<Phone size={14} />} label="Phone" value={selected.phone} />
              <Field label="Service" value={selected.preferredService} />
              <Field label="Source" value={selected.source.replace('_', ' ')} />
              <Field label="Mode" value={selected.preferredMode} />
              <Field label="Budget" value={`₹${selected.budgetMin} - ₹${selected.budgetMax}`} />
              <Field label="Counsellor" value={selected.assignedCounsellor} />
              <Field label="Follow-up Date" value={formatDate(selected.followUpDate)} />
            </div>
            {selected.careerInterests.length > 0 && <div><p className="text-xs text-navy-500 uppercase mb-1">Career Interests</p><div className="flex flex-wrap gap-1.5">{selected.careerInterests.map((c, i) => <Badge key={i} variant="info">{c}</Badge>)}</div></div>}
            {selected.notes && <div className="rounded-lg bg-navy-50 p-3"><p className="text-xs text-navy-500 uppercase mb-1">Notes</p><p className="text-sm text-navy-700">{selected.notes}</p></div>}
            <div>
              <p className="text-sm font-semibold text-navy-900 mb-2">Follow-up History ({selected.followUpHistory.length})</p>
              {selected.followUpHistory.length === 0 ? <p className="text-sm text-navy-400">No follow-ups recorded</p> : (
                <div className="space-y-2">{selected.followUpHistory.map((f) => (
                  <div key={f.id} className="rounded-lg border border-navy-100 p-3">
                    <div className="flex justify-between"><span className="text-xs text-navy-500">{formatDate(f.date)}</span><Badge variant="neutral">{f.outcome.replace('_', ' ')}</Badge></div>
                    <p className="text-sm text-navy-700 mt-1">{f.note}</p>
                    <p className="text-xs text-navy-400 mt-1">— {f.by}</p>
                  </div>
                ))}</div>
              )}
            </div>
          </div>
        )}
      </Modal>

      <Modal open={!!addFollowUp} onClose={() => setAddFollowUp(null)} title="Add Follow-up"
        footer={<><button className="btn-secondary" onClick={() => setAddFollowUp(null)}>Cancel</button><button className="btn-primary" onClick={addFollowUpEntry}>Save Follow-up</button></>}>
        <div className="space-y-4">
          <Textarea label="Note *" value={followUpNote} onChange={(e) => setFollowUpNote(e.target.value)} rows={3} placeholder="What was discussed?" />
          <Select label="Outcome" value={followUpOutcome} onChange={(e) => setFollowUpOutcome(e.target.value as FollowUpEntry['outcome'])}
            options={[{ value: 'no_response', label: 'No Response' }, { value: 'interested', label: 'Interested' }, { value: 'not_interested', label: 'Not Interested' }, { value: 'callback_scheduled', label: 'Callback Scheduled' }, { value: 'converted', label: 'Converted' }]} />
        </div>
      </Modal>

      <ConfirmDialog
        open={!!confirmConvert}
        onClose={() => setConfirmConvert(null)}
        onConfirm={() => confirmConvert && convertEnquiry(confirmConvert)}
        title="Convert to Student"
        message={`Convert ${confirmConvert?.studentName}'s enquiry into a registered student? A new student record will be created.`}
        confirmLabel="Convert"
        danger={false}
      />

      <Modal open={newEnquiryOpen} onClose={() => setNewEnquiryOpen(false)} title="New Enquiry"
        footer={<><button className="btn-secondary" onClick={() => setNewEnquiryOpen(false)}>Cancel</button><button className="btn-primary" onClick={createEnquiry}>Create</button></>}>
        <div className="space-y-4">
          <Input label="Student Name *" value={enqForm.studentName} onChange={(e) => setEnqForm({ ...enqForm, studentName: e.target.value })} />
          <div className="grid grid-cols-2 gap-4">
            <Input label="Email *" value={enqForm.email} onChange={(e) => setEnqForm({ ...enqForm, email: e.target.value })} />
            <Input label="Phone" value={enqForm.phone} onChange={(e) => setEnqForm({ ...enqForm, phone: e.target.value })} />
          </div>
          <Input label="Preferred Service" value={enqForm.preferredService} onChange={(e) => setEnqForm({ ...enqForm, preferredService: e.target.value })} placeholder="e.g. Premium Plan" />
          <div className="grid grid-cols-2 gap-4">
            <Select label="Source" value={enqForm.source} onChange={(e) => setEnqForm({ ...enqForm, source: e.target.value as EnquirySource })}
              options={[{ value: 'website', label: 'Website' }, { value: 'referral', label: 'Referral' }, { value: 'social_media', label: 'Social Media' }, { value: 'walk_in', label: 'Walk-in' }, { value: 'phone', label: 'Phone' }, { value: 'email', label: 'Email' }]} />
            <Select label="Mode" value={enqForm.preferredMode} onChange={(e) => setEnqForm({ ...enqForm, preferredMode: e.target.value as LearningMode })}
              options={[{ value: 'online', label: 'Online' }, { value: 'offline', label: 'Offline' }, { value: 'hybrid', label: 'Hybrid' }]} />
          </div>
          <Textarea label="Notes" value={enqForm.notes} onChange={(e) => setEnqForm({ ...enqForm, notes: e.target.value })} rows={2} />
        </div>
      </Modal>
    </div>
  );
}

function Field({ icon, label, value }: { icon?: React.ReactNode; label: string; value: string }) {
  return <div><p className="text-xs text-navy-500 uppercase flex items-center gap-1">{icon}{label}</p><p className="text-sm font-medium text-navy-900 capitalize">{value}</p></div>;
}
