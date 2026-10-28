import type { UserRole } from '@/types';

export interface Permission {
  resource: string;
  actions: ('view' | 'create' | 'edit' | 'delete' | 'manage')[];
}

const rolePermissions: Record<UserRole, string[]> = {
  super_admin: ['*'],
  admin: [
    'dashboard.view',
    'students.view', 'students.create', 'students.edit',
    'instructors.view', 'instructors.create', 'instructors.edit',
    'courses.view', 'courses.create', 'courses.edit', 'courses.delete',
    'payments.view', 'payments.verify', 'payments.reject',
    'enquiries.view', 'enquiries.create', 'enquiries.edit', 'enquiries.convert',
    'assessments.view', 'assessments.create', 'assessments.edit',
    'career.view',
    'resources.view', 'resources.create', 'resources.edit',
    'notifications.view',
    'reports.view',
    'settings.view',
  ],
  instructor: [
    'dashboard.view',
    'courses.view',
    'students.view',
    'assessments.view', 'assessments.create', 'assessments.edit',
    'resources.view',
    'notifications.view',
  ],
  student: [
    'dashboard.view',
    'courses.view',
    'notifications.view',
  ],
};

export function hasPermission(role: UserRole, permission: string): boolean {
  const perms = rolePermissions[role] ?? [];
  if (perms.includes('*')) return true;
  if (perms.includes(permission)) return true;
  const [resource] = permission.split('.');
  return perms.includes(`${resource}.*`);
}

export function canManageAdmins(role: UserRole): boolean {
  return role === 'super_admin';
}

export function roleLabel(role: UserRole): string {
  switch (role) {
    case 'super_admin': return 'Super Admin';
    case 'admin': return 'Administrator';
    case 'instructor': return 'Instructor';
    case 'student': return 'Student';
  }
}
