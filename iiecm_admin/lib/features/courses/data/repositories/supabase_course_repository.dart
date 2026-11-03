import 'dart:developer' as developer;

import '../../../../core/network/supabase_client.dart';
import '../../domain/models/course.dart';
import '../../domain/models/course_lesson.dart';
import '../../domain/models/course_module.dart';
import '../../domain/repositories/course_repository.dart';

class SupabaseCourseRepository implements CourseRepository {
  @override
  Future<List<Course>> getCourses({
    String? categoryId,
    String? status,
    String? searchQuery,
  }) async {
    final client = AppSupabase.client;

    try {
      var query = client.from('courses').select('*');

      if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all') {
        query = query.eq('category_id', categoryId);
      }
      if (status != null && status.isNotEmpty && status != 'all') {
        query = query.eq('status', status);
      }

      final List<dynamic> rows = await query.order(
        'created_at',
        ascending: false,
      );

      // Fetch instructors for display
      final Map<String, String> instructorNames = {};
      try {
        final instructors = await client
            .from('instructors')
            .select('id, full_name');
        for (final ins in instructors) {
          instructorNames[ins['id'].toString()] =
              ins['full_name']?.toString() ?? 'Faculty Member';
        }
      } catch (_) {}

      // Fetch enrollment counts
      final Map<String, int> enrollCounts = {};
      try {
        final enrollments = await client
            .from('course_enrollments')
            .select('course_id');
        for (final e in enrollments) {
          final cid = e['course_id']?.toString() ?? '';
          if (cid.isNotEmpty) {
            enrollCounts[cid] = (enrollCounts[cid] ?? 0) + 1;
          }
        }
      } catch (_) {}

      final courses = rows.map((r) {
        final insId = r['instructor_id']?.toString();
        final cid = r['id']?.toString() ?? '';
        return Course.fromJson(
          r as Map<String, dynamic>,
          instructorName: insId != null ? instructorNames[insId] : null,
          enrolledCount: enrollCounts[cid] ?? 0,
        );
      }).toList();

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.toLowerCase().trim();
        return courses
            .where(
              (c) =>
                  c.title.toLowerCase().contains(q) ||
                  c.description.toLowerCase().contains(q) ||
                  c.categoryName.toLowerCase().contains(q),
            )
            .toList();
      }

      return courses;
    } catch (e) {
      developer.log(
        'Error fetching courses: $e',
        name: 'SupabaseCourseRepository',
      );
      return [];
    }
  }

  @override
  Future<Course?> getCourseById(String id) async {
    final client = AppSupabase.client;
    try {
      final res = await client
          .from('courses')
          .select('*')
          .eq('id', id)
          .maybeSingle();
      if (res == null) return null;

      String? instructorName;
      final insId = res['instructor_id']?.toString();
      if (insId != null && insId.isNotEmpty) {
        final ins = await client
            .from('instructors')
            .select('full_name')
            .eq('id', insId)
            .maybeSingle();
        instructorName = ins?['full_name']?.toString();
      }

      int enrolledCount = 0;
      try {
        final enrollments = await client
            .from('course_enrollments')
            .select('id')
            .eq('course_id', id);
        enrolledCount = enrollments.length;
      } catch (_) {}

      return Course.fromJson(
        res,
        instructorName: instructorName,
        enrolledCount: enrolledCount,
      );
    } catch (e) {
      developer.log(
        'Error fetching course by id $id: $e',
        name: 'SupabaseCourseRepository',
      );
      return null;
    }
  }

  @override
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
  }) async {
    final client = AppSupabase.client;
    final payload = <String, dynamic>{
      'title': title.trim(),
      'description': description.trim(),
      'category_id': categoryId,
      'category_name': categoryName,
      'instructor_id': instructorId,
      'duration_weeks': durationWeeks,
      'fee': fee,
      'format': format,
      'status': status,
      if (status == 'published')
        'published_at': DateTime.now().toIso8601String(),
    };

    try {
      final res = await client
          .from('courses')
          .insert(payload)
          .select()
          .single();
      return Course.fromJson(res);
    } catch (e) {
      developer.log(
        'Error creating course: $e',
        name: 'SupabaseCourseRepository',
      );
      rethrow;
    }
  }

  @override
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
  }) async {
    final client = AppSupabase.client;
    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title.trim();
    if (description != null) updates['description'] = description.trim();
    if (categoryId != null) updates['category_id'] = categoryId;
    if (categoryName != null) updates['category_name'] = categoryName;
    if (instructorId != null) updates['instructor_id'] = instructorId;
    if (durationWeeks != null) updates['duration_weeks'] = durationWeeks;
    if (fee != null) updates['fee'] = fee;
    if (format != null) updates['format'] = format;
    if (status != null) {
      updates['status'] = status;
      if (status == 'published') {
        updates['published_at'] = DateTime.now().toIso8601String();
      }
    }

    try {
      final res = await client
          .from('courses')
          .update(updates)
          .eq('id', id)
          .select()
          .single();
      return Course.fromJson(res);
    } catch (e) {
      developer.log(
        'Error updating course $id: $e',
        name: 'SupabaseCourseRepository',
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteCourse(String id) async {
    final client = AppSupabase.client;
    try {
      await client.from('courses').delete().eq('id', id);
    } catch (e) {
      developer.log(
        'Error deleting course $id: $e',
        name: 'SupabaseCourseRepository',
      );
      rethrow;
    }
  }

  @override
  Future<List<CourseModule>> getModules(String courseId) async {
    final client = AppSupabase.client;
    try {
      final List<dynamic> modRows = await client
          .from('course_modules')
          .select('*')
          .eq('course_id', courseId)
          .order('order_index', ascending: true);

      final List<CourseModule> modules = [];
      for (final m in modRows) {
        final mId = m['id']?.toString() ?? '';
        final List<dynamic> lessonRows = await client
            .from('course_lessons')
            .select('*')
            .eq('module_id', mId)
            .order('order_index', ascending: true);

        final lessons = lessonRows
            .map((l) => CourseLesson.fromJson(l as Map<String, dynamic>))
            .toList();

        modules.add(
          CourseModule.fromJson(m as Map<String, dynamic>, lessons: lessons),
        );
      }

      return modules;
    } catch (e) {
      developer.log(
        'Error fetching modules for course $courseId: $e',
        name: 'SupabaseCourseRepository',
      );
      rethrow;
    }
  }

  @override
  Future<CourseModule> createModule(CourseModule module) async {
    final client = AppSupabase.client;
    try {
      final res = await client
          .from('course_modules')
          .insert(module.toJson())
          .select('*')
          .single();
      return CourseModule.fromJson(res);
    } catch (e) {
      developer.log(
        'Error creating course module: $e',
        name: 'SupabaseCourseRepository',
      );
      rethrow;
    }
  }

  @override
  Future<CourseModule> updateModule(CourseModule module) async {
    final client = AppSupabase.client;
    try {
      final res = await client
          .from('course_modules')
          .update(module.toJson())
          .eq('id', module.id)
          .select('*')
          .single();
      return CourseModule.fromJson(res, lessons: module.lessons);
    } catch (e) {
      developer.log(
        'Error updating course module: $e',
        name: 'SupabaseCourseRepository',
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteModule(String moduleId) async {
    final client = AppSupabase.client;
    try {
      await client.from('course_modules').delete().eq('id', moduleId);
    } catch (e) {
      developer.log(
        'Error deleting course module: $e',
        name: 'SupabaseCourseRepository',
      );
      rethrow;
    }
  }

  @override
  Future<CourseLesson> createLesson(CourseLesson lesson) async {
    final client = AppSupabase.client;
    try {
      final res = await client
          .from('course_lessons')
          .insert(lesson.toJson())
          .select('*')
          .single();
      return CourseLesson.fromJson(res);
    } catch (e) {
      developer.log(
        'Error creating course lesson: $e',
        name: 'SupabaseCourseRepository',
      );
      rethrow;
    }
  }

  @override
  Future<CourseLesson> updateLesson(CourseLesson lesson) async {
    final client = AppSupabase.client;
    try {
      final res = await client
          .from('course_lessons')
          .update(lesson.toJson())
          .eq('id', lesson.id)
          .select('*')
          .single();
      return CourseLesson.fromJson(res);
    } catch (e) {
      developer.log(
        'Error updating course lesson: $e',
        name: 'SupabaseCourseRepository',
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteLesson(String lessonId) async {
    final client = AppSupabase.client;
    try {
      await client.from('course_lessons').delete().eq('id', lessonId);
    } catch (e) {
      developer.log(
        'Error deleting course lesson: $e',
        name: 'SupabaseCourseRepository',
      );
      rethrow;
    }
  }
}
