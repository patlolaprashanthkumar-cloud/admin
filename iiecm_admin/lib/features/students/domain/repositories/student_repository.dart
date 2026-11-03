import '../models/student.dart';

abstract class StudentRepository {
  Future<List<Student>> getStudents({
    String? categoryId,
    String? searchQuery,
    String? status,
  });
  Future<Student?> getStudentById(String id);
  Future<Student> registerStudent({
    required String fullName,
    required String email,
    required String phone,
    required String educationLevel,
    required String qualification,
    required List<String> categoryIds,
    required List<String> courseIds,
    String? city,
    String subscriptionPlan = 'basic',
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
  Future<List<StudentCategoryLmsGroup>> getStudentCategoryLmsDetails(
    String studentId,
  );
}
