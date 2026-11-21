/// Enum representing the authoritative lifecycle completion status
/// of a permanent student deletion operation.
enum StudentDeletionStatus {
  completed('completed'),
  failedAuth('failed_auth');

  final String value;
  const StudentDeletionStatus(this.value);

  static StudentDeletionStatus fromString(String? status) {
    if (status != null && status.trim().toLowerCase() == 'failed_auth') {
      return StudentDeletionStatus.failedAuth;
    }
    return StudentDeletionStatus.completed;
  }
}

/// Represents the typed outcome of a permanent student deletion request
/// executed via the administrative Edge Function `admin-delete-student`.
class StudentDeletionResult {
  final StudentDeletionStatus status;
  final String studentId;
  final String? studentCode;
  final String? fullName;
  final String? email;
  final String? profileId;
  final String? deletionRecordId;
  final String message;
  final bool authDeleted;
  final bool isRecoveryRetry;
  final String? recoveryInstruction;

  const StudentDeletionResult({
    required this.status,
    required this.studentId,
    this.studentCode,
    this.fullName,
    this.email,
    this.profileId,
    this.deletionRecordId,
    required this.message,
    this.authDeleted = false,
    this.isRecoveryRetry = false,
    this.recoveryInstruction,
  });

  /// Returns true only when both database records and Supabase Auth credentials
  /// have been fully and permanently removed.
  bool get isCompleted => status == StudentDeletionStatus.completed;

  /// Returns true when database records were successfully deleted, but
  /// Supabase Auth user deletion encountered an error, leaving a durable recovery record.
  bool get isFailedAuth => status == StudentDeletionStatus.failedAuth;

  /// Convenience alias for partial failure
  bool get isPartialFailure => isFailedAuth;

  factory StudentDeletionResult.completed({
    required String studentId,
    String? studentCode,
    String? fullName,
    String? email,
    String? profileId,
    String? deletionRecordId,
    required String message,
    bool authDeleted = true,
    bool isRecoveryRetry = false,
  }) {
    return StudentDeletionResult(
      status: StudentDeletionStatus.completed,
      studentId: studentId,
      studentCode: studentCode,
      fullName: fullName,
      email: email,
      profileId: profileId,
      deletionRecordId: deletionRecordId,
      message: message,
      authDeleted: authDeleted,
      isRecoveryRetry: isRecoveryRetry,
    );
  }

  factory StudentDeletionResult.failedAuth({
    required String studentId,
    String? studentCode,
    String? fullName,
    String? email,
    String? profileId,
    String? deletionRecordId,
    required String message,
    String? recoveryInstruction,
  }) {
    return StudentDeletionResult(
      status: StudentDeletionStatus.failedAuth,
      studentId: studentId,
      studentCode: studentCode,
      fullName: fullName,
      email: email,
      profileId: profileId,
      deletionRecordId: deletionRecordId,
      message: message,
      authDeleted: false,
      recoveryInstruction: recoveryInstruction,
    );
  }

  factory StudentDeletionResult.fromJson(
    Map<String, dynamic> json, {
    required String fallbackStudentId,
  }) {
    final statusStr = json['status']?.toString();
    final status = StudentDeletionStatus.fromString(statusStr);
    final deletedStudent = json['deletedStudent'] is Map
        ? Map<String, dynamic>.from(json['deletedStudent'] as Map)
        : null;

    final studentId =
        json['studentId']?.toString() ??
        deletedStudent?['id']?.toString() ??
        fallbackStudentId;

    return StudentDeletionResult(
      status: status,
      studentId: studentId,
      studentCode:
          json['studentCode']?.toString() ??
          deletedStudent?['studentCode']?.toString(),
      fullName:
          json['fullName']?.toString() ??
          deletedStudent?['fullName']?.toString(),
      email: json['email']?.toString() ?? deletedStudent?['email']?.toString(),
      profileId:
          json['profileId']?.toString() ??
          deletedStudent?['profileId']?.toString(),
      deletionRecordId: json['deletionRecordId']?.toString(),
      message:
          json['message']?.toString() ??
          json['error']?.toString() ??
          (status == StudentDeletionStatus.completed
              ? 'Student permanently deleted.'
              : 'Database records deleted; Auth cleanup failed.'),
      authDeleted: json['authDeleted'] == true,
      isRecoveryRetry: json['isRecoveryRetry'] == true,
      recoveryInstruction: json['recoveryInstruction']?.toString(),
    );
  }
}

/// Explicit domain exception representing failure during permanent student deletion.
class StudentDeletionException implements Exception {
  final String message;
  final int statusCode;
  final String? code;
  final String? studentId;
  final String? deletionRecordId;
  final bool isPartialFailure;
  final Map<String, dynamic>? counts;

  const StudentDeletionException({
    required this.message,
    this.statusCode = 500,
    this.code,
    this.studentId,
    this.deletionRecordId,
    this.isPartialFailure = false,
    this.counts,
  });

  /// HTTP 401: Admin session expired or invalid
  bool get isUnauthorized => statusCode == 401;

  /// HTTP 403: Caller does not have Super Admin authority
  bool get isForbidden => statusCode == 403;

  /// HTTP 409 or Dependency Conflict: Protected payments, enrollments, or academic records exist
  bool get isConflict =>
      statusCode == 409 ||
      code == 'PROTECTED_DEPENDENCIES_EXIST' ||
      code == 'STUDENT_NOT_ELIGIBLE';

  /// Self-deletion safety check
  bool get isSelfDeletion => code == 'SELF_DELETION_PROHIBITED';

  /// Student record does not exist
  bool get isNotFound => statusCode == 404 || code == 'STUDENT_NOT_FOUND';

  /// HTTP 502 or partial failure where DB deleted but Auth cleanup failed
  bool get isPartialAuthFailure => statusCode == 502 || isPartialFailure;

  @override
  String toString() => message;
}
