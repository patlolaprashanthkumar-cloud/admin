import { NavLink, useNavigate } from 'react-router-dom';
import { LogOut, X, Sparkles, LayoutGrid, ArrowRight } from 'lucide-react';
import { navItems } from '@/components/navigation/nav-config';
import { Logo } from '@/components/navigation/Logo';
import { useAuth } from '@/hooks/useAuth';
import { hasPermission, roleLabel } from '@/utils/permissions';
import { Avatar } from '@/components/ui/Avatar';
import { ConfirmDialog } from '@/components/ui/ConfirmDialog';
import { useState } from 'react';
import { classNames } from '@/utils';

interface SidebarProps {
  open: boolean;
  onClose: () => void;
}

export function Sidebar({ open, onClose }: SidebarProps) {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const [confirmLogout, setConfirmLogout] = useState(false);

  const visibleItems = navItems.filter((item) => user && hasPermission(user.role, item.permission));

  return (
    <>
      {open && (
        <div
          className="fixed inset-0 z-30 bg-navy-950/60 backdrop-blur-sm lg:hidden transition-opacity"
          onClick={onClose}
        />
      )}

      <aside
        className={classNames(
          'fixed lg:sticky top-0 z-40 h-screen w-64 shrink-0 bg-gradient-to-b from-[#0B1D30] via-[#091828] to-[#061320] text-navy-100 flex flex-col transition-transform duration-300 lg:translate-x-0 border-r border-navy-800/80 shadow-2xl',
          open ? 'translate-x-0' : '-translate-x-full',
        )}
      >
        {/* Top Header */}
        <div className="flex items-center justify-between px-5 h-16 border-b border-navy-800/80 relative">
          <div className="absolute top-0 left-0 right-0 h-[1px] bg-gradient-to-r from-transparent via-forest-400/30 to-transparent" />
          <Logo size="md" variant="light" />
          <button
            onClick={onClose}
            className="lg:hidden text-navy-400 hover:text-white p-1 rounded-lg hover:bg-white/10 transition-colors"
          >
            <X size={20} />
          </button>
        </div>

        {/* Navigation List */}
        <nav className="flex-1 overflow-y-auto px-3.5 py-4 space-y-1.5 scrollbar-thin">
          <div className="px-2 pb-1.5 flex items-center justify-between">
            <span className="text-[10px] font-bold uppercase tracking-wider text-navy-400/90 flex items-center gap-1.5">
              <Sparkles size={11} className="text-peach-400" /> Core Pillars
            </span>
            <span className="text-[9px] font-semibold text-navy-500 uppercase tracking-widest">
              Institutional
            </span>
          </div>

          {visibleItems.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              onClick={onClose}
              className={({ isActive }) =>
                classNames(
                  'nav-link group relative',
                  isActive && 'nav-link-active font-semibold',
                )
              }
            >
              <item.icon
                size={18}
                className="shrink-0 transition-transform duration-200 group-hover:scale-110"
              />
              <span className="truncate">{item.label}</span>
              {item.badge && (
                <span className="ml-auto rounded-full bg-peach-500 px-2 py-0.5 text-[10px] font-bold text-white shadow-xs">
                  {item.badge}
                </span>
              )}
            </NavLink>
          ))}

          {/* Quick Hub Access Card */}
          <div className="pt-4 px-1">
            <div
              onClick={() => {
                navigate('/dashboard#academic-hubs');
                onClose();
              }}
              className="group cursor-pointer rounded-2xl p-3 bg-gradient-to-br from-white/10 via-white/5 to-transparent border border-white/10 hover:border-forest-400/50 hover:bg-white/15 transition-all shadow-md relative overflow-hidden"
            >
              <div className="absolute -right-3 -bottom-3 w-16 h-16 bg-forest-500/20 rounded-full blur-xl pointer-events-none" />
              <div className="flex items-center gap-2 mb-1.5">
                <div className="flex h-7 w-7 items-center justify-center rounded-lg bg-forest-600/80 text-white shadow-2xs group-hover:scale-110 transition-transform">
                  <LayoutGrid size={14} />
                </div>
                <div>
                  <p className="text-xs font-bold text-white leading-tight">Management Hubs</p>
                  <p className="text-[10px] text-peach-300 font-medium">6 Specialized Portals</p>
                </div>
              </div>
              <p className="text-[10px] text-navy-300 leading-relaxed mb-2">
                Assessments, Categories, Guidance, CRM, Resources & Broadcasts on Home.
              </p>
              <div className="flex items-center gap-1 text-[10px] font-bold text-forest-300 group-hover:text-forest-200 transition-colors">
                <span>Explore Portals</span>
                <ArrowRight size={12} className="group-hover:translate-x-1 transition-transform" />
              </div>
            </div>
          </div>
        </nav>

        {/* User Profile Card at Bottom */}
        {user && (
          <div className="p-3 border-t border-navy-800/80 bg-navy-950/40">
            <div className="flex items-center justify-between p-2 rounded-xl bg-white/5 border border-white/5">
              <div className="flex items-center gap-2.5 min-w-0">
                <Avatar name={user.fullName} size="sm" />
                <div className="min-w-0">
                  <p className="text-xs font-semibold text-white truncate leading-tight">
                    {user.fullName}
                  </p>
                  <p className="text-[10px] text-peach-300 font-medium truncate mt-0.5">
                    {roleLabel(user.role)}
                  </p>
                </div>
              </div>
              <button
                onClick={() => setConfirmLogout(true)}
                title="Sign out"
                className="text-navy-400 hover:text-red-400 p-1.5 rounded-lg hover:bg-white/10 transition-colors shrink-0"
              >
                <LogOut size={16} />
              </button>
            </div>
          </div>
        )}
      </aside>

      <ConfirmDialog
        open={confirmLogout}
        onClose={() => setConfirmLogout(false)}
        onConfirm={async () => {
          await logout();
          navigate('/login');
        }}
        title="Sign out"
        message="Are you sure you want to sign out of the IIECM Admin Portal?"
        confirmLabel="Sign out"
        danger={false}
      />
    </>
  );
}
