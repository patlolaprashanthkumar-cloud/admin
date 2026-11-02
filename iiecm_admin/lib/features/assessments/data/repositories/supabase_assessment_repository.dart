import 'dart:developer' as developer;
import '../../../../core/network/supabase_client.dart';
import '../../../assignments/domain/models/assignment_submission.dart';
import '../../domain/models/assessment.dart';
import '../../domain/models/question.dart';
import '../../domain/repositories/assessment_repository.dart';

class SupabaseAssessmentRepository implements AssessmentRepository {
  @override
  Future<List<Assessment>> getAssessments({
    String? status,
    String? categoryId,
    String? type,
    String? searchQuery,
  }) async {
    final client = AppSupabase.client;

    try {
      var query = client
          .from('assessments')
          .select('*')
          .inFilter('type', ['mcq', 'quiz']);

      if (status != null && status.isNotEmpty && status != 'all') {
        query = query.eq('status', status);
      }
      if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all') {
        query = query.eq('category_id', categoryId);
      }
      if (type != null && type.isNotEmpty && type != 'all') {
        query = query.eq('type', type);
      }

      final List<dynamic> rows = await query.order('created_at', ascending: false);

      // Question count map
      final Map<String, int> questionCounts = {};
      try {
        final qLinks = await client.from('assessment_questions').select('assessment_id');
        for (final q in qLinks) {
          final aId = q['assessment_id']?.toString() ?? '';
          questionCounts[aId] = (questionCounts[aId] ?? 0) + 1;
        }
      } catch (e) {
        developer.log('Error counting assessment questions: $e', name: 'SupabaseAssessmentRepository');
      }

      // Results / attempts map
      final Map<String, int> totalAttempts = {};
      final Map<String, int> passedAttempts = {};
      try {
        final res = await client.from('assessment_results').select('assessment_id, passed');
        for (final r in res) {
          final aId = r['assessment_id']?.toString() ?? '';
          totalAttempts[aId] = (totalAttempts[aId] ?? 0) + 1;
          if (r['passed'] == true) {
            passedAttempts[aId] = (passedAttempts[aId] ?? 0) + 1;
          }
        }
      } catch (e) {
        developer.log('Error counting results: $e', name: 'SupabaseAssessmentRepository');
      }

      List<Assessment> assessments = rows.map((r) {
        final aId = r['id']?.toString() ?? '';
        return Assessment.fromJson(
          r as Map<String, dynamic>,
          questionCount: questionCounts[aId] ?? 0,
          totalAttempts: totalAttempts[aId] ?? 0,
          passedAttempts: passedAttempts[aId] ?? 0,
        );
      }).toList();

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        assessments = assessments.where((a) {
          return a.title.toLowerCase().contains(q) || a.description.toLowerCase().contains(q);
        }).toList();
      }

      return assessments;
    } catch (e) {
      developer.log('Error in getAssessments: $e', name: 'SupabaseAssessmentRepository');
      rethrow;
    }
  }

  @override
  Future<Assessment?> getAssessmentById(String id) async {
    final client = AppSupabase.client;

    try {
      final List<dynamic> rows = await client
          .from('assessments')
          .select('*')
          .eq('id', id)
          .limit(1);

      if (rows.isEmpty) return null;
      final aRow = rows.first as Map<String, dynamic>;

      final questions = await getAssessmentQuestions(id);

      int attempts = 0;
      int passed = 0;
      try {
        final res = await client.from('assessment_results').select('passed').eq('assessment_id', id);
        attempts = res.length;
        passed = res.where((r) => r['passed'] == true).length;
      } catch (_) {}

      return Assessment.fromJson(
        aRow,
        questions: questions,
        questionCount: questions.length,
        totalAttempts: attempts,
        passedAttempts: passed,
      );
    } catch (e) {
      developer.log('Error in getAssessmentById: $e', name: 'SupabaseAssessmentRepository');
      rethrow;
    }
  }

  @override
  Future<Assessment> createAssessment(Assessment assessment) async {
    final client = AppSupabase.client;

    try {
      final payload = assessment.toJson();
      final List<dynamic> inserted = await client
          .from('assessments')
          .insert(payload)
          .select('*');

      if (inserted.isEmpty) {
        throw Exception('Failed to insert assessment.');
      }

      return Assessment.fromJson(inserted.first as Map<String, dynamic>);
    } catch (e) {
      developer.log('Error in createAssessment: $e', name: 'SupabaseAssessmentRepository');
      rethrow;
    }
  }

  @override
  Future<Assessment> updateAssessment(Assessment assessment) async {
    final client = AppSupabase.client;

    try {
      final payload = assessment.toJson();
      await client.from('assessments').update(payload).eq('id', assessment.id);
      return (await getAssessmentById(assessment.id)) ?? assessment;
    } catch (e) {
      developer.log('Error in updateAssessment: $e', name: 'SupabaseAssessmentRepository');
      rethrow;
    }
  }

  @override
  Future<void> updateAssessmentStatus(String id, String status) async {
    final client = AppSupabase.client;
    try {
      await client.from('assessments').update({'status': status}).eq('id', id);
    } catch (e) {
      developer.log('Error in updateAssessmentStatus: $e', name: 'SupabaseAssessmentRepository');
      rethrow;
    }
  }

  @override
  Future<void> deleteAssessment(String id) async {
    final client = AppSupabase.client;
    try {
      await client.from('assessment_questions').delete().eq('assessment_id', id);
      await client.from('assessments').delete().eq('id', id);
    } catch (e) {
      developer.log('Error in deleteAssessment: $e', name: 'SupabaseAssessmentRepository');
      rethrow;
    }
  }

  @override
  Future<List<Question>> getAssessmentQuestions(String assessmentId) async {
    final client = AppSupabase.client;

    try {
      final List<dynamic> rows = await client
          .from('assessment_questions')
          .select('order_index, questions(*)')
          .eq('assessment_id', assessmentId)
          .order('order_index', ascending: true);

      final List<Question> questions = [];
      for (final r in rows) {
        if (r['questions'] != null) {
          final qData = r['questions'] as Map<String, dynamic>;
          final order = (r['order_index'] as int?) ?? 1;
          questions.add(Question.fromJson(qData, orderIndex: order));
        }
      }

      return questions;
    } catch (e) {
      developer.log('Error in getAssessmentQuestions: $e', name: 'SupabaseAssessmentRepository');
      return [];
    }
  }

  @override
  Future<Question> addQuestionToAssessment(String assessmentId, Question question, int orderIndex) async {
    final client = AppSupabase.client;

    try {
      final qPayload = question.toJson();
      final List<dynamic> inserted = await client
          .from('questions')
          .insert(qPayload)
          .select('*');

      if (inserted.isEmpty) {
        throw Exception('Failed to insert question.');
      }

      final createdQ = Question.fromJson(inserted.first as Map<String, dynamic>, orderIndex: orderIndex);

      // Link to assessment
      await client.from('assessment_questions').insert({
        'assessment_id': assessmentId,
        'question_id': createdQ.id,
        'order_index': orderIndex,
      });

      return createdQ;
    } catch (e) {
      developer.log('Error in addQuestionToAssessment: $e', name: 'SupabaseAssessmentRepository');
      rethrow;
    }
  }

  @override
  Future<Question> updateQuestion(Question question) async {
    final client = AppSupabase.client;

    try {
      final payload = question.toJson();
      final List<dynamic> updated = await client
          .from('questions')
          .update(payload)
          .eq('id', question.id)
          .select('*');

      if (updated.isEmpty) {
        throw Exception('Question not found to update.');
      }

      return Question.fromJson(updated.first as Map<String, dynamic>, orderIndex: question.orderIndex);
    } catch (e) {
      developer.log('Error in updateQuestion: $e', name: 'SupabaseAssessmentRepository');
      rethrow;
    }
  }

  @override
  Future<void> removeQuestionFromAssessment(String assessmentId, String questionId) async {
    final client = AppSupabase.client;
    try {
      await client
          .from('assessment_questions')
          .delete()
          .eq('assessment_id', assessmentId)
          .eq('question_id', questionId);

      // Also clean up question
      await client.from('questions').delete().eq('id', questionId);
    } catch (e) {
      developer.log('Error in removeQuestionFromAssessment: $e', name: 'SupabaseAssessmentRepository');
      rethrow;
    }
  }

  @override
  Future<List<AssignmentSubmission>> getAssessmentResults(String assessmentId) async {
    final client = AppSupabase.client;

    try {
      final List<dynamic> rows = await client
          .from('assessment_results')
          .select('*')
          .eq('assessment_id', assessmentId)
          .order('completed_at', ascending: false);

      return rows.map((r) => AssignmentSubmission.fromJson(r as Map<String, dynamic>)).toList();
    } catch (e) {
      developer.log('Error in getAssessmentResults: $e', name: 'SupabaseAssessmentRepository');
      rethrow;
    }
  }
}
