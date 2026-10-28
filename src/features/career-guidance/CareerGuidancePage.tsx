import { useState } from 'react';
import { Compass, Calendar, FileText, Target, Plus, CheckCircle2, XCircle, Clock } from 'lucide-react';
import { useMockStore } from '@/hooks/useMockStore';
import { Card } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { StatCard } from '@/components/ui/Card';
import { PageHeader } from '@/components/ui/PageHeader';
import { EmptyState } from '@/components/ui/State';
import { formatDate } from '@/utils';
import type { AppointmentStatus } from '@/types';

const statusVariant: Record<AppointmentStatus, 'info' | 'success' | 'danger' | 'warning'> = {
  scheduled: 'info', completed: 'success', cancelled: 'danger', no_show: 'warning',
};

export function CareerGuidancePage() {
  const store = useMockStore();
  const [tab, setTab] = useState<'appointments' | 'plans'>('appointments');

  const upcomingAppointments = store.careerAppointments.filter((a) => a.status === 'scheduled').length;
  const completedAppointments = store.careerAppointments.filter((a) => a.status === 'completed').length;
  const activePlans = store.careerActionPlans.length;

  return (
    <div>
      <PageHeader
        title="Career Guidance"
        subtitle="Manage student career appointments and action plans"
        breadcrumbs={[{ label: 'Dashboard', to: '/dashboard' }, { label: 'Career Guidance' }]}
      />

      <div className="grid grid-cols-3 gap-3 mb-5">
        <StatCard label="Upcoming" value={upcomingAppointments} icon={<Calendar size={20} />} accent="info" />
        <StatCard label="Completed" value={completedAppointments} icon={<CheckCircle2 size={20} />} accent="teal" />
        <StatCard label="Action Plans" value={activePlans} icon={<Target size={20} />} accent="indigo" />
      </div>

      <div className="flex gap-1 mb-4">
        {(['appointments', 'plans'] as const).map((t) => (
          <button key={t} onClick={() => setTab(t)} className={`rounded-lg px-4 py-2 text-sm font-medium capitalize transition-colors ${tab === t ? 'bg-navy-800 text-white' : 'text-navy-600 hover:bg-navy-100'}`}>{t}</button>
        ))}
      </div>

      {tab === 'appointments' && (
        <Card title="Career Appointments">
          {store.careerAppointments.length === 0 ? <EmptyState title="No appointments" /> : (
            <div className="divide-y divide-navy-50">
              {store.careerAppointments.map((a) => (
                <div key={a.id} className="flex items-center gap-3 px-5 py-4">
                  <div className="flex h-12 w-12 items-center justify-center rounded-lg bg-indigo-100 text-indigo-600">
                    {a.type === 'resume_review' ? <FileText size={22} /> : a.type === 'mock_interview' ? <Target size={22} /> : <Compass size={22} />}
                  </div>
                  <div className="min-w-0 flex-1">
                    <p className="text-sm font-medium text-navy-900 capitalize">{a.type.replace('_', ' ')}</p>
                    <p className="text-xs text-navy-500">{a.studentName} · {a.counsellor}</p>
                    <p className="text-xs text-navy-400 mt-0.5">{formatDate(a.scheduledAt)}</p>
                  </div>
                  <div className="flex flex-col items-end gap-1">
                    <Badge variant={statusVariant[a.status]} dot>{a.status.replace('_', ' ')}</Badge>
                    {a.notes && <span className="text-xs text-navy-400 max-w-40 truncate">{a.notes}</span>}
                  </div>
                </div>
              ))}
            </div>
          )}
        </Card>
      )}

      {tab === 'plans' && (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {store.careerActionPlans.length === 0 ? <Card className="md:col-span-2"><EmptyState title="No action plans" /></Card> : store.careerActionPlans.map((plan) => {
            const completedMilestones = plan.milestones.filter((m) => m.completed).length;
            const progress = Math.round((completedMilestones / plan.milestones.length) * 100);
            return (
              <Card key={plan.id} className="p-5">
                <div className="flex items-start justify-between mb-3">
                  <div><h3 className="text-sm font-semibold text-navy-900">{plan.studentName}</h3><p className="text-xs text-navy-500">Created {formatDate(plan.createdAt)}</p></div>
                  <Badge variant={progress === 100 ? 'success' : 'info'}>{progress}% complete</Badge>
                </div>
                <div className="mb-3">
                  <p className="text-xs font-medium text-navy-500 uppercase mb-1">Goals</p>
                  <ul className="text-sm text-navy-700 list-disc pl-4 space-y-0.5">{plan.goals.map((g, i) => <li key={i}>{g}</li>)}</ul>
                </div>
                <div>
                  <p className="text-xs font-medium text-navy-500 uppercase mb-2">Milestones</p>
                  <div className="space-y-2">{plan.milestones.map((m) => (
                    <div key={m.id} className="flex items-center gap-2 text-sm">
                      {m.completed ? <CheckCircle2 size={16} className="text-teal-500" /> : <Clock size={16} className="text-navy-300" />}
                      <span className={m.completed ? 'text-navy-400 line-through flex-1' : 'text-navy-700 flex-1'}>{m.title}</span>
                      <span className="text-xs text-navy-400">{formatDate(m.targetDate)}</span>
                    </div>
                  ))}</div>
                </div>
              </Card>
            );
          })}
        </div>
      )}
    </div>
  );
}
