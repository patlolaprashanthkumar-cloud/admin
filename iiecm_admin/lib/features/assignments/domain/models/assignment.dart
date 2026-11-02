class AssignmentCourseRef {
  final String id;
  final String title;

  const AssignmentCourseRef({required this.id, required this.title});

  factory AssignmentCourseRef.fromJson(Map<String, dynamic> json) {
    return AssignmentCourseRef(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Course',
    );
  }
}

class Assignment {
  final String id;
  final String title;
  final String description;
  final String? categoryId;
  final String? categoryName;
  final String type; // 'assignment', 'project'
  final int totalMarks;
  final int passingMarks;
  final int durationMinutes;
  final String status; // 'draft', 'scheduled', 'active', 'completed'
  final DateTime? deadline; // stored in scheduled_at
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<AssignmentCourseRef> assignedCourses;
  final int totalSubmissions;
  final int gradedSubmissions;

  const Assignment({
    required this.id,
    required this.title,
    this.description = '',
    this.categoryId,
    this.categoryName,
    this.type = 'assignment',
    this.totalMarks = 100,
    this.passingMarks = 40,
    this.durationMinutes = 1440, // default 24h
    this.status = 'active',
    this.deadline,
    this.createdBy = 'admin',
    required this.createdAt,
    this.updatedAt,
    this.assignedCourses = const [],
    this.totalSubmissions = 0,
    this.gradedSubmissions = 0,
  });

  bool get isActive => status.toLowerCase() == 'active';
  bool get isDraft => status.toLowerCase() == 'draft';
  bool get isCompleted => status.toLowerCase() == 'completed';

  factory Assignment.fromJson(
    Map<String, dynamic> json, {
    String? categoryName,
    List<AssignmentCourseRef> assignedCourses = const [],
    int totalSubmissions = 0,
    int gradedSubmissions = 0,
  }) {
    return Assignment(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled Assignment',
      description: json['description']?.toString() ?? '',
      categoryId: json['category_id']?.toString(),
      categoryName: categoryName ?? json['category_name']?.toString(),
      type: json['type']?.toString() ?? 'assignment',
      totalMarks: json['total_marks'] is int
          ? json['total_marks'] as int
          : int.tryParse(json['total_marks']?.toString() ?? '100') ?? 100,
      passingMarks: json['passing_marks'] is int
          ? json['passing_marks'] as int
          : int.tryParse(json['passing_marks']?.toString() ?? '40') ?? 40,
      durationMinutes: json['duration_minutes'] is int
          ? json['duration_minutes'] as int
          : int.tryParse(json['duration_minutes']?.toString() ?? '1440') ?? 1440,
      status: json['status']?.toString() ?? 'active',
      deadline: json['scheduled_at'] != null
          ? DateTime.tryParse(json['scheduled_at'].toString())
          : null,
      createdBy: json['created_by']?.toString() ?? 'admin',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      assignedCourses: assignedCourses,
      totalSubmissions: totalSubmissions,
      gradedSubmissions: gradedSubmissions,
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
    if (deadline != null) {
      map['scheduled_at'] = deadline!.toIso8601String();
    }
    if (includeId && id.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }

  Assignment copyWith({
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
    DateTime? deadline,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<AssignmentCourseRef>? assignedCourses,
    int? totalSubmissions,
    int? gradedSubmissions,
  }) {
    return Assignment(
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
      deadline: deadline ?? this.deadline,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      assignedCourses: assignedCourses ?? this.assignedCourses,
      totalSubmissions: totalSubmissions ?? this.totalSubmissions,
      gradedSubmissions: gradedSubmissions ?? this.gradedSubmissions,
    );
  }
}

