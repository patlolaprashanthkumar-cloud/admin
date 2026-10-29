import { createBrowserRouter, Navigate } from 'react-router-dom';
import { AppLayout } from '@/components/layout/AppLayout';
import { useAuth } from '@/hooks/useAuth';
import type { ReactNode } from 'react';

import { LoginPage } from '@/features/auth/LoginPage';
import { ForgotPasswordPage } from '@/features/auth/ForgotPasswordPage';
import { ResetPasswordPage } from '@/features/auth/ResetPasswordPage';
import { ProfilePage } from '@/features/auth/ProfilePage';
import { DashboardPage } from '@/features/dashboard/DashboardPage';
import { StudentListPage } from '@/features/students/StudentListPage';
import { AddStudentPage } from '@/features/students/AddStudentPage';
import { StudentProfilePage } from '@/features/students/StudentProfilePage';
import { InstructorListPage } from '@/features/instructors/InstructorListPage';
import { CourseListPage } from '@/features/courses/CourseListPage';
import { CourseDetailPage } from '@/features/courses/CourseDetailPage';
import { PaymentListPage } from '@/features/payments/PaymentListPage';
import { EnquiryListPage } from '@/features/enquiries/EnquiryListPage';
import { AssessmentListPage } from '@/features/assessments/AssessmentListPage';
import { CareerGuidancePage } from '@/features/career-guidance/CareerGuidancePage';
import { ResourceListPage } from '@/features/resources/ResourceListPage';
import { NotificationListPage } from '@/features/notifications/NotificationListPage';
import { ReportsPage } from '@/features/reports/ReportsPage';
import { SettingsPage } from '@/features/settings/SettingsPage';
import { CategoryListPage } from '@/features/categories/CategoryListPage';
import { MorePage } from '@/features/more/MorePage';

function ProtectedRoute({ children }: { children: ReactNode }) {
  const { user, loading } = useAuth();
  if (loading) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-navy-50">
        <div className="h-8 w-8 animate-spin rounded-full border-2 border-navy-200 border-t-indigo-600" />
      </div>
    );
  }
  if (!user) return <Navigate to="/login" replace />;
  return <>{children}</>;
}

export const router = createBrowserRouter([
  { path: '/login', element: <LoginPage /> },
  { path: '/forgot-password', element: <ForgotPasswordPage /> },
  { path: '/reset-password', element: <ResetPasswordPage /> },
  {
    path: '/',
    element: <ProtectedRoute><AppLayout /></ProtectedRoute>,
    children: [
      { index: true, element: <Navigate to="/dashboard" replace /> },
      { path: 'dashboard', element: <DashboardPage /> },
      { path: 'students', element: <StudentListPage /> },
      { path: 'students/new', element: <AddStudentPage /> },
      { path: 'students/:id', element: <StudentProfilePage /> },
      { path: 'students/:id/edit', element: <StudentProfilePage /> },
      { path: 'instructors', element: <InstructorListPage /> },
      { path: 'instructors/new', element: <InstructorListPage /> },
      { path: 'courses', element: <CourseListPage /> },
      { path: 'courses/new', element: <CourseListPage /> },
      { path: 'courses/:id', element: <CourseDetailPage /> },
      { path: 'payments', element: <PaymentListPage /> },
      { path: 'enquiries', element: <EnquiryListPage /> },
      { path: 'assessments', element: <AssessmentListPage /> },
      { path: 'career-guidance', element: <CareerGuidancePage /> },
      { path: 'resources', element: <ResourceListPage /> },
      { path: 'notifications', element: <NotificationListPage /> },
      { path: 'reports', element: <ReportsPage /> },
      { path: 'settings', element: <SettingsPage /> },
      { path: 'categories', element: <CategoryListPage /> },
      { path: 'profile', element: <ProfilePage /> },
      { path: 'more', element: <MorePage /> },
      { path: '*', element: <Navigate to="/dashboard" replace /> },
    ],
  },
]);
