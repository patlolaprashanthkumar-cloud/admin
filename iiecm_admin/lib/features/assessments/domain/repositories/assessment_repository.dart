import '../models/assessment.dart';
import '../models/question.dart';
import '../../../assignments/domain/models/assignment_submission.dart';

abstract class AssessmentRepository {
  /// Fetch all assessments (MCQ & Quizzes) with optional filters
  Future<List<Assessment>> getAssessments({
    String? status,
    String? categoryId,
    String? type,
    String? searchQuery,
  });

  /// Get assessment by ID with questions
  Future<Assessment?> getAssessmentById(String id);

  /// Create assessment
  Future<Assessment> createAssessment(Assessment assessment);

  /// Update assessment
  Future<Assessment> updateAssessment(Assessment assessment);

  /// Update status
  Future<void> updateAssessmentStatus(String id, String status);

  /// Delete assessment
  Future<void> deleteAssessment(String id);

  // Question Management
  Future<List<Question>> getAssessmentQuestions(String assessmentId);
  Future<Question> addQuestionToAssessment(
    String assessmentId,
    Question question,
    int orderIndex,
  );
  Future<Question> updateQuestion(Question question);
  Future<void> removeQuestionFromAssessment(
    String assessmentId,
    String questionId,
  );

  // Student Results & Monitoring
  Future<List<AssignmentSubmission>> getAssessmentResults(String assessmentId);
}
