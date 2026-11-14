import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/network/supabase_client.dart';
import '../../domain/models/auth_exception.dart';
import '../../domain/models/student_profile.dart';
import '../../domain/repositories/auth_repository.dart';

/// Concrete Supabase implementation of AuthRepository for the Student Portal
class SupabaseAuthRepository implements AuthRepository {
  sb.SupabaseClient get _client => AppSupabase.client;

  @override
  Stream<sb.AuthState> get onAuthStateChange {
    if (!AppSupabase.isInitialized) {
      return const Stream.empty();
    }
    return _client.auth.onAuthStateChange;
  }

  @override
  sb.Session? get currentSession {
    if (!AppSupabase.isInitialized) return null;
    return _client.auth.currentSession;
  }

  @override
  Future<StudentProfile> signIn({
    required String email,
    required String password,
  }) async {
    if (!AppSupabase.isInitialized) {
      throw const UnconfiguredAuthException();
    }

    sb.AuthResponse response;
    try {
      response = await _client.auth
          .signInWithPassword(email: email.trim(), password: password)
          .timeout(const Duration(seconds: 15));
    } on sb.AuthException catch (e) {
      throw InvalidCredentialsException(e.message);
    } catch (e) {
      if (e is SocketException || e is TimeoutException) {
        throw const AuthNetworkException(
          'Network connection error. Please check your internet connection.',
        );
      }
      throw GenericAuthException(e.toString());
    }

    final authUser = response.user;
    if (authUser == null) {
      throw const InvalidCredentialsException(
        'No user identity returned from authentication service.',
      );
    }

    try {
      // Authoritatively verify public.profiles (role == 'student') & public.students (profile_id == authUser.id)
      final studentProfile = await fetchAuthoritativeStudentProfile(
        userId: authUser.id,
        emailFallback: authUser.email,
      );

      // Best-effort update of last_login_at in public.profiles
      try {
        await _client
            .from('profiles')
            .update({'last_login_at': DateTime.now().toIso8601String()})
            .eq('id', authUser.id);
      } catch (_) {
        // Non-fatal if update fails
      }

      return studentProfile;
    } on AccessDeniedNonStudentException {
      // Security measure: Immediately terminate session for non-student accounts attempting student portal access
      await signOut();
      rethrow;
    } on StudentProfileNotFoundException {
      await signOut();
      rethrow;
    } on StudentRecordNotFoundException {
      await signOut();
      rethrow;
    } on StudentAccountSuspendedException {
      await signOut();
      rethrow;
    } on AuthNetworkException catch (e) {
      // Do not sign out on temporary network failure; allow user to retry verification
      throw AuthNetworkException(
        e.message,
        e.userId ?? authUser.id,
        e.email ?? authUser.email,
      );
    }
  }

  @override
  Future<StudentProfile> fetchAuthoritativeStudentProfile({
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
          .maybeSingle()
          .timeout(const Duration(seconds: 12));

      if (response != null) {
        profileData = Map<String, dynamic>.from(response);
      }
    } on sb.PostgrestException catch (e) {
      throw AuthNetworkException('Database query failed: ${e.message}');
    } catch (e) {
      if (e is SocketException || e is TimeoutException) {
        throw const AuthNetworkException(
          'Network timeout while loading student profile. Tap retry to check again.',
        );
      }
      throw AuthNetworkException('Profile verification error: $e');
    }

    if (profileData == null) {
      throw const StudentProfileNotFoundException();
    }

    final role = (profileData['role'] as String?)?.toLowerCase().trim();
    if (role != 'student') {
      throw AccessDeniedNonStudentException(role ?? 'unassigned');
    }

    // Now query public.students linked via profile_id == userId
    Map<String, dynamic>? studentData;
    try {
      final response = await _client
          .from('students')
          .select('*')
          .eq('profile_id', userId)
          .maybeSingle()
          .timeout(const Duration(seconds: 12));

      if (response != null) {
        studentData = Map<String, dynamic>.from(response);
      }
    } on sb.PostgrestException catch (e) {
      throw AuthNetworkException('Database query for student record failed: ${e.message}');
    } catch (e) {
      if (e is SocketException || e is TimeoutException) {
        throw const AuthNetworkException(
          'Network timeout while loading student record. Tap retry to check again.',
        );
      }
      throw AuthNetworkException('Student record lookup error: $e');
    }

    if (studentData == null) {
      throw const StudentRecordNotFoundException();
    }

    final status = (studentData['account_status'] as String?)?.toLowerCase().trim() ?? 'active';
    if (status != 'active') {
      throw StudentAccountSuspendedException(status);
    }

    return StudentProfile.fromData(
      profileMap: profileData,
      studentMap: studentData,
      emailFallback: emailFallback,
    );
  }

  @override
  Future<StudentProfile?> restoreSession() async {
    if (!AppSupabase.isInitialized) return null;

    final session = currentSession;
    if (session == null) return null;

    final user = session.user;
    try {
      final student = await fetchAuthoritativeStudentProfile(
        userId: user.id,
        emailFallback: user.email,
      );
      return student;
    } on AccessDeniedNonStudentException {
      await signOut();
      return null;
    } on StudentProfileNotFoundException {
      await signOut();
      return null;
    } on StudentRecordNotFoundException {
      await signOut();
      return null;
    } on StudentAccountSuspendedException {
      await signOut();
      return null;
    } on AuthNetworkException {
      // Propagate network error so state notifier can present a retry interface instead of dropping session
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
      // Gracefully finish local cleanup
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    if (!AppSupabase.isInitialized) {
      throw const UnconfiguredAuthException();
    }

    try {
      await _client.auth.resetPasswordForEmail(email.trim());
    } on sb.AuthException catch (e) {
      throw GenericAuthException(e.message);
    } catch (e) {
      throw GenericAuthException('Failed to send password reset: $e');
    }
  }
}

