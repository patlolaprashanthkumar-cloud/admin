import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/supabase_client.dart';
import '../../domain/models/assessment_attempt_result.dart';
import '../../domain/models/assessment_question.dart';
import '../../domain/models/student_assessment.dart';
import '../../domain/repositories/assessments_repository.dart';

/// Concrete Supabase implementation of AssessmentsRepository for the student portal
class SupabaseAssessmentsRepository implements AssessmentsRepository {
  SupabaseClient get _client => AppSupabase.client;

  @override
  Future<List<StudentAssessment>> getStudentAssessments(
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

      // 3. Find assessment IDs allocated to enrolled courses
      final List<dynamic> linkRows = await _client
          .from('assessment_course_assignments')
          .select('assessment_id, course_id')
          .inFilter('course_id', enrolledCourseIds)
          .timeout(const Duration(seconds: 10));

      if (linkRows.isEmpty) return [];

      final Set<String> assessmentIds = {};
      final Map<String, String> assessmentCourseMap = {};
      for (final l in linkRows) {
        final aId = l['assessment_id']?.toString() ?? '';
        final cId = l['course_id']?.toString() ?? '';
        if (aId.isNotEmpty) {
          assessmentIds.add(aId);
          if (cId.isNotEmpty && !assessmentCourseMap.containsKey(aId)) {
            assessmentCourseMap[aId] = cId;
          }
        }
      }

      if (assessmentIds.isEmpty) return [];

      // 4. Fetch assessments (type mcq or quiz)
      final List<dynamic> assessmentRows = await _client
          .from('assessments')
          .select('*')
          .inFilter('id', assessmentIds.toList())
          .inFilter('type', ['mcq', 'quiz'])
          .order('scheduled_at', ascending: false)
          .timeout(const Duration(seconds: 10));

      if (assessmentRows.isEmpty) return [];

      // 5. Fetch question counts
      final Map<String, int> questionCountMap = {};
      try {
        final List<dynamic> qLinks = await _client
            .from('assessment_questions')
            .select('assessment_id')
            .inFilter('assessment_id', assessmentIds.toList())
            .timeout(const Duration(seconds: 10));

        for (final q in qLinks) {
          final aId = q['assessment_id']?.toString() ?? '';
          if (aId.isNotEmpty) {
            questionCountMap[aId] = (questionCountMap[aId] ?? 0) + 1;
          }
        }
      } catch (e) {
        developer.log(
          'Error counting assessment questions: $e',
          name: 'SupabaseAssessmentsRepository',
        );
      }

      // 6. Fetch student's completed results
      final Map<String, Map<String, dynamic>> resultMap = {};
      try {
        final List<dynamic> resultRows = await _client
            .from('assessment_results')
            .select('*')
            .eq('student_id', studentRecordId)
            .inFilter('assessment_id', assessmentIds.toList())
            .timeout(const Duration(seconds: 10));

        for (final r in resultRows) {
          final aId = r['assessment_id']?.toString() ?? '';
          if (aId.isNotEmpty) {
            resultMap[aId] = Map<String, dynamic>.from(r as Map);
          }
        }
      } catch (e) {
        developer.log(
          'Error loading assessment results: $e',
          name: 'SupabaseAssessmentsRepository',
        );
      }

      return assessmentRows.map((a) {
        final aMap = Map<String, dynamic>.from(a as Map);
        final aId = aMap['id']?.toString() ?? '';
        final cId = assessmentCourseMap[aId];
        final cTitle = cId != null ? courseTitleMap[cId] : null;

        return StudentAssessment.fromData(
          assessmentJson: aMap,
          courseId: cId,
          courseTitle: cTitle,
          questionCount: questionCountMap[aId] ?? 0,
          resultJson: resultMap[aId],
        );
      }).toList();
    } catch (e) {
      developer.log(
        'Error fetching assessments for student $studentRecordId: $e',
        name: 'SupabaseAssessmentsRepository',
      );
      rethrow;
    }
  }

  @override
  Future<StudentAssessment?> getAssessmentDetails({
    required String assessmentId,
    required String studentRecordId,
  }) async {
    if (!AppSupabase.isInitialized) {
      throw StateError('Supabase is not initialized.');
    }

    try {
      final aRow = await _client
          .from('assessments')
          .select('*')
          .eq('id', assessmentId)
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
            .eq('assessment_id', assessmentId)
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

      // Question count lookup
      int qCount = 0;
      try {
        final qRows = await _client
            .from('assessment_questions')
            .select('question_id')
            .eq('assessment_id', assessmentId)
            .timeout(const Duration(seconds: 8));
        qCount = qRows.length;
      } catch (_) {}

      // Previous result lookup
      Map<String, dynamic>? resultMap;
      if (studentRecordId.isNotEmpty) {
        try {
          final res = await _client
              .from('assessment_results')
              .select('*')
              .eq('assessment_id', assessmentId)
              .eq('student_id', studentRecordId)
              .maybeSingle()
              .timeout(const Duration(seconds: 8));

          if (res != null) {
            resultMap = Map<String, dynamic>.from(res);
          }
        } catch (_) {}
      }

      return StudentAssessment.fromData(
        assessmentJson: aMap,
        courseId: courseId,
        courseTitle: courseTitle,
        questionCount: qCount,
        resultJson: resultMap,
      );
    } catch (e) {
      developer.log(
        'Error fetching assessment details for $assessmentId: $e',
        name: 'SupabaseAssessmentsRepository',
      );
      rethrow;
    }
  }

  @override
  Future<List<StudentQuestion>> getAssessmentQuestions(
    String assessmentId,
  ) async {
    if (!AppSupabase.isInitialized) {
      throw StateError('Supabase is not initialized.');
    }

    try {
      final List<dynamic> rows = await _client
          .from('assessment_questions')
          .select('order_index, questions(*)')
          .eq('assessment_id', assessmentId)
          .order('order_index', ascending: true)
          .timeout(const Duration(seconds: 12));

      final List<StudentQuestion> questions = [];
      for (final r in rows) {
        if (r['questions'] != null) {
          final qData = Map<String, dynamic>.from(r['questions'] as Map);
          final order = (r['order_index'] as int?) ?? (questions.length + 1);
          questions.add(StudentQuestion.fromJson(qData, orderIndex: order));
        }
      }

      return questions;
    } catch (e) {
      developer.log(
        'Error loading questions for assessment $assessmentId: $e',
        name: 'SupabaseAssessmentsRepository',
      );
      return [];
    }
  }

  @override
  Future<AssessmentAttemptResult?> submitAssessmentAttempt({
    required String assessmentId,
    required String studentRecordId,
    required Map<String, String> selectedAnswers,
  }) async {
    if (!AppSupabase.isInitialized) {
      throw StateError('Supabase is not initialized.');
    }
    if (assessmentId.isEmpty || studentRecordId.isEmpty) return null;

    try {
      // 1. Check if student already completed this assessment
      final existing = await _client
          .from('assessment_results')
          .select('*')
          .eq('assessment_id', assessmentId)
          .eq('student_id', studentRecordId)
          .maybeSingle();

      if (existing != null) {
        return AssessmentAttemptResult.fromJson(
          Map<String, dynamic>.from(existing),
        );
      }

      // 2. Fetch assessment passing & total marks
      int passingMarks = 40;
      int configuredTotalMarks = 100;
      try {
        final a = await _client
            .from('assessments')
            .select('passing_marks, total_marks')
            .eq('id', assessmentId)
            .maybeSingle();
        if (a != null) {
          passingMarks = (a['passing_marks'] as num?)?.toInt() ?? 40;
          configuredTotalMarks = (a['total_marks'] as num?)?.toInt() ?? 100;
        }
      } catch (_) {}

      // 3. Load questions with correct answers to compute score
      final questions = await getAssessmentQuestions(assessmentId);
      double computedScore = 0.0;
      double totalPossibleMarks = 0.0;

      for (final q in questions) {
        totalPossibleMarks += q.marks;
        final selectedOptionId = selectedAnswers[q.id];
        if (selectedOptionId != null &&
            q.correctOptionId != null &&
            selectedOptionId == q.correctOptionId) {
          computedScore += q.marks;
        }
      }

      final finalTotalMarks = totalPossibleMarks > 0
          ? totalPossibleMarks
          : configuredTotalMarks.toDouble();

      final percentage = finalTotalMarks > 0
          ? ((computedScore / finalTotalMarks) * 100).clamp(0.0, 100.0)
          : 0.0;

      final passed = computedScore >= passingMarks;

      // 4. Record result in assessment_results
      final payload = {
        'assessment_id': assessmentId,
        'student_id': studentRecordId,
        'score': computedScore,
        'total_marks': finalTotalMarks,
        'percentage': percentage,
        'passed': passed,
        'completed_at': DateTime.now().toIso8601String(),
        'answers': selectedAnswers,
      };

      final List<dynamic> inserted = await _client
          .from('assessment_results')
          .insert(payload)
          .select('*');

      if (inserted.isNotEmpty) {
        return AssessmentAttemptResult.fromJson(
          Map<String, dynamic>.from(inserted.first as Map),
        );
      }

      return AssessmentAttemptResult(
        assessmentId: assessmentId,
        studentId: studentRecordId,
        score: computedScore,
        totalMarks: finalTotalMarks,
        percentage: percentage,
        passed: passed,
        completedAt: DateTime.now(),
      );
    } catch (e) {
      developer.log(
        'Error submitting assessment attempt $assessmentId: $e',
        name: 'SupabaseAssessmentsRepository',
      );
      rethrow;
    }
  }
}

