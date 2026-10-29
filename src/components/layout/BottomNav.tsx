import { NavLink } from 'react-router-dom';
import { mobileNavItems } from '@/components/navigation/nav-config';
import { classNames } from '@/utils';

export function BottomNav() {
  return (
    <nav className="lg:hidden fixed bottom-3 left-4 right-4 z-30 bg-white/90 backdrop-blur-2xl border border-navy-100/90 rounded-2xl shadow-floating safe-area-bottom p-1.5">
      <div className="flex items-center justify-around h-14">
        {mobileNavItems.map((item) => (
          <NavLink
            key={item.to}
            to={item.to}
            className={({ isActive }) =>
              classNames(
                'flex flex-col items-center justify-center gap-1 px-3 py-1.5 rounded-xl text-[10px] font-semibold transition-all duration-200',
                isActive
                  ? 'bg-forest-50 text-forest-700 shadow-xs scale-105'
                  : 'text-navy-400 hover:text-navy-700',
              )
            }
          >
            <item.icon size={20} className="shrink-0" />
            <span>{item.label}</span>
          </NavLink>
        ))}
      </div>
    </nav>
  );
}
