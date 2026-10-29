import type { LucideIcon } from 'lucide-react';
import {
  LayoutDashboard, Users, GraduationCap, BookOpen, CreditCard,
  MessageSquare, ClipboardCheck, Compass, FolderOpen, Bell,
  BarChart3, Settings, Tag, ShieldCheck,
} from 'lucide-react';

export interface NavItem {
  label: string;
  to: string;
  icon: LucideIcon;
  permission: string;
  badge?: number;
}

export interface HubItem extends NavItem {
  description: string;
  category: 'Academics' | 'Admissions & CRM' | 'Student Services' | 'Administration';
  accentColor: string;
  statKey?: 'assessments' | 'categories' | 'careerGuidance' | 'resources' | 'enquiries' | 'notifications';
}

/**
 * Primary Institutional Pillars (Displayed in the clean sidebar navigation)
 */
export const navItems: NavItem[] = [
  { label: 'Dashboard', to: '/dashboard', icon: LayoutDashboard, permission: 'dashboard.view' },
  { label: 'Students', to: '/students', icon: Users, permission: 'students.view' },
  { label: 'Instructors', to: '/instructors', icon: GraduationCap, permission: 'instructors.view' },
  { label: 'Courses', to: '/courses', icon: BookOpen, permission: 'courses.view' },
  { label: 'Payments', to: '/payments', icon: CreditCard, permission: 'payments.view' },
  { label: 'Reports', to: '/reports', icon: BarChart3, permission: 'reports.view' },
  { label: 'Settings', to: '/settings', icon: Settings, permission: 'settings.view' },
];

/**
 * Academic & Operational Management Hubs
 * (Featured prominently on the Home Dashboard, In-Page Navigations, and App Switcher)
 */
export const operationalHubs: HubItem[] = [
  {
    label: 'Assessments & Exams',
    to: '/assessments',
    icon: ClipboardCheck,
    permission: 'assessments.view',
    description: 'Online tests, question banks, grading rubrics and performance evaluations',
    category: 'Academics',
    accentColor: '#064B3E',
    statKey: 'assessments',
  },
  {
    label: 'Course Categories',
    to: '/categories',
    icon: Tag,
    permission: 'categories.view',
    description: 'Curriculum taxonomy, subject grouping tags and academic domain hierarchies',
    category: 'Academics',
    accentColor: '#C76543',
    statKey: 'categories',
  },
  {
    label: 'Career Guidance',
    to: '/career-guidance',
    icon: Compass,
    permission: 'career.view',
    description: '1-on-1 career counseling, pathway roadmaps and student action plans',
    category: 'Student Services',
    accentColor: '#FF8E53',
    statKey: 'careerGuidance',
  },
  {
    label: 'Digital Resources',
    to: '/resources',
    icon: FolderOpen,
    permission: 'resources.view',
    description: 'Centralized institutional library, lecture slides, datasets and study materials',
    category: 'Academics',
    accentColor: '#102A43',
    statKey: 'resources',
  },
  {
    label: 'Admissions CRM',
    to: '/enquiries',
    icon: MessageSquare,
    permission: 'enquiries.view',
    description: 'Prospective applicant inquiries, admissions pipeline and follow-up tracking',
    category: 'Admissions & CRM',
    accentColor: '#064B3E',
    statKey: 'enquiries',
  },
  {
    label: 'Campus Broadcasts',
    to: '/notifications',
    icon: Bell,
    permission: 'notifications.view',
    description: 'Institutional announcements, alert dispatches and critical student notifications',
    category: 'Administration',
    accentColor: '#C76543',
    statKey: 'notifications',
  },
];

export const mobileNavItems: NavItem[] = [
  { label: 'Dashboard', to: '/dashboard', icon: LayoutDashboard, permission: 'dashboard.view' },
  { label: 'Students', to: '/students', icon: Users, permission: 'students.view' },
  { label: 'Courses', to: '/courses', icon: BookOpen, permission: 'courses.view' },
  { label: 'Payments', to: '/payments', icon: CreditCard, permission: 'payments.view' },
  { label: 'Hubs', to: '/more', icon: LayoutDashboard, permission: 'dashboard.view' },
];
