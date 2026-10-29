/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        // IIECM Official Navy Palette (Reference: iiecm.org)
        navy: {
          50: '#f0f4f8',
          100: '#d9e2ec',
          200: '#bcccdc',
          300: '#829ab1', // --navy-subtle
          400: '#627d98',
          500: '#486581', // --navy-muted
          600: '#334e68',
          700: '#243b53',
          800: '#102a43', // --navy
          900: '#0b1d30',
          950: '#061320',
        },
        // IIECM Official Forest Green (Primary Brand & Institution)
        forest: {
          50: '#ebf5f3',
          100: '#d2ece6',
          200: '#a6dacd',
          300: '#79c8b4',
          400: '#3e9e88',
          500: '#064b3e', // --forest & --primary
          600: '#053f34',
          700: '#043229',
          800: '#03251f',
          900: '#021814',
          950: '#010c0a',
        },
        // IIECM Official Saffron (Accent & Highlights)
        saffron: {
          50: '#fdf6f3',
          100: '#fbece6',
          200: '#f6d5ca',
          300: '#f0bdae',
          400: '#e58e75',
          500: '#c76543', // --saffron & --accent
          600: '#b35535',
          700: '#954226',
          800: '#78341e',
          900: '#5c2716',
        },
        // IIECM Official Peach (CTA & Active Accent)
        peach: {
          50: '#fff7f2',
          100: '#fff0e6', // --peach-light
          200: '#ffd9c2', // --peach-border
          300: '#ffbe99',
          400: '#ffa570',
          500: '#ff8e53', // --peach
          600: '#e66a2b', // --peach-dark
          700: '#bf4f19',
          800: '#993c12',
          900: '#7a2e0e',
        },
        // IIECM Official Sage (Secondary Tones & Badges)
        sage: {
          50: '#f8faf6',
          100: '#f0f4ec',
          200: '#dde2d0', // --sage & --secondary
          300: '#c5ceb3',
          400: '#abb795',
          500: '#8e9f76',
          600: '#718b7c', // --muted-green
          700: '#586f62',
          800: '#415349',
          900: '#2b3831',
        },
        // Mapped indigo -> IIECM Forest Green for seamless project-wide brand alignment
        indigo: {
          50: '#ebf5f3',
          100: '#d2ece6',
          200: '#a6dacd',
          300: '#79c8b4',
          400: '#3e9e88',
          500: '#064b3e',
          600: '#064b3e', // IIECM Primary Forest Green
          700: '#043b31',
          800: '#032b24',
          900: '#021c17',
        },
        // IIECM Specialized Brand Surfaces
        paper: '#f5f1e6',
        cream: {
          DEFAULT: '#fff7f1',
          card: '#ffffff',
        },
        'soft-white': '#fffdf7',
        ink: {
          DEFAULT: '#173f3d',
          foreground: '#f5f1e6',
        },
        // Teal aligned to IIECM botanical greens
        teal: {
          50: '#f2f7f5',
          100: '#ddece6',
          200: '#bdd8ce',
          300: '#94c0b1',
          400: '#718b7c', // --muted-green
          500: '#064b3e',
          600: '#053f34',
          700: '#043229',
          800: '#03251f',
          900: '#021814',
        },
        // Amber aligned to IIECM Warm Saffron & Peach
        amber: {
          50: '#fff7f2',
          100: '#fff0e6',
          200: '#ffd9c2',
          300: '#ffbe99',
          400: '#ffa570',
          500: '#ff8e53', // --peach
          600: '#e66a2b',
          700: '#c76543', // --saffron
          800: '#954226',
          900: '#78341e',
        },
      },
      fontFamily: {
        sans: ['Manrope', 'Inter', 'system-ui', '-apple-system', 'sans-serif'],
        display: ['Fraunces', 'Plus Jakarta Sans', 'serif'],
      },
      boxShadow: {
        xs: '0 1px 2px 0 rgb(16 42 67 / 0.05)',
        card: '0 1px 3px 0 rgb(16 42 67 / 0.06), 0 1px 2px -1px rgb(16 42 67 / 0.04)',
        'card-hover': '0 4px 12px -2px rgb(16 42 67 / 0.08), 0 2px 6px -2px rgb(16 42 67 / 0.04)',
        elevated: '0 10px 30px -10px rgb(16 42 67 / 0.14), 0 4px 12px -4px rgb(16 42 67 / 0.06)',
        soft: '0 1px 2px #173f3d0f, 0 12px 32px -12px #173f3d33',
        // 3D Shadow Variations
        '3d': '0 2px 4px -1px rgba(16, 42, 67, 0.06), 0 8px 16px -2px rgba(16, 42, 67, 0.08), inset 0 1px 0 rgba(255, 255, 255, 0.9)',
        '3d-hover': '0 12px 28px -4px rgba(16, 42, 67, 0.12), 0 6px 12px -2px rgba(16, 42, 67, 0.06), inset 0 1px 0 rgba(255, 255, 255, 1)',
        '3d-btn': '0 4px 0 0 #03251f, 0 6px 12px rgba(6, 75, 62, 0.25)',
        '3d-btn-peach': '0 4px 0 0 #bf4f19, 0 6px 12px rgba(255, 142, 83, 0.3)',
        glass: '0 8px 32px 0 rgba(16, 42, 67, 0.08), inset 0 1px 1px 0 rgba(255, 255, 255, 0.9)',
        floating: '0 16px 36px -6px rgba(16, 42, 67, 0.16), 0 6px 12px -2px rgba(16, 42, 67, 0.08)',
        'glow-forest': '0 0 24px -4px rgba(6, 75, 62, 0.35)',
        'glow-peach': '0 0 24px -4px rgba(255, 142, 83, 0.4)',
      },
      borderRadius: {
        xl: '0.875rem',
        '2xl': '1.25rem',
        '3xl': '1.5rem',
      },
      animation: {
        'fade-in': 'fadeIn 0.25s ease-out',
        'slide-up': 'slideUp 0.3s cubic-bezier(0.16, 1, 0.3, 1)',
        'slide-down': 'slideDown 0.3s cubic-bezier(0.16, 1, 0.3, 1)',
        'scale-in': 'scaleIn 0.2s cubic-bezier(0.16, 1, 0.3, 1)',
        float: 'float 3s ease-in-out infinite',
        shimmer: 'shimmer 2s linear infinite',
      },
      keyframes: {
        fadeIn: { '0%': { opacity: '0' }, '100%': { opacity: '1' } },
        slideUp: { '0%': { opacity: '0', transform: 'translateY(10px)' }, '100%': { opacity: '1', transform: 'translateY(0)' } },
        slideDown: { '0%': { opacity: '0', transform: 'translateY(-10px)' }, '100%': { opacity: '1', transform: 'translateY(0)' } },
        scaleIn: { '0%': { opacity: '0', transform: 'scale(0.96)' }, '100%': { opacity: '1', transform: 'scale(1)' } },
        float: {
          '0%, 100%': { transform: 'translateY(0px)' },
          '50%': { transform: 'translateY(-6px)' },
        },
        shimmer: {
          '0%': { backgroundPosition: '-200% 0' },
          '100%': { backgroundPosition: '200% 0' },
        },
      },
    },
  },
  plugins: [],
};
