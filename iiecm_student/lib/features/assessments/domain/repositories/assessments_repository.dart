import '../models/assessment_attempt_result.dart';
import '../models/assessment_question.dart';
import '../models/student_assessment.dart';

/// Repository interface contract for student examinations, quizzes, and assessments
abstract class AssessmentsRepository {
  /// Fetches all examinations and MCQ assessments assigned to courses the student is enrolled in
  Future<List<StudentAssessment>> getStudentAssessments(String studentRecordId);

  /// Fetches single assessment details with previous completion record
  Future<StudentAssessment?> getAssessmentDetails({
    required String assessmentId,
    required String studentRecordId,
  });

  /// Loads questions and options for an assessment attempt
  Future<List<StudentQuestion>> getAssessmentQuestions(String assessmentId);

  /// Submits candidate answers for an assessment attempt, computes score, and stores in assessment_results
  Future<AssessmentAttemptResult?> submitAssessmentAttempt({
    required String assessmentId,
    required String studentRecordId,
    required Map<String, String> selectedAnswers, // questionId -> selectedOptionId
  });
}

