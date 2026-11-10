import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/navigation/presentation/student_shell.dart';
import '../shared/widgets/placeholder_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  static const String login = '/login';
  static const String courses = '/courses';
  static const String assessments = '/assessments';
  static const String profile = '/profile';
  static const String assignments = '/assignments';
  static const String results = '/results';
  static const String notifications = '/notifications';
  static const String payments = '/payments';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.home,
    routes: [
      // Authentication
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Main Student Navigation Shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return StudentShell(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Dashboard (Home)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: 'dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),

          // Branch 1: My Courses
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.courses,
                name: 'courses',
                builder: (context, state) => const PlaceholderScreen(
                  title: 'My Courses',
                  subtitle: 'Access your enrolled medical and management curriculum, modules, and video lectures.',
                  icon: Icons.menu_book_rounded,
                  badgeText: 'Course Curriculum • Phase 2',
                ),
              ),
            ],
          ),

          // Branch 2: Assessments & Checkpoints
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.assessments,
                name: 'assessments',
                builder: (context, state) => const PlaceholderScreen(
                  title: 'Assessments',
                  subtitle: 'Take your scheduled clinical quizzes, OSCE checkpoints, and final examinations.',
                  icon: Icons.assignment_rounded,
                  badgeText: 'Examination Portal • Phase 2',
                ),
              ),
            ],
          ),

          // Branch 3: Student Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                name: 'profile',
                builder: (context, state) => const PlaceholderScreen(
                  title: 'Student Profile',
                  subtitle: 'Manage your candidate details, batch information, and institutional credentials.',
                  icon: Icons.person_rounded,
                  badgeText: 'Candidate Dossier • Phase 2',
                ),
              ),
            ],
          ),
        ],
      ),

      // Additional Student Portal Destinations
      GoRoute(
        path: AppRoutes.assignments,
        name: 'assignments',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PlaceholderScreen(
          title: 'Assignments & Case Submissions',
          subtitle: 'Submit clinical case studies, reports, and review faculty feedback.',
          icon: Icons.task_alt_rounded,
        ),
      ),
      GoRoute(
        path: AppRoutes.results,
        name: 'results',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PlaceholderScreen(
          title: 'Results & Certificates',
          subtitle: 'View evaluated grades, performance transcripts, and digital verification credentials.',
          icon: Icons.workspace_premium_rounded,
        ),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        name: 'notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PlaceholderScreen(
          title: 'Notifications & Alerts',
          subtitle: 'Read academic bulletins, timetable updates, and announcements from the registry.',
          icon: Icons.notifications_active_rounded,
        ),
      ),
      GoRoute(
        path: AppRoutes.payments,
        name: 'payments',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PlaceholderScreen(
          title: 'Fee Status & Receipts',
          subtitle: 'Review semester tuition invoices, installment records, and payment receipts.',
          icon: Icons.receipt_long_rounded,
        ),
      ),
    ],
  );
});

