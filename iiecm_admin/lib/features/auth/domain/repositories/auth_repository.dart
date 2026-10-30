import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/admin_user.dart';

/// Contract defining all authentication operations for IIECM Admin
abstract class AuthRepository {
  /// Stream of Supabase Auth state transitions (signedIn, signedOut, tokenRefreshed)
  Stream<AuthState> get onAuthStateChange;

  /// Current raw Supabase session if any
  Session? get currentSession;

  /// Authenticate with email & password, fetch authoritative profile, and verify admin role
  Future<AdminUser> signIn({
    required String email,
    required String password,
  });

  /// Authoritatively fetches the user's role and details directly from `public.profiles`
  /// Throws [ProfileNotFoundException] if row is missing
  /// Throws [AccessDeniedNonAdminException] if role is not admin or super_admin
  /// Throws [ProfileVerificationNetworkException] if connection fails
  Future<AdminUser> fetchAuthoritativeProfile({
    required String userId,
    String? emailFallback,
  });

  /// Signs out from Supabase Auth
  Future<void> signOut();

  /// Sends a password reset email using Supabase Auth
  Future<void> sendPasswordResetEmail(String email);

  /// Attempts to restore an existing persisted session on app launch
  Future<AdminUser?> restoreSession();
}

