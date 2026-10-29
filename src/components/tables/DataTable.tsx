import type { ReactNode } from 'react';
import { classNames } from '@/utils';

interface TableColumn<T> {
  key: string;
  header: string;
  render?: (item: T) => ReactNode;
  className?: string;
  hideOnMobile?: boolean;
}

interface DataTableProps<T> {
  columns: TableColumn<T>[];
  data: T[];
  onRowClick?: (item: T) => void;
  emptyState?: ReactNode;
  rowKey: (item: T) => string;
}

export function DataTable<T>({ columns, data, onRowClick, emptyState, rowKey }: DataTableProps<T>) {
  if (data.length === 0 && emptyState) return <div className="animate-fade-in">{emptyState}</div>;

  return (
    <div className="overflow-x-auto scrollbar-thin">
      <table className="w-full">
        <thead>
          <tr className="border-b border-navy-100 bg-gradient-to-r from-navy-50/70 via-navy-50/40 to-navy-50/70">
            {columns.map((col) => (
              <th
                key={col.key}
                className={classNames(
                  'table-header whitespace-nowrap',
                  col.hideOnMobile && 'hidden sm:table-cell',
                  col.className,
                )}
              >
                {col.header}
              </th>
            ))}
          </tr>
        </thead>
        <tbody className="divide-y divide-navy-50">
          {data.map((item) => (
            <tr
              key={rowKey(item)}
              onClick={() => onRowClick?.(item)}
              className={classNames(
                'transition-all duration-150 hover:bg-forest-50/40 group',
                onRowClick && 'cursor-pointer',
              )}
            >
              {columns.map((col) => (
                <td
                  key={col.key}
                  className={classNames(
                    'table-cell align-middle',
                    col.hideOnMobile && 'hidden sm:table-cell',
                    col.className,
                  )}
                >
                  {col.render ? col.render(item) : String((item as Record<string, unknown>)[col.key] ?? '')}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
