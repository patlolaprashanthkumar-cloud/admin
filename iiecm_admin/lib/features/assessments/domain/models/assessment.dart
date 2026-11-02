import 'question.dart';

class Assessment {
  final String id;
  final String title;
  final String description;
  final String? categoryId;
  final String? categoryName;
  final String type; // 'mcq', 'quiz'
  final int totalMarks;
  final int passingMarks;
  final int durationMinutes;
  final String status; // 'draft', 'scheduled', 'active', 'completed'
  final DateTime? scheduledAt;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<Question> questions;
  final int questionCount;
  final int totalAttempts;
  final int passedAttempts;

  const Assessment({
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
    this.createdBy = 'admin',
    required this.createdAt,
    this.updatedAt,
    this.questions = const [],
    this.questionCount = 0,
    this.totalAttempts = 0,
    this.passedAttempts = 0,
  });

  bool get isActive => status.toLowerCase() == 'active';
  bool get isDraft => status.toLowerCase() == 'draft';
  bool get isCompleted => status.toLowerCase() == 'completed';

  factory Assessment.fromJson(
    Map<String, dynamic> json, {
    String? categoryName,
    List<Question> questions = const [],
    int questionCount = 0,
    int totalAttempts = 0,
    int passedAttempts = 0,
  }) {
    return Assessment(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled Assessment',
      description: json['description']?.toString() ?? '',
      categoryId: json['category_id']?.toString(),
      categoryName: categoryName,
      type: json['type']?.toString() ?? 'mcq',
      totalMarks: json['total_marks'] is int
          ? json['total_marks'] as int
          : int.tryParse(json['total_marks']?.toString() ?? '100') ?? 100,
      passingMarks: json['passing_marks'] is int
          ? json['passing_marks'] as int
          : int.tryParse(json['passing_marks']?.toString() ?? '40') ?? 40,
      durationMinutes: json['duration_minutes'] is int
          ? json['duration_minutes'] as int
          : int.tryParse(json['duration_minutes']?.toString() ?? '60') ?? 60,
      status: json['status']?.toString() ?? 'active',
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.tryParse(json['scheduled_at'].toString())
          : null,
      createdBy: json['created_by']?.toString() ?? 'admin',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      questions: questions,
      questionCount: questionCount > 0 ? questionCount : questions.length,
      totalAttempts: totalAttempts,
      passedAttempts: passedAttempts,
    );
  }

  Map<String, dynamic> toJson({bool includeId = false}) {
    final map = <String, dynamic>{
      'title': title,
      'description': description,
      'type': type,
      'total_marks': totalMarks,
      'passing_marks': passingMarks,
      'duration_minutes': durationMinutes,
      'status': status,
      'created_by': createdBy,
    };
    if (categoryId != null && categoryId!.isNotEmpty) {
      map['category_id'] = categoryId;
    }
    if (scheduledAt != null) {
      map['scheduled_at'] = scheduledAt!.toIso8601String();
    }
    if (includeId && id.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }

  Assessment copyWith({
    String? id,
    String? title,
    String? description,
    String? categoryId,
    String? categoryName,
    String? type,
    int? totalMarks,
    int? passingMarks,
    int? durationMinutes,
    String? status,
    DateTime? scheduledAt,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Question>? questions,
    int? questionCount,
    int? totalAttempts,
    int? passedAttempts,
  }) {
    return Assessment(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      type: type ?? this.type,
      totalMarks: totalMarks ?? this.totalMarks,
      passingMarks: passingMarks ?? this.passingMarks,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      questions: questions ?? this.questions,
      questionCount: questionCount ?? this.questionCount,
      totalAttempts: totalAttempts ?? this.totalAttempts,
      passedAttempts: passedAttempts ?? this.passedAttempts,
    );
  }
}

