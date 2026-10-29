import { createContext, useContext, useState, useEffect, useCallback, type ReactNode } from 'react';
import type { AdminUser } from '@/types';
import { signIn, signOut, isDemoMode } from '@/services/supabase/auth';

interface AuthContextValue {
  user: AdminUser | null;
  loading: boolean;
  demoMode: boolean;
  login: (email: string, password: string) => Promise<{ error?: string }>;
  logout: () => Promise<void>;
  updateUser: (patch: Partial<AdminUser>) => void;
}

// Preserve context across Vite Fast Refresh / HMR reloads
const globalAuth = globalThis as unknown as {
  __IIECM_AUTH_CONTEXT__?: React.Context<AuthContextValue | undefined>;
};

if (!globalAuth.__IIECM_AUTH_CONTEXT__) {
  globalAuth.__IIECM_AUTH_CONTEXT__ = createContext<AuthContextValue | undefined>(undefined);
}

const AuthContext = globalAuth.__IIECM_AUTH_CONTEXT__;

const STORAGE_KEY = 'iiecm-admin-auth';

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<AdminUser | null>(null);
  const [loading, setLoading] = useState(true);
  const demoMode = isDemoMode();

  useEffect(() => {
    if (demoMode) {
      try {
        const stored = localStorage.getItem(STORAGE_KEY);
        if (stored) setUser(JSON.parse(stored));
      } catch {
        /* ignore */
      }
    }
    setLoading(false);
  }, [demoMode]);

  const login = useCallback(
    async (email: string, password: string) => {
      const result = await signIn(email, password);
      if (result.user) {
        setUser(result.user);
        // Clear any leftover demo data from local storage if present
        if (!demoMode) {
          localStorage.removeItem(STORAGE_KEY);
        }
        // Store demo user locally only in demo mode
        if (demoMode) localStorage.setItem(STORAGE_KEY, JSON.stringify(result.user));
        return {};
      }
      return { error: result.error };
    },
    [demoMode]
  );

  const logout = useCallback(async () => {
    await signOut();
    setUser(null);
    localStorage.removeItem(STORAGE_KEY);
  }, []);

  const updateUser = useCallback(
    (patch: Partial<AdminUser>) => {
      setUser((prev) => {
        if (!prev) return prev;
        const next = { ...prev, ...patch };
        if (demoMode) localStorage.setItem(STORAGE_KEY, JSON.stringify(next));
        return next;
      });
    },
    [demoMode]
  );

  return (
    <AuthContext.Provider value={{ user, loading, demoMode, login, logout, updateUser }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) {
    // Provide safe fallback during HMR or initialization transitions
    return {
      user: null,
      loading: false,
      demoMode: isDemoMode(),
      login: async (email, password) => {
        const result = await signIn(email, password);
        return { error: result.error };
      },
      logout: async () => {
        await signOut();
      },
      updateUser: () => {},
    };
  }
  return ctx;
}
