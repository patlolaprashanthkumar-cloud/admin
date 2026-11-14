import '../../../auth/domain/models/student_profile.dart';

/// Represents a course the student is actively enrolled in
class EnrolledCourseItem {
  final String courseId;
  final String title;
  final String categoryName;
  final String? instructorName;
  final String enrollmentStatus; // 'active', 'completed', 'dropped'
  final String format; // 'hybrid', 'online', 'offline'
  final int durationWeeks;
  final DateTime? enrolledAt;

  const EnrolledCourseItem({
    required this.courseId,
    required this.title,
    required this.categoryName,
    this.instructorName,
    this.enrollmentStatus = 'active',
    this.format = 'hybrid',
    this.durationWeeks = 8,
    this.enrolledAt,
  });

  factory EnrolledCourseItem.fromData({
    required Map<String, dynamic> courseMap,
    Map<String, dynamic>? enrollmentMap,
    String? instructorName,
  }) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString());
    }

    return EnrolledCourseItem(
      courseId: courseMap['id']?.toString() ?? '',
      title: courseMap['title']?.toString() ?? 'Curriculum Module',
      categoryName:
          courseMap['category_name']?.toString() ?? 'Emergency Medicine',
      instructorName:
          instructorName ?? courseMap['instructor_name']?.toString(),
      enrollmentStatus: enrollmentMap?['status']?.toString() ?? 'active',
      format: courseMap['format']?.toString() ?? 'hybrid',
      durationWeeks: (courseMap['duration_weeks'] as num?)?.toInt() ?? 8,
      enrolledAt: parseDate(
        enrollmentMap?['enrolled_at'] ?? courseMap['created_at'],
      ),
    );
  }
}

/// Represents an upcoming or live interactive session for the student
class LiveClassItem {
  final String id;
  final String title;
  final String courseId;
  final String courseName;
  final String instructorName;
  final DateTime scheduledAt;
  final int durationMinutes;
  final String status; // 'upcoming', 'live', 'completed', 'cancelled'
  final String? meetingLink;
  final String? specialization;

  const LiveClassItem({
    required this.id,
    required this.title,
    required this.courseId,
    required this.courseName,
    required this.instructorName,
    required this.scheduledAt,
    this.durationMinutes = 60,
    this.status = 'upcoming',
    this.meetingLink,
    this.specialization,
  });

  bool get isLive => status.toLowerCase() == 'live';

  DateTime get endsAt => scheduledAt.add(Duration(minutes: durationMinutes));

  factory LiveClassItem.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val is DateTime) return val;
      return DateTime.tryParse(val?.toString() ?? '') ?? DateTime.now();
    }

    return LiveClassItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Clinical Lecture',
      courseId: json['course_id']?.toString() ?? '',
      courseName: json['course_name']?.toString() ?? 'Emergency Medicine',
      instructorName:
          json['instructor_name']?.toString() ?? 'Faculty Consultant',
      scheduledAt: parseDate(json['scheduled_at']),
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 60,
      status: json['status']?.toString() ?? 'upcoming',
      meetingLink: json['meeting_link']?.toString(),
      specialization:
          json['specialization']?.toString() ??
          json['category_name']?.toString(),
    );
  }
}

/// Consolidated authoritative dashboard dataset scoped to the logged-in student
class StudentDashboardData {
  final StudentProfile student;
  final List<EnrolledCourseItem> enrolledCourses;
  final int totalEnrolledCourses;
  final int inProgressCourses;
  final int pendingAssignmentsCount;
  final int upcomingAssessmentsCount;
  final int evaluatedResultsCount;
  final String? averageGrade;
  final double? averageScorePercentage;
  final LiveClassItem? nextScheduledSession;
  final DateTime lastRefreshed;

  const StudentDashboardData({
    required this.student,
    required this.enrolledCourses,
    required this.totalEnrolledCourses,
    required this.inProgressCourses,
    required this.pendingAssignmentsCount,
    required this.upcomingAssessmentsCount,
    required this.evaluatedResultsCount,
    this.averageGrade,
    this.averageScorePercentage,
    this.nextScheduledSession,
    required this.lastRefreshed,
  });

  /// Primary course displayed on the Continue Learning spotlight
  EnrolledCourseItem? get primaryCourse =>
      enrolledCourses.isNotEmpty ? enrolledCourses.first : null;

  /// Whether the student has at least one active course enrollment
  bool get hasEnrollments => enrolledCourses.isNotEmpty;
}
