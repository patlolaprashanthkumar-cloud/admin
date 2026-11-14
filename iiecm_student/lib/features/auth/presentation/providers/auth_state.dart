import '../../domain/models/student_profile.dart';

/// All possible authentication and authorization states for IIECM Student Portal
enum AuthStatus {
  /// Initial state on app startup while inspecting persistent storage
  initial,

  /// App is missing SUPABASE_URL or SUPABASE_ANON_KEY
  unconfigured,

  /// No active user session
  unauthenticated,

  /// Authentication or profile check in progress
  authenticating,

  /// Authenticated as verified Student
  authenticated,

  /// User credentials validated, but profile check encountered a temporary network issue
  verificationError,
}

class AuthState {
  final AuthStatus status;
  final StudentProfile? student;
  final String? errorMessage;
  final bool isRetryable;
  final String? pendingUserId;
  final String? pendingEmail;

  const AuthState({
    required this.status,
    this.student,
    this.errorMessage,
    this.isRetryable = false,
    this.pendingUserId,
    this.pendingEmail,
  });

  const AuthState.initial()
      : status = AuthStatus.initial,
        student = null,
        errorMessage = null,
        isRetryable = false,
        pendingUserId = null,
        pendingEmail = null;

  const AuthState.unconfigured()
      : status = AuthStatus.unconfigured,
        student = null,
        errorMessage = 'Supabase credentials are not configured. Run with --dart-define-from-file=.env.json',
        isRetryable = false,
        pendingUserId = null,
        pendingEmail = null;

  const AuthState.unauthenticated({this.errorMessage})
      : status = AuthStatus.unauthenticated,
        student = null,
        isRetryable = false,
        pendingUserId = null,
        pendingEmail = null;

  const AuthState.authenticating()
      : status = AuthStatus.authenticating,
        student = null,
        errorMessage = null,
        isRetryable = false,
        pendingUserId = null,
        pendingEmail = null;

  const AuthState.authenticated(StudentProfile studentProfile)
      : status = AuthStatus.authenticated,
        student = studentProfile,
        errorMessage = null,
        isRetryable = false,
        pendingUserId = null,
        pendingEmail = null;

  const AuthState.verificationError({
    required this.errorMessage,
    required this.pendingUserId,
    this.pendingEmail,
  })  : status = AuthStatus.verificationError,
        student = null,
        isRetryable = true;

  bool get isAuthenticated => status == AuthStatus.authenticated && student != null;
  bool get isLoading => status == AuthStatus.authenticating || status == AuthStatus.initial;
  bool get isUnconfigured => status == AuthStatus.unconfigured;
}

