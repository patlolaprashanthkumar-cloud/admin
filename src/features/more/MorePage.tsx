import { NavLink } from 'react-router-dom';
import { navItems } from '@/components/navigation/nav-config';
import { useAuth } from '@/hooks/useAuth';
import { hasPermission, roleLabel } from '@/utils/permissions';
import { Avatar } from '@/components/ui/Avatar';
import { Card } from '@/components/ui/Card';
import { PageHeader } from '@/components/ui/PageHeader';
import { classNames } from '@/utils';

const mobileExtras = navItems.slice(4);

export function MorePage() {
  const { user } = useAuth();
  if (!user) return null;
  const items = mobileExtras.filter((item) => hasPermission(user.role, item.permission));

  return (
    <div>
      <PageHeader title="More" subtitle="All admin sections" />

      <Card className="p-4 mb-4">
        <div className="flex items-center gap-3">
          <Avatar name={user.fullName} size="lg" />
          <div>
            <p className="font-semibold text-navy-900">{user.fullName}</p>
            <p className="text-sm text-navy-500">{user.email}</p>
            <p className="text-xs text-indigo-600 font-medium mt-0.5">{roleLabel(user.role)}</p>
          </div>
        </div>
      </Card>

      <div className="grid grid-cols-2 gap-3">
        {items.map((item) => (
          <NavLink
            key={item.to}
            to={item.to}
            className={({ isActive }) => classNames(
              'card card-hover p-4 flex flex-col items-center gap-2 text-center transition-all',
              isActive && 'border-indigo-300 bg-indigo-50/50',
            )}
          >
            <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-navy-100 text-navy-700">
              <item.icon size={24} />
            </div>
            <span className="text-sm font-medium text-navy-800">{item.label}</span>
          </NavLink>
        ))}
      </div>
    </div>
  );
}
