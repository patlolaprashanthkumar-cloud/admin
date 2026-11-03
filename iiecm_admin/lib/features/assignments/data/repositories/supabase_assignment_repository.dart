import 'dart:developer' as developer;

import '../../../../core/network/supabase_client.dart';
import '../../domain/models/assignment.dart';
import '../../domain/models/assignment_submission.dart';
import '../../domain/repositories/assignment_repository.dart';

class SupabaseAssignmentRepository implements AssignmentRepository {
  @override
  Future<List<Assignment>> getAssignments({
    String? status,
    String? categoryId,
    String? type,
    String? searchQuery,
  }) async {
    final client = AppSupabase.client;

    try {
      var query = client.from('assessments').select('*').inFilter('type', [
        'assignment',
        'project',
      ]);

      if (status != null && status.isNotEmpty && status != 'all') {
        query = query.eq('status', status);
      }
      if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all') {
        query = query.eq('category_id', categoryId);
      }
      if (type != null && type.isNotEmpty && type != 'all') {
        query = query.eq('type', type);
      }

      final List<dynamic> rows = await query.order(
        'created_at',
        ascending: false,
      );

      // Load course allocations
      final Map<String, List<AssignmentCourseRef>> courseMap = {};
      try {
        final links = await client
            .from('assessment_course_assignments')
            .select('assessment_id, courses(id, title)');
        for (final l in links) {
          final aId = l['assessment_id']?.toString() ?? '';
          if (l['courses'] != null) {
            final cRef = AssignmentCourseRef.fromJson(
              l['courses'] as Map<String, dynamic>,
            );
            courseMap.putIfAbsent(aId, () => []).add(cRef);
          }
        }
      } catch (e) {
        developer.log(
          'Error loading assignment courses: $e',
          name: 'SupabaseAssignmentRepository',
        );
      }

      // Load submission counts
      final Map<String, int> totalSubs = {};
      final Map<String, int> gradedSubs = {};
      try {
        final results = await client
            .from('assessment_results')
            .select('assessment_id, score');
        for (final r in results) {
          final aId = r['assessment_id']?.toString() ?? '';
          totalSubs[aId] = (totalSubs[aId] ?? 0) + 1;
          final score = (r['score'] as num?)?.toDouble() ?? 0.0;
          if (score > 0) {
            gradedSubs[aId] = (gradedSubs[aId] ?? 0) + 1;
          }
        }
      } catch (e) {
        developer.log(
          'Error loading submission counts: $e',
          name: 'SupabaseAssignmentRepository',
        );
      }

      List<Assignment> assignments = rows.map((r) {
        final aId = r['id']?.toString() ?? '';
        return Assignment.fromJson(
          r as Map<String, dynamic>,
          assignedCourses: courseMap[aId] ?? [],
          totalSubmissions: totalSubs[aId] ?? 0,
          gradedSubmissions: gradedSubs[aId] ?? 0,
        );
      }).toList();

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        assignments = assignments.where((a) {
          return a.title.toLowerCase().contains(q) ||
              a.description.toLowerCase().contains(q) ||
              a.assignedCourses.any((c) => c.title.toLowerCase().contains(q));
        }).toList();
      }

      return assignments;
    } catch (e) {
      developer.log(
        'Error in getAssignments: $e',
        name: 'SupabaseAssignmentRepository',
      );
      rethrow;
    }
  }

  @override
  Future<Assignment?> getAssignmentById(String id) async {
    final client = AppSupabase.client;

    try {
      final List<dynamic> rows = await client
          .from('assessments')
          .select('*')
          .eq('id', id)
          .limit(1);

      if (rows.isEmpty) return null;

      final aRow = rows.first as Map<String, dynamic>;

      // Load assigned courses
      final List<AssignmentCourseRef> courses = [];
      try {
        final links = await client
            .from('assessment_course_assignments')
            .select('courses(id, title)')
            .eq('assessment_id', id);

        for (final l in links) {
          if (l['courses'] != null) {
            courses.add(
              AssignmentCourseRef.fromJson(
                l['courses'] as Map<String, dynamic>,
              ),
            );
          }
        }
      } catch (e) {
        developer.log(
          'Error loading assignment courses: $e',
          name: 'SupabaseAssignmentRepository',
        );
      }

      // Load submissions count
      int totalSubs = 0;
      int gradedSubs = 0;
      try {
        final results = await client
            .from('assessment_results')
            .select('score')
            .eq('assessment_id', id);

        totalSubs = results.length;
        gradedSubs = results
            .where((r) => ((r['score'] as num?)?.toDouble() ?? 0.0) > 0)
            .length;
      } catch (_) {}

      return Assignment.fromJson(
        aRow,
        assignedCourses: courses,
        totalSubmissions: totalSubs,
        gradedSubmissions: gradedSubs,
      );
    } catch (e) {
      developer.log(
        'Error in getAssignmentById: $e',
        name: 'SupabaseAssignmentRepository',
      );
      rethrow;
    }
  }

  @override
  Future<Assignment> createAssignment(
    Assignment assignment, {
    List<String> courseIds = const [],
  }) async {
    final client = AppSupabase.client;

    try {
      final payload = assignment.toJson();
      final List<dynamic> inserted = await client
          .from('assessments')
          .insert(payload)
          .select('*');

      if (inserted.isEmpty) {
        throw Exception('Failed to insert assignment.');
      }

      final newAss = inserted.first as Map<String, dynamic>;
      final newId = newAss['id'].toString();

      // Allocate to courses
      if (courseIds.isNotEmpty) {
        final linkPayload = courseIds
            .map((cId) => {'assessment_id': newId, 'course_id': cId})
            .toList();
        await client.from('assessment_course_assignments').insert(linkPayload);
      }

      return (await getAssignmentById(newId)) ?? Assignment.fromJson(newAss);
    } catch (e) {
      developer.log(
        'Error in createAssignment: $e',
        name: 'SupabaseAssignmentRepository',
      );
      rethrow;
    }
  }

  @override
  Future<Assignment> updateAssignment(
    Assignment assignment, {
    List<String>? courseIds,
  }) async {
    final client = AppSupabase.client;

    try {
      final payload = assignment.toJson();
      await client.from('assessments').update(payload).eq('id', assignment.id);

      if (courseIds != null) {
        await client
            .from('assessment_course_assignments')
            .delete()
            .eq('assessment_id', assignment.id);

        if (courseIds.isNotEmpty) {
          final linkPayload = courseIds
              .map((cId) => {'assessment_id': assignment.id, 'course_id': cId})
              .toList();
          await client
              .from('assessment_course_assignments')
              .insert(linkPayload);
        }
      }

      return (await getAssignmentById(assignment.id)) ?? assignment;
    } catch (e) {
      developer.log(
        'Error in updateAssignment: $e',
        name: 'SupabaseAssignmentRepository',
      );
      rethrow;
    }
  }

  @override
  Future<void> updateAssignmentStatus(String id, String status) async {
    final client = AppSupabase.client;
    try {
      await client.from('assessments').update({'status': status}).eq('id', id);
    } catch (e) {
      developer.log(
        'Error in updateAssignmentStatus: $e',
        name: 'SupabaseAssignmentRepository',
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteAssignment(String id) async {
    final client = AppSupabase.client;
    try {
      await client
          .from('assessment_course_assignments')
          .delete()
          .eq('assessment_id', id);
      await client.from('assessments').delete().eq('id', id);
    } catch (e) {
      developer.log(
        'Error in deleteAssignment: $e',
        name: 'SupabaseAssignmentRepository',
      );
      rethrow;
    }
  }

  @override
  Future<List<AssignmentSubmission>> getSubmissions(String assessmentId) async {
    final client = AppSupabase.client;

    try {
      final List<dynamic> rows = await client
          .from('assessment_results')
          .select('*')
          .eq('assessment_id', assessmentId)
          .order('completed_at', ascending: false);

      return rows
          .map((r) => AssignmentSubmission.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      developer.log(
        'Error in getSubmissions: $e',
        name: 'SupabaseAssignmentRepository',
      );
      rethrow;
    }
  }

  @override
  Future<AssignmentSubmission> gradeSubmission({
    required String submissionId,
    required double score,
    required double totalMarks,
    required bool passed,
    String? feedback,
  }) async {
    final client = AppSupabase.client;

    try {
      final percentage = totalMarks > 0
          ? ((score / totalMarks) * 100).clamp(0.0, 100.0)
          : 0.0;

      final payload = <String, dynamic>{
        'score': score,
        'percentage': percentage,
        'passed': passed,
      };

      if (feedback != null) {
        payload['answers'] = {'feedback': feedback};
      }

      final List<dynamic> updated = await client
          .from('assessment_results')
          .update(payload)
          .eq('id', submissionId)
          .select('*');

      if (updated.isEmpty) {
        throw Exception('Submission record not found for grading.');
      }

      return AssignmentSubmission.fromJson(
        updated.first as Map<String, dynamic>,
      );
    } catch (e) {
      developer.log(
        'Error in gradeSubmission: $e',
        name: 'SupabaseAssignmentRepository',
      );
      rethrow;
    }
  }
}
