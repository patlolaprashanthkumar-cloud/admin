import { GraduationCap } from 'lucide-react';

interface LogoProps {
  size?: 'sm' | 'md' | 'lg';
  variant?: 'light' | 'dark';
}

const sizes = {
  sm: { icon: 20, text: 'text-base', sub: 'text-[9px]' },
  md: { icon: 24, text: 'text-lg', sub: 'text-[10px]' },
  lg: { icon: 32, text: 'text-2xl', sub: 'text-xs' },
};

export function Logo({ size = 'md', variant = 'light' }: LogoProps) {
  const s = sizes[size];
  return (
    <div className="flex items-center gap-2.5">
      <div className={`flex items-center justify-center rounded-lg ${variant === 'light' ? 'bg-indigo-600' : 'bg-white/10'} text-white`}>
        <GraduationCap size={s.icon} className="m-1.5" />
      </div>
      <div className="leading-tight">
        <p className={`font-display font-bold ${s.text} ${variant === 'light' ? 'text-white' : 'text-navy-900'}`}>
          IIECM
        </p>
        <p className={`${s.sub} font-medium uppercase tracking-wider ${variant === 'light' ? 'text-navy-300' : 'text-navy-500'}`}>
          Admin Portal
        </p>
      </div>
    </div>
  );
}
