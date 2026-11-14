import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/supabase_client.dart';
import '../../domain/models/student_assignment.dart';
import '../../domain/repositories/assignments_repository.dart';

/// Concrete Supabase implementation of AssignmentsRepository for the student portal
class SupabaseAssignmentsRepository implements AssignmentsRepository {
  SupabaseClient get _client => AppSupabase.client;

  @override
  Future<List<StudentAssignment>> getStudentAssignments(
    String studentRecordId,
  ) async {
    if (!AppSupabase.isInitialized) {
      throw StateError('Supabase is not initialized.');
    }
    if (studentRecordId.isEmpty) return [];

    try {
      // 1. Fetch student's course enrollment IDs
      final List<dynamic> enrollmentRows = await _client
          .from('course_enrollments')
          .select('course_id')
          .eq('student_id', studentRecordId)
          .timeout(const Duration(seconds: 10));

      final List<String> enrolledCourseIds = enrollmentRows
          .map((r) => r['course_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();

      if (enrolledCourseIds.isEmpty) return [];

      // 2. Fetch course titles for reference
      final Map<String, String> courseTitleMap = {};
      try {
        final List<dynamic> courseRows = await _client
            .from('courses')
            .select('id, title')
            .inFilter('id', enrolledCourseIds)
            .timeout(const Duration(seconds: 8));

        for (final c in courseRows) {
          final id = c['id']?.toString() ?? '';
          final title = c['title']?.toString() ?? 'Course';
          if (id.isNotEmpty) courseTitleMap[id] = title;
        }
      } catch (_) {}

      // 3. Find assignment IDs allocated to enrolled courses
      final List<dynamic> linkRows = await _client
          .from('assessment_course_assignments')
          .select('assessment_id, course_id')
          .inFilter('course_id', enrolledCourseIds)
          .timeout(const Duration(seconds: 10));

      if (linkRows.isEmpty) return [];

      final Set<String> assignmentIds = {};
      final Map<String, String> assignmentCourseMap = {};
      for (final l in linkRows) {
        final aId = l['assessment_id']?.toString() ?? '';
        final cId = l['course_id']?.toString() ?? '';
        if (aId.isNotEmpty) {
          assignmentIds.add(aId);
          if (cId.isNotEmpty && !assignmentCourseMap.containsKey(aId)) {
            assignmentCourseMap[aId] = cId;
          }
        }
      }

      if (assignmentIds.isEmpty) return [];

      // 4. Fetch assignments matching these IDs
      final List<dynamic> assignmentRows = await _client
          .from('assessments')
          .select('*')
          .inFilter('id', assignmentIds.toList())
          .inFilter('type', ['assignment', 'project'])
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 10));

      if (assignmentRows.isEmpty) return [];

      // 5. Fetch student's completed results / submissions
      final Map<String, Map<String, dynamic>> submissionMap = {};
      try {
        final List<dynamic> resultRows = await _client
            .from('assessment_results')
            .select('*')
            .eq('student_id', studentRecordId)
            .inFilter('assessment_id', assignmentIds.toList())
            .timeout(const Duration(seconds: 10));

        for (final r in resultRows) {
          final aId = r['assessment_id']?.toString() ?? '';
          if (aId.isNotEmpty) {
            submissionMap[aId] = Map<String, dynamic>.from(r as Map);
          }
        }
      } catch (e) {
        developer.log(
          'Error loading assignment submissions: $e',
          name: 'SupabaseAssignmentsRepository',
        );
      }

      return assignmentRows.map((a) {
        final aMap = Map<String, dynamic>.from(a as Map);
        final aId = aMap['id']?.toString() ?? '';
        final cId = assignmentCourseMap[aId];
        final cTitle = cId != null ? courseTitleMap[cId] : null;

        return StudentAssignment.fromData(
          assessmentJson: aMap,
          courseId: cId,
          courseTitle: cTitle,
          submissionJson: submissionMap[aId],
        );
      }).toList();
    } catch (e) {
      developer.log(
        'Error fetching assignments for student $studentRecordId: $e',
        name: 'SupabaseAssignmentsRepository',
      );
      rethrow;
    }
  }

  @override
  Future<StudentAssignment?> getAssignmentDetails({
    required String assignmentId,
    required String studentRecordId,
  }) async {
    if (!AppSupabase.isInitialized) {
      throw StateError('Supabase is not initialized.');
    }

    try {
      final aRow = await _client
          .from('assessments')
          .select('*')
          .eq('id', assignmentId)
          .maybeSingle()
          .timeout(const Duration(seconds: 10));

      if (aRow == null) return null;

      final aMap = Map<String, dynamic>.from(aRow);

      // Associated course lookup
      String? courseId;
      String? courseTitle;
      try {
        final link = await _client
            .from('assessment_course_assignments')
            .select('course_id, courses(title)')
            .eq('assessment_id', assignmentId)
            .maybeSingle()
            .timeout(const Duration(seconds: 8));

        if (link != null) {
          courseId = link['course_id']?.toString();
          final coursesObj = link['courses'];
          if (coursesObj is Map) {
            courseTitle = coursesObj['title']?.toString();
          }
        }
      } catch (_) {}

      // Student submission lookup
      Map<String, dynamic>? submissionMap;
      if (studentRecordId.isNotEmpty) {
        try {
          final sub = await _client
              .from('assessment_results')
              .select('*')
              .eq('assessment_id', assignmentId)
              .eq('student_id', studentRecordId)
              .maybeSingle()
              .timeout(const Duration(seconds: 8));

          if (sub != null) {
            submissionMap = Map<String, dynamic>.from(sub);
          }
        } catch (_) {}
      }

      return StudentAssignment.fromData(
        assessmentJson: aMap,
        courseId: courseId,
        courseTitle: courseTitle,
        submissionJson: submissionMap,
      );
    } catch (e) {
      developer.log(
        'Error fetching assignment details for $assignmentId: $e',
        name: 'SupabaseAssignmentsRepository',
      );
      rethrow;
    }
  }

  @override
  Future<bool> submitAssignment({
    required String assignmentId,
    required String studentRecordId,
    required String submissionText,
    String? attachmentUrl,
  }) async {
    if (!AppSupabase.isInitialized) {
      throw StateError('Supabase is not initialized.');
    }
    if (assignmentId.isEmpty || studentRecordId.isEmpty) return false;

    try {
      // 1. Fetch total marks of assignment
      int totalMarks = 100;
      try {
        final a = await _client
            .from('assessments')
            .select('total_marks')
            .eq('id', assignmentId)
            .maybeSingle();
        if (a != null && a['total_marks'] != null) {
          totalMarks = (a['total_marks'] as num).toInt();
        }
      } catch (_) {}

      // 2. Check if a submission already exists
      final existing = await _client
          .from('assessment_results')
          .select('id')
          .eq('assessment_id', assignmentId)
          .eq('student_id', studentRecordId)
          .maybeSingle();

      final answersPayload = <String, dynamic>{
        'submission_text': submissionText.trim(),
        'submitted_at': DateTime.now().toIso8601String(),
      };
      if (attachmentUrl != null && attachmentUrl.trim().isNotEmpty) {
        answersPayload['file_url'] = attachmentUrl.trim();
      }

      if (existing != null) {
        // Update existing record
        await _client.from('assessment_results').update({
          'completed_at': DateTime.now().toIso8601String(),
          'answers': answersPayload,
        }).eq('id', existing['id']);
      } else {
        // Insert new submission record
        await _client.from('assessment_results').insert({
          'assessment_id': assignmentId,
          'student_id': studentRecordId,
          'score': 0.0,
          'total_marks': totalMarks.toDouble(),
          'percentage': 0.0,
          'passed': false,
          'completed_at': DateTime.now().toIso8601String(),
          'answers': answersPayload,
        });
      }

      return true;
    } catch (e) {
      developer.log(
        'Error submitting assignment $assignmentId: $e',
        name: 'SupabaseAssignmentsRepository',
      );
      rethrow;
    }
  }
}

