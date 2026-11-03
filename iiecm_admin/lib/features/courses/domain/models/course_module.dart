import 'course_lesson.dart';

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

  factory CourseModule.fromJson(
    Map<String, dynamic> json, {
    List<CourseLesson> lessons = const [],
  }) {
    return CourseModule(
      id: json['id']?.toString() ?? '',
      courseId: json['course_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Module',
      description: json['description']?.toString(),
      orderIndex: json['order_index'] is int
          ? json['order_index'] as int
          : int.tryParse(json['order_index']?.toString() ?? '1') ?? 1,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      lessons: lessons,
    );
  }

  Map<String, dynamic> toJson({bool includeId = false}) {
    final map = <String, dynamic>{
      'course_id': courseId,
      'title': title,
      'description': description,
      'order_index': orderIndex,
    };
    if (includeId && id.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }

  CourseModule copyWith({
    String? id,
    String? courseId,
    String? title,
    String? description,
    int? orderIndex,
    DateTime? createdAt,
    List<CourseLesson>? lessons,
  }) {
    return CourseModule(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      description: description ?? this.description,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt ?? this.createdAt,
      lessons: lessons ?? this.lessons,
    );
  }
}
