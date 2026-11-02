import 'dart:developer' as developer;
import '../../../../core/network/supabase_client.dart';
import '../../domain/models/course_category.dart';
import '../../domain/repositories/category_repository.dart';

class SupabaseCategoryRepository implements CategoryRepository {
  @override
  Future<List<CourseCategory>> getCategories({bool? onlyActive}) async {
    final client = AppSupabase.client;

    try {
      var query = client.from('course_categories').select('*');
      if (onlyActive == true) {
        query = query.eq('is_active', true);
      }
      final List<dynamic> catRows = await query.order('name', ascending: true);

      // Fetch courses telemetry to compute associated courses and faculty
      List<dynamic> courses = [];
      try {
        courses = await client.from('courses').select('id, category_id, instructor_id');
      } catch (e) {
        developer.log('Error fetching courses for category counts: $e', name: 'SupabaseCategoryRepository');
      }

      // Fetch course enrollments to compute enrolled student counts
      List<dynamic> enrollments = [];
      try {
        enrollments = await client.from('course_enrollments').select('course_id, student_id');
      } catch (e) {
        developer.log('Error fetching enrollments for category counts: $e', name: 'SupabaseCategoryRepository');
      }

      // Map counts
      final Map<String, int> courseCountMap = {};
      final Map<String, Set<String>> instructorMap = {};
      final Map<String, String> courseToCategoryMap = {};

      for (final c in courses) {
        final catId = c['category_id']?.toString() ?? '';
        final courseId = c['id']?.toString() ?? '';
        final instructorId = c['instructor_id']?.toString();

        if (catId.isNotEmpty) {
          courseCountMap[catId] = (courseCountMap[catId] ?? 0) + 1;
          courseToCategoryMap[courseId] = catId;

          if (instructorId != null && instructorId.isNotEmpty) {
            instructorMap.putIfAbsent(catId, () => <String>{}).add(instructorId);
          }
        }
      }

      final Map<String, Set<String>> studentMap = {};
      for (final e in enrollments) {
        final courseId = e['course_id']?.toString() ?? '';
        final studentId = e['student_id']?.toString() ?? '';
        final catId = courseToCategoryMap[courseId];
        if (catId != null && studentId.isNotEmpty) {
          studentMap.putIfAbsent(catId, () => <String>{}).add(studentId);
        }
      }

      return catRows.map((json) {
        final id = json['id']?.toString() ?? '';
        final cCount = courseCountMap[id] ?? (json['course_count'] is int ? json['course_count'] as int : 0);
        final iCount = instructorMap[id]?.length ?? 0;
        final sCount = studentMap[id]?.length ?? 0;

        return CourseCategory.fromJson(
          json as Map<String, dynamic>,
          courseCount: cCount,
          instructorCount: iCount,
          studentCount: sCount,
        );
      }).toList();
    } catch (e) {
      developer.log('Error loading categories: $e', name: 'SupabaseCategoryRepository');
      rethrow;
    }
  }

  @override
  Future<CourseCategory?> getCategoryById(String id) async {
    final client = AppSupabase.client;
    try {
      final res = await client
          .from('course_categories')
          .select('*')
          .eq('id', id)
          .maybeSingle();

      if (res == null) return null;

      final courses = await client.from('courses').select('id, instructor_id').eq('category_id', id);
      final courseCount = courses.length;
      final instructorIds = courses
          .map((c) => c['instructor_id']?.toString())
          .where((i) => i != null && i.isNotEmpty)
          .toSet();

      final courseIds = courses.map((c) => c['id'].toString()).toList();
      int studentCount = 0;
      if (courseIds.isNotEmpty) {
        final enrollments = await client
            .from('course_enrollments')
            .select('student_id')
            .inFilter('course_id', courseIds);
        studentCount = enrollments.map((e) => e['student_id'].toString()).toSet().length;
      }

      return CourseCategory.fromJson(
        res,
        courseCount: courseCount,
        instructorCount: instructorIds.length,
        studentCount: studentCount,
      );
    } catch (e) {
      developer.log('Error loading category by id $id: $e', name: 'SupabaseCategoryRepository');
      rethrow;
    }
  }

  @override
  Future<CourseCategory> createCategory({
    required String name,
    required String description,
    required String color,
    String? iconName,
    bool isActive = true,
  }) async {
    final client = AppSupabase.client;
    final payload = <String, dynamic>{
      'name': name.trim(),
      'description': description.trim(),
      'color': color.trim(),
      'is_active': isActive,
    };
    if (iconName != null) {
      // If table supports icon_name
      payload['icon_name'] = iconName;
    }

    try {
      final res = await client
          .from('course_categories')
          .insert(payload)
          .select()
          .single();

      return CourseCategory.fromJson(res);
    } catch (e) {
      // If icon_name failed because column not yet created, retry without icon_name
      if (payload.containsKey('icon_name')) {
        payload.remove('icon_name');
        final res = await client
            .from('course_categories')
            .insert(payload)
            .select()
            .single();
        return CourseCategory.fromJson(res);
      }
      developer.log('Error creating category: $e', name: 'SupabaseCategoryRepository');
      rethrow;
    }
  }

  @override
  Future<CourseCategory> updateCategory(
    String id, {
    String? name,
    String? description,
    String? color,
    String? iconName,
    bool? isActive,
  }) async {
    final client = AppSupabase.client;
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name.trim();
    if (description != null) updates['description'] = description.trim();
    if (color != null) updates['color'] = color.trim();
    if (isActive != null) updates['is_active'] = isActive;
    if (iconName != null) updates['icon_name'] = iconName;

    try {
      final res = await client
          .from('course_categories')
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      return CourseCategory.fromJson(res);
    } catch (e) {
      if (updates.containsKey('icon_name')) {
        updates.remove('icon_name');
        final res = await client
            .from('course_categories')
            .update(updates)
            .eq('id', id)
            .select()
            .single();
        return CourseCategory.fromJson(res);
      }
      developer.log('Error updating category $id: $e', name: 'SupabaseCategoryRepository');
      rethrow;
    }
  }

  @override
  Future<void> toggleCategoryActive(String id, bool isActive) async {
    final client = AppSupabase.client;
    await client.from('course_categories').update({'is_active': isActive}).eq('id', id);
  }

  @override
  Future<void> deleteCategory(String id) async {
    final client = AppSupabase.client;
    await client.from('course_categories').delete().eq('id', id);
  }

  @override
  Future<List<Map<String, dynamic>>> getCoursesForCategory(String categoryId) async {
    final client = AppSupabase.client;
    try {
      final res = await client
          .from('courses')
          .select('id, title, description, duration_weeks, fee, status, instructor_id')
          .eq('category_id', categoryId)
          .order('title', ascending: true);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      developer.log('Error fetching courses for category $categoryId: $e', name: 'SupabaseCategoryRepository');
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getInstructorsForCategory(String categoryId) async {
    final client = AppSupabase.client;
    try {
      final Set<String> instructorIds = {};

      // 1. Direct junction table query
      try {
        final jRows = await client
            .from('instructor_categories')
            .select('instructor_id')
            .eq('category_id', categoryId);
        for (final r in jRows) {
          final id = r['instructor_id']?.toString();
          if (id != null && id.isNotEmpty) instructorIds.add(id);
        }
      } catch (e) {
        developer.log('Error reading instructor_categories: $e', name: 'SupabaseCategoryRepository');
      }

      // 2. Fallback / supplementary via courses taught in this category
      try {
        final courses = await client
            .from('courses')
            .select('instructor_id')
            .eq('category_id', categoryId);
        for (final c in courses) {
          final id = c['instructor_id']?.toString();
          if (id != null && id.isNotEmpty) instructorIds.add(id);
        }
      } catch (_) {}

      if (instructorIds.isEmpty) return [];

      final instructors = await client
          .from('instructors')
          .select('id, full_name, email, specialization, rating, account_status')
          .inFilter('id', instructorIds.toList());

      return List<Map<String, dynamic>>.from(instructors);
    } catch (e) {
      developer.log('Error fetching instructors for category $categoryId: $e', name: 'SupabaseCategoryRepository');
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getStudentsForCategory(String categoryId) async {
    final client = AppSupabase.client;
    try {
      final Set<String> studentIds = {};

      // 1. Direct junction table query
      try {
        final jRows = await client
            .from('student_categories')
            .select('student_id')
            .eq('category_id', categoryId);
        for (final r in jRows) {
          final id = r['student_id']?.toString();
          if (id != null && id.isNotEmpty) studentIds.add(id);
        }
      } catch (e) {
        developer.log('Error reading student_categories: $e', name: 'SupabaseCategoryRepository');
      }

      // 2. Supplementary via course enrollments in this category
      try {
        final courses = await client
            .from('courses')
            .select('id')
            .eq('category_id', categoryId);

        final courseIds = courses.map((c) => c['id'].toString()).toList();
        if (courseIds.isNotEmpty) {
          final enrollments = await client
              .from('course_enrollments')
              .select('student_id')
              .inFilter('course_id', courseIds);

          for (final e in enrollments) {
            final id = e['student_id']?.toString();
            if (id != null && id.isNotEmpty) studentIds.add(id);
          }
        }
      } catch (_) {}

      if (studentIds.isEmpty) return [];

      final students = await client
          .from('students')
          .select('id, student_id, full_name, email, preferred_category, account_status')
          .inFilter('id', studentIds.toList());

      return List<Map<String, dynamic>>.from(students);
    } catch (e) {
      developer.log('Error fetching students for category $categoryId: $e', name: 'SupabaseCategoryRepository');
      return [];
    }
  }

  // --------------------------------------------------------------------------
  // Student Multi-Category Junction Operations
  // --------------------------------------------------------------------------

  @override
  Future<List<CourseCategory>> getCategoriesForStudent(String studentId) async {
    final client = AppSupabase.client;
    try {
      final Set<String> categoryIds = {};

      // 1. Query student_categories junction table
      try {
        final rows = await client
            .from('student_categories')
            .select('category_id')
            .eq('student_id', studentId);
        for (final r in rows) {
          final cid = r['category_id']?.toString();
          if (cid != null && cid.isNotEmpty) categoryIds.add(cid);
        }
      } catch (e) {
        developer.log('Error querying student_categories for student $studentId: $e', name: 'SupabaseCategoryRepository');
      }

      // 2. If empty, check enrolled courses' categories
      if (categoryIds.isEmpty) {
        try {
          final enrollments = await client
              .from('course_enrollments')
              .select('course_id')
              .eq('student_id', studentId);
          final cIds = enrollments.map((e) => e['course_id']?.toString()).whereType<String>().toList();
          if (cIds.isNotEmpty) {
            final courses = await client.from('courses').select('category_id').inFilter('id', cIds);
            for (final c in courses) {
              final cid = c['category_id']?.toString();
              if (cid != null && cid.isNotEmpty) categoryIds.add(cid);
            }
          }
        } catch (_) {}
      }

      if (categoryIds.isEmpty) return [];

      final catRows = await client
          .from('course_categories')
          .select('*')
          .inFilter('id', categoryIds.toList());

      return catRows.map((json) => CourseCategory.fromJson(json)).toList();
    } catch (e) {
      developer.log('Error fetching categories for student $studentId: $e', name: 'SupabaseCategoryRepository');
      return [];
    }
  }

  @override
  Future<void> assignCategoriesToStudent(String studentId, List<String> categoryIds) async {
    final client = AppSupabase.client;
    if (categoryIds.isEmpty) return;

    try {
      final inserts = categoryIds.map((cid) => {
        'student_id': studentId,
        'category_id': cid,
      }).toList();

      await client.from('student_categories').upsert(
        inserts,
        onConflict: 'student_id, category_id',
      );
    } catch (e) {
      developer.log('Error assigning categories to student $studentId: $e', name: 'SupabaseCategoryRepository');
      rethrow;
    }
  }

  @override
  Future<void> removeCategoryFromStudent(String studentId, String categoryId) async {
    final client = AppSupabase.client;
    try {
      await client
          .from('student_categories')
          .delete()
          .match({'student_id': studentId, 'category_id': categoryId});
    } catch (e) {
      developer.log('Error removing category $categoryId from student $studentId: $e', name: 'SupabaseCategoryRepository');
      rethrow;
    }
  }

  // --------------------------------------------------------------------------
  // Instructor Multi-Category Junction Operations
  // --------------------------------------------------------------------------

  @override
  Future<List<CourseCategory>> getCategoriesForInstructor(String instructorId) async {
    final client = AppSupabase.client;
    try {
      final Set<String> categoryIds = {};

      // 1. Query instructor_categories junction table
      try {
        final rows = await client
            .from('instructor_categories')
            .select('category_id')
            .eq('instructor_id', instructorId);
        for (final r in rows) {
          final cid = r['category_id']?.toString();
          if (cid != null && cid.isNotEmpty) categoryIds.add(cid);
        }
      } catch (e) {
        developer.log('Error querying instructor_categories for instructor $instructorId: $e', name: 'SupabaseCategoryRepository');
      }

      // 2. Also check categories of courses assigned to this instructor
      try {
        final courses = await client
            .from('courses')
            .select('category_id')
            .eq('instructor_id', instructorId);
        for (final c in courses) {
          final cid = c['category_id']?.toString();
          if (cid != null && cid.isNotEmpty) categoryIds.add(cid);
        }
      } catch (_) {}

      if (categoryIds.isEmpty) return [];

      final catRows = await client
          .from('course_categories')
          .select('*')
          .inFilter('id', categoryIds.toList());

      return catRows.map((json) => CourseCategory.fromJson(json)).toList();
    } catch (e) {
      developer.log('Error fetching categories for instructor $instructorId: $e', name: 'SupabaseCategoryRepository');
      return [];
    }
  }

  @override
  Future<void> assignCategoriesToInstructor(String instructorId, List<String> categoryIds) async {
    final client = AppSupabase.client;
    if (categoryIds.isEmpty) return;

    try {
      final inserts = categoryIds.map((cid) => {
        'instructor_id': instructorId,
        'category_id': cid,
      }).toList();

      await client.from('instructor_categories').upsert(
        inserts,
        onConflict: 'instructor_id, category_id',
      );
    } catch (e) {
      developer.log('Error assigning categories to instructor $instructorId: $e', name: 'SupabaseCategoryRepository');
      rethrow;
    }
  }

  @override
  Future<void> removeCategoryFromInstructor(String instructorId, String categoryId) async {
    final client = AppSupabase.client;
    try {
      await client
          .from('instructor_categories')
          .delete()
          .match({'instructor_id': instructorId, 'category_id': categoryId});
    } catch (e) {
      developer.log('Error removing category $categoryId from instructor $instructorId: $e', name: 'SupabaseCategoryRepository');
      rethrow;
    }
  }
}

