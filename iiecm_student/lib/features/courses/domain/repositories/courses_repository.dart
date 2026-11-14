import '../models/course_module.dart';
import '../models/student_course.dart';

/// Contract for student course catalog and curriculum access
abstract class CoursesRepository {
  /// Loads all courses the student is actively enrolled in
  Future<List<StudentCourse>> getEnrolledCourses(String studentRecordId);

  /// Loads full course details with enrollment metadata for the specified student
  Future<StudentCourse?> getCourseDetails(String courseId, String studentRecordId);

  /// Loads all curriculum modules and lessons for a course ordered by order_index
  Future<List<CourseModule>> getCourseModules(String courseId);
}

