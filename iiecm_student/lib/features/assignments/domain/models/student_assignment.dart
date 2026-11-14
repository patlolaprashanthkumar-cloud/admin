/// Domain model representing an assignment or practical project assigned to a student's course
class StudentAssignment {
  final String id;
  final String title;
  final String description;
  final String? categoryId;
  final String? categoryName;
  final String type; // 'assignment', 'project'
  final int totalMarks;
  final int passingMarks;
  final int durationMinutes;
  final String status; // 'active', 'scheduled', 'draft', 'completed'
  final DateTime? deadline; // from scheduled_at
  final DateTime createdAt;
  final String? courseId;
  final String courseTitle;

  // Student-specific submission / evaluation metadata
  final bool isSubmitted;
  final String? submissionId;
  final DateTime? submittedAt;
  final double? score;
  final double? percentage;
  final bool? isPassed;
  final bool isGraded;
  final String? feedback;
  final String? submissionNotes;

  const StudentAssignment({
    required this.id,
    required this.title,
    this.description = '',
    this.categoryId,
    this.categoryName,
    this.type = 'assignment',
    this.totalMarks = 100,
    this.passingMarks = 40,
    this.durationMinutes = 1440,
    this.status = 'active',
    this.deadline,
    required this.createdAt,
    this.courseId,
    this.courseTitle = 'Emergency Medicine',
    this.isSubmitted = false,
    this.submissionId,
    this.submittedAt,
    this.score,
    this.percentage,
    this.isPassed,
    this.isGraded = false,
    this.feedback,
    this.submissionNotes,
  });

  bool get isActive => status.toLowerCase() == 'active';
  bool get isProject => type.toLowerCase() == 'project';
  bool get isOverdue =>
      !isSubmitted && deadline != null && DateTime.now().isAfter(deadline!);

  /// Returns user-friendly status badge label
  String get displayStatus {
    if (isGraded) {
      return isPassed == true ? 'PASSED' : 'NEEDS REVISION';
    }
    if (isSubmitted) {
      return 'SUBMITTED';
    }
    if (isOverdue) {
      return 'OVERDUE';
    }
    return 'PENDING';
  }

  factory StudentAssignment.fromData({
    required Map<String, dynamic> assessmentJson,
    String? courseTitle,
    String? courseId,
    Map<String, dynamic>? submissionJson,
  }) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString());
    }

    final hasSubmission = submissionJson != null;
    final scoreVal = (submissionJson?['score'] as num?)?.toDouble();
    final pctVal = (submissionJson?['percentage'] as num?)?.toDouble();
    final isPassedVal = submissionJson?['passed'] == true ||
        submissionJson?['passed']?.toString().toLowerCase() == 'true';

    String? feedbackText;
    String? submissionNotesText;
    final answersData = submissionJson?['answers'];
    if (answersData is Map<String, dynamic>) {
      feedbackText = answersData['feedback']?.toString() ??
          answersData['instructor_feedback']?.toString() ??
          answersData['review']?.toString();
      submissionNotesText = answersData['submission_text']?.toString() ??
          answersData['notes']?.toString();
    }

    final hasFeedback = feedbackText != null && feedbackText.trim().isNotEmpty;
    // An assignment is graded if faculty has evaluated it:
    // feedback is present, score > 0, percentage > 0, or explicitly marked passed.
    final isGradedVal = hasSubmission &&
        (hasFeedback ||
            (scoreVal != null && scoreVal > 0) ||
            (pctVal != null && pctVal > 0) ||
            isPassedVal);

    return StudentAssignment(
      id: assessmentJson['id']?.toString() ?? '',
      title: assessmentJson['title']?.toString() ?? 'Clinical Case Assignment',
      description: assessmentJson['description']?.toString() ?? '',
      categoryId: assessmentJson['category_id']?.toString(),
      categoryName: assessmentJson['category_name']?.toString(),
      type: assessmentJson['type']?.toString() ?? 'assignment',
      totalMarks: (assessmentJson['total_marks'] as num?)?.toInt() ?? 100,
      passingMarks: (assessmentJson['passing_marks'] as num?)?.toInt() ?? 40,
      durationMinutes: (assessmentJson['duration_minutes'] as num?)?.toInt() ?? 1440,
      status: assessmentJson['status']?.toString() ?? 'active',
      deadline: parseDate(assessmentJson['scheduled_at']),
      createdAt: parseDate(assessmentJson['created_at']) ?? DateTime.now(),
      courseId: courseId,
      courseTitle: courseTitle ?? 'Emergency Medicine',
      isSubmitted: hasSubmission,
      submissionId: submissionJson?['id']?.toString(),
      submittedAt: parseDate(submissionJson?['completed_at']),
      score: scoreVal,
      percentage: pctVal,
      isPassed: hasSubmission ? isPassedVal : null,
      isGraded: isGradedVal,
      feedback: feedbackText,
      submissionNotes: submissionNotesText,
    );
  }
}

