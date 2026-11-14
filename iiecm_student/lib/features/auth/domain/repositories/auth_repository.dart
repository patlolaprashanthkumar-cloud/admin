import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../models/student_profile.dart';

/// Contract for student authentication and authoritative role verification
abstract class AuthRepository {
  /// Stream of Supabase authentication events (signed in, signed out, token refreshed)
  Stream<sb.AuthState> get onAuthStateChange;

  /// Current active Supabase session, if any
  sb.Session? get currentSession;

  /// Authenticates using registered student email and password,
  /// then validates `public.profiles.role == 'student'` and queries linked `public.students`.
  Future<StudentProfile> signIn({
    required String email,
    required String password,
  });

  /// Authoritatively fetches and validates profile and student record from database
  Future<StudentProfile> fetchAuthoritativeStudentProfile({
    required String userId,
    String? emailFallback,
  });

  /// Restores session on app startup if a valid cached JWT exists
  Future<StudentProfile?> restoreSession();

  /// Terminates the current session across the app and Supabase SDK
  Future<void> signOut();

  /// Dispatches password reset email to student's registered address
  Future<void> sendPasswordResetEmail(String email);
}

