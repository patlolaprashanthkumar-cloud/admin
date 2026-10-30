/// Base exception for IIECM Admin authentication flows
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
          'Supabase backend credentials are not configured. Run the app with --dart-define or --dart-define-from-file.',
          isRetryable: false,
        );
}

/// Invalid email or password
class InvalidCredentialsException extends AppAuthException {
  const InvalidCredentialsException([String? message])
      : super(
          message ?? 'Invalid email or password. Please check your credentials.',
          isRetryable: false,
        );
}

/// User authenticated in Supabase Auth, but has NO row in `public.profiles`
class ProfileNotFoundException extends AppAuthException {
  const ProfileNotFoundException()
      : super(
          'Authoritative administrator profile was not found in the IIECM database. Access denied.',
          isRetryable: false,
        );
}

/// User exists and has a profile, but the role is NOT `admin` or `super_admin` (e.g. `student` or `instructor`)
class AccessDeniedNonAdminException extends AppAuthException {
  final String currentRole;

  const AccessDeniedNonAdminException(this.currentRole)
      : super(
          'Access denied. This portal is strictly for IIECM Administrators. (Role assigned: $currentRole)',
          isRetryable: false,
        );
}

/// Network or server error during the authoritative profile verification step
class ProfileVerificationNetworkException extends AppAuthException {
  const ProfileVerificationNetworkException([String? details])
      : super(
          details ?? 'Network error while verifying administrator permissions. Please check connection and retry.',
          isRetryable: true,
        );
}

/// General or unexpected authentication error
class GenericAuthException extends AppAuthException {
  const GenericAuthException(super.message, {super.isRetryable});
}

