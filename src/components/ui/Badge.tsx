import { classNames } from '@/utils';
import type { ReactNode } from 'react';

interface BadgeProps {
  children: ReactNode;
  variant?: 'default' | 'success' | 'warning' | 'danger' | 'info' | 'neutral' | 'accent' | 'forest' | 'peach' | 'sage';
  size?: 'sm' | 'md';
  dot?: boolean;
}

const variants: Record<string, string> = {
  default: 'bg-navy-100/90 text-navy-800 border border-navy-200/80 shadow-2xs',
  success: 'bg-forest-50 text-forest-700 border border-forest-200/70 shadow-2xs',
  warning: 'bg-peach-50 text-peach-800 border border-peach-200/70 shadow-2xs',
  danger: 'bg-red-50 text-red-700 border border-red-200/70 shadow-2xs',
  info: 'bg-navy-50 text-navy-800 border border-navy-200/70 shadow-2xs',
  neutral: 'bg-gray-100 text-gray-700 border border-gray-200/70 shadow-2xs',
  accent: 'bg-saffron-50 text-saffron-800 border border-saffron-200/70 shadow-2xs',
  forest: 'bg-forest-50 text-forest-700 border border-forest-200/70 shadow-2xs',
  peach: 'bg-peach-50 text-peach-800 border border-peach-200/70 shadow-2xs',
  sage: 'bg-sage-100 text-forest-800 border border-sage-200 shadow-2xs',
};

const dotColors: Record<string, string> = {
  default: 'bg-navy-400',
  success: 'bg-forest-500 shadow-glow-forest',
  warning: 'bg-peach-500 shadow-glow-peach',
  danger: 'bg-red-500',
  info: 'bg-navy-500',
  neutral: 'bg-gray-400',
  accent: 'bg-saffron-500',
  forest: 'bg-forest-500 shadow-glow-forest',
  peach: 'bg-peach-500 shadow-glow-peach',
  sage: 'bg-forest-600',
};

export function Badge({ children, variant = 'default', size = 'sm', dot = false }: BadgeProps) {
  return (
    <span
      className={classNames(
        'inline-flex items-center gap-1.5 rounded-full font-semibold transition-all',
        size === 'sm' ? 'px-2.5 py-0.5 text-[11px]' : 'px-3 py-1 text-xs',
        variants[variant],
      )}
    >
      {dot && <span className={classNames('h-1.5 w-1.5 rounded-full shrink-0', dotColors[variant])} />}
      {children}
    </span>
  );
}
