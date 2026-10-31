import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/app_bottom_nav_scaffold.dart';
import '../../core/widgets/app_loading_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/providers/auth_state.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/courses/presentation/screens/courses_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/hubs/presentation/screens/more_hubs_screen.dart';
import '../../features/payments/presentation/screens/payments_screen.dart';
import '../../features/students/presentation/screens/students_screen.dart';

/// Centralized route paths for IIECM Admin
class AppRoutes {
  static const String splash = '/splash';
  static const String home = '/';
  static const String students = '/students';
  static const String courses = '/courses';
  static const String payments = '/payments';
  static const String hubs = '/hubs';
  static const String login = '/login';
}

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

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
