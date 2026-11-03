import 'dart:developer' as developer;

import '../../../../core/network/supabase_client.dart';
import '../../../categories/domain/models/course_category.dart';
import '../../domain/models/faculty.dart';
import '../../domain/repositories/faculty_repository.dart';

class SupabaseFacultyRepository implements FacultyRepository {
  @override
  Future<List<Faculty>> getFaculty({
    String? categoryId,
    String? status,
    String? searchQuery,
  }) async {
    final client = AppSupabase.client;

    try {
      var query = client.from('instructors').select('*');
      if (status != null && status.isNotEmpty && status != 'all') {
        query = query.eq('account_status', status);
      }

      final List<dynamic> rows = await query.order(
        'created_at',
        ascending: false,
      );

      // 1. Fetch categories for name/color lookup
      final Map<String, CourseCategory> catMap = {};
      try {
        final catRows = await client.from('course_categories').select('*');
        for (final c in catRows) {
          catMap[c['id'].toString()] = CourseCategory.fromJson(c);
        }
      } catch (e) {
        developer.log(
          'Error fetching categories: $e',
          name: 'SupabaseFacultyRepository',
        );
      }

      // 2. Fetch instructor_categories mappings
      final Map<String, List<CourseCategory>> instructorCats = {};
      try {
        final jRows = await client
            .from('instructor_categories')
            .select('instructor_id, category_id');
        for (final j in jRows) {
          final instId = j['instructor_id']?.toString() ?? '';
          final cId = j['category_id']?.toString() ?? '';
          if (catMap.containsKey(cId)) {
            instructorCats.putIfAbsent(instId, () => []).add(catMap[cId]!);
          }
        }
      } catch (e) {
        developer.log(
          'Error fetching instructor_categories: $e',
          name: 'SupabaseFacultyRepository',
        );
      }

      // 3. Fetch courses assigned to instructors
      final Map<String, List<FacultyCourseRef>> instructorCourses = {};
      final Map<String, List<String>> instructorCourseIds = {};
      try {
        final cRows = await client
            .from('courses')
            .select('id, title, category_name, instructor_id');
        for (final c in cRows) {
          final instId = c['instructor_id']?.toString();
          if (instId != null && instId.isNotEmpty) {
            final courseRef = FacultyCourseRef.fromJson(c);
            instructorCourses.putIfAbsent(instId, () => []).add(courseRef);
            instructorCourseIds.putIfAbsent(instId, () => []).add(courseRef.id);
          }
        }
      } catch (e) {
        developer.log(
          'Error fetching courses for instructors: $e',
          name: 'SupabaseFacultyRepository',
        );
      }

      List<Faculty> facultyList = rows.map((r) {
        final instId = r['id']?.toString() ?? '';
        return Faculty.fromJson(
          r as Map<String, dynamic>,
          assignedCategories: instructorCats[instId] ?? [],
          assignedCourseIds: instructorCourseIds[instId] ?? [],
          assignedCourses: instructorCourses[instId] ?? [],
        );
      }).toList();

      // Filter by category if requested
      if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all') {
        facultyList = facultyList.where((f) {
          return f.assignedCategories.any((cat) => cat.id == categoryId);
        }).toList();
      }

      // Filter by search query if requested
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        facultyList = facultyList.where((f) {
          return f.fullName.toLowerCase().contains(q) ||
              f.email.toLowerCase().contains(q) ||
              f.specialization.toLowerCase().contains(q) ||
              f.qualifications.toLowerCase().contains(q);
        }).toList();
      }

      return facultyList;
    } catch (e) {
      developer.log(
        'Error in getFaculty: $e',
        name: 'SupabaseFacultyRepository',
      );
      rethrow;
    }
  }

  @override
  Future<Faculty?> getFacultyById(String id) async {
    final client = AppSupabase.client;

    try {
      final List<dynamic> rows = await client
          .from('instructors')
          .select('*')
          .eq('id', id)
          .limit(1);

      if (rows.isEmpty) return null;

      final instRow = rows.first as Map<String, dynamic>;

      // Load categories
      final List<CourseCategory> assignedCategories = [];
      try {
        final jRows = await client
            .from('instructor_categories')
            .select('category_id, course_categories(*)')
            .eq('instructor_id', id);

        for (final j in jRows) {
          if (j['course_categories'] != null) {
            assignedCategories.add(
              CourseCategory.fromJson(
                j['course_categories'] as Map<String, dynamic>,
              ),
            );
          }
        }
      } catch (e) {
        developer.log(
          'Error fetching instructor categories by id: $e',
          name: 'SupabaseFacultyRepository',
        );
      }

      // Load assigned courses
      final List<FacultyCourseRef> courses = [];
      final List<String> courseIds = [];
      try {
        final cRows = await client
            .from('courses')
            .select('id, title, category_name')
            .eq('instructor_id', id);

        for (final c in cRows) {
          final cId = c['id']?.toString() ?? '';
          courses.add(FacultyCourseRef.fromJson(c));
          courseIds.add(cId);
        }
      } catch (e) {
        developer.log(
          'Error fetching courses by instructor id: $e',
          name: 'SupabaseFacultyRepository',
        );
      }

      return Faculty.fromJson(
        instRow,
        assignedCategories: assignedCategories,
        assignedCourseIds: courseIds,
        assignedCourses: courses,
      );
    } catch (e) {
      developer.log(
        'Error in getFacultyById: $e',
        name: 'SupabaseFacultyRepository',
      );
      rethrow;
    }
  }

  @override
  Future<Faculty> createFaculty(
    Faculty faculty, {
    List<String> categoryIds = const [],
    List<String> courseIds = const [],
  }) async {
    final client = AppSupabase.client;

    try {
      final payload = faculty.toJson();
      final List<dynamic> inserted = await client
          .from('instructors')
          .insert(payload)
          .select('*');

      if (inserted.isEmpty) {
        throw Exception('Failed to insert faculty record.');
      }

      final newInst = inserted.first as Map<String, dynamic>;
      final newId = newInst['id'].toString();

      // 1. Insert category associations
      if (categoryIds.isNotEmpty) {
        final jPayload = categoryIds
            .map((catId) => {'instructor_id': newId, 'category_id': catId})
            .toList();
        await client.from('instructor_categories').insert(jPayload);
      }

      // 2. Link courses to this instructor
      if (courseIds.isNotEmpty) {
        for (final cId in courseIds) {
          await client
              .from('courses')
              .update({'instructor_id': newId})
              .eq('id', cId);
        }
      }

      return (await getFacultyById(newId)) ?? Faculty.fromJson(newInst);
    } catch (e) {
      developer.log(
        'Error in createFaculty: $e',
        name: 'SupabaseFacultyRepository',
      );
      rethrow;
    }
  }

  @override
  Future<Faculty> updateFaculty(
    Faculty faculty, {
    List<String>? categoryIds,
    List<String>? courseIds,
  }) async {
    final client = AppSupabase.client;

    try {
      final payload = faculty.toJson();
      await client.from('instructors').update(payload).eq('id', faculty.id);

      // 1. Update category associations if provided
      if (categoryIds != null) {
        await client
            .from('instructor_categories')
            .delete()
            .eq('instructor_id', faculty.id);
        if (categoryIds.isNotEmpty) {
          final jPayload = categoryIds
              .map(
                (catId) => {'instructor_id': faculty.id, 'category_id': catId},
              )
              .toList();
          await client.from('instructor_categories').insert(jPayload);
        }
      }

      // 2. Update course associations if provided
      if (courseIds != null) {
        // Unlink courses previously assigned to this instructor that are no longer selected
        await client
            .from('courses')
            .update({'instructor_id': null})
            .eq('instructor_id', faculty.id);

        if (courseIds.isNotEmpty) {
          for (final cId in courseIds) {
            await client
                .from('courses')
                .update({'instructor_id': faculty.id})
                .eq('id', cId);
          }
        }
      }

      return (await getFacultyById(faculty.id)) ?? faculty;
    } catch (e) {
      developer.log(
        'Error in updateFaculty: $e',
        name: 'SupabaseFacultyRepository',
      );
      rethrow;
    }
  }

  @override
  Future<void> updateFacultyStatus(String id, String status) async {
    final client = AppSupabase.client;
    try {
      await client
          .from('instructors')
          .update({'account_status': status})
          .eq('id', id);
    } catch (e) {
      developer.log(
        'Error in updateFacultyStatus: $e',
        name: 'SupabaseFacultyRepository',
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteFaculty(String id) async {
    final client = AppSupabase.client;
    try {
      // Unlink courses first
      await client
          .from('courses')
          .update({'instructor_id': null})
          .eq('instructor_id', id);
      // Remove junction mappings
      await client
          .from('instructor_categories')
          .delete()
          .eq('instructor_id', id);
      // Delete instructor
      await client.from('instructors').delete().eq('id', id);
    } catch (e) {
      developer.log(
        'Error in deleteFaculty: $e',
        name: 'SupabaseFacultyRepository',
      );
      rethrow;
    }
  }
}
