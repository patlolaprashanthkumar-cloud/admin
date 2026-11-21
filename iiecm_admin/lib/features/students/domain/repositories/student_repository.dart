import '../models/student.dart';

abstract class StudentRepository {
  Future<List<Student>> getStudents({
    String? categoryId,
    String? searchQuery,
    String? status,
  });
  Future<Student?> getStudentById(String id);
  Future<StudentRegistrationResult> registerStudent({
    required String fullName,
    required String email,
    required String phone,
    required String educationLevel,
    required String qualification,
    required List<String> categoryIds,
    required List<String> courseIds,
    String? city,
    String subscriptionPlan = 'basic',
    String? learningFormat,
    String? preferredSlot,
  });
  Future<Student> updateStudent(
    String id, {
    String? fullName,
    String? email,
    String? phone,
    String? educationLevel,
    String? qualification,
    String? city,
    String? accountStatus,
  });
  Future<void> updateStudentCategories(
    String studentId,
    List<String> categoryIds,
  );
  Future<void> unenrollStudentCourse(
    String studentId,
    String courseId,
  );
  Future<void> updateStudentCourses(
    String studentId,
    List<String> courseIds,
  );
  Future<void> updateStudentStreamsAndCourses(
    String studentId, {
    required List<String> categoryIds,
    required List<String> courseIds,
  });
  Future<List<StudentCategoryLmsGroup>> getStudentCategoryLmsDetails(
    String studentId,
  );

  /// Performs preflight dependency eligibility check for permanent student deletion.
  Future<Map<String, dynamic>> checkStudentDeletionEligibility(
    String studentId,
  );

  /// Permanently deletes an eligible student and their Supabase Auth credentials
  /// via the secure administrative Edge Function.
  Future<StudentDeletionResult> deleteStudent(String studentId);
}
