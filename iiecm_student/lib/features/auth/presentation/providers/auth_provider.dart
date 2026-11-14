import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthChangeEvent;

import '../../../../core/network/supabase_client.dart';
import '../../data/repositories/supabase_auth_repository.dart';
import '../../domain/models/auth_exception.dart';
import '../../domain/models/student_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

/// Provider exposing the AuthRepository contract
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository();
});

/// Riverpod StateNotifier managing the student authentication lifecycle
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

    // Check for an existing valid student session on app startup
    try {
      final student = await _repository.restoreSession();
      if (student != null) {
        state = AuthState.authenticated(student);
      } else {
        state = const AuthState.unauthenticated();
      }
    } on AuthNetworkException catch (e) {
      final currentSession = _repository.currentSession;
      state = AuthState.verificationError(
        errorMessage: e.message,
        pendingUserId: currentSession?.user.id,
        pendingEmail: currentSession?.user.email,
      );
    } catch (_) {
      state = const AuthState.unauthenticated();
    }
  }

  /// Attempts to sign in with student email & password
  Future<bool> login({required String email, required String password}) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty || password.isEmpty) {
      state = const AuthState.unauthenticated(
        errorMessage: 'Please enter both your registered email and password.',
      );
      return false;
    }

    state = const AuthState.authenticating();

    try {
      final student = await _repository.signIn(
        email: cleanEmail,
        password: password,
      );
      state = AuthState.authenticated(student);
      return true;
    } on AuthNetworkException catch (e) {
      final session = _repository.currentSession;
      final userId = e.userId ?? session?.user.id;
      final pendingEmail = e.email ?? session?.user.email ?? cleanEmail;
      state = AuthState.verificationError(
        errorMessage: e.message,
        pendingUserId: userId,
        pendingEmail: pendingEmail,
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

  /// Retries authoritative profile and student record lookup after a network glitch
  Future<bool> retryVerification() async {
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
      final student = await _repository.fetchAuthoritativeStudentProfile(
        userId: userId,
        emailFallback: emailFallback,
      );
      state = AuthState.authenticated(student);
      return true;
    } on AuthNetworkException catch (e) {
      state = AuthState.verificationError(
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

  /// Updates the active student profile after an authoritative update
  void updateStudentProfile(StudentProfile updatedProfile) {
    state = AuthState.authenticated(updatedProfile);
  }

  /// Signs out of IIECM Student Portal
  Future<void> logout() async {
    state = const AuthState.authenticating();
    await _repository.signOut();
    state = const AuthState.unauthenticated();
  }

  /// Sends password reset email
  Future<void> sendPasswordReset(String email) async {
    if (email.trim().isEmpty) {
      throw const GenericAuthException('Please enter a valid registered email address.');
    }
    await _repository.sendPasswordResetEmail(email.trim());
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

