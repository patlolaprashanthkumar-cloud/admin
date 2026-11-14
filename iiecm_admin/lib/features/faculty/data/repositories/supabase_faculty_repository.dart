import 'dart:convert';
import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

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
  Future<FacultyRegistrationResult> createFaculty(
    Faculty faculty, {
    List<String> categoryIds = const [],
    List<String> courseIds = const [],
  }) async {
    final client = AppSupabase.client;

    // 1. Prepare request payload matching CreateUserPayload for instructor role
    final edgePayload = {
      'email': faculty.email.trim().toLowerCase(),
      'fullName': faculty.fullName.trim(),
      'role': 'instructor',
      'phone': faculty.phone.trim().isNotEmpty ? faculty.phone.trim() : null,
      if (faculty.id.isNotEmpty) 'entityId': faculty.id,
      'qualification': faculty.qualifications.trim().isNotEmpty
          ? faculty.qualifications.trim()
          : 'N/A',
      'specialization': faculty.specialization.trim().isNotEmpty
          ? faculty.specialization.trim()
          : 'General',
      'experienceYears': faculty.experienceYears,
      'redirectTo': 'https://auth.iiecm.org/auth/callback',
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
          (session.expiresAt != null && session.expiresAt! <= (nowSeconds + 60))) {
        try {
          final refreshResponse = await auth.refreshSession();
          session = refreshResponse.session ?? auth.currentSession;
        } catch (e) {
          developer.log(
            'Proactive admin session refresh failed: $e',
            name: 'SupabaseFacultyRepository',
          );
        }
      }

      if (session == null) {
        throw const FacultyProvisioningException(
          message:
              'Your administrator session has expired or is invalid. Please sign out and sign in again to register faculty.',
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
            name: 'SupabaseFacultyRepository',
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
            'Instructor provisioning failed (HTTP $statusCode)';
        if (statusCode == 401) {
          errorMsg =
              'Your administrator session has expired. Please sign out and sign in again to continue.';
        }
        final isPartial = responseData['partialFailure'] == true;
        throw FacultyProvisioningException(
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
        errorMsg =
            'Your administrator session has expired. Please sign out and sign in again to continue.';
      }
      throw FacultyProvisioningException(
        message: errorMsg,
        statusCode: status,
        isPartialFailure: isPartial,
      );
    } catch (e) {
      if (e is FacultyProvisioningException) rethrow;
      throw FacultyProvisioningException(
        message:
            'Network error or unable to reach provisioning service: ${e.toString()}',
        statusCode: 0,
      );
    }

    // 2. Extract and validate linkedEntityId
    final linkedEntityId = responseData['linkedEntityId']?.toString();
    if (linkedEntityId == null || linkedEntityId.isEmpty) {
      throw const FacultyProvisioningException(
        message: 'Edge Function succeeded, but no linked instructor entity ID was returned.',
        statusCode: 500,
        isPartialFailure: true,
      );
    }

    // 3. Preserve bio if provided (since Edge Function CreateUserPayload does not include bio)
    bool assignmentFailed = false;
    String? assignmentError;

    if (faculty.bio != null && faculty.bio!.trim().isNotEmpty) {
      try {
        await client
            .from('instructors')
            .update({'bio': faculty.bio!.trim()})
            .eq('id', linkedEntityId);
      } catch (e) {
        assignmentFailed = true;
        assignmentError = 'Instructor bio could not be saved: $e';
        developer.log(
          'Warning: Failed to preserve instructor bio: $e',
          name: 'SupabaseFacultyRepository',
        );
      }
    }

    // 4. Perform junction table category and course assignments
    if (categoryIds.isNotEmpty) {
      final jPayload = categoryIds
          .map(
            (catId) => {'instructor_id': linkedEntityId, 'category_id': catId},
          )
          .toList();
      try {
        await client.from('instructor_categories').insert(jPayload);
      } catch (e) {
        assignmentFailed = true;
        final catMsg = 'Category assignments incomplete: $e';
        assignmentError = assignmentError != null
            ? '$assignmentError; $catMsg'
            : catMsg;
        developer.log(
          'Error inserting instructor_categories: $e',
          name: 'SupabaseFacultyRepository',
        );
      }
    }

    if (courseIds.isNotEmpty) {
      try {
        for (final cId in courseIds) {
          await client
              .from('courses')
              .update({'instructor_id': linkedEntityId})
              .eq('id', cId);
        }
      } catch (e) {
        assignmentFailed = true;
        final crsMsg = 'Course assignments incomplete: $e';
        assignmentError = assignmentError != null
            ? '$assignmentError; $crsMsg'
            : crsMsg;
        developer.log(
          'Error updating course instructor: $e',
          name: 'SupabaseFacultyRepository',
        );
      }
    }

    // 5. Retrieve full resulting Faculty entity and validate profile relationship
    final resultingFaculty = await getFacultyById(linkedEntityId);
    if (resultingFaculty == null) {
      throw const FacultyProvisioningException(
        message: 'Instructor account was provisioned, but the database record could not be retrieved.',
        statusCode: 500,
        isPartialFailure: true,
      );
    }

    if (resultingFaculty.profileId == null ||
        resultingFaculty.profileId!.trim().isEmpty) {
      throw const FacultyProvisioningException(
        message: 'Instructor record was provisioned, but authentication profile relationship is missing.',
        statusCode: 500,
        isPartialFailure: true,
      );
    }

    final returnedUserId = responseData['userId']?.toString();
    if (returnedUserId != null &&
        returnedUserId.isNotEmpty &&
        resultingFaculty.profileId != returnedUserId) {
      throw const FacultyProvisioningException(
        message: 'Instructor provisioning integrity failure: linked profile does not match authentication user identity.',
        statusCode: 500,
        isPartialFailure: true,
      );
    }

    final isExisting = statusCode == 200;
    final inviteSent = responseData['invitationSent'] == true;
    final message =
        responseData['message']?.toString() ??
        (isExisting
            ? 'Existing account recognized and linked to instructor profile.'
            : 'Account successfully provisioned.');

    return FacultyRegistrationResult(
      faculty: resultingFaculty,
      statusCode: statusCode,
      isExistingUser: isExisting,
      invitationSent: inviteSent,
      message: message,
      hasAssignmentWarning: assignmentFailed,
      assignmentWarning: assignmentError,
    );
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
