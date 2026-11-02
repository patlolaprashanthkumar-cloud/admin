class CourseCategory {
  final String id;
  final String name;
  final String description;
  final String color;
  final bool isActive;
  final String? iconName;
  final int courseCount;
  final int instructorCount;
  final int studentCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CourseCategory({
    required this.id,
    required this.name,
    required this.description,
    this.color = '#245B43',
    this.isActive = true,
    this.iconName,
    this.courseCount = 0,
    this.instructorCount = 0,
    this.studentCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CourseCategory.fromJson(
    Map<String, dynamic> json, {
    int courseCount = 0,
    int instructorCount = 0,
    int studentCount = 0,
  }) {
    return CourseCategory(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      color: json['color']?.toString() ?? '#245B43',
      isActive: json['is_active'] is bool ? json['is_active'] as bool : true,
      iconName: json['icon_name']?.toString(),
      courseCount: (json['course_count'] is int)
          ? json['course_count'] as int
          : courseCount,
      instructorCount: instructorCount,
      studentCount: studentCount,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'color': color,
      'is_active': isActive,
      if (iconName != null) 'icon_name': iconName,
    };
  }

  CourseCategory copyWith({
    String? id,
    String? name,
    String? description,
    String? color,
    bool? isActive,
    String? iconName,
    int? courseCount,
    int? instructorCount,
    int? studentCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CourseCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      iconName: iconName ?? this.iconName,
      courseCount: courseCount ?? this.courseCount,
      instructorCount: instructorCount ?? this.instructorCount,
      studentCount: studentCount ?? this.studentCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

