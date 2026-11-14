/// Authoritative student-enrolled course domain model combining course metadata and enrollment status
class StudentCourse {
  final String id;
  final String title;
  final String description;
  final String? categoryId;
  final String categoryName;
  final String? instructorId;
  final String? instructorName;
  final String? thumbnailUrl;
  final int durationWeeks;
  final double fee;
  final String format; // 'hybrid', 'online', 'offline', 'live'
  final String status; // 'published', 'draft', 'archived'
  final List<String> learningObjectives;
  final List<String> prerequisites;
  final DateTime? publishedAt;
  final DateTime createdAt;
  final DateTime? enrolledAt;
  final String enrollmentStatus; // 'active', 'completed', 'dropped'
  final int enrolledCount;

  const StudentCourse({
    required this.id,
    required this.title,
    required this.description,
    this.categoryId,
    this.categoryName = 'Emergency Medicine',
    this.instructorId,
    this.instructorName,
    this.thumbnailUrl,
    this.durationWeeks = 8,
    this.fee = 0.0,
    this.format = 'hybrid',
    this.status = 'published',
    this.learningObjectives = const [],
    this.prerequisites = const [],
    this.publishedAt,
    required this.createdAt,
    this.enrolledAt,
    this.enrollmentStatus = 'active',
    this.enrolledCount = 0,
  });

  bool get isActive => enrollmentStatus.toLowerCase() == 'active';
  bool get isCompleted => enrollmentStatus.toLowerCase() == 'completed';

  factory StudentCourse.fromData({
    required Map<String, dynamic> courseJson,
    Map<String, dynamic>? enrollmentJson,
    String? instructorName,
    int enrolledCount = 0,
  }) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString());
    }

    List<String> parseList(dynamic val) {
      if (val is List) {
        return val.map((e) => e.toString()).toList();
      }
      return [];
    }

    return StudentCourse(
      id: courseJson['id']?.toString() ?? '',
      title: courseJson['title']?.toString() ?? 'Curriculum Module',
      description: courseJson['description']?.toString() ?? '',
      categoryId: courseJson['category_id']?.toString(),
      categoryName: courseJson['category_name']?.toString() ?? 'Emergency Medicine',
      instructorId: courseJson['instructor_id']?.toString(),
      instructorName: instructorName ?? courseJson['instructor_name']?.toString(),
      thumbnailUrl: courseJson['thumbnail_url']?.toString(),
      durationWeeks: (courseJson['duration_weeks'] as num?)?.toInt() ?? 8,
      fee: (courseJson['fee'] as num?)?.toDouble() ?? 0.0,
      format: courseJson['format']?.toString() ?? 'hybrid',
      status: courseJson['status']?.toString() ?? 'published',
      learningObjectives: parseList(courseJson['learning_objectives']),
      prerequisites: parseList(courseJson['prerequisites']),
      publishedAt: parseDate(courseJson['published_at']),
      createdAt: parseDate(courseJson['created_at']) ?? DateTime.now(),
      enrolledAt: parseDate(enrollmentJson?['enrolled_at']),
      enrollmentStatus: enrollmentJson?['status']?.toString() ?? 'active',
      enrolledCount: enrolledCount,
    );
  }
}

