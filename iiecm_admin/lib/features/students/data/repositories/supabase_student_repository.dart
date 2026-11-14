import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/supabase_client.dart';
import '../../../categories/domain/models/course_category.dart';
import '../../domain/models/student.dart';
import '../../domain/repositories/student_repository.dart';

class SupabaseStudentRepository implements StudentRepository {
  @override
  Future<List<Student>> getStudents({
    String? categoryId,
    String? searchQuery,
    String? status,
  }) async {
    final client = AppSupabase.client;

    try {
      var query = client.from('students').select('*');
      if (status != null && status.isNotEmpty && status != 'all') {
        query = query.eq('account_status', status);
      }

      final List<dynamic> rows = await query.order(
        'created_at',
        ascending: false,
      );

      // Load all categories for resolution
      final Map<String, CourseCategory> catMap = {};
      try {
        final catRows = await client.from('course_categories').select('*');
        for (final c in catRows) {
          catMap[c['id'].toString()] = CourseCategory.fromJson(c);
        }
      } catch (_) {}

      // Load student_categories junction mappings
      final Map<String, List<CourseCategory>> studentCatMap = {};
      try {
        final jRows = await client
            .from('student_categories')
            .select('student_id, category_id');
        for (final j in jRows) {
          final sId = j['student_id']?.toString() ?? '';
          final cId = j['category_id']?.toString() ?? '';
          if (catMap.containsKey(cId)) {
            studentCatMap.putIfAbsent(sId, () => []).add(catMap[cId]!);
          }
        }
      } catch (e) {
        developer.log(
          'Error querying student_categories: $e',
          name: 'SupabaseStudentRepository',
        );
      }

      // Load enrolled course IDs
      final Map<String, List<String>> studentCourseMap = {};
      try {
        final enrollments = await client
            .from('course_enrollments')
            .select('student_id, course_id');
        for (final e in enrollments) {
          final sId = e['student_id']?.toString() ?? '';
          final cId = e['course_id']?.toString() ?? '';
          studentCourseMap.putIfAbsent(sId, () => []).add(cId);
        }
      } catch (_) {}

      List<Student> students = rows.map((r) {
        final sId = r['id']?.toString() ?? '';
        final assignedCats = studentCatMap[sId] ?? [];
        return Student.fromJson(
          r as Map<String, dynamic>,
          assignedCategories: assignedCats,
          enrolledCourseIds: studentCourseMap[sId] ?? [],
        );
      }).toList();

      // Filter by category
      if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all') {
        students = students.where((s) {
          final hasInJunction = s.assignedCategories.any(
            (c) => c.id == categoryId,
          );
          final matchesPreferred =
              catMap[categoryId]?.name == s.preferredCategory;
          return hasInJunction || matchesPreferred;
        }).toList();
      }

      // Filter by search
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.toLowerCase().trim();
        students = students
            .where(
              (s) =>
                  s.fullName.toLowerCase().contains(q) ||
                  s.studentId.toLowerCase().contains(q) ||
                  s.email.toLowerCase().contains(q) ||
                  s.preferredCategory.toLowerCase().contains(q),
            )
            .toList();
      }

      return students;
    } catch (e) {
      developer.log(
        'Error fetching students: $e',
        name: 'SupabaseStudentRepository',
      );
      return [];
    }
  }

  @override
  Future<Student?> getStudentById(String id) async {
    final client = AppSupabase.client;
    try {
      final res = await client
          .from('students')
          .select('*')
          .eq('id', id)
          .maybeSingle();
      if (res == null) return null;

      // Fetch assigned categories from student_categories
      List<CourseCategory> assignedCats = [];
      try {
        final jRows = await client
            .from('student_categories')
            .select('category_id')
            .eq('student_id', id);
        final catIds = jRows
            .map((r) => r['category_id']?.toString())
            .whereType<String>()
            .toList();
        if (catIds.isNotEmpty) {
          final catRows = await client
              .from('course_categories')
              .select('*')
              .inFilter('id', catIds);
          assignedCats = catRows
              .map((c) => CourseCategory.fromJson(c))
              .toList();
        }
      } catch (_) {}

      // Fetch enrolled courses
      List<String> courseIds = [];
      try {
        final enrollments = await client
            .from('course_enrollments')
            .select('course_id')
            .eq('student_id', id);
        courseIds = enrollments
            .map((e) => e['course_id']?.toString())
            .whereType<String>()
            .toList();
      } catch (_) {}

      return Student.fromJson(
        res,
        assignedCategories: assignedCats,
        enrolledCourseIds: courseIds,
      );
    } catch (e) {
      developer.log(
        'Error fetching student by id $id: $e',
        name: 'SupabaseStudentRepository',
      );
      return null;
    }
  }

  @override
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
  }) async {
    final client = AppSupabase.client;

    // 1. Resolve first category name for backward-compatibility
    // with preferred_category column
    String primaryCategoryName = 'General';
    if (categoryIds.isNotEmpty) {
      try {
        final catRes = await client
            .from('course_categories')
            .select('name')
            .eq('id', categoryIds.first)
            .maybeSingle();
        if (catRes != null && catRes['name'] != null) {
          primaryCategoryName = catRes['name'].toString();
        }
      } catch (_) {}
    }

    // Generate unique institutional student ID
    final randomSuffix = (1000 + Random().nextInt(9000)).toString();
    final studentIdCode = 'IIECM${DateTime.now().year}$randomSuffix';

    // 2. Prepare request payload for admin-create-user Edge Function
    final edgePayload = {
      'email': email.trim().toLowerCase(),
      'fullName': fullName.trim(),
      'role': 'student',
      'phone': phone.trim().isNotEmpty ? phone.trim() : null,
      'studentId': studentIdCode,
      'studentIdCode': studentIdCode,
      'educationLevel': educationLevel.trim().isNotEmpty
          ? educationLevel.trim()
          : 'Not specified',
      'qualification': qualification.trim().isNotEmpty
          ? qualification.trim()
          : 'N/A',
      'preferredCategory': primaryCategoryName,
      'city': city?.trim().isNotEmpty == true ? city!.trim() : null,
      'country': 'India',
      'redirectTo': 'https://auth.iiecm.org/auth/callback',
      if (learningFormat != null && learningFormat.trim().isNotEmpty)
        'learningFormat': learningFormat.trim(),
      if (preferredSlot != null && preferredSlot.trim().isNotEmpty)
        'preferredSlot': preferredSlot.trim(),
    };

    int statusCode = 201;
    Map<String, dynamic> responseData = {};

    try {
      final auth = client.auth;
      var session = auth.currentSession;
      final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Ensure the administrator has a fresh, valid authentication session before calling Edge Function.
      // If the session is missing, expired, or expiring within 60s, proactively refresh it.
      if (session == null ||
          (session.expiresAt != null &&
              session.expiresAt! <= (nowSeconds + 60))) {
        try {
          final refreshResponse = await auth.refreshSession();
          session = refreshResponse.session ?? auth.currentSession;
        } catch (e) {
          developer.log(
            'Proactive admin session refresh failed: $e',
            name: 'SupabaseStudentRepository',
          );
        }
      }

      if (session == null) {
        throw const StudentProvisioningException(
          message: 'Your administrator session has expired or is invalid. Please sign out and sign in again to add students.',
          statusCode: 401,
        );
      }

      // Explicitly pass Authorization header with the fresh bearer token
      Map<String, String> invokeHeaders = {
        'Authorization': 'Bearer ${session.accessToken}',
      };

      FunctionResponse response;
      try {
        response = await client.functions.invoke(
          'admin-create-user',
          headers: invokeHeaders,
          body: edgePayload,
        );
      } on FunctionException catch (fe) {
        if (fe.status == 401) {
          developer.log(
            'Received 401 FunctionException. Attempting session refresh and retry...',
            name: 'SupabaseStudentRepository',
          );
          try {
            final refreshResponse = await auth.refreshSession();
            final newSession = refreshResponse.session ?? auth.currentSession;
            if (newSession != null) {
              session = newSession;
              invokeHeaders = {
                'Authorization': 'Bearer ${newSession.accessToken}',
              };
              response = await client.functions.invoke(
                'admin-create-user',
                headers: invokeHeaders,
                body: edgePayload,
              );
            } else {
              rethrow;
            }
          } catch (_) {
            rethrow;
          }
        } else {
          rethrow;
        }
      }

      statusCode = response.status;
      if (response.data is Map) {
        responseData = Map<String, dynamic>.from(response.data as Map);
      } else if (response.data is String) {
        try {
          responseData = Map<String, dynamic>.from(
            jsonDecode(response.data as String) as Map,
          );
        } catch (_) {}
      }

      if (statusCode != 200 && statusCode != 201) {
        String errorMsg =
            responseData['error']?.toString() ??
            'Student provisioning failed (HTTP $statusCode)';
        if (statusCode == 401) {
          errorMsg = 'Your administrator session has expired. Please sign out and sign in again to continue.';
        }
        final isPartial = responseData['partialFailure'] == true;
        throw StudentProvisioningException(
          message: errorMsg,
          statusCode: statusCode,
          isPartialFailure: isPartial,
        );
      }
    } on FunctionException catch (fe) {
      final status = fe.status;
      String errorMsg = fe.reasonPhrase ?? 'Edge Function invocation failed';
      bool isPartial = false;
      if (fe.details is Map) {
        final detailsMap = Map<String, dynamic>.from(fe.details as Map);
        if (detailsMap['error'] != null) {
          errorMsg = detailsMap['error'].toString();
        }
        if (detailsMap['partialFailure'] == true) {
          isPartial = true;
        }
      } else if (fe.details is String) {
        try {
          final parsed = jsonDecode(fe.details as String);
          if (parsed is Map && parsed['error'] != null) {
            errorMsg = parsed['error'].toString();
          }
        } catch (_) {
          if ((fe.details as String).isNotEmpty) {
            errorMsg = fe.details as String;
          }
        }
      }
      if (status == 401) {
        errorMsg = 'Your administrator session has expired. Please sign out and sign in again to continue.';
      }
      throw StudentProvisioningException(
        message: errorMsg,
        statusCode: status,
        isPartialFailure: isPartial,
      );
    } catch (e) {
      if (e is StudentProvisioningException) rethrow;
      throw StudentProvisioningException(
        message:
            'Network error or unable to reach provisioning service: ${e.toString()}',
        statusCode: 0,
      );
    }

    // 3. Extract linkedEntityId returned by admin-create-user
    final linkedEntityId = responseData['linkedEntityId']?.toString();
    if (linkedEntityId == null || linkedEntityId.isEmpty) {
      throw const StudentProvisioningException(
        message: 'Edge Function succeeded, but no linked student entity ID was returned.',
        statusCode: 500,
        isPartialFailure: true,
      );
    }

    // 4. Retrieve resulting student record created or linked by Edge Function
    Map<String, dynamic>? studentRow;
    try {
      studentRow = await client
          .from('students')
          .select('*')
          .eq('id', linkedEntityId)
          .maybeSingle();
    } catch (e) {
      developer.log(
        'Warning: Failed to fetch student row after provisioning: $e',
        name: 'SupabaseStudentRepository',
      );
    }

    if (studentRow == null) {
      throw StudentProvisioningException(
        message:
            'Student account was provisioned, but the database record ($linkedEntityId) could not be retrieved.',
        statusCode: 500,
        isPartialFailure: true,
      );
    }

    // 5. Perform junction table category and course enrollment assignments
    bool assignmentFailed = false;
    String? assignmentError;

    if (categoryIds.isNotEmpty) {
      final catInserts = categoryIds
          .map((cid) => {'student_id': linkedEntityId, 'category_id': cid})
          .toList();

      try {
        await client.from('student_categories').insert(catInserts);
      } catch (e) {
        assignmentFailed = true;
        assignmentError = 'Category assignments incomplete: $e';
        developer.log(
          'Error inserting student_categories: $e',
          name: 'SupabaseStudentRepository',
        );
      }
    }

    if (courseIds.isNotEmpty) {
      final enrollInserts = courseIds
          .map(
            (cid) => {
              'student_id': linkedEntityId,
              'course_id': cid,
              'status': 'active',
            },
          )
          .toList();

      try {
        await client.from('course_enrollments').insert(enrollInserts);
      } catch (e) {
        assignmentFailed = true;
        assignmentError = assignmentError != null
            ? '$assignmentError; Course enrollments incomplete: $e'
            : 'Course enrollments incomplete: $e';
        developer.log(
          'Error inserting course_enrollments: $e',
          name: 'SupabaseStudentRepository',
        );
      }
    }

    // 6. Resolve category models for the returned Student instance
    final List<CourseCategory> assignedCats = [];
    if (categoryIds.isNotEmpty) {
      try {
        final catRows = await client
            .from('course_categories')
            .select('*')
            .inFilter('id', categoryIds);
        for (final c in catRows) {
          assignedCats.add(CourseCategory.fromJson(c));
        }
      } catch (_) {}
    }

    final student = Student.fromJson(
      studentRow,
      assignedCategories: assignedCats,
      enrolledCourseIds: courseIds,
    );

    final isExisting = statusCode == 200;
    final inviteSent = responseData['invitationSent'] == true;
    final message =
        responseData['message']?.toString() ??
        (isExisting
            ? 'Existing account recognized and re-linked.'
            : 'Account successfully provisioned.');

    return StudentRegistrationResult(
      student: student,
      statusCode: statusCode,
      isExistingUser: isExisting,
      invitationSent: inviteSent,
      message: message,
      hasAssignmentWarning: assignmentFailed,
      assignmentWarning: assignmentError,
    );
  }

  @override
  Future<Student> updateStudent(
    String id, {
    String? fullName,
    String? email,
    String? phone,
    String? educationLevel,
    String? qualification,
    String? city,
    String? accountStatus,
  }) async {
    final client = AppSupabase.client;
    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName.trim();
    if (email != null) updates['email'] = email.trim().toLowerCase();
    if (phone != null) updates['phone'] = phone.trim();
    if (educationLevel != null) {
      updates['education_level'] = educationLevel.trim();
    }
    if (qualification != null) updates['qualification'] = qualification.trim();
    if (city != null) updates['city'] = city.trim();
    if (accountStatus != null) updates['account_status'] = accountStatus;

    try {
      final res = await client
          .from('students')
          .update(updates)
          .eq('id', id)
          .select()
          .single();
      return Student.fromJson(res);
    } catch (e) {
      developer.log(
        'Error updating student $id: $e',
        name: 'SupabaseStudentRepository',
      );
      rethrow;
    }
  }

  @override
  Future<void> updateStudentCategories(
    String studentId,
    List<String> categoryIds,
  ) async {
    final client = AppSupabase.client;
    try {
      // Clear previous and replace with new categories
      await client
          .from('student_categories')
          .delete()
          .eq('student_id', studentId);
      if (categoryIds.isNotEmpty) {
        final inserts = categoryIds
            .map((cid) => {'student_id': studentId, 'category_id': cid})
            .toList();
        await client.from('student_categories').insert(inserts);
      }
    } catch (e) {
      developer.log(
        'Error updating categories for student $studentId: $e',
        name: 'SupabaseStudentRepository',
      );
      rethrow;
    }
  }

  @override
  Future<List<StudentCategoryLmsGroup>> getStudentCategoryLmsDetails(
    String studentId,
  ) async {
    final client = AppSupabase.client;

    try {
      // 1. Fetch student's assigned categories
      final jRows = await client
          .from('student_categories')
          .select('category_id')
          .eq('student_id', studentId);
      final catIds = jRows
          .map((r) => r['category_id']?.toString())
          .whereType<String>()
          .toSet()
          .toList();

      // If empty, fallback to category of enrolled courses
      final enrollments = await client
          .from('course_enrollments')
          .select('course_id, status')
          .eq('student_id', studentId);
      final enrolledCourseIds = enrollments
          .map((e) => e['course_id']?.toString())
          .whereType<String>()
          .toList();

      List<dynamic> allCourses = [];
      if (enrolledCourseIds.isNotEmpty) {
        try {
          allCourses = await client
              .from('courses')
              .select('*')
              .inFilter('id', enrolledCourseIds);
          for (final c in allCourses) {
            final cid = c['category_id']?.toString();
            if (cid != null && cid.isNotEmpty) catIds.add(cid);
          }
        } catch (_) {}
      }

      if (catIds.isEmpty) return [];

      final catRows = await client
          .from('course_categories')
          .select('*')
          .inFilter('id', catIds);
      final categories = catRows
          .map((c) => CourseCategory.fromJson(c))
          .toList();

      // 2. Fetch instructors for these courses
      final instructorIds = allCourses
          .map((c) => c['instructor_id']?.toString())
          .whereType<String>()
          .toSet()
          .toList();
      Map<String, Map<String, dynamic>> instructorMap = {};
      if (instructorIds.isNotEmpty) {
        try {
          final insRows = await client
              .from('instructors')
              .select('*')
              .inFilter('id', instructorIds);
          for (final ins in insRows) {
            instructorMap[ins['id'].toString()] = Map<String, dynamic>.from(
              ins,
            );
          }
        } catch (_) {}
      }

      // 3. Fetch live classes for enrolled courses
      List<dynamic> liveClasses = [];
      if (enrolledCourseIds.isNotEmpty) {
        try {
          liveClasses = await client
              .from('live_classes')
              .select('*')
              .inFilter('course_id', enrolledCourseIds)
              .order('scheduled_at', ascending: true);
        } catch (_) {}
      }

      // 4. Fetch assessments assigned to these courses
      List<dynamic> assessments = [];
      if (enrolledCourseIds.isNotEmpty) {
        try {
          final acaRows = await client
              .from('assessment_course_assignments')
              .select('assessment_id, course_id')
              .inFilter('course_id', enrolledCourseIds);
          final asmIds = acaRows
              .map((r) => r['assessment_id']?.toString())
              .whereType<String>()
              .toSet()
              .toList();
          if (asmIds.isNotEmpty) {
            assessments = await client
                .from('assessments')
                .select('*')
                .inFilter('id', asmIds);
          }
        } catch (_) {}
      }

      // 5. Build per-category LMS groups
      final List<StudentCategoryLmsGroup> groups = [];
      for (final cat in categories) {
        final catCourses = allCourses
            .where(
              (c) =>
                  c['category_id']?.toString() == cat.id ||
                  c['category_name']?.toString() == cat.name,
            )
            .map((c) => Map<String, dynamic>.from(c))
            .toList();

        final catCourseIds = catCourses.map((c) => c['id'].toString()).toSet();

        final catInstructors = catCourses
            .map((c) => c['instructor_id']?.toString())
            .where((id) => id != null && instructorMap.containsKey(id))
            .map((id) => instructorMap[id]!)
            .toSet()
            .toList();

        final catLiveClasses = liveClasses
            .where((lc) => catCourseIds.contains(lc['course_id']?.toString()))
            .map((lc) => Map<String, dynamic>.from(lc))
            .toList();

        final catAssessments = assessments
            .where((asm) => true) // All relevant to enrolled streams
            .map((asm) => Map<String, dynamic>.from(asm))
            .toList();

        groups.add(
          StudentCategoryLmsGroup(
            category: cat,
            courses: catCourses,
            instructors: catInstructors,
            liveClasses: catLiveClasses,
            assessments: catAssessments,
            progressPercentage: catCourses.isNotEmpty ? 45.0 : 0.0,
          ),
        );
      }

      return groups;
    } catch (e) {
      developer.log(
        'Error getting student category LMS details: $e',
        name: 'SupabaseStudentRepository',
      );
      return [];
    }
  }
}
