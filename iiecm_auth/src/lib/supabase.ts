import { createClient, type SupabaseClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL as string | undefined;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY as string | undefined;

/**
 * Checks whether the Supabase client has been provided with runtime environment variables.
 */
export const isSupabaseConfigured: boolean = Boolean(
  supabaseUrl &&
  supabaseUrl.trim().length > 0 &&
  supabaseAnonKey &&
  supabaseAnonKey.trim().length > 0
);

/**
 * Shared storage key used for persisting session data and PKCE code verifiers.
 */
export const STORAGE_KEY = 'iiecm-auth-session';

export interface InitialPkceState {
  code: string | null;
  hasVerifier: boolean;
}

/**
 * Synchronously captures initial URL authorization code and PKCE verifier state
 * BEFORE createClient() starts automatic initialization and potentially strips
 * the URL parameter or consumes the verifier from storage.
 */
export const initialPkceState: InitialPkceState = (() => {
  if (typeof window === 'undefined') {
    return { code: null, hasVerifier: false };
  }

  const searchParams = new URLSearchParams(window.location.search);
  const code = searchParams.get('code') || null;

  let hasVerifier = false;
  try {
    hasVerifier = Boolean(window.localStorage?.getItem(`${STORAGE_KEY}-code-verifier`));
  } catch {
    hasVerifier = false;
  }

  return { code, hasVerifier };
})();

/**
 * Public client instance for authentication sessions.
 * Configured with automatic URL session detection for invitation and password recovery tokens.
 * Service-role keys are strictly forbidden in client-side code.
 */
export const supabase: SupabaseClient | null = isSupabaseConfigured
  ? createClient(supabaseUrl!, supabaseAnonKey!, {
      auth: {
        persistSession: true,
        autoRefreshToken: true,
        detectSessionInUrl: true,
        storageKey: STORAGE_KEY,
      },
    })
  : null;

