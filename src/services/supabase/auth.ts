import { supabase, isSupabaseConfigured } from './client';
import type { AdminUser } from '@/types';
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
  if (isDemoMode()) {
    await new Promise((r) => setTimeout(r, 600));
    if (email.trim().toLowerCase() === DEMO_CREDENTIALS.email && password === DEMO_CREDENTIALS.password) {
      return { user: { ...demoAdmin, lastLoginAt: new Date().toISOString() } };
    }
    return { user: null, error: 'Invalid email or password. Use the demo credentials shown below.' };
  }

  if (!supabase) return { user: null, error: 'Authentication service not available.' };
  const { data, error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) return { user: null, error: error.message };
  if (!data.user) return { user: null, error: 'No user returned.' };

  const adminUser: AdminUser = {
    id: data.user.id,
    email: data.user.email ?? '',
    fullName: data.user.user_metadata?.full_name ?? data.user.email ?? 'Administrator',
    role: data.user.user_metadata?.role ?? 'admin',
    phone: data.user.user_metadata?.phone,
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
  return {
    id: data.user.id,
    email: data.user.email ?? '',
    fullName: data.user.user_metadata?.full_name ?? 'Administrator',
    role: data.user.user_metadata?.role ?? 'admin',
    phone: data.user.user_metadata?.phone,
    createdAt: data.user.created_at ?? new Date().toISOString(),
  };
}
