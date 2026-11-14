import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/assessments/presentation/screens/assessment_attempt_screen.dart';
import '../features/assessments/presentation/screens/assessment_instructions_screen.dart';
import '../features/assessments/presentation/screens/assessments_screen.dart';
import '../features/assignments/presentation/screens/assignment_detail_screen.dart';
import '../features/assignments/presentation/screens/assignments_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/providers/auth_state.dart';
import '../features/courses/presentation/screens/course_detail_screen.dart';
import '../features/courses/presentation/screens/my_courses_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/navigation/presentation/student_shell.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../features/payments/presentation/screens/payment_detail_screen.dart';
import '../features/payments/presentation/screens/payments_screen.dart';
import '../features/profile/presentation/student_profile_screen.dart';
import '../features/results/presentation/screens/result_detail_screen.dart';
import '../features/results/presentation/screens/results_screen.dart';
import '../shared/widgets/app_loading_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String home = '/';
  static const String login = '/login';
  static const String courses = '/courses';
  static const String courseDetail = '/courses/:id';
  static const String assessments = '/assessments';
  static const String assessmentDetail = '/assessments/:id';
  static const String assessmentAttempt = '/assessments/:id/attempt';
  static const String profile = '/profile';
  static const String assignments = '/assignments';
  static const String assignmentDetail = '/assignments/:id';
  static const String results = '/results';
  static const String resultDetail = '/results/:id';
  static const String notifications = '/notifications';
  static const String payments = '/payments';
  static const String paymentDetail = '/payments/:id';
}

/// Listenable that triggers GoRouter evaluation whenever AuthState changes
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

      // While authenticating / initial startup session check, show splash
      if (authState.status == AuthStatus.initial) {
        return isSplash ? null : AppRoutes.splash;
      }

      final isAuthenticated = authState.isAuthenticated;

      // If verified student account:
      if (isAuthenticated) {
        if (isSplash || isLoggingIn) {
          return AppRoutes.home;
        }
        return null;
      }

      // If unauthenticated or verification failed:
      if (!isLoggingIn) {
        return AppRoutes.login;
      }

      return null;
    },
    routes: [
      // Splash / Session Check
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const AppLoadingScreen(),
      ),

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
                builder: (context, state) => const MyCoursesScreen(),
              ),
            ],
          ),

          // Branch 2: Assessments & Checkpoints
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.assessments,
                name: 'assessments',
                builder: (context, state) => const AssessmentsScreen(),
              ),
            ],
          ),

          // Branch 3: Student Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                name: 'profile',
                builder: (context, state) => const StudentProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Additional Student Portal Destinations
      GoRoute(
        path: AppRoutes.courseDetail,
        name: 'course_detail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => CourseDetailScreen(
          courseId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.assignments,
        name: 'assignments',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AssignmentsScreen(),
      ),
      GoRoute(
        path: AppRoutes.assignmentDetail,
        name: 'assignment_detail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => AssignmentDetailScreen(
          assignmentId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.assessmentDetail,
        name: 'assessment_detail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => AssessmentInstructionsScreen(
          assessmentId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.assessmentAttempt,
        name: 'assessment_attempt',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => AssessmentAttemptScreen(
          assessmentId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.results,
        name: 'results',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ResultsScreen(),
      ),
      GoRoute(
        path: AppRoutes.resultDetail,
        name: 'result_detail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => ResultDetailScreen(
          resultId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        name: 'notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.payments,
        name: 'payments',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PaymentsScreen(),
      ),
      GoRoute(
        path: AppRoutes.paymentDetail,
        name: 'payment_detail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => PaymentDetailScreen(
          paymentId: state.pathParameters['id'] ?? '',
        ),
      ),
    ],
  );
});
