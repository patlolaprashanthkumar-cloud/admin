import { initials, classNames } from '@/utils';

interface AvatarProps {
  name: string;
  src?: string;
  size?: 'xs' | 'sm' | 'md' | 'lg';
  className?: string;
}

const sizes = { xs: 'h-6 w-6 text-[10px]', sm: 'h-8 w-8 text-xs', md: 'h-10 w-10 text-sm', lg: 'h-14 w-14 text-base' };

const colors = [
  'bg-navy-600 text-white', 'bg-indigo-600 text-white', 'bg-teal-600 text-white',
  'bg-cyan-600 text-white', 'bg-amber-600 text-white', 'bg-navy-700 text-white',
];

function colorFor(name: string) {
  const hash = name.split('').reduce((a, c) => a + c.charCodeAt(0), 0);
  return colors[hash % colors.length];
}

export function Avatar({ name, src, size = 'sm', className }: AvatarProps) {
  if (src) return <img src={src} alt={name} className={classNames('rounded-full object-cover', sizes[size], className)} />;
  return (
    <div className={classNames('flex items-center justify-center rounded-full font-semibold', sizes[size], colorFor(name), className)}>
      {initials(name)}
    </div>
  );
}
