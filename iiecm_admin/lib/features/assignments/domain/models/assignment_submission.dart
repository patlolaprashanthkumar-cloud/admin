class AssignmentSubmission {
  final String id;
  final String assessmentId;
  final String assessmentTitle;
  final String studentId;
  final String studentName;
  final double score;
  final double totalMarks;
  final double percentage;
  final bool passed;
  final DateTime completedAt;
  final dynamic answers; // JSONB: contains answer text, files, or feedback
  final String? feedback;

  const AssignmentSubmission({
    required this.id,
    required this.assessmentId,
    required this.assessmentTitle,
    required this.studentId,
    required this.studentName,
    required this.score,
    required this.totalMarks,
    required this.percentage,
    required this.passed,
    required this.completedAt,
    this.answers,
    this.feedback,
  });

  bool get isGraded => score > 0 || percentage > 0;

  factory AssignmentSubmission.fromJson(Map<String, dynamic> json) {
    String? feedbackText;
    final answersData = json['answers'];
    if (answersData is Map<String, dynamic>) {
      feedbackText = answersData['feedback']?.toString();
    }

    return AssignmentSubmission(
      id: json['id']?.toString() ?? '',
      assessmentId: json['assessment_id']?.toString() ?? '',
      assessmentTitle: json['assessment_title']?.toString() ?? '',
      studentId: json['student_id']?.toString() ?? '',
      studentName: json['student_name']?.toString() ?? 'Student',
      score: json['score'] is num
          ? (json['score'] as num).toDouble()
          : double.tryParse(json['score']?.toString() ?? '0') ?? 0.0,
      totalMarks: json['total_marks'] is num
          ? (json['total_marks'] as num).toDouble()
          : double.tryParse(json['total_marks']?.toString() ?? '100') ?? 100.0,
      percentage: json['percentage'] is num
          ? (json['percentage'] as num).toDouble()
          : double.tryParse(json['percentage']?.toString() ?? '0') ?? 0.0,
      passed: json['passed'] is bool ? json['passed'] as bool : false,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      answers: answersData,
      feedback: feedbackText,
    );
  }

  Map<String, dynamic> toGradingPayload() {
    Map<String, dynamic> answersMap = {};
    if (answers is Map<String, dynamic>) {
      answersMap = Map<String, dynamic>.from(answers as Map<String, dynamic>);
    }
    if (feedback != null && feedback!.isNotEmpty) {
      answersMap['feedback'] = feedback;
    }

    return {
      'score': score,
      'percentage': percentage,
      'passed': passed,
      'answers': answersMap,
    };
  }

  AssignmentSubmission copyWith({
    String? id,
    String? assessmentId,
    String? assessmentTitle,
    String? studentId,
    String? studentName,
    double? score,
    double? totalMarks,
    double? percentage,
    bool? passed,
    DateTime? completedAt,
    dynamic answers,
    String? feedback,
  }) {
    return AssignmentSubmission(
      id: id ?? this.id,
      assessmentId: assessmentId ?? this.assessmentId,
      assessmentTitle: assessmentTitle ?? this.assessmentTitle,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      score: score ?? this.score,
      totalMarks: totalMarks ?? this.totalMarks,
      percentage: percentage ?? this.percentage,
      passed: passed ?? this.passed,
      completedAt: completedAt ?? this.completedAt,
      answers: answers ?? this.answers,
      feedback: feedback ?? this.feedback,
    );
  }
}

