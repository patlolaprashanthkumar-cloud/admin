import { NavLink, useNavigate } from 'react-router-dom';
import { LogOut, X } from 'lucide-react';
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
      {open && <div className="fixed inset-0 z-30 bg-navy-950/40 lg:hidden" onClick={onClose} />}

      <aside className={classNames(
        'fixed lg:sticky top-0 z-40 h-screen w-64 shrink-0 bg-navy-900 text-navy-100 flex flex-col transition-transform duration-300 lg:translate-x-0',
        open ? 'translate-x-0' : '-translate-x-full',
      )}>
        <div className="flex items-center justify-between px-4 h-16 border-b border-navy-800">
          <Logo size="md" variant="light" />
          <button onClick={onClose} className="lg:hidden text-navy-400 hover:text-white">
            <X size={20} />
          </button>
        </div>

        <nav className="flex-1 overflow-y-auto px-3 py-4 space-y-1">
          {visibleItems.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              onClick={onClose}
              className={({ isActive }) => classNames('nav-link', isActive && 'nav-link-active')}
            >
              <item.icon size={18} />
              <span>{item.label}</span>
              {item.badge && <span className="ml-auto rounded-full bg-amber-500 px-1.5 py-0.5 text-[10px] font-bold text-white">{item.badge}</span>}
            </NavLink>
          ))}
        </nav>

        <div className="border-t border-navy-800 p-3">
          <button
            onClick={() => setConfirmLogout(true)}
            className="nav-link w-full text-navy-300 hover:text-white"
          >
            <LogOut size={18} />
            <span>Sign out</span>
          </button>
        </div>
      </aside>

      <ConfirmDialog
        open={confirmLogout}
        onClose={() => setConfirmLogout(false)}
        onConfirm={async () => { await logout(); navigate('/login'); }}
        title="Sign out"
        message="Are you sure you want to sign out of the IIECM Admin Portal?"
        confirmLabel="Sign out"
        danger={false}
      />
    </>
  );
}
