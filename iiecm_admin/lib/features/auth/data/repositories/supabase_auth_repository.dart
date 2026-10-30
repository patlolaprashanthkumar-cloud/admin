import 'dart:async';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_client.dart';
import '../../domain/models/admin_user.dart';
import '../../domain/models/auth_exception.dart';
import '../../domain/models/user_role.dart';
import '../../domain/repositories/auth_repository.dart';

/// Concrete Supabase implementation of AuthRepository
class SupabaseAuthRepository implements AuthRepository {
  SupabaseClient get _client => AppSupabase.client;

  @override
  Stream<AuthState> get onAuthStateChange {
    if (!AppSupabase.isInitialized) {
      return const Stream.empty();
    }
    return _client.auth.onAuthStateChange;
  }

  @override
  Session? get currentSession {
    if (!AppSupabase.isInitialized) return null;
    return _client.auth.currentSession;
  }

  @override
  Future<AdminUser> signIn({
    required String email,
    required String password,
  }) async {
    if (!AppSupabase.isInitialized) {
      throw const UnconfiguredAuthException();
    }

    AuthResponse response;
    try {
      response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } on AuthException catch (e) {
      throw InvalidCredentialsException(e.message);
    } catch (e) {
      if (e is SocketException || e is TimeoutException) {
        throw const ProfileVerificationNetworkException(
          'Network connection error. Check your internet connection.',
        );
      }
      throw GenericAuthException(e.toString());
    }

    final authUser = response.user;
    if (authUser == null) {
      throw const InvalidCredentialsException('No user returned from authentication service.');
    }

    try {
      // Authoritative verification against public.profiles
      final adminUser = await fetchAuthoritativeProfile(
        userId: authUser.id,
        emailFallback: authUser.email,
      );

      // Best-effort update of last_login_at in public.profiles
      try {
        await _client.from('profiles').update({
          'last_login_at': DateTime.now().toIso8601String(),
        }).eq('id', authUser.id);
      } catch (_) {
        // Non-fatal if update fails due to network or trigger
      }

      return adminUser;
    } on AccessDeniedNonAdminException {
      // Security measure: Do not leave non-admin sessions active in the admin application
      await signOut();
      rethrow;
    } on ProfileNotFoundException {
      // Security measure: User exists in Auth, but has no admin profile in public.profiles
      await signOut();
      rethrow;
    } on ProfileVerificationNetworkException {
      // Do NOT sign out on temporary network failure; allow user to retry
      rethrow;
    }
  }

  @override
  Future<AdminUser> fetchAuthoritativeProfile({
    required String userId,
    String? emailFallback,
  }) async {
    if (!AppSupabase.isInitialized) {
      throw const UnconfiguredAuthException();
    }

    Map<String, dynamic>? profileData;
    try {
      final response = await _client
          .from('profiles')
          .select('id, email, full_name, role, phone, avatar_url, last_login_at, created_at')
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        profileData = Map<String, dynamic>.from(response);
      }
    } on PostgrestException catch (e) {
      throw ProfileVerificationNetworkException('Database query failed: ${e.message}');
    } catch (e) {
      if (e is SocketException || e is TimeoutException) {
        throw const ProfileVerificationNetworkException(
          'Network timeout while verifying profile. Tap retry to check again.',
        );
      }
      throw ProfileVerificationNetworkException('Profile verification error: $e');
    }

    if (profileData == null) {
      throw const ProfileNotFoundException();
    }

    final roleStr = profileData['role'] as String?;
    final role = UserRole.fromString(roleStr);

    if (role == null || !role.isAdmin) {
      throw AccessDeniedNonAdminException(roleStr ?? 'unknown');
    }

    return AdminUser.fromProfileJson(
      profileData,
      emailFallback: emailFallback,
    );
  }

  @override
  Future<AdminUser?> restoreSession() async {
    if (!AppSupabase.isInitialized) return null;

    final session = currentSession;
    if (session == null) return null;

    final user = session.user;
    try {
      final admin = await fetchAuthoritativeProfile(
        userId: user.id,
        emailFallback: user.email,
      );
      return admin;
    } on AccessDeniedNonAdminException {
      await signOut();
      return null;
    } on ProfileNotFoundException {
      await signOut();
      return null;
    } on ProfileVerificationNetworkException {
      // Propagate network error so state can display retry rather than kicking user out
      rethrow;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> signOut() async {
    if (!AppSupabase.isInitialized) return;
    try {
      await _client.auth.signOut();
    } catch (_) {
      // Clean up locally even if network sign-out has issues
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    if (!AppSupabase.isInitialized) {
      throw const UnconfiguredAuthException();
    }

    try {
      await _client.auth.resetPasswordForEmail(email.trim());
    } on AuthException catch (e) {
      throw GenericAuthException(e.message);
    } catch (e) {
      throw GenericAuthException('Failed to send password reset: $e');
    }
  }
}

