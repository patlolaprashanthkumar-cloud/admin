import '../../../auth/domain/models/student_profile.dart';

/// Contract defining profile management and account security actions
abstract class ProfileRepository {
  /// Updates student's editable personal and contact details in Supabase
  Future<StudentProfile> updateProfile({
    required String userId,
    required String studentRecordId,
    required String fullName,
    required String phone,
    String? qualification,
    String? educationLevel,
    String? preferredCategory,
    String? city,
  });

  /// Changes the authenticated student's password using Supabase Auth
  Future<void> changePassword({
    required String newPassword,
  });
}

