import { useNavigate } from 'react-router-dom';
import { Bell, CheckCheck, Filter } from 'lucide-react';
import { useMockStore } from '@/hooks/useMockStore';
import { mockStore } from '@/mock-data/store';
import { Card } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { PageHeader } from '@/components/ui/PageHeader';
import { EmptyState } from '@/components/ui/State';
import { timeAgo } from '@/utils';
import type { NotificationType, NotificationPriority } from '@/types';

const typeVariant: Record<NotificationType, 'info' | 'success' | 'accent' | 'warning' | 'default'> = {
  student: 'info', instructor: 'accent', course: 'default', payment: 'warning', class: 'info', system: 'default',
};
const priorityVariant: Record<NotificationPriority, 'danger' | 'warning' | 'neutral'> = { high: 'danger', medium: 'warning', low: 'neutral' };

export function NotificationListPage() {
  const store = useMockStore();
  const navigate = useNavigate();
  const unread = store.notifications.filter((n) => !n.read).length;

  return (
    <div>
      <PageHeader
        title="Notifications"
        subtitle={`${store.notifications.length} notifications · ${unread} unread`}
        breadcrumbs={[{ label: 'Dashboard', to: '/dashboard' }, { label: 'Notifications' }]}
        actions={unread > 0 ? <button className="btn-secondary" onClick={() => mockStore.markAllNotificationsRead()}><CheckCheck size={16} /> Mark All Read</button> : undefined}
      />

      <Card>
        {store.notifications.length === 0 ? (
          <EmptyState icon={<Bell size={26} />} title="No notifications" description="You're all caught up." />
        ) : (
          <div className="divide-y divide-navy-50">
            {store.notifications.map((n) => (
              <div
                key={n.id}
                className={`flex items-start gap-3 px-5 py-4 cursor-pointer transition-colors ${!n.read ? 'bg-indigo-50/30 hover:bg-indigo-50/50' : 'hover:bg-navy-50/40'}`}
                onClick={() => { mockStore.markNotificationRead(n.id); if (n.actionUrl) navigate(n.actionUrl); }}
              >
                <div className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-lg ${!n.read ? 'bg-indigo-100 text-indigo-600' : 'bg-navy-100 text-navy-400'}`}>
                  <Bell size={18} />
                </div>
                <div className="min-w-0 flex-1">
                  <div className="flex items-center gap-2">
                    {!n.read && <span className="h-2 w-2 shrink-0 rounded-full bg-indigo-500" />}
                    <p className={`text-sm ${!n.read ? 'font-semibold text-navy-900' : 'font-medium text-navy-700'}`}>{n.title}</p>
                  </div>
                  <p className="text-sm text-navy-500 mt-0.5">{n.message}</p>
                  <div className="flex items-center gap-2 mt-1.5">
                    <Badge variant={typeVariant[n.type]}>{n.type}</Badge>
                    <Badge variant={priorityVariant[n.priority]}>{n.priority}</Badge>
                    <span className="text-xs text-navy-400">{timeAgo(n.createdAt)}</span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </Card>

      <div className="mt-4 rounded-lg bg-navy-50 border border-navy-100 px-4 py-3 text-sm text-navy-500">
        <strong>Note:</strong> Push notification delivery requires server-side integration. This view shows in-app notifications only.
      </div>
    </div>
  );
}
