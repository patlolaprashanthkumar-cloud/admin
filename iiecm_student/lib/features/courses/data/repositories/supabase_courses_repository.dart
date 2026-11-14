import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/supabase_client.dart';
import '../../domain/models/course_lesson.dart';
import '../../domain/models/course_module.dart';
import '../../domain/models/student_course.dart';
import '../../domain/repositories/courses_repository.dart';

/// Concrete Supabase implementation of CoursesRepository for the Student Portal
class SupabaseCoursesRepository implements CoursesRepository {
  SupabaseClient get _client => AppSupabase.client;

  @override
  Future<List<StudentCourse>> getEnrolledCourses(String studentRecordId) async {
    if (!AppSupabase.isInitialized) {
      throw StateError('Supabase is not initialized.');
    }

    if (studentRecordId.isEmpty) return [];

    try {
      // 1. Fetch student's course enrollment records
      final List<dynamic> enrollmentRows = await _client
          .from('course_enrollments')
          .select('id, course_id, status, enrolled_at')
          .eq('student_id', studentRecordId)
          .timeout(const Duration(seconds: 12));

      if (enrollmentRows.isEmpty) return [];

      final List<String> enrolledCourseIds = [];
      final Map<String, Map<String, dynamic>> enrollmentMap = {};

      for (final r in enrollmentRows) {
        final cid = r['course_id']?.toString() ?? '';
        if (cid.isNotEmpty) {
          enrolledCourseIds.add(cid);
          enrollmentMap[cid] = Map<String, dynamic>.from(r as Map);
        }
      }

      if (enrolledCourseIds.isEmpty) return [];

      // 2. Fetch course definitions matching the enrolled IDs
      final List<dynamic> courseRows = await _client
          .from('courses')
          .select('*')
          .inFilter('id', enrolledCourseIds)
          .timeout(const Duration(seconds: 12));

      // 3. Resolve instructor display names
      final Set<String> instructorIds = courseRows
          .map((c) => c['instructor_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
      final Map<String, String> instructorMap = {};

      if (instructorIds.isNotEmpty) {
        try {
          final List<dynamic> insRows = await _client
              .from('instructors')
              .select('id, full_name')
              .inFilter('id', instructorIds.toList())
              .timeout(const Duration(seconds: 8));

          for (final ins in insRows) {
            final id = ins['id']?.toString() ?? '';
            final name = ins['full_name']?.toString() ?? 'Faculty Member';
            if (id.isNotEmpty) instructorMap[id] = name;
          }
        } catch (_) {
          // Non-fatal
        }
      }

      return courseRows.map((c) {
        final cMap = Map<String, dynamic>.from(c as Map);
        final cid = cMap['id']?.toString() ?? '';
        final insId = cMap['instructor_id']?.toString() ?? '';
        return StudentCourse.fromData(
          courseJson: cMap,
          enrollmentJson: enrollmentMap[cid],
          instructorName: instructorMap[insId],
        );
      }).toList();
    } catch (e) {
      developer.log(
        'Error fetching enrolled courses for student $studentRecordId: $e',
        name: 'SupabaseCoursesRepository',
      );
      rethrow;
    }
  }

  @override
  Future<StudentCourse?> getCourseDetails(
    String courseId,
    String studentRecordId,
  ) async {
    if (!AppSupabase.isInitialized) {
      throw StateError('Supabase is not initialized.');
    }

    try {
      final courseRow = await _client
          .from('courses')
          .select('*')
          .eq('id', courseId)
          .maybeSingle()
          .timeout(const Duration(seconds: 10));

      if (courseRow == null) return null;

      final courseMap = Map<String, dynamic>.from(courseRow);

      // Check enrollment
      Map<String, dynamic>? enrollmentMap;
      if (studentRecordId.isNotEmpty) {
        try {
          final enrRow = await _client
              .from('course_enrollments')
              .select('*')
              .eq('course_id', courseId)
              .eq('student_id', studentRecordId)
              .maybeSingle()
              .timeout(const Duration(seconds: 8));
          if (enrRow != null) {
            enrollmentMap = Map<String, dynamic>.from(enrRow);
          }
        } catch (_) {
          // Non-fatal
        }
      }

      // Instructor
      String? instructorName;
      final insId = courseMap['instructor_id']?.toString();
      if (insId != null && insId.isNotEmpty) {
        try {
          final insRow = await _client
              .from('instructors')
              .select('full_name')
              .eq('id', insId)
              .maybeSingle()
              .timeout(const Duration(seconds: 8));
          instructorName = insRow?['full_name']?.toString();
        } catch (_) {}
      }

      return StudentCourse.fromData(
        courseJson: courseMap,
        enrollmentJson: enrollmentMap,
        instructorName: instructorName,
      );
    } catch (e) {
      developer.log(
        'Error fetching course details for $courseId: $e',
        name: 'SupabaseCoursesRepository',
      );
      rethrow;
    }
  }

  @override
  Future<List<CourseModule>> getCourseModules(String courseId) async {
    if (!AppSupabase.isInitialized) {
      throw StateError('Supabase is not initialized.');
    }

    try {
      // 1. Fetch all modules for this course ordered by order_index
      final List<dynamic> modRows = await _client
          .from('course_modules')
          .select('*')
          .eq('course_id', courseId)
          .order('order_index', ascending: true)
          .timeout(const Duration(seconds: 10));

      final List<CourseModule> modules = [];

      for (final m in modRows) {
        final mMap = Map<String, dynamic>.from(m as Map);
        final moduleId = mMap['id']?.toString() ?? '';

        // 2. Fetch all lessons for this module ordered by order_index
        List<CourseLesson> lessons = [];
        if (moduleId.isNotEmpty) {
          try {
            final List<dynamic> lessonRows = await _client
                .from('course_lessons')
                .select('*')
                .eq('module_id', moduleId)
                .order('order_index', ascending: true)
                .timeout(const Duration(seconds: 10));

            lessons = lessonRows
                .map((l) => CourseLesson.fromJson(Map<String, dynamic>.from(l as Map)))
                .toList();
          } catch (le) {
            developer.log(
              'Error fetching lessons for module $moduleId: $le',
              name: 'SupabaseCoursesRepository',
            );
          }
        }

        modules.add(CourseModule.fromJson(mMap, lessons: lessons));
      }

      return modules;
    } catch (e) {
      developer.log(
        'Error fetching course modules for $courseId: $e',
        name: 'SupabaseCoursesRepository',
      );
      rethrow;
    }
  }
}

