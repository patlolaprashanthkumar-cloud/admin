import { NavLink, useNavigate } from 'react-router-dom';
import { Home, Users, BookOpen, CreditCard, Grid3x3 } from 'lucide-react';
import { classNames } from '@/utils';

const items = [
  { to: '/dashboard', label: 'Home', icon: Home },
  { to: '/students', label: 'Students', icon: Users },
  { to: '/courses', label: 'Courses', icon: BookOpen },
  { to: '/payments', label: 'Payments', icon: CreditCard },
];

export function BottomNav() {
  return (
    <nav className="lg:hidden fixed bottom-0 left-0 right-0 z-30 bg-white border-t border-navy-100 safe-area-bottom shadow-elevated">
      <div className="flex items-center justify-around h-16">
        {items.map((item) => (
          <NavLink
            key={item.to}
            to={item.to}
            className={({ isActive }) => classNames(
              'flex flex-col items-center gap-1 px-3 py-1.5 text-[10px] font-medium transition-colors',
              isActive ? 'text-indigo-600' : 'text-navy-400',
            )}
          >
            <item.icon size={22} />
            <span>{item.label}</span>
          </NavLink>
        ))}
        <NavLink
          to="/more"
          className={({ isActive }) => classNames(
            'flex flex-col items-center gap-1 px-3 py-1.5 text-[10px] font-medium transition-colors',
            isActive ? 'text-indigo-600' : 'text-navy-400',
          )}
        >
          <Grid3x3 size={22} />
          <span>More</span>
        </NavLink>
      </div>
    </nav>
  );
}
