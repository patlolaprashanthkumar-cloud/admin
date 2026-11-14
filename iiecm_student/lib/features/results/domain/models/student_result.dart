import 'dart:convert';

/// Classification of academic result types supported by IIECM curriculum
enum ResultType {
  mcq,
  quiz,
  assignment,
  project;

  static ResultType fromString(String? type) {
    switch (type?.toLowerCase()) {
      case 'quiz':
        return ResultType.quiz;
      case 'assignment':
        return ResultType.assignment;
      case 'project':
        return ResultType.project;
      case 'mcq':
      default:
        return ResultType.mcq;
    }
  }

  String get displayName {
    switch (this) {
      case ResultType.quiz:
        return 'Quiz';
      case ResultType.assignment:
        return 'Clinical Assignment';
      case ResultType.project:
        return 'Practical Project';
      case ResultType.mcq:
        return 'MCQ Examination';
    }
  }

  bool get isAssessment => this == ResultType.mcq || this == ResultType.quiz;
  bool get isAssignment =>
      this == ResultType.assignment || this == ResultType.project;
}

/// Authoritative student result domain entity matching Supabase `public.assessment_results`
class StudentResult {
  /// Result record ID (`assessment_results.id`)
  final String id;

  /// Foreign key referencing `public.assessments.id`
  final String assessmentId;

  /// Title of the assessment or assignment
  final String title;

  /// Academic category/type of the assessment
  final ResultType type;

  /// Course ID if assigned to a curriculum course
  final String? courseId;

  /// Human-readable title of the course
  final String courseTitle;

  /// Score obtained by the student
  final double score;

  /// Maximum total marks possible
  final double totalMarks;

  /// Score percentage (0.0 - 100.0)
  final double percentage;

  /// Passing threshold status recorded in database
  final bool passed;

  /// Timestamp when attempt was submitted/completed
  final DateTime completedAt;

  /// Minimum passing marks configured for the assessment
  final int? passingMarks;

  /// Faculty feedback provided during grading (if stored)
  final String? feedback;

  /// Student's submitted notes or narrative text
  final String? submissionNotes;

  /// Stored raw answer details or questions summary
  final dynamic answersData;

  /// Total count of answered questions (for MCQs)
  final int? answeredQuestionsCount;

  /// Whether the result has been finalized/evaluated
  final bool isEvaluated;

  const StudentResult({
    required this.id,
    required this.assessmentId,
    required this.title,
    this.type = ResultType.mcq,
    this.courseId,
    this.courseTitle = 'Emergency Medicine',
    required this.score,
    required this.totalMarks,
    required this.percentage,
    required this.passed,
    required this.completedAt,
    this.passingMarks,
    this.feedback,
    this.submissionNotes,
    this.answersData,
    this.answeredQuestionsCount,
    this.isEvaluated = true,
  });

  bool get isAssessment => type.isAssessment;
  bool get isAssignment => type.isAssignment;

  /// Formatted score display (e.g. "85.0 / 100")
  String get formattedScore {
    final sStr = score % 1 == 0 ? score.toInt().toString() : score.toStringAsFixed(1);
    final tStr = totalMarks % 1 == 0 ? totalMarks.toInt().toString() : totalMarks.toStringAsFixed(0);
    return '$sStr / $tStr';
  }

  /// Formatted percentage string (e.g. "85.0%")
  String get formattedPercentage => '${percentage.toStringAsFixed(1)}%';

  /// Authoritative status badge text
  String get displayStatus {
    if (!isEvaluated) {
      return 'PENDING EVALUATION';
    }
    return passed ? 'PASSED' : 'NOT PASSED';
  }

  /// Factory constructing from joined `assessment_results`, `assessments`, and `courses` data
  factory StudentResult.fromData({
    required Map<String, dynamic> resultJson,
    Map<String, dynamic>? assessmentJson,
    String? courseTitle,
    String? courseId,
  }) {
    DateTime parseDate(dynamic val) {
      if (val is DateTime) return val;
      return DateTime.tryParse(val?.toString() ?? '') ?? DateTime.now();
    }

    final rawType = assessmentJson?['type']?.toString();
    final resultType = ResultType.fromString(rawType);

    final rawScore = (resultJson['score'] as num?)?.toDouble() ?? 0.0;
    final rawTotal = (resultJson['total_marks'] as num?)?.toDouble() ?? 100.0;
    final rawPct = (resultJson['percentage'] as num?)?.toDouble() ??
        (rawTotal > 0 ? ((rawScore / rawTotal) * 100).clamp(0.0, 100.0) : 0.0);
    final isPassed = resultJson['passed'] is bool
        ? resultJson['passed'] as bool
        : (resultJson['passed']?.toString().toLowerCase() == 'true');

    // Parse answers JSONB
    dynamic answers = resultJson['answers'];
    if (answers is String) {
      try {
        answers = jsonDecode(answers);
      } catch (_) {}
    }

    String? feedbackText;
    String? submissionNotesText;
    int? answeredCount;

    if (answers is Map<String, dynamic>) {
      feedbackText = answers['feedback']?.toString() ??
          answers['instructor_feedback']?.toString() ??
          answers['review']?.toString();
      submissionNotesText = answers['submission_text']?.toString() ??
          answers['notes']?.toString();
      if (resultType.isAssessment) {
        answeredCount = answers.length;
      }
    } else if (answers is List) {
      answeredCount = answers.length;
    }

    // Determine evaluation state:
    // MCQs/quizzes are evaluated immediately on submission.
    // Assignments are evaluated if feedback is present, score > 0, percentage > 0, or explicitly passed.
    final bool evaluated;
    if (resultType.isAssessment) {
      evaluated = true;
    } else {
      evaluated = (feedbackText != null && feedbackText.isNotEmpty) ||
          rawScore > 0 ||
          rawPct > 0 ||
          isPassed;
    }

    final passingMarksVal = (assessmentJson?['passing_marks'] as num?)?.toInt();

    return StudentResult(
      id: resultJson['id']?.toString() ?? '',
      assessmentId: resultJson['assessment_id']?.toString() ?? '',
      title: assessmentJson?['title']?.toString() ??
          resultJson['assessment_title']?.toString() ??
          'Assessment Result',
      type: resultType,
      courseId: courseId,
      courseTitle: courseTitle ?? 'Emergency Medicine Curriculum',
      score: rawScore,
      totalMarks: rawTotal,
      percentage: rawPct,
      passed: isPassed,
      completedAt: parseDate(resultJson['completed_at'] ?? resultJson['created_at']),
      passingMarks: passingMarksVal,
      feedback: feedbackText,
      submissionNotes: submissionNotesText,
      answersData: answers,
      answeredQuestionsCount: answeredCount,
      isEvaluated: evaluated,
    );
  }

  factory StudentResult.fromJson(Map<String, dynamic> json) {
    return StudentResult.fromData(resultJson: json);
  }
}

