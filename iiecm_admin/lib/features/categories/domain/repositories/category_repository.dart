import '../models/course_category.dart';

abstract class CategoryRepository {
  Future<List<CourseCategory>> getCategories({bool? onlyActive});
  Future<CourseCategory?> getCategoryById(String id);
  Future<CourseCategory> createCategory({
    required String name,
    required String description,
    required String color,
    String? iconName,
    bool isActive = true,
  });
  Future<CourseCategory> updateCategory(
    String id, {
    String? name,
    String? description,
    String? color,
    String? iconName,
    bool? isActive,
  });
  Future<void> toggleCategoryActive(String id, bool isActive);
  Future<void> deleteCategory(String id);
  Future<List<Map<String, dynamic>>> getCoursesForCategory(String categoryId);
  Future<List<Map<String, dynamic>>> getInstructorsForCategory(
    String categoryId,
  );
  Future<List<Map<String, dynamic>>> getStudentsForCategory(String categoryId);

  // Student Multi-Category Junction Methods
  Future<List<CourseCategory>> getCategoriesForStudent(String studentId);
  Future<void> assignCategoriesToStudent(
    String studentId,
    List<String> categoryIds,
  );
  Future<void> removeCategoryFromStudent(String studentId, String categoryId);

  // Instructor Multi-Category Junction Methods
  Future<List<CourseCategory>> getCategoriesForInstructor(String instructorId);
  Future<void> assignCategoriesToInstructor(
    String instructorId,
    List<String> categoryIds,
  );
  Future<void> removeCategoryFromInstructor(
    String instructorId,
    String categoryId,
  );
}
