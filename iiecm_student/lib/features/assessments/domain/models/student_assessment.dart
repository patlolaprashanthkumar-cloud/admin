/// Domain model representing an examination or MCQ assessment assigned to an enrolled course
class StudentAssessment {
  final String id;
  final String title;
  final String description;
  final String? categoryId;
  final String? categoryName;
  final String type; // 'mcq', 'quiz'
  final int totalMarks;
  final int passingMarks;
  final int durationMinutes;
  final String status; // 'active', 'scheduled', 'draft', 'completed'
  final DateTime? scheduledAt;
  final DateTime createdAt;
  final String? courseId;
  final String courseTitle;
  final int questionCount;

  // Student attempt / result metadata from assessment_results
  final bool isCompleted;
  final String? resultId;
  final double? score;
  final double? percentage;
  final bool? isPassed;
  final DateTime? completedAt;

  const StudentAssessment({
    required this.id,
    required this.title,
    this.description = '',
    this.categoryId,
    this.categoryName,
    this.type = 'mcq',
    this.totalMarks = 100,
    this.passingMarks = 40,
    this.durationMinutes = 60,
    this.status = 'active',
    this.scheduledAt,
    required this.createdAt,
    this.courseId,
    this.courseTitle = 'Emergency Medicine',
    this.questionCount = 0,
    this.isCompleted = false,
    this.resultId,
    this.score,
    this.percentage,
    this.isPassed,
    this.completedAt,
  });

  bool get isActive => status.toLowerCase() == 'active';
  bool get isMcq => type.toLowerCase() == 'mcq';
  bool get isQuiz => type.toLowerCase() == 'quiz';

  bool get isAvailable {
    if (isCompleted) return false;
    if (!isActive) return false;
    if (scheduledAt == null) return true;
    // Available if current time is after scheduledAt or within the window
    return DateTime.now().isAfter(scheduledAt!);
  }

  bool get isUpcoming {
    if (isCompleted) return false;
    if (scheduledAt == null) return false;
    return scheduledAt!.isAfter(DateTime.now());
  }

  String get displayStatus {
    if (isCompleted) {
      return isPassed == true ? 'PASSED' : 'COMPLETED';
    }
    if (isUpcoming) {
      return 'SCHEDULED';
    }
    if (isActive) {
      return 'AVAILABLE';
    }
    return status.toUpperCase();
  }

  factory StudentAssessment.fromData({
    required Map<String, dynamic> assessmentJson,
    String? courseTitle,
    String? courseId,
    int questionCount = 0,
    Map<String, dynamic>? resultJson,
  }) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString());
    }

    final hasResult = resultJson != null;
    final scoreVal = (resultJson?['score'] as num?)?.toDouble();
    final pctVal = (resultJson?['percentage'] as num?)?.toDouble();

    return StudentAssessment(
      id: assessmentJson['id']?.toString() ?? '',
      title: assessmentJson['title']?.toString() ?? 'Clinical Examination',
      description: assessmentJson['description']?.toString() ?? '',
      categoryId: assessmentJson['category_id']?.toString(),
      categoryName: assessmentJson['category_name']?.toString(),
      type: assessmentJson['type']?.toString() ?? 'mcq',
      totalMarks: (assessmentJson['total_marks'] as num?)?.toInt() ?? 100,
      passingMarks: (assessmentJson['passing_marks'] as num?)?.toInt() ?? 40,
      durationMinutes: (assessmentJson['duration_minutes'] as num?)?.toInt() ?? 60,
      status: assessmentJson['status']?.toString() ?? 'active',
      scheduledAt: parseDate(assessmentJson['scheduled_at']),
      createdAt: parseDate(assessmentJson['created_at']) ?? DateTime.now(),
      courseId: courseId,
      courseTitle: courseTitle ?? 'Emergency Medicine',
      questionCount: questionCount,
      isCompleted: hasResult,
      resultId: resultJson?['id']?.toString(),
      score: scoreVal,
      percentage: pctVal,
      isPassed: resultJson?['passed'] is bool ? resultJson!['passed'] as bool : null,
      completedAt: parseDate(resultJson?['completed_at']),
    );
  }
}

