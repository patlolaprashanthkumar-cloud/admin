import { GraduationCap } from 'lucide-react';

interface LogoProps {
  size?: 'sm' | 'md' | 'lg';
  variant?: 'light' | 'dark';
}

const sizes = {
  sm: { icon: 18, box: 'h-8 w-8 rounded-xl', text: 'text-base', sub: 'text-[9px]' },
  md: { icon: 20, box: 'h-10 w-10 rounded-2xl', text: 'text-lg', sub: 'text-[10px]' },
  lg: { icon: 26, box: 'h-12 w-12 rounded-2xl', text: 'text-2xl', sub: 'text-xs' },
};

export function Logo({ size = 'md', variant = 'light' }: LogoProps) {
  const s = sizes[size];
  const isLight = variant === 'light';

  return (
    <div className="flex items-center gap-2.5 group">
      <span
        className={`grid ${s.box} place-items-center shrink-0 ${
          isLight
            ? 'bg-forest-500 text-white shadow-xs border border-forest-400/30'
            : 'bg-[#102A43] text-[#FFF7F1] shadow-xs'
        } transition-transform duration-300 group-hover:scale-105 group-hover:bg-[#FF8E53]`}
      >
        <GraduationCap size={s.icon} />
      </span>
      <div className="flex flex-col leading-tight">
        <span
          className={`font-display font-bold tracking-tight ${s.text} ${
            isLight ? 'text-white' : 'text-[#102A43]'
          }`}
        >
          IIECM
        </span>
        <span className={`${s.sub} font-semibold uppercase tracking-wider text-[#FF8E53]`}>
          Admin Portal
        </span>
      </div>
    </div>
  );
}
