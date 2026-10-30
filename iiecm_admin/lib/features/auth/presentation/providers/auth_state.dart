import '../../domain/models/admin_user.dart';

/// Represents all possible authentication states in IIECM Admin
enum AuthStatus {
  /// Initial state on app startup while inspecting persistent storage
  initial,

  /// App is missing SUPABASE_URL or SUPABASE_ANON_KEY
  unconfigured,

  /// No active user session
  unauthenticated,

  /// Authentication or profile check in progress
  authenticating,

  /// Authenticated as verified Admin or Super Admin
  authenticated,

  /// User credentials validated, but profile check encountered a temporary network issue
  profileVerificationError,
}

class AuthState {
  final AuthStatus status;
  final AdminUser? adminUser;
  final String? errorMessage;
  final bool isRetryable;
  final String? pendingUserId;
  final String? pendingEmail;

  const AuthState({
    required this.status,
    this.adminUser,
    this.errorMessage,
    this.isRetryable = false,
    this.pendingUserId,
    this.pendingEmail,
  });

  const AuthState.initial()
      : status = AuthStatus.initial,
        adminUser = null,
        errorMessage = null,
        isRetryable = false,
        pendingUserId = null,
        pendingEmail = null;

  const AuthState.unconfigured()
      : status = AuthStatus.unconfigured,
        adminUser = null,
        errorMessage = 'Supabase credentials are not configured.',
        isRetryable = false,
        pendingUserId = null,
        pendingEmail = null;

  const AuthState.unauthenticated({this.errorMessage})
      : status = AuthStatus.unauthenticated,
        adminUser = null,
        isRetryable = false,
        pendingUserId = null,
        pendingEmail = null;

  const AuthState.authenticating()
      : status = AuthStatus.authenticating,
        adminUser = null,
        errorMessage = null,
        isRetryable = false,
        pendingUserId = null,
        pendingEmail = null;

  const AuthState.authenticated(AdminUser user)
      : status = AuthStatus.authenticated,
        adminUser = user,
        errorMessage = null,
        isRetryable = false,
        pendingUserId = null,
        pendingEmail = null;

  const AuthState.profileVerificationError({
    required this.errorMessage,
    required this.pendingUserId,
    this.pendingEmail,
  })  : status = AuthStatus.profileVerificationError,
        adminUser = null,
        isRetryable = true;

  bool get isAuthenticated => status == AuthStatus.authenticated && adminUser != null;
  bool get isLoading => status == AuthStatus.authenticating || status == AuthStatus.initial;
}

