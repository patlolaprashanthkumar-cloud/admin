import { useState, useRef, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Menu, Bell, Search, ChevronDown, User, Settings, LogOut } from 'lucide-react';
import { useAuth } from '@/hooks/useAuth';
import { useMockStore } from '@/hooks/useMockStore';
import { Avatar } from '@/components/ui/Avatar';
import { roleLabel } from '@/utils/permissions';
import { timeAgo, classNames } from '@/utils';

interface HeaderProps {
  onMenuClick: () => void;
}

export function Header({ onMenuClick }: HeaderProps) {
  const { user, logout } = useAuth();
  const store = useMockStore();
  const navigate = useNavigate();
  const [notifOpen, setNotifOpen] = useState(false);
  const [profileOpen, setProfileOpen] = useState(false);
  const notifRef = useRef<HTMLDivElement>(null);
  const profileRef = useRef<HTMLDivElement>(null);

  const unread = store.notifications.filter((n) => !n.read).length;

  useEffect(() => {
    function handler(e: MouseEvent) {
      if (notifRef.current && !notifRef.current.contains(e.target as Node)) setNotifOpen(false);
      if (profileRef.current && !profileRef.current.contains(e.target as Node)) setProfileOpen(false);
    }
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, []);

  if (!user) return null;

  return (
    <header className="sticky top-0 z-20 h-16 bg-white/95 backdrop-blur border-b border-navy-100 flex items-center justify-between px-4 safe-area-top">
      <div className="flex items-center gap-3">
        <button onClick={onMenuClick} className="lg:hidden text-navy-600 hover:text-navy-900">
          <Menu size={22} />
        </button>
        <div className="hidden sm:flex items-center">
          <div className="relative">
            <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-navy-400" />
            <input
              type="text"
              placeholder="Search students, courses..."
              onKeyDown={(e) => {
                if (e.key === 'Enter') {
                  const val = (e.target as HTMLInputElement).value.trim();
                  if (val) navigate(`/students?q=${encodeURIComponent(val)}`);
                }
              }}
              className="w-48 md:w-64 rounded-lg border border-navy-200 bg-navy-50/50 py-2 pl-9 pr-3 text-sm text-navy-900 placeholder-navy-400 focus:bg-white focus:border-indigo-500 focus:outline-none focus:ring-2 focus:ring-indigo-500/20 transition-all"
            />
          </div>
        </div>
      </div>

      <div className="flex items-center gap-2">
        <div className="relative" ref={notifRef}>
          <button
            onClick={() => setNotifOpen((v) => !v)}
            className="relative rounded-lg p-2 text-navy-600 hover:bg-navy-100 transition-colors"
          >
            <Bell size={20} />
            {unread > 0 && (
              <span className="absolute top-1 right-1 h-4 min-w-4 rounded-full bg-red-500 px-1 text-[10px] font-bold text-white flex items-center justify-center">
                {unread}
              </span>
            )}
          </button>
          {notifOpen && (
            <div className="absolute right-0 mt-2 w-80 max-w-[calc(100vw-2rem)] rounded-xl border border-navy-100 bg-white shadow-elevated animate-slide-down overflow-hidden">
              <div className="flex items-center justify-between border-b border-navy-100 px-4 py-3">
                <p className="text-sm font-semibold text-navy-900">Notifications</p>
                <span className="text-xs text-navy-500">{unread} unread</span>
              </div>
              <div className="max-h-80 overflow-y-auto divide-y divide-navy-50">
                {store.notifications.slice(0, 5).map((n) => (
                  <button
                    key={n.id}
                    onClick={() => { if (n.actionUrl) navigate(n.actionUrl); setNotifOpen(false); }}
                    className="w-full text-left px-4 py-3 hover:bg-navy-50 transition-colors"
                  >
                    <div className="flex items-start gap-2">
                      {!n.read && <span className="mt-1.5 h-2 w-2 shrink-0 rounded-full bg-indigo-500" />}
                      <div className={classNames('min-w-0 flex-1', n.read && 'pl-4')}>
                        <p className="text-sm font-medium text-navy-900 truncate">{n.title}</p>
                        <p className="text-xs text-navy-500 line-clamp-2 mt-0.5">{n.message}</p>
                        <p className="text-[10px] text-navy-400 mt-1">{timeAgo(n.createdAt)}</p>
                      </div>
                    </div>
                  </button>
                ))}
              </div>
              <button
                onClick={() => { navigate('/notifications'); setNotifOpen(false); }}
                className="w-full border-t border-navy-100 px-4 py-2.5 text-center text-sm font-medium text-indigo-600 hover:bg-navy-50"
              >
                View all
              </button>
            </div>
          )}
        </div>

        <div className="relative" ref={profileRef}>
          <button
            onClick={() => setProfileOpen((v) => !v)}
            className="flex items-center gap-2 rounded-lg p-1.5 hover:bg-navy-100 transition-colors"
          >
            <Avatar name={user.fullName} size="sm" />
            <div className="hidden sm:block text-left">
              <p className="text-sm font-medium text-navy-900 leading-tight">{user.fullName}</p>
              <p className="text-[10px] text-navy-500">{roleLabel(user.role)}</p>
            </div>
            <ChevronDown size={16} className="text-navy-400" />
          </button>
          {profileOpen && (
            <div className="absolute right-0 mt-2 w-56 rounded-xl border border-navy-100 bg-white shadow-elevated animate-slide-down overflow-hidden">
              <div className="px-4 py-3 border-b border-navy-100">
                <p className="text-sm font-medium text-navy-900">{user.fullName}</p>
                <p className="text-xs text-navy-500">{user.email}</p>
              </div>
              <button onClick={() => { navigate('/profile'); setProfileOpen(false); }} className="flex items-center gap-3 w-full px-4 py-2.5 text-sm text-navy-700 hover:bg-navy-50">
                <User size={16} /> My Profile
              </button>
              <button onClick={() => { navigate('/settings'); setProfileOpen(false); }} className="flex items-center gap-3 w-full px-4 py-2.5 text-sm text-navy-700 hover:bg-navy-50">
                <Settings size={16} /> Settings
              </button>
              <button onClick={async () => { await logout(); navigate('/login'); }} className="flex items-center gap-3 w-full px-4 py-2.5 text-sm text-red-600 hover:bg-red-50 border-t border-navy-100">
                <LogOut size={16} /> Sign out
              </button>
            </div>
          )}
        </div>
      </div>
    </header>
  );
}
