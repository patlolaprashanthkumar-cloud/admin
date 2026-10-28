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
      return () => { document.body.style.overflow = ''; };
    }
  }, [open]);

  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center p-0 sm:p-4">
      <div className="absolute inset-0 bg-navy-950/50 backdrop-blur-sm animate-fade-in" onClick={onClose} />
      <div className={classNames(
        'relative w-full bg-white rounded-t-2xl sm:rounded-2xl shadow-elevated animate-slide-up max-h-[90vh] flex flex-col',
        sizeMap[size],
      )}>
        {title && (
          <div className="flex items-center justify-between border-b border-navy-100 px-5 py-4">
            <h2 className="text-base font-semibold text-navy-900">{title}</h2>
            <button onClick={onClose} className="rounded-lg p-1.5 text-navy-400 hover:bg-navy-100 hover:text-navy-700 transition-colors">
              <X size={20} />
            </button>
          </div>
        )}
        <div className="overflow-y-auto px-5 py-4 flex-1">{children}</div>
        {footer && <div className="border-t border-navy-100 px-5 py-3 flex justify-end gap-2">{footer}</div>}
      </div>
    </div>
  );
}
