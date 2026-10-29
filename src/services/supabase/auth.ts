import { supabase, isSupabaseConfigured } from './client';
import type { AdminUser, UserRole } from '@/types';
import { demoAdmin } from '@/mock-data';

export interface AuthResult {
  user: AdminUser | null;
  error?: string;
}

export const DEMO_CREDENTIALS = {
  email: 'admin@iiecm.org',
  password: 'admin123',
};

export function isDemoMode(): boolean {
  return !isSupabaseConfigured;
}

export async function signIn(email: string, password: string): Promise<AuthResult> {
  // Explicit demo mode check
  if (isDemoMode()) {
    await new Promise((r) => setTimeout(r, 600));
    if (email.trim().toLowerCase() === DEMO_CREDENTIALS.email && password === DEMO_CREDENTIALS.password) {
      return { user: { ...demoAdmin, lastLoginAt: new Date().toISOString() } };
    }
    return {
      user: null,
      error: 'Invalid credentials. If signing in with your Supabase account, please configure VITE_SUPABASE_URL and VITE_SUPABASE_PUBLISHABLE_KEY in .env.local and restart Vite. (For offline demo mode, use admin@iiecm.org / admin123).',
    };
  }

  // Supabase Production Auth Mode: Never silently fall back to demo mode on failure
  if (!supabase) {
    return { user: null, error: 'Authentication service not available. Check your Supabase configuration.' };
  }

  const { data, error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) {
    return { user: null, error: error.message };
  }
  if (!data.user) {
    return { user: null, error: 'No user returned from authentication provider.' };
  }

  // Attempt to read authoritative role and profile details from public.profiles
  let userRole: UserRole = (data.user.user_metadata?.role as UserRole) || 'admin';
  let fullName = data.user.user_metadata?.full_name || data.user.email || 'Administrator';
  let phone = data.user.user_metadata?.phone;

  try {
    const { data: profile } = (await supabase
      .from('profiles')
      .select('role, full_name, phone')
      .eq('id', data.user.id)
      .single()) as { data: any; error: any };

    if (profile) {
      if (profile.role) userRole = profile.role as UserRole;
      if (profile.full_name) fullName = profile.full_name;
      if (profile.phone) phone = profile.phone;
    }
  } catch {
    // Non-fatal if profile query is delayed; metadata is used as fallback
  }

  const adminUser: AdminUser = {
    id: data.user.id,
    email: data.user.email ?? '',
    fullName,
    role: userRole,
    phone,
    createdAt: data.user.created_at ?? new Date().toISOString(),
    lastLoginAt: new Date().toISOString(),
  };

  return { user: adminUser };
}

export async function signOut(): Promise<void> {
  if (!isDemoMode() && supabase) {
    await supabase.auth.signOut();
  }
}

export async function resetPassword(email: string): Promise<{ error?: string }> {
  if (isDemoMode()) {
    await new Promise((r) => setTimeout(r, 500));
    if (!email.includes('@')) return { error: 'Enter a valid email address.' };
    return {};
  }
  if (!supabase) return { error: 'Service not available.' };
  const { error } = await supabase.auth.resetPasswordForEmail(email);
  if (error) return { error: error.message };
  return {};
}

export async function updatePassword(newPassword: string): Promise<{ error?: string }> {
  if (isDemoMode()) {
    await new Promise((r) => setTimeout(r, 500));
    if (newPassword.length < 8) return { error: 'Password must be at least 8 characters.' };
    return {};
  }
  if (!supabase) return { error: 'Service not available.' };
  const { error } = await supabase.auth.updateUser({ password: newPassword });
  if (error) return { error: error.message };
  return {};
}

export async function getCurrentUser(): Promise<AdminUser | null> {
  if (isDemoMode()) return null;
  if (!supabase) return null;
  const { data } = await supabase.auth.getUser();
  if (!data.user) return null;

  let userRole: UserRole = (data.user.user_metadata?.role as UserRole) || 'admin';
  let fullName = data.user.user_metadata?.full_name || 'Administrator';
  let phone = data.user.user_metadata?.phone;

  try {
    const { data: profile } = (await supabase
      .from('profiles')
      .select('role, full_name, phone')
      .eq('id', data.user.id)
      .single()) as { data: any; error: any };

    if (profile) {
      if (profile.role) userRole = profile.role as UserRole;
      if (profile.full_name) fullName = profile.full_name;
      if (profile.phone) phone = profile.phone;
    }
  } catch {
    // metadata fallback
  }

  return {
    id: data.user.id,
    email: data.user.email ?? '',
    fullName,
    role: userRole,
    phone,
    createdAt: data.user.created_at ?? new Date().toISOString(),
  };
}
