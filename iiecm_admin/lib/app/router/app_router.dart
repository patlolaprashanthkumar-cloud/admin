import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/providers/auth_state.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/home/presentation/screens/home_placeholder_screen.dart';

/// Centralized route paths for IIECM Admin
class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
}

/// Listenable that notifies GoRouter whenever the auth state changes
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authNotifierProvider,
      (_, __) => notifyListeners(),
    );
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

/// Riverpod provider exposing the GoRouter configuration with Auth Guards
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final isLoggingIn = state.matchedLocation == AppRoutes.login;

      // Allow splash / initial restoration to settle
      if (authState.status == AuthStatus.initial) {
        return null;
      }

      final isAuthenticated = authState.isAuthenticated;

      // If unauthenticated or profile error and not on login screen, redirect to /login
      if (!isAuthenticated && !isLoggingIn) {
        return AppRoutes.login;
      }

      // If authenticated and attempting to view the login screen, redirect to home
      if (isAuthenticated && isLoggingIn) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const HomePlaceholderScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
    ],
  );
});
