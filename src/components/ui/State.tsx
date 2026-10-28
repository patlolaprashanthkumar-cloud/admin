import type { ReactNode } from 'react';
import { Inbox } from 'lucide-react';
import { classNames } from '@/utils';

interface EmptyStateProps {
  icon?: ReactNode;
  title: string;
  description?: string;
  action?: ReactNode;
  className?: string;
}

export function EmptyState({ icon, title, description, action, className }: EmptyStateProps) {
  return (
    <div className={classNames('flex flex-col items-center justify-center py-12 px-4 text-center', className)}>
      <div className="flex h-14 w-14 items-center justify-center rounded-full bg-navy-100 text-navy-400">
        {icon ?? <Inbox size={26} />}
      </div>
      <h3 className="mt-4 text-sm font-semibold text-navy-800">{title}</h3>
      {description && <p className="mt-1 text-sm text-navy-500 max-w-sm">{description}</p>}
      {action && <div className="mt-4">{action}</div>}
    </div>
  );
}

interface LoadingStateProps {
  message?: string;
}

export function LoadingState({ message = 'Loading...' }: LoadingStateProps) {
  return (
    <div className="flex flex-col items-center justify-center py-12">
      <div className="h-8 w-8 animate-spin rounded-full border-2 border-navy-200 border-t-indigo-600" />
      <p className="mt-3 text-sm text-navy-500">{message}</p>
    </div>
  );
}

interface ErrorStateProps {
  message: string;
  onRetry?: () => void;
}

export function ErrorState({ message, onRetry }: ErrorStateProps) {
  return (
    <div className="flex flex-col items-center justify-center py-12 px-4 text-center">
      <div className="flex h-14 w-14 items-center justify-center rounded-full bg-red-100 text-red-500">
        <span className="text-xl">!</span>
      </div>
      <h3 className="mt-4 text-sm font-semibold text-navy-800">Something went wrong</h3>
      <p className="mt-1 text-sm text-navy-500">{message}</p>
      {onRetry && <button className="btn-secondary mt-4" onClick={onRetry}>Try again</button>}
    </div>
  );
}
