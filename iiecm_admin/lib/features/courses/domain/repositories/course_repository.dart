import '../models/course.dart';
import '../models/course_lesson.dart';
import '../models/course_module.dart';

abstract class CourseRepository {
  Future<List<Course>> getCourses({
    String? categoryId,
    String? status,
    String? searchQuery,
  });
  Future<Course?> getCourseById(String id);
  Future<Course> createCourse({
    required String title,
    required String description,
    required String categoryId,
    required String categoryName,
    String? instructorId,
    int durationWeeks = 8,
    double fee = 0.0,
    String format = 'hybrid',
    String status = 'draft',
  });
  Future<Course> updateCourse(
    String id, {
    String? title,
    String? description,
    String? categoryId,
    String? categoryName,
    String? instructorId,
    int? durationWeeks,
    double? fee,
    String? format,
    String? status,
  });
  Future<void> deleteCourse(String id);

  // Course Modules & Lessons (Video Curriculum with Thumbnails)
  Future<List<CourseModule>> getModules(String courseId);
  Future<CourseModule> createModule(CourseModule module);
  Future<CourseModule> updateModule(CourseModule module);
  Future<void> deleteModule(String moduleId);
  Future<CourseLesson> createLesson(CourseLesson lesson);
  Future<CourseLesson> updateLesson(CourseLesson lesson);
  Future<void> deleteLesson(String lessonId);
}
