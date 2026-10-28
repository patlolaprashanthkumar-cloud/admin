import type { ReactNode } from 'react';
import { Link } from 'react-router-dom';
import { ArrowRight } from 'lucide-react';
import { classNames } from '@/utils';

interface StatCardProps {
  label: string;
  value: string | number;
  icon: ReactNode;
  trend?: { value: string; positive: boolean };
  accent?: 'navy' | 'teal' | 'amber' | 'indigo' | 'cyan' | 'red' | 'info' | 'success' | 'warning';
  to?: string;
}

const accents: Record<string, string> = {
  navy: 'bg-navy-100 text-navy-700',
  teal: 'bg-teal-100 text-teal-700',
  amber: 'bg-amber-100 text-amber-700',
  indigo: 'bg-indigo-100 text-indigo-700',
  cyan: 'bg-cyan-100 text-cyan-700',
  red: 'bg-red-100 text-red-700',
  info: 'bg-indigo-100 text-indigo-700',
  success: 'bg-teal-100 text-teal-700',
  warning: 'bg-amber-100 text-amber-700',
};

export function StatCard({ label, value, icon, trend, accent = 'navy', to }: StatCardProps) {
  const content = (
    <div className={classNames('card card-hover p-4', to && 'cursor-pointer')}>
      <div className="flex items-start justify-between">
        <div className="min-w-0">
          <p className="text-xs font-medium text-navy-500 uppercase tracking-wide">{label}</p>
          <p className="mt-1 text-2xl font-bold text-navy-900 font-display">{value}</p>
          {trend && (
            <p className={classNames('mt-1 text-xs font-medium', trend.positive ? 'text-teal-600' : 'text-red-500')}>
              {trend.positive ? '↑' : '↓'} {trend.value}
            </p>
          )}
        </div>
        <div className={classNames('flex h-10 w-10 shrink-0 items-center justify-center rounded-lg', accents[accent])}>
          {icon}
        </div>
      </div>
      {to && (
        <div className="mt-3 flex items-center gap-1 text-xs font-medium text-indigo-600">
          View all <ArrowRight size={12} />
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
    <div className={classNames('card', className)}>
      {(title || action) && (
        <div className="flex items-center justify-between border-b border-navy-100 px-5 py-3.5">
          <div>
            {title && <h3 className="text-sm font-semibold text-navy-900">{title}</h3>}
            {subtitle && <p className="text-xs text-navy-500 mt-0.5">{subtitle}</p>}
          </div>
          {action}
        </div>
      )}
      {children}
    </div>
  );
}
