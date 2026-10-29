import type { ReactNode } from 'react';
import { Link } from 'react-router-dom';
import { ArrowRight } from 'lucide-react';
import { classNames } from '@/utils';

interface StatCardProps {
  label: string;
  value: string | number;
  icon: ReactNode;
  trend?: { value: string; positive: boolean };
  accent?: 'navy' | 'teal' | 'amber' | 'indigo' | 'cyan' | 'red' | 'info' | 'success' | 'warning' | 'forest' | 'peach' | 'saffron' | 'sage';
  to?: string;
}

const accents: Record<string, string> = {
  navy: 'bg-navy-100 text-navy-800 shadow-xs border border-navy-200/50',
  teal: 'bg-forest-100 text-forest-700 shadow-xs border border-forest-200/50',
  amber: 'bg-peach-100 text-peach-700 shadow-xs border border-peach-200/50',
  indigo: 'bg-forest-100 text-forest-700 shadow-xs border border-forest-200/50',
  cyan: 'bg-sage-200 text-forest-800 shadow-xs border border-sage-300/50',
  sage: 'bg-sage-200 text-forest-800 shadow-xs border border-sage-300/50',
  red: 'bg-red-100 text-red-700 shadow-xs border border-red-200/50',
  info: 'bg-navy-100 text-navy-800 shadow-xs border border-navy-200/50',
  success: 'bg-forest-100 text-forest-700 shadow-xs border border-forest-200/50',
  warning: 'bg-peach-100 text-peach-700 shadow-xs border border-peach-200/50',
  forest: 'bg-forest-100 text-forest-700 shadow-xs border border-forest-200/50',
  peach: 'bg-peach-100 text-peach-700 shadow-xs border border-peach-200/50',
  saffron: 'bg-saffron-100 text-saffron-700 shadow-xs border border-saffron-200/50',
};

export function StatCard({ label, value, icon, trend, accent = 'navy', to }: StatCardProps) {
  const content = (
    <div
      className={classNames(
        'card-3d card-hover p-5 relative overflow-hidden group',
        to && 'cursor-pointer',
      )}
    >
      {/* Top subtle lighting rim */}
      <div className="absolute top-0 left-0 right-0 h-[1px] bg-gradient-to-r from-transparent via-white to-transparent" />

      <div className="flex items-start justify-between gap-3">
        <div className="min-w-0 flex-1">
          <p className="text-xs font-bold uppercase tracking-wider text-navy-500 truncate">
            {label}
          </p>
          <p className="mt-1.5 text-2xl sm:text-3xl font-extrabold text-navy-900 font-display tracking-tight">
            {value}
          </p>
          {trend && (
            <div className="mt-2 flex items-center gap-1.5">
              <span
                className={classNames(
                  'inline-flex items-center gap-0.5 rounded-full px-2 py-0.5 text-[11px] font-bold shadow-2xs',
                  trend.positive
                    ? 'bg-forest-50 text-forest-700 border border-forest-200/60'
                    : 'bg-red-50 text-red-700 border border-red-200/60',
                )}
              >
                {trend.positive ? '↑' : '↓'} {trend.value}
              </span>
            </div>
          )}
        </div>
        <div
          className={classNames(
            'flex size-11 shrink-0 items-center justify-center rounded-xl transition-transform duration-300 group-hover:scale-110 group-hover:-translate-y-0.5',
            accents[accent],
          )}
        >
          {icon}
        </div>
      </div>

      {to && (
        <div className="mt-3.5 pt-3 border-t border-navy-100/60 flex items-center gap-1 text-xs font-bold text-forest-600 group-hover:text-forest-700">
          <span>View details</span>
          <ArrowRight
            size={13}
            className="transition-transform duration-200 group-hover:translate-x-1"
          />
        </div>
      )}
    </div>
  );
  return to ? <Link to={to}>{content}</Link> : content;
}

interface CardProps {
  children: ReactNode;
  className?: string;
  title?: string;
  subtitle?: string;
  action?: ReactNode;
}

export function Card({ children, className, title, subtitle, action }: CardProps) {
  return (
    <div className={classNames('card-3d relative overflow-hidden', className)}>
      {/* Top subtle lighting rim */}
      <div className="absolute top-0 left-0 right-0 h-[1px] bg-gradient-to-r from-transparent via-white to-transparent" />

      {(title || action) && (
        <div className="flex items-center justify-between border-b border-navy-100/80 px-5 py-4 bg-gradient-to-r from-navy-50/40 via-white to-white">
          <div>
            {title && (
              <h3 className="text-sm font-bold text-navy-900 font-display tracking-tight">
                {title}
              </h3>
            )}
            {subtitle && <p className="text-xs text-navy-500 mt-0.5">{subtitle}</p>}
          </div>
          {action}
        </div>
      )}
      {children}
    </div>
  );
}
