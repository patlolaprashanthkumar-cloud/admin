import '../models/student_result.dart';

/// Contract defining results access for the authenticated student
abstract class ResultsRepository {
  /// Fetches all assessment and assignment results for the specified student record
  Future<List<StudentResult>> getStudentResults(String studentRecordId);

  /// Fetches detailed result information for a specific result ID
  Future<StudentResult?> getResultDetails({
    required String resultId,
    required String studentRecordId,
  });
}

