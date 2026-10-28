import type { LucideIcon } from 'lucide-react';
import {
  LayoutDashboard, Users, GraduationCap, BookOpen, CreditCard,
  MessageSquare, ClipboardCheck, Compass, FolderOpen, Bell,
  BarChart3, Settings,
} from 'lucide-react';

export interface NavItem {
  label: string;
  to: string;
  icon: LucideIcon;
  permission: string;
  badge?: number;
}

export const navItems: NavItem[] = [
  { label: 'Dashboard', to: '/dashboard', icon: LayoutDashboard, permission: 'dashboard.view' },
  { label: 'Students', to: '/students', icon: Users, permission: 'students.view' },
  { label: 'Instructors', to: '/instructors', icon: GraduationCap, permission: 'instructors.view' },
  { label: 'Courses', to: '/courses', icon: BookOpen, permission: 'courses.view' },
  { label: 'Payments', to: '/payments', icon: CreditCard, permission: 'payments.view' },
  { label: 'Enquiries', to: '/enquiries', icon: MessageSquare, permission: 'enquiries.view' },
  { label: 'Assessments', to: '/assessments', icon: ClipboardCheck, permission: 'assessments.view' },
  { label: 'Career Guidance', to: '/career-guidance', icon: Compass, permission: 'career.view' },
  { label: 'Resources', to: '/resources', icon: FolderOpen, permission: 'resources.view' },
  { label: 'Notifications', to: '/notifications', icon: Bell, permission: 'notifications.view' },
  { label: 'Reports', to: '/reports', icon: BarChart3, permission: 'reports.view' },
  { label: 'Settings', to: '/settings', icon: Settings, permission: 'settings.view' },
];

export const mobileNavItems: NavItem[] = [
  { label: 'Dashboard', to: '/dashboard', icon: LayoutDashboard, permission: 'dashboard.view' },
  { label: 'Students', to: '/students', icon: Users, permission: 'students.view' },
  { label: 'Courses', to: '/courses', icon: BookOpen, permission: 'courses.view' },
  { label: 'Payments', to: '/payments', icon: CreditCard, permission: 'payments.view' },
  { label: 'More', to: '/more', icon: Settings, permission: 'dashboard.view' },
];
