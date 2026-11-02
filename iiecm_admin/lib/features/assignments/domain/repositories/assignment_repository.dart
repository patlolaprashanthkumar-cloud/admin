import '../models/assignment.dart';
import '../models/assignment_submission.dart';

abstract class AssignmentRepository {
  /// Fetch all assignments with optional status, category, or search filters
  Future<List<Assignment>> getAssignments({
    String? status,
    String? categoryId,
    String? type,
    String? searchQuery,
  });

  /// Get assignment by ID with assigned courses
  Future<Assignment?> getAssignmentById(String id);

  /// Create an assignment and allocate it to courses
  Future<Assignment> createAssignment(
    Assignment assignment, {
    List<String> courseIds = const [],
  });

  /// Update an assignment
  Future<Assignment> updateAssignment(
    Assignment assignment, {
    List<String>? courseIds,
  });

  /// Update assignment status
  Future<void> updateAssignmentStatus(String id, String status);

  /// Delete assignment
  Future<void> deleteAssignment(String id);

  /// Fetch submissions for an assignment
  Future<List<AssignmentSubmission>> getSubmissions(String assessmentId);

  /// Grade a student submission
  Future<AssignmentSubmission> gradeSubmission({
    required String submissionId,
    required double score,
    required double totalMarks,
    required bool passed,
    String? feedback,
  });
}

