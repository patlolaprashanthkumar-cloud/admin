import { NavLink } from 'react-router-dom';
import { operationalHubs, navItems } from '@/components/navigation/nav-config';
import { useAuth } from '@/hooks/useAuth';
import { hasPermission, roleLabel } from '@/utils/permissions';
import { Avatar } from '@/components/ui/Avatar';
import { Card } from '@/components/ui/Card';
import { PageHeader } from '@/components/ui/PageHeader';
import { classNames } from '@/utils';
import { Layers, ShieldCheck, Sparkles } from 'lucide-react';

export function MorePage() {
  const { user } = useAuth();
  if (!user) return null;

  const allowedHubs = operationalHubs.filter((item) => hasPermission(user.role, item.permission));
  const otherNavItems = navItems.filter(
    (item) => item.to !== '/dashboard' && item.to !== '/students' && item.to !== '/courses' && item.to !== '/payments' && hasPermission(user.role, item.permission)
  );

  return (
    <div className="space-y-6">
      <PageHeader
        title="Institutional Hubs & Navigation"
        subtitle="Access all specialized academic management suites, examination portals, and portal settings"
      />

      {/* User Overview Profile Card */}
      <Card className="p-5 border-l-4 border-l-forest-600 bg-gradient-to-r from-white via-forest-50/20 to-white shadow-3d">
        <div className="flex items-center gap-4">
          <Avatar name={user.fullName} size="lg" />
          <div className="min-w-0 flex-1">
            <div className="flex items-center gap-2">
              <p className="font-bold text-navy-950 font-display text-base">{user.fullName}</p>
              <span className="px-2 py-0.5 rounded-full text-[10px] font-extrabold uppercase bg-peach-100 text-peach-700 border border-peach-200">
                {roleLabel(user.role)}
              </span>
            </div>
            <p className="text-xs text-navy-500 truncate mt-0.5">{user.email}</p>
            <p className="text-[11px] text-forest-700 font-semibold mt-1 flex items-center gap-1">
              <ShieldCheck size={13} /> IIECM Verified Administrator
            </p>
          </div>
        </div>
      </Card>

      {/* Operational Management Hubs */}
      <div className="space-y-3">
        <div className="flex items-center gap-2">
          <Layers size={16} className="text-forest-600" />
          <h3 className="text-sm font-bold uppercase tracking-wider text-navy-900 font-display">
            Specialized Management Suites
          </h3>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-3.5">
          {allowedHubs.map((hub) => (
            <NavLink
              key={hub.to}
              to={hub.to}
              className={({ isActive }) =>
                classNames(
                  'card-3d card-hover p-4 flex flex-col justify-between transition-all group',
                  isActive && 'border-forest-500 bg-forest-50/40',
                )
              }
            >
              <div>
                <div className="flex items-center justify-between mb-2.5">
                  <div
                    className="flex h-10 w-10 items-center justify-center rounded-xl text-white shadow-sm transition-transform duration-200 group-hover:scale-110"
                    style={{ backgroundColor: hub.accentColor }}
                  >
                    <hub.icon size={20} />
                  </div>
                  <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-navy-50 text-navy-600">
                    {hub.category}
                  </span>
                </div>
                <p className="text-sm font-bold text-navy-900 group-hover:text-forest-700 transition-colors">
                  {hub.label}
                </p>
                <p className="text-xs text-navy-500 mt-1 line-clamp-2 leading-relaxed">
                  {hub.description}
                </p>
              </div>
              <div className="mt-3 pt-2.5 border-t border-navy-50 text-[11px] font-bold text-forest-600 flex items-center gap-1">
                Enter Suite →
              </div>
            </NavLink>
          ))}
        </div>
      </div>

      {/* Additional Administrative Modules */}
      {otherNavItems.length > 0 && (
        <div className="space-y-3 pt-2">
          <div className="flex items-center gap-2">
            <Sparkles size={16} className="text-peach-500" />
            <h3 className="text-sm font-bold uppercase tracking-wider text-navy-900 font-display">
              Administrative & Reporting
            </h3>
          </div>

          <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
            {otherNavItems.map((item) => (
              <NavLink
                key={item.to}
                to={item.to}
                className={({ isActive }) =>
                  classNames(
                    'card-3d card-hover p-4 flex flex-col items-center text-center gap-2 transition-all group',
                    isActive && 'border-peach-400 bg-peach-50/40',
                  )
                }
              >
                <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-navy-100 text-navy-700 group-hover:bg-navy-800 group-hover:text-white transition-colors">
                  <item.icon size={20} />
                </div>
                <span className="text-xs font-bold text-navy-900 group-hover:text-forest-700">
                  {item.label}
                </span>
              </NavLink>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
