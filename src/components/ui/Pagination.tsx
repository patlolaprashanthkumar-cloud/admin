import { ChevronLeft, ChevronRight } from 'lucide-react';
import { classNames } from '@/utils';

interface PaginationProps {
  currentPage: number;
  totalPages: number;
  onPageChange: (page: number) => void;
  total?: number;
  perPage?: number;
}

export function Pagination({ currentPage, totalPages, onPageChange, total, perPage }: PaginationProps) {
  if (totalPages <= 1) return null;
  const start = (currentPage - 1) * (perPage ?? 0) + 1;
  const end = Math.min(currentPage * (perPage ?? 0), total ?? 0);

  return (
    <div className="flex items-center justify-between border-t border-navy-100 px-4 py-3">
      <p className="text-xs text-navy-500">
        {total != null && perPage != null ? `Showing ${start}–${end} of ${total}` : `Page ${currentPage} of ${totalPages}`}
      </p>
      <div className="flex items-center gap-1">
        <button
          onClick={() => onPageChange(currentPage - 1)}
          disabled={currentPage <= 1}
          className="rounded-lg p-1.5 text-navy-500 hover:bg-navy-100 disabled:opacity-30 disabled:cursor-not-allowed transition-colors"
        >
          <ChevronLeft size={18} />
        </button>
        {Array.from({ length: totalPages }, (_, i) => i + 1)
          .filter((p) => p === 1 || p === totalPages || Math.abs(p - currentPage) <= 1)
          .map((page, idx, arr) => (
            <span key={page} className="flex items-center">
              {idx > 0 && arr[idx - 1] !== page - 1 && <span className="px-1 text-navy-300">…</span>}
              <button
                onClick={() => onPageChange(page)}
                className={classNames(
                  'min-w-[32px] rounded-lg px-2 py-1.5 text-sm font-medium transition-colors',
                  page === currentPage ? 'bg-navy-800 text-white' : 'text-navy-600 hover:bg-navy-100',
                )}
              >
                {page}
              </button>
            </span>
          ))}
        <button
          onClick={() => onPageChange(currentPage + 1)}
          disabled={currentPage >= totalPages}
          className="rounded-lg p-1.5 text-navy-500 hover:bg-navy-100 disabled:opacity-30 disabled:cursor-not-allowed transition-colors"
        >
          <ChevronRight size={18} />
        </button>
      </div>
    </div>
  );
}
