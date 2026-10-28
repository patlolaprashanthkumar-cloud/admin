import { Search, Filter } from 'lucide-react';
import { classNames } from '@/utils';

interface SearchBarProps {
  value: string;
  onChange: (v: string) => void;
  placeholder?: string;
  className?: string;
}

export function SearchBar({ value, onChange, placeholder = 'Search...', className }: SearchBarProps) {
  return (
    <div className={classNames('relative', className)}>
      <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-navy-400" />
      <input
        type="text"
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        className="input-base pl-9"
      />
    </div>
  );
}

interface FilterBarProps {
  children: React.ReactNode;
  className?: string;
}

export function FilterBar({ children, className }: FilterBarProps) {
  return (
    <div className={classNames('flex flex-wrap items-center gap-3', className)}>
      <div className="flex items-center gap-1.5 text-xs font-medium text-navy-500">
        <Filter size={14} /> Filters
      </div>
      {children}
    </div>
  );
}
