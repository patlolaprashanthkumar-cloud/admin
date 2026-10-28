import { useState, useMemo } from 'react';
import { useNavigate } from 'react-router-dom';
import { CreditCard, Download, CheckCircle2, XCircle, Printer, IndianRupee } from 'lucide-react';
import { useMockStore } from '@/hooks/useMockStore';
import { mockStore } from '@/mock-data/store';
import { Card } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { StatCard } from '@/components/ui/Card';
import { PageHeader } from '@/components/ui/PageHeader';
import { SearchBar, FilterBar } from '@/components/ui/SearchBar';
import { Select } from '@/components/ui/FormField';
import { EmptyState } from '@/components/ui/State';
import { Modal, Textarea } from '@/components/ui';
import { ConfirmDialog } from '@/components/ui/ConfirmDialog';
import { Pagination } from '@/components/ui/Pagination';
import { DataTable } from '@/components/tables/DataTable';
import { formatCurrency, formatDate, paginate, downloadCSV } from '@/utils';
import type { Payment, PaymentStatus } from '@/types';

const PER_PAGE = 8;

export function PaymentListPage() {
  const store = useMockStore();
  const navigate = useNavigate();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [page, setPage] = useState(1);
  const [selected, setSelected] = useState<Payment | null>(null);
  const [rejectAction, setRejectAction] = useState<Payment | null>(null);
  const [rejectReason, setRejectReason] = useState('');
  const [confirmApprove, setConfirmApprove] = useState<Payment | null>(null);

  const filtered = useMemo(() => store.payments.filter((p) => {
    const q = search.toLowerCase();
    const matchesSearch = !q || p.studentName.toLowerCase().includes(q) || p.transactionRef.toLowerCase().includes(q) || p.courseName?.toLowerCase().includes(q);
    const matchesStatus = !statusFilter || p.status === statusFilter;
    return matchesSearch && matchesStatus;
  }), [store.payments, search, statusFilter]);

  const { data, total, totalPages, currentPage } = paginate(filtered, page, PER_PAGE);

  const totalRevenue = store.payments.filter((p) => p.status === 'verified').reduce((sum, p) => sum + p.amount, 0);
  const pendingCount = store.payments.filter((p) => p.status === 'pending').length;
  const pendingAmount = store.payments.filter((p) => p.status === 'pending').reduce((sum, p) => sum + p.amount, 0);
  const refundedAmount = store.payments.filter((p) => p.status === 'refunded').reduce((sum, p) => sum + p.amount, 0);

  function approvePayment(payment: Payment) {
    mockStore.updatePayment(payment.id, { status: 'verified', verifiedBy: 'Dr. Priya Sharma' });
    mockStore.addActivity({ id: `act-${Date.now()}`, adminName: 'Dr. Priya Sharma', action: 'Verified payment', target: `${payment.transactionRef} — ${payment.studentName}`, timestamp: new Date().toISOString() });
    setConfirmApprove(null);
    setSelected(null);
  }

  function rejectPayment() {
    if (!rejectAction || !rejectReason.trim()) return;
    mockStore.updatePayment(rejectAction.id, { status: 'rejected', rejectionReason: rejectReason.trim() });
    mockStore.addActivity({ id: `act-${Date.now()}`, adminName: 'Dr. Priya Sharma', action: 'Rejected payment', target: `${rejectAction.transactionRef} — ${rejectAction.studentName}`, timestamp: new Date().toISOString() });
    setRejectAction(null);
    setRejectReason('');
    setSelected(null);
  }

  function exportCSV() {
    const rows = filtered.map((p) => ({
      TransactionRef: p.transactionRef, Student: p.studentName, Course: p.courseName ?? '', Plan: p.subscriptionPlan ?? '',
      Amount: p.amount, Method: p.paymentMethod, Status: p.status, Date: formatDate(p.paymentDate),
    }));
    downloadCSV('iiecm-payments.csv', rows);
  }

  const statusVariant: Record<PaymentStatus, 'success' | 'warning' | 'danger' | 'info' | 'neutral'> = {
    verified: 'success', pending: 'warning', rejected: 'danger', failed: 'danger', refunded: 'info',
  };

  return (
    <div>
      <PageHeader
        title="Payments & Subscriptions"
        subtitle={`${store.payments.length} transactions`}
        breadcrumbs={[{ label: 'Dashboard', to: '/dashboard' }, { label: 'Payments' }]}
        actions={<button className="btn-secondary" onClick={exportCSV}><Download size={16} /> Export CSV</button>}
      />

      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3 mb-5">
        <StatCard label="Total Revenue" value={formatCurrency(totalRevenue)} icon={<IndianRupee size={20} />} accent="teal" />
        <StatCard label="Pending" value={pendingCount} icon={<CreditCard size={20} />} accent="amber" />
        <StatCard label="Pending Amount" value={formatCurrency(pendingAmount)} icon={<IndianRupee size={20} />} accent="amber" />
        <StatCard label="Refunded" value={formatCurrency(refundedAmount)} icon={<IndianRupee size={20} />} accent="indigo" />
      </div>

      <Card className="p-4 mb-4">
        <div className="flex flex-col sm:flex-row gap-3">
          <SearchBar value={search} onChange={(v) => { setSearch(v); setPage(1); }} placeholder="Search by student, reference, or course..." className="flex-1" />
          <FilterBar>
            <Select value={statusFilter} onChange={(e) => { setStatusFilter(e.target.value); setPage(1); }} placeholder="All Statuses"
              options={[{ value: 'pending', label: 'Pending' }, { value: 'verified', label: 'Verified' }, { value: 'rejected', label: 'Rejected' }, { value: 'failed', label: 'Failed' }, { value: 'refunded', label: 'Refunded' }]} className="w-auto min-w-32" />
          </FilterBar>
        </div>
      </Card>

      <Card>
        {filtered.length === 0 ? (
          <EmptyState icon={<CreditCard size={26} />} title="No transactions found" description="Try adjusting your search or filters." />
        ) : (
          <>
            <DataTable
              data={data}
              rowKey={(p) => p.id}
              onRowClick={(p) => setSelected(p)}
              columns={[
                { key: 'transactionRef', header: 'Reference', render: (p) => <span className="font-mono text-xs text-navy-700">{p.transactionRef}</span> },
                { key: 'studentName', header: 'Student', render: (p) => <div><p className="text-sm font-medium text-navy-900">{p.studentName}</p><p className="text-xs text-navy-500">{p.courseName ?? 'Subscription'}</p></div> },
                { key: 'amount', header: 'Amount', render: (p) => <span className="font-semibold text-navy-900">{formatCurrency(p.amount)}</span> },
                { key: 'paymentMethod', header: 'Method', hideOnMobile: true, render: (p) => <span className="capitalize text-navy-600">{p.paymentMethod.replace('_', ' ')}</span> },
                { key: 'status', header: 'Status', render: (p) => <Badge variant={statusVariant[p.status]} dot>{p.status}</Badge> },
                { key: 'paymentDate', header: 'Date', hideOnMobile: true, render: (p) => <span className="text-xs text-navy-500">{formatDate(p.paymentDate)}</span> },
              ]}
            />
            <Pagination currentPage={currentPage} totalPages={totalPages} onPageChange={setPage} total={total} perPage={PER_PAGE} />
          </>
        )}
      </Card>

      <Modal open={!!selected} onClose={() => setSelected(null)} title="Transaction Details" size="lg"
        footer={
          selected && (selected.status === 'pending' ? (
            <>
              <button className="btn-danger" onClick={() => setRejectAction(selected)}><XCircle size={16} /> Reject</button>
              <button className="btn-primary" onClick={() => setConfirmApprove(selected)}><CheckCircle2 size={16} /> Verify Payment</button>
            </>
          ) : <button className="btn-secondary" onClick={() => setSelected(null)}>Close</button>)
        }
      >
        {selected && (
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <div><p className="text-xs text-navy-500">Transaction Reference</p><p className="font-mono text-sm font-semibold text-navy-900">{selected.transactionRef}</p></div>
              <Badge variant={statusVariant[selected.status]} dot size="md">{selected.status}</Badge>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <DetailField label="Student" value={selected.studentName} />
              <DetailField label="Course" value={selected.courseName ?? '—'} />
              <DetailField label="Amount" value={formatCurrency(selected.amount)} />
              <DetailField label="Method" value={selected.paymentMethod.replace('_', ' ')} />
              <DetailField label="Plan" value={selected.subscriptionPlan ?? '—'} />
              <DetailField label="Date" value={formatDate(selected.paymentDate)} />
              <DetailField label="Subscription Start" value={selected.subscriptionStart ? formatDate(selected.subscriptionStart) : '—'} />
              <DetailField label="Subscription Expiry" value={selected.subscriptionExpiry ? formatDate(selected.subscriptionExpiry) : '—'} />
              <DetailField label="Verified By" value={selected.verifiedBy ?? '—'} />
              <DetailField label="Refund Status" value={selected.refundStatus ?? 'None'} />
            </div>
            {selected.rejectionReason && (
              <div className="rounded-lg bg-red-50 border border-red-200 p-3"><p className="text-xs text-red-600 font-medium">Rejection Reason</p><p className="text-sm text-red-700 mt-1">{selected.rejectionReason}</p></div>
            )}
            <div className="border-t border-navy-100 pt-4">
              <button className="btn-secondary w-full" onClick={() => window.print()}><Printer size={16} /> Print Receipt</button>
            </div>
          </div>
        )}
      </Modal>

      <Modal open={!!rejectAction} onClose={() => setRejectAction(null)} title="Reject Payment"
        footer={<><button className="btn-secondary" onClick={() => setRejectAction(null)}>Cancel</button><button className="btn-danger" onClick={rejectPayment}>Reject Payment</button></>}>
        <div className="space-y-3">
          <p className="text-sm text-navy-600">Provide a reason for rejecting <strong>{rejectAction?.transactionRef}</strong> ({rejectAction?.studentName}).</p>
          <Textarea label="Rejection Reason *" value={rejectReason} onChange={(e) => setRejectReason(e.target.value)} rows={3} placeholder="e.g. Payment proof insufficient..." />
        </div>
      </Modal>

      <ConfirmDialog
        open={!!confirmApprove}
        onClose={() => setConfirmApprove(null)}
        onConfirm={() => confirmApprove && approvePayment(confirmApprove)}
        title="Verify Payment"
        message={`Verify payment of ${confirmApprove ? formatCurrency(confirmApprove.amount) : ''} from ${confirmApprove?.studentName}? This will confirm their subscription.`}
        confirmLabel="Verify"
        danger={false}
      />
    </div>
  );
}

function DetailField({ label, value }: { label: string; value: string }) {
  return <div><p className="text-xs text-navy-500 uppercase">{label}</p><p className="text-sm font-medium text-navy-900 capitalize">{value}</p></div>;
}
