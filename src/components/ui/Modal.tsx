import type { ReactNode } from 'react';
import { X } from 'lucide-react';
import { useEffect } from 'react';
import { classNames } from '@/utils';

interface ModalProps {
  open: boolean;
  onClose: () => void;
  title?: string;
  children: ReactNode;
  size?: 'sm' | 'md' | 'lg' | 'xl';
  footer?: ReactNode;
}

const sizeMap = { sm: 'max-w-md', md: 'max-w-lg', lg: 'max-w-2xl', xl: 'max-w-4xl' };

export function Modal({ open, onClose, title, children, size = 'md', footer }: ModalProps) {
  useEffect(() => {
    if (open) {
      document.body.style.overflow = 'hidden';
      return () => {
        document.body.style.overflow = '';
      };
    }
  }, [open]);

  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center p-0 sm:p-4">
      <div
        className="absolute inset-0 bg-navy-950/60 backdrop-blur-md animate-fade-in transition-opacity"
        onClick={onClose}
      />
      <div
        className={classNames(
          'relative w-full bg-white rounded-t-3xl sm:rounded-3xl shadow-floating border border-navy-100/90 animate-scale-in max-h-[90vh] flex flex-col overflow-hidden',
          sizeMap[size],
        )}
      >
        {/* Top lighting reflection */}
        <div className="absolute top-0 left-0 right-0 h-1 bg-gradient-to-r from-forest-500 via-saffron-500 to-peach-500" />

        {title && (
          <div className="flex items-center justify-between border-b border-navy-100/80 px-6 py-4.5 bg-gradient-to-r from-navy-50/50 to-white">
            <h2 className="text-base font-bold text-navy-900 font-display tracking-tight">{title}</h2>
            <button
              onClick={onClose}
              className="rounded-xl p-1.5 text-navy-400 hover:bg-navy-100 hover:text-navy-700 transition-colors"
            >
              <X size={18} />
            </button>
          </div>
        )}
        <div className="overflow-y-auto px-6 py-5 flex-1 scrollbar-thin">{children}</div>
        {footer && (
          <div className="border-t border-navy-100/80 px-6 py-3.5 flex justify-end gap-2.5 bg-navy-50/40">
            {footer}
          </div>
        )}
      </div>
    </div>
  );
}
