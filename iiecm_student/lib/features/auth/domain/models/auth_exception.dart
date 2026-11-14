/// Base exception for IIECM Student Portal authentication and authorization flows
sealed class AppAuthException implements Exception {
  final String message;
  final bool isRetryable;

  const AppAuthException(this.message, {this.isRetryable = false});

  @override
  String toString() => message;
}

/// Supabase environment variables are missing
class UnconfiguredAuthException extends AppAuthException {
  const UnconfiguredAuthException()
      : super(
          'Supabase backend credentials are not configured. Run the app with --dart-define-from-file=.env.json.',
          isRetryable: false,
        );
}

/// Invalid email or password
class InvalidCredentialsException extends AppAuthException {
  const InvalidCredentialsException([String? message])
      : super(
          message ?? 'Invalid email or password. Please verify your student credentials.',
          isRetryable: false,
        );
}

/// User authenticated in Supabase Auth, but has NO row in `public.profiles`
class StudentProfileNotFoundException extends AppAuthException {
  const StudentProfileNotFoundException()
      : super(
          'Student profile record not found in the IIECM registry. Please contact administration.',
          isRetryable: false,
        );
}

/// User exists and has a profile, but the role is NOT `student` (e.g. `admin`, `instructor`, `super_admin`)
class AccessDeniedNonStudentException extends AppAuthException {
  final String currentRole;

  const AccessDeniedNonStudentException(this.currentRole)
      : super(
          'Access denied. This portal is strictly for enrolled students. (Account role: $currentRole)',
          isRetryable: false,
        );
}

/// Profile exists with role `student`, but no linked row in `public.students` (`profile_id == user.id`)
class StudentRecordNotFoundException extends AppAuthException {
  const StudentRecordNotFoundException()
      : super(
          'Institutional student enrollment record not found. Please contact the registrar.',
          isRetryable: false,
        );
}

/// Student account is suspended, inactive, or archived
class StudentAccountSuspendedException extends AppAuthException {
  final String status;

  const StudentAccountSuspendedException(this.status)
      : super(
          'Your student enrollment account status is "$status". Access is currently disabled. Please contact the registrar.',
          isRetryable: false,
        );
}

/// Network or database connectivity error during profile or student record verification
class AuthNetworkException extends AppAuthException {
  final String? userId;
  final String? email;

  const AuthNetworkException([
    String? details,
    this.userId,
    this.email,
  ]) : super(
          details ?? 'Network connection error while communicating with IIECM servers. Please check your connection and retry.',
          isRetryable: true,
        );
}

/// General or unexpected authentication error
class GenericAuthException extends AppAuthException {
  const GenericAuthException(super.message, {super.isRetryable});
}

