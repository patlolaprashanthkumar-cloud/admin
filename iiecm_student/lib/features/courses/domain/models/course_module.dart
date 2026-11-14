import 'course_lesson.dart';

/// Represents an academic module containing multiple lessons in a course
class CourseModule {
  final String id;
  final String courseId;
  final String title;
  final String? description;
  final int orderIndex;
  final DateTime createdAt;
  final List<CourseLesson> lessons;

  const CourseModule({
    required this.id,
    required this.courseId,
    required this.title,
    this.description,
    this.orderIndex = 1,
    required this.createdAt,
    this.lessons = const [],
  });

  int get totalDurationMinutes =>
      lessons.fold<int>(0, (sum, lesson) => sum + lesson.durationMinutes);

  int get videoCount => lessons.where((l) => l.isVideo).length;
  int get pdfCount => lessons.where((l) => l.isPdf).length;
  int get imageCount => lessons.where((l) => l.isImage).length;
  int get fileCount => lessons.where((l) => l.isFile).length;

  factory CourseModule.fromJson(
    Map<String, dynamic> json, {
    List<CourseLesson> lessons = const [],
  }) {
    DateTime parseDate(dynamic val) {
      if (val is DateTime) return val;
      return DateTime.tryParse(val?.toString() ?? '') ?? DateTime.now();
    }

    return CourseModule(
      id: json['id']?.toString() ?? '',
      courseId: json['course_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Module',
      description: json['description']?.toString(),
      orderIndex: (json['order_index'] as num?)?.toInt() ?? 1,
      createdAt: parseDate(json['created_at']),
      lessons: lessons,
    );
  }
}

