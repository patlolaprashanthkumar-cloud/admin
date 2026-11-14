/// Result metadata returned after completing and submitting an assessment
class AssessmentAttemptResult {
  final String assessmentId;
  final String studentId;
  final double score;
  final double totalMarks;
  final double percentage;
  final bool passed;
  final DateTime completedAt;

  const AssessmentAttemptResult({
    required this.assessmentId,
    required this.studentId,
    required this.score,
    required this.totalMarks,
    required this.percentage,
    required this.passed,
    required this.completedAt,
  });

  factory AssessmentAttemptResult.fromJson(Map<String, dynamic> json) {
    return AssessmentAttemptResult(
      assessmentId: json['assessment_id']?.toString() ?? '',
      studentId: json['student_id']?.toString() ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      totalMarks: (json['total_marks'] as num?)?.toDouble() ?? 100.0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      passed: json['passed'] is bool ? json['passed'] as bool : false,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

