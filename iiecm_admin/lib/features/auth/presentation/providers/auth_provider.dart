import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthChangeEvent;
import '../../../core/network/supabase_client.dart';
import '../../data/repositories/supabase_auth_repository.dart';
import '../../domain/models/auth_exception.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

/// Provider for the AuthRepository contract
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository();
});

/// Riverpod StateNotifier managing the authentication lifecycle
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  StreamSubscription? _authSubscription;

  AuthNotifier(this._repository) : super(const AuthState.initial()) {
    _initialize();
  }

  Future<void> _initialize() async {
    if (!AppSupabase.isInitialized) {
      state = const AuthState.unconfigured();
      return;
    }

    // Listen for auth state changes from Supabase (e.g. token refresh, sign out)
    _authSubscription = _repository.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedOut) {
        if (state.status != AuthStatus.unauthenticated) {
          state = const AuthState.unauthenticated();
        }
      }
    });

    // Check for an existing session on app startup
    try {
      final user = await _repository.restoreSession();
      if (user != null) {
        state = AuthState.authenticated(user);
      } else {
        state = const AuthState.unauthenticated();
      }
    } on ProfileVerificationNetworkException catch (e) {
      final currentSession = _repository.currentSession;
      state = AuthState.profileVerificationError(
        errorMessage: e.message,
        pendingUserId: currentSession?.user.id,
        pendingEmail: currentSession?.user.email,
      );
    } catch (e) {
      state = const AuthState.unauthenticated();
    }
  }

  /// Attempts to sign in with email & password
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty || password.isEmpty) {
      state = const AuthState.unauthenticated(
        errorMessage: 'Please enter both email and password.',
      );
      return false;
    }

    state = const AuthState.authenticating();

    try {
      final adminUser = await _repository.signIn(
        email: email,
        password: password,
      );
      state = AuthState.authenticated(adminUser);
      return true;
    } on ProfileVerificationNetworkException catch (e) {
      final session = _repository.currentSession;
      state = AuthState.profileVerificationError(
        errorMessage: e.message,
        pendingUserId: session?.user.id,
        pendingEmail: session?.user.email,
      );
      return false;
    } on AppAuthException catch (e) {
      state = AuthState.unauthenticated(errorMessage: e.message);
      return false;
    } catch (e) {
      state = AuthState.unauthenticated(errorMessage: 'Login failed: $e');
      return false;
    }
  }

  /// Retries authoritative profile lookup after a network error without requiring password re-entry
  Future<bool> retryProfileVerification() async {
    final userId = state.pendingUserId ?? _repository.currentSession?.user.id;
    if (userId == null) {
      state = const AuthState.unauthenticated(
        errorMessage: 'Session expired. Please sign in again.',
      );
      return false;
    }

    final emailFallback = state.pendingEmail ?? _repository.currentSession?.user.email;
    state = const AuthState.authenticating();

    try {
      final adminUser = await _repository.fetchAuthoritativeProfile(
        userId: userId,
        emailFallback: emailFallback,
      );
      state = AuthState.authenticated(adminUser);
      return true;
    } on ProfileVerificationNetworkException catch (e) {
      state = AuthState.profileVerificationError(
        errorMessage: e.message,
        pendingUserId: userId,
        pendingEmail: emailFallback,
      );
      return false;
    } on AppAuthException catch (e) {
      await _repository.signOut();
      state = AuthState.unauthenticated(errorMessage: e.message);
      return false;
    } catch (e) {
      state = AuthState.unauthenticated(errorMessage: 'Verification failed: $e');
      return false;
    }
  }

  /// Signs out of IIECM Admin
  Future<void> logout() async {
    state = const AuthState.authenticating();
    await _repository.signOut();
    state = const AuthState.unauthenticated();
  }

  /// Sends password reset email
  Future<void> sendPasswordReset(String email) async {
    if (email.trim().isEmpty) {
      throw const GenericAuthException('Please enter a valid email address.');
    }
    await _repository.sendPasswordResetEmail(email.trim());
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

