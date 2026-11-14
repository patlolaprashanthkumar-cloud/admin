import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/supabase_client.dart';
import '../../domain/models/student_result.dart';
import '../../domain/repositories/results_repository.dart';

/// Concrete Supabase implementation of ResultsRepository
class SupabaseResultsRepository implements ResultsRepository {
  SupabaseClient get _client => AppSupabase.client;

  @override
  Future<List<StudentResult>> getStudentResults(String studentRecordId) async {
    if (!AppSupabase.isInitialized) {
      throw StateError('Supabase is not initialized.');
    }
    if (studentRecordId.isEmpty) return [];

    try {
      // 1. Fetch student's completed results
      final List<dynamic> resultRows = await _client
          .from('assessment_results')
          .select('*')
          .eq('student_id', studentRecordId)
          .order('completed_at', ascending: false)
          .timeout(const Duration(seconds: 10));

      if (resultRows.isEmpty) return [];

      final List<String> assessmentIds = resultRows
          .map((r) => r['assessment_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      // 2. Fetch assessment metadata (type, passing_marks, description)
      final Map<String, Map<String, dynamic>> assessmentMap = {};
      if (assessmentIds.isNotEmpty) {
        try {
          final List<dynamic> assessments = await _client
              .from('assessments')
              .select('id, title, type, passing_marks, total_marks, description')
              .inFilter('id', assessmentIds)
              .timeout(const Duration(seconds: 8));

          for (final a in assessments) {
            final aId = a['id']?.toString() ?? '';
            if (aId.isNotEmpty) {
              assessmentMap[aId] = Map<String, dynamic>.from(a as Map);
            }
          }
        } catch (e) {
          developer.log(
            'Error loading assessment metadata: $e',
            name: 'SupabaseResultsRepository',
          );
        }
      }

      // 3. Resolve course associations via assessment_course_assignments
      final Map<String, String> assessmentCourseIdMap = {};
      final Map<String, String> courseTitleMap = {};

      if (assessmentIds.isNotEmpty) {
        try {
          final List<dynamic> courseLinks = await _client
              .from('assessment_course_assignments')
              .select('assessment_id, course_id, courses(id, title)')
              .inFilter('assessment_id', assessmentIds)
              .timeout(const Duration(seconds: 8));

          for (final l in courseLinks) {
            final aId = l['assessment_id']?.toString() ?? '';
            final cId = l['course_id']?.toString() ?? '';
            if (aId.isNotEmpty && cId.isNotEmpty) {
              assessmentCourseIdMap[aId] = cId;
            }
            if (l['courses'] != null && l['courses'] is Map) {
              final cMap = l['courses'] as Map;
              final cIdFromJoin = cMap['id']?.toString() ?? cId;
              final cTitle = cMap['title']?.toString();
              if (cIdFromJoin.isNotEmpty && cTitle != null) {
                courseTitleMap[cIdFromJoin] = cTitle;
              }
            }
          }
        } catch (e) {
          developer.log(
            'Error loading course mappings for results: $e',
            name: 'SupabaseResultsRepository',
          );
        }
      }

      // 4. Assemble authoritative StudentResult list
      return resultRows.map((r) {
        final rMap = Map<String, dynamic>.from(r as Map);
        final aId = rMap['assessment_id']?.toString() ?? '';
        final aMeta = assessmentMap[aId];
        final cId = assessmentCourseIdMap[aId];
        final cTitle = cId != null ? courseTitleMap[cId] : null;

        return StudentResult.fromData(
          resultJson: rMap,
          assessmentJson: aMeta,
          courseId: cId,
          courseTitle: cTitle,
        );
      }).toList();
    } catch (e, stack) {
      developer.log(
        'Error fetching results for student $studentRecordId: $e',
        name: 'SupabaseResultsRepository',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<StudentResult?> getResultDetails({
    required String resultId,
    required String studentRecordId,
  }) async {
    if (!AppSupabase.isInitialized) {
      throw StateError('Supabase is not initialized.');
    }
    if (resultId.isEmpty || studentRecordId.isEmpty) return null;

    try {
      final List<dynamic> rows = await _client
          .from('assessment_results')
          .select('*')
          .eq('id', resultId)
          .eq('student_id', studentRecordId)
          .limit(1)
          .timeout(const Duration(seconds: 8));

      if (rows.isEmpty) return null;

      final rMap = Map<String, dynamic>.from(rows.first as Map);
      final aId = rMap['assessment_id']?.toString() ?? '';

      Map<String, dynamic>? aMeta;
      String? cId;
      String? cTitle;

      if (aId.isNotEmpty) {
        try {
          final aRow = await _client
              .from('assessments')
              .select('id, title, type, passing_marks, total_marks, description')
              .eq('id', aId)
              .maybeSingle();
          if (aRow != null) {
            aMeta = Map<String, dynamic>.from(aRow);
          }
        } catch (_) {}

        try {
          final link = await _client
              .from('assessment_course_assignments')
              .select('course_id, courses(id, title)')
              .eq('assessment_id', aId)
              .maybeSingle();
          if (link != null) {
            cId = link['course_id']?.toString();
            if (link['courses'] != null && link['courses'] is Map) {
              cTitle = link['courses']['title']?.toString();
            }
          }
        } catch (_) {}
      }

      return StudentResult.fromData(
        resultJson: rMap,
        assessmentJson: aMeta,
        courseId: cId,
        courseTitle: cTitle,
      );
    } catch (e, stack) {
      developer.log(
        'Error fetching result details for $resultId: $e',
        name: 'SupabaseResultsRepository',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }
}

