import { classNames } from '@/utils';
import type { ReactNode } from 'react';

interface BadgeProps {
  children: ReactNode;
  variant?: 'default' | 'success' | 'warning' | 'danger' | 'info' | 'neutral' | 'accent';
  size?: 'sm' | 'md';
  dot?: boolean;
}

const variants: Record<string, string> = {
  default: 'bg-navy-100 text-navy-700',
  success: 'bg-teal-100 text-teal-700',
  warning: 'bg-amber-100 text-amber-700',
  danger: 'bg-red-100 text-red-700',
  info: 'bg-indigo-100 text-indigo-700',
  neutral: 'bg-gray-100 text-gray-600',
  accent: 'bg-cyan-100 text-cyan-700',
};

const dotColors: Record<string, string> = {
  default: 'bg-navy-400',
  success: 'bg-teal-500',
  warning: 'bg-amber-500',
  danger: 'bg-red-500',
  info: 'bg-indigo-500',
  neutral: 'bg-gray-400',
  accent: 'bg-cyan-500',
};

export function Badge({ children, variant = 'default', size = 'sm', dot = false }: BadgeProps) {
  return (
    <span
      className={classNames(
        'inline-flex items-center gap-1.5 rounded-full font-medium',
        size === 'sm' ? 'px-2.5 py-0.5 text-xs' : 'px-3 py-1 text-sm',
        variants[variant],
      )}
    >
      {dot && <span className={classNames('h-1.5 w-1.5 rounded-full', dotColors[variant])} />}
      {children}
    </span>
  );
}
