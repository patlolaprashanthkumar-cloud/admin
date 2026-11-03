import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_bottom_nav_scaffold.dart';
import '../../core/widgets/app_loading_screen.dart';
import '../../features/assessments/presentation/screens/assessment_monitoring_screen.dart';
import '../../features/assessments/presentation/screens/assessment_questions_screen.dart';
import '../../features/assessments/presentation/screens/assessments_screen.dart';
import '../../features/assignments/presentation/screens/assignment_detail_screen.dart';
import '../../features/assignments/presentation/screens/assignments_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/providers/auth_state.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/categories/presentation/screens/categories_screen.dart';
import '../../features/categories/presentation/screens/category_detail_screen.dart';
import '../../features/classes/presentation/screens/classes_screen.dart';
import '../../features/courses/presentation/screens/course_curriculum_screen.dart';
import '../../features/courses/presentation/screens/courses_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/faculty/presentation/screens/faculty_profile_screen.dart';
import '../../features/faculty/presentation/screens/faculty_screen.dart';
import '../../features/hubs/presentation/screens/more_hubs_screen.dart';
import '../../features/payments/presentation/screens/payments_screen.dart';
import '../../features/students/presentation/screens/add_student_wizard.dart';
import '../../features/students/presentation/screens/student_profile_screen.dart';
import '../../features/students/presentation/screens/students_screen.dart';

/// Centralized route paths for IIECM Admin
class AppRoutes {
  static const String splash = '/splash';
  static const String home = '/';
  static const String students = '/students';
  static const String courses = '/courses';
  static const String payments = '/payments';
  static const String hubs = '/hubs';
  static const String categories = '/categories';
  static const String faculty = '/faculty';
  static const String classes = '/classes';
  static const String assignments = '/assignments';
  static const String assessments = '/assessments';
  static const String login = '/login';
}

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

/// Listenable that notifies GoRouter whenever the auth state changes
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authNotifierProvider,
      (previous, next) => notifyListeners(),
    );
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

/// Riverpod provider exposing the GoRouter configuration with Auth Guards and Shell Navigation
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final isSplash = state.matchedLocation == AppRoutes.splash;
      final isLoggingIn = state.matchedLocation == AppRoutes.login;

      // While authenticating / initial startup, keep on loading splash screen
      if (authState.status == AuthStatus.initial) {
        return isSplash ? null : AppRoutes.splash;
      }

      final isAuthenticated = authState.isAuthenticated;

      // If verified as administrator:
      if (isAuthenticated) {
        if (isSplash || isLoggingIn) {
          return AppRoutes.home;
        }
        return null;
      }

      // If unauthenticated or profile lookup error:
      if (!isLoggingIn) {
        return AppRoutes.login;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const AppLoadingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.categories,
        name: 'categories',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CategoriesScreen(),
        routes: [
          GoRoute(
            path: ':id',
            name: 'category_detail',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              return CategoryDetailScreen(categoryId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.faculty,
        name: 'faculty',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const FacultyScreen(),
        routes: [
          GoRoute(
            path: ':id',
            name: 'faculty_profile',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              return FacultyProfileScreen(facultyId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.classes,
        name: 'classes',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ClassesScreen(),
      ),
      GoRoute(
        path: AppRoutes.assignments,
        name: 'assignments',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AssignmentsScreen(),
        routes: [
          GoRoute(
            path: ':id',
            name: 'assignment_detail',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              return AssignmentDetailScreen(assignmentId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.assessments,
        name: 'assessments',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AssessmentsScreen(),
        routes: [
          GoRoute(
            path: ':id/questions',
            name: 'assessment_questions',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              return AssessmentQuestionsScreen(assessmentId: id);
            },
          ),
          GoRoute(
            path: ':id/results',
            name: 'assessment_results',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              return AssessmentMonitoringScreen(assessmentId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/courses/:id/curriculum',
        name: 'course_curriculum',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return CourseCurriculumScreen(courseId: id);
        },
      ),
      // Stateful bottom navigation shell for authenticated admin tabs
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppBottomNavScaffold(navigationShell: navigationShell);
        },
        branches: [
          // Tab 0: Executive Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: 'dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          // Tab 1: Students & Registrations
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.students,
                name: 'students',
                builder: (context, state) => const StudentsScreen(),
                routes: [
                  GoRoute(
                    path: 'add',
                    name: 'add_student',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const AddStudentWizard(),
                  ),
                  GoRoute(
                    path: ':id',
                    name: 'student_profile',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final id = state.pathParameters['id'] ?? '';
                      return StudentProfileScreen(studentId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          // Tab 2: Curricula & Courses
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.courses,
                name: 'courses',
                builder: (context, state) => const CoursesScreen(),
              ),
            ],
          ),
          // Tab 3: Payments & Fees
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.payments,
                name: 'payments',
                builder: (context, state) => const PaymentsScreen(),
              ),
            ],
          ),
          // Tab 4: Operational Hubs & Suites
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.hubs,
                name: 'hubs',
                builder: (context, state) => const MoreHubsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
