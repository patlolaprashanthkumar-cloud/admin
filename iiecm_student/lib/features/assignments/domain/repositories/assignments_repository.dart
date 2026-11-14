import '../models/student_assignment.dart';

/// Repository interface contract for student assignments and practical deliverables
abstract class AssignmentsRepository {
  /// Fetches all assignments linked to courses the student is enrolled in
  Future<List<StudentAssignment>> getStudentAssignments(String studentRecordId);

  /// Fetches a single assignment by its ID with the student's submission record
  Future<StudentAssignment?> getAssignmentDetails({
    required String assignmentId,
    required String studentRecordId,
  });

  /// Submits candidate deliverable notes/solution for an assignment
  Future<bool> submitAssignment({
    required String assignmentId,
    required String studentRecordId,
    required String submissionText,
    String? attachmentUrl,
  });
}

