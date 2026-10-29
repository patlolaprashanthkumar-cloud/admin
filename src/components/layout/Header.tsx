import { useState, useRef, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Menu, Bell, Search, ChevronDown, User, Settings, LogOut,
  Command, LayoutGrid, ArrowUpRight, Sparkles,
} from 'lucide-react';
import { useAuth } from '@/hooks/useAuth';
import { useMockStore } from '@/hooks/useMockStore';
import { Avatar } from '@/components/ui/Avatar';
import { roleLabel } from '@/utils/permissions';
import { timeAgo, classNames } from '@/utils';
import { operationalHubs } from '@/components/navigation/nav-config';

interface HeaderProps {
  onMenuClick: () => void;
}

export function Header({ onMenuClick }: HeaderProps) {
  const { user, logout } = useAuth();
  const store = useMockStore();
  const navigate = useNavigate();
  const [notifOpen, setNotifOpen] = useState(false);
  const [profileOpen, setProfileOpen] = useState(false);
  const [hubsOpen, setHubsOpen] = useState(false);

  const notifRef = useRef<HTMLDivElement>(null);
  const profileRef = useRef<HTMLDivElement>(null);
  const hubsRef = useRef<HTMLDivElement>(null);

  const unread = store.notifications.filter((n) => !n.read).length;

  useEffect(() => {
    function handler(e: MouseEvent) {
      if (notifRef.current && !notifRef.current.contains(e.target as Node)) setNotifOpen(false);
      if (profileRef.current && !profileRef.current.contains(e.target as Node)) setProfileOpen(false);
      if (hubsRef.current && !hubsRef.current.contains(e.target as Node)) setHubsOpen(false);
    }
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, []);

  if (!user) return null;

  return (
    <header className="sticky top-0 z-20 h-16 bg-white/80 backdrop-blur-xl border-b border-navy-100/80 flex items-center justify-between px-4 sm:px-6 safe-area-top shadow-xs">
      <div className="flex items-center gap-3">
        <button
          onClick={onMenuClick}
          className="lg:hidden text-navy-600 hover:text-navy-900 p-1.5 rounded-xl hover:bg-navy-100/70 transition-colors"
        >
          <Menu size={22} />
        </button>

        {/* 3D Search Pill */}
        <div className="hidden sm:flex items-center">
          <div className="relative group">
            <Search
              size={15}
              className="absolute left-3.5 top-1/2 -translate-y-1/2 text-navy-400 group-focus-within:text-forest-600 transition-colors"
            />
            <input
              type="text"
              placeholder="Search students, courses..."
              onKeyDown={(e) => {
                if (e.key === 'Enter') {
                  const val = (e.target as HTMLInputElement).value.trim();
                  if (val) navigate(`/students?q=${encodeURIComponent(val)}`);
                }
              }}
              className="w-56 md:w-72 rounded-xl border border-navy-200/80 bg-navy-50/50 py-2 pl-9 pr-10 text-xs sm:text-sm text-navy-900 placeholder-navy-400 focus:bg-white focus:border-forest-500 focus:outline-none focus:ring-4 focus:ring-forest-500/15 shadow-xs transition-all"
            />
            <kbd className="hidden md:inline-flex absolute right-2.5 top-1/2 -translate-y-1/2 items-center gap-0.5 rounded-md border border-navy-200/90 bg-white px-1.5 py-0.5 text-[10px] font-semibold text-navy-500 shadow-2xs">
              <Command size={10} />K
            </kbd>
          </div>
        </div>
      </div>

      <div className="flex items-center gap-2 sm:gap-2.5">
        {/* Quick Hubs & Portals Launcher */}
        <div className="relative" ref={hubsRef}>
          <button
            onClick={() => setHubsOpen((v) => !v)}
            className={classNames(
              'flex items-center gap-1.5 rounded-xl px-2.5 py-2 text-xs font-semibold transition-all',
              hubsOpen
                ? 'bg-forest-50 text-forest-800 shadow-xs ring-1 ring-forest-200'
                : 'text-navy-600 hover:bg-navy-100/70 hover:text-navy-900',
            )}
            title="Institutional Hubs & Portals"
          >
            <LayoutGrid size={18} className="text-forest-600" />
            <span className="hidden md:inline">Hubs</span>
          </button>

          {hubsOpen && (
            <div className="absolute right-0 mt-2.5 w-80 sm:w-96 rounded-2xl border border-navy-100 bg-white shadow-floating animate-slide-down overflow-hidden z-50">
              <div className="flex items-center justify-between border-b border-navy-100/90 px-4 py-3 bg-gradient-to-r from-forest-50/60 via-navy-50/40 to-white">
                <div className="flex items-center gap-2">
                  <div className="flex h-7 w-7 items-center justify-center rounded-lg bg-forest-600 text-white shadow-xs">
                    <Sparkles size={14} />
                  </div>
                  <div>
                    <p className="text-xs font-bold text-navy-900 font-display">Management Hubs</p>
                    <p className="text-[10px] text-navy-500">Specialized institutional portals</p>
                  </div>
                </div>
                <button
                  onClick={() => {
                    navigate('/dashboard');
                    setHubsOpen(false);
                  }}
                  className="text-[11px] font-semibold text-forest-700 hover:text-forest-800 flex items-center gap-0.5"
                >
                  Dashboard Hubs <ArrowUpRight size={12} />
                </button>
              </div>

              <div className="p-2 grid grid-cols-2 gap-1.5 max-h-88 overflow-y-auto">
                {operationalHubs.map((hub) => {
                  const Icon = hub.icon;
                  return (
                    <button
                      key={hub.to}
                      onClick={() => {
                        navigate(hub.to);
                        setHubsOpen(false);
                      }}
                      className="group flex flex-col items-start p-2.5 rounded-xl hover:bg-forest-50/50 hover:border-forest-200/60 border border-transparent transition-all text-left"
                    >
                      <div className="flex items-center gap-2 w-full mb-1">
                        <div
                          className="flex h-7 w-7 shrink-0 items-center justify-center rounded-lg text-white shadow-2xs transition-transform duration-200 group-hover:scale-110"
                          style={{ backgroundColor: hub.accentColor }}
                        >
                          <Icon size={14} />
                        </div>
                        <span className="text-xs font-bold text-navy-900 group-hover:text-forest-800 truncate">
                          {hub.label}
                        </span>
                      </div>
                      <p className="text-[10px] text-navy-500 line-clamp-2 leading-relaxed">
                        {hub.description}
                      </p>
                    </button>
                  );
                })}
              </div>

              <div className="p-2 border-t border-navy-100 bg-navy-50/50 text-center">
                <button
                  onClick={() => {
                    navigate('/categories');
                    setHubsOpen(false);
                  }}
                  className="text-[11px] font-semibold text-navy-600 hover:text-forest-700"
                >
                  Configure Taxonomies & Categories →
                </button>
              </div>
            </div>
          )}
        </div>

        {/* Notification Bell */}
        <div className="relative" ref={notifRef}>
          <button
            onClick={() => setNotifOpen((v) => !v)}
            className="relative rounded-xl p-2 text-navy-600 hover:bg-navy-100/80 hover:text-navy-900 transition-all hover:scale-105 active:scale-95"
            title="Notifications"
          >
            <Bell size={19} />
            {unread > 0 && (
              <span className="absolute top-1.5 right-1.5 flex h-4 min-w-4 items-center justify-center rounded-full bg-peach-500 px-1 text-[10px] font-extrabold text-white shadow-xs animate-pulse">
                {unread}
              </span>
            )}
          </button>

          {notifOpen && (
            <div className="absolute right-0 mt-2.5 w-80 max-w-[calc(100vw-2rem)] rounded-2xl border border-navy-100 bg-white shadow-floating animate-slide-down overflow-hidden z-50">
              <div className="flex items-center justify-between border-b border-navy-100/90 px-4 py-3 bg-gradient-to-r from-navy-50/50 to-white">
                <p className="text-sm font-bold text-navy-900 font-display">Notifications</p>
                <span className="text-[11px] font-semibold text-forest-700 bg-forest-50 px-2 py-0.5 rounded-full border border-forest-200/60">
                  {unread} unread
                </span>
              </div>
              <div className="max-h-80 overflow-y-auto divide-y divide-navy-50">
                {store.notifications.slice(0, 5).map((n) => (
                  <button
                    key={n.id}
                    onClick={() => {
                      if (n.actionUrl) navigate(n.actionUrl);
                      setNotifOpen(false);
                    }}
                    className="w-full text-left px-4 py-3 hover:bg-navy-50/70 transition-colors"
                  >
                    <div className="flex items-start gap-2.5">
                      {!n.read && (
                        <span className="mt-1.5 h-2 w-2 shrink-0 rounded-full bg-forest-500 ring-4 ring-forest-100" />
                      )}
                      <div className={classNames('min-w-0 flex-1', n.read && 'pl-4')}>
                        <p className="text-xs font-semibold text-navy-900 truncate">{n.title}</p>
                        <p className="text-xs text-navy-500 line-clamp-2 mt-0.5">{n.message}</p>
                        <p className="text-[10px] text-navy-400 mt-1 font-medium">{timeAgo(n.createdAt)}</p>
                      </div>
                    </div>
                  </button>
                ))}
              </div>
              <button
                onClick={() => {
                  navigate('/notifications');
                  setNotifOpen(false);
                }}
                className="w-full border-t border-navy-100 px-4 py-2.5 text-center text-xs font-bold text-forest-600 hover:bg-navy-50/80 transition-colors"
              >
                View all notifications →
              </button>
            </div>
          )}
        </div>

        {/* User Profile Dropdown */}
        <div className="relative" ref={profileRef}>
          <button
            onClick={() => setProfileOpen((v) => !v)}
            className="flex items-center gap-2.5 rounded-xl p-1.5 pr-2.5 hover:bg-navy-100/70 border border-transparent hover:border-navy-200/70 transition-all"
          >
            <Avatar name={user.fullName} size="sm" />
            <div className="hidden sm:block text-left">
              <p className="text-xs font-bold text-navy-900 leading-tight">{user.fullName}</p>
              <p className="text-[10px] text-navy-500 font-medium">{roleLabel(user.role)}</p>
            </div>
            <ChevronDown size={14} className="text-navy-400 transition-transform duration-200" />
          </button>

          {profileOpen && (
            <div className="absolute right-0 mt-2.5 w-60 rounded-2xl border border-navy-100 bg-white shadow-floating animate-slide-down overflow-hidden z-50">
              <div className="px-4 py-3.5 border-b border-navy-100 bg-gradient-to-r from-navy-50/60 to-white">
                <p className="text-xs font-bold text-navy-900 font-display">{user.fullName}</p>
                <p className="text-[11px] text-navy-500 truncate mt-0.5">{user.email}</p>
              </div>
              <div className="p-1.5 space-y-0.5">
                <button
                  onClick={() => {
                    navigate('/profile');
                    setProfileOpen(false);
                  }}
                  className="flex items-center gap-2.5 w-full px-3 py-2 text-xs font-medium text-navy-700 hover:bg-navy-50 hover:text-navy-900 rounded-xl transition-colors"
                >
                  <User size={15} /> My Profile
                </button>
                <button
                  onClick={() => {
                    navigate('/settings');
                    setProfileOpen(false);
                  }}
                  className="flex items-center gap-2.5 w-full px-3 py-2 text-xs font-medium text-navy-700 hover:bg-navy-50 hover:text-navy-900 rounded-xl transition-colors"
                >
                  <Settings size={15} /> Portal Settings
                </button>
              </div>
              <div className="p-1.5 border-t border-navy-100">
                <button
                  onClick={async () => {
                    await logout();
                    navigate('/login');
                  }}
                  className="flex items-center gap-2.5 w-full px-3 py-2 text-xs font-medium text-red-600 hover:bg-red-50 rounded-xl transition-colors"
                >
                  <LogOut size={15} /> Sign out
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </header>
  );
}
