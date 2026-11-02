import '../models/faculty.dart';

abstract class FacultyRepository {
  /// Fetch all faculty with optional category, status, or search filters
  Future<List<Faculty>> getFaculty({
    String? categoryId,
    String? status,
    String? searchQuery,
  });

  /// Fetch a single faculty member by ID with full relations
  Future<Faculty?> getFacultyById(String id);

  /// Create a new faculty member with category mappings & course assignments
  Future<Faculty> createFaculty(
    Faculty faculty, {
    List<String> categoryIds = const [],
    List<String> courseIds = const [],
  });

  /// Update an existing faculty member's profile, categories & course assignments
  Future<Faculty> updateFaculty(
    Faculty faculty, {
    List<String>? categoryIds,
    List<String>? courseIds,
  });

  /// Update account status ('active', 'suspended', 'inactive')
  Future<void> updateFacultyStatus(String id, String status);

  /// Delete or archive a faculty member
  Future<void> deleteFaculty(String id);
}
