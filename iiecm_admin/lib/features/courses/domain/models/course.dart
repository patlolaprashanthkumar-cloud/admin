class Course {
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
  final String format; // 'live', 'recorded', 'hybrid'
  final String status; // 'draft', 'published', 'archived'
  final List<String> learningObjectives;
  final List<String> prerequisites;
  final DateTime? publishedAt;
  final DateTime createdAt;
  final int enrolledCount;

  const Course({
    required this.id,
    required this.title,
    required this.description,
    this.categoryId,
    this.categoryName = 'General',
    this.instructorId,
    this.instructorName,
    this.thumbnailUrl,
    this.durationWeeks = 8,
    this.fee = 0.0,
    this.format = 'hybrid',
    this.status = 'draft',
    this.learningObjectives = const [],
    this.prerequisites = const [],
    this.publishedAt,
    required this.createdAt,
    this.enrolledCount = 0,
  });

  factory Course.fromJson(
    Map<String, dynamic> json, {
    String? instructorName,
    int enrolledCount = 0,
  }) {
    return Course(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled Course',
      description: json['description']?.toString() ?? '',
      categoryId: json['category_id']?.toString(),
      categoryName: json['category_name']?.toString() ?? 'General',
      instructorId: json['instructor_id']?.toString(),
      instructorName: instructorName,
      thumbnailUrl: json['thumbnail_url']?.toString(),
      durationWeeks: json['duration_weeks'] is int
          ? json['duration_weeks'] as int
          : 8,
      fee: json['fee'] is num
          ? (json['fee'] as num).toDouble()
          : double.tryParse(json['fee']?.toString() ?? '0') ?? 0.0,
      format: json['format']?.toString() ?? 'hybrid',
      status: json['status']?.toString() ?? 'draft',
      learningObjectives:
          (json['learning_objectives'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      prerequisites:
          (json['prerequisites'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      publishedAt: json['published_at'] != null
          ? DateTime.tryParse(json['published_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      enrolledCount: enrolledCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category_id': categoryId,
      'category_name': categoryName,
      'instructor_id': instructorId,
      'thumbnail_url': thumbnailUrl,
      'duration_weeks': durationWeeks,
      'fee': fee,
      'format': format,
      'status': status,
      'learning_objectives': learningObjectives,
      'prerequisites': prerequisites,
    };
  }
}
