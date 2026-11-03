import '../../../categories/domain/models/course_category.dart';

class FacultyCourseRef {
  final String id;
  final String title;
  final String categoryName;
  final int enrolledCount;

  const FacultyCourseRef({
    required this.id,
    required this.title,
    this.categoryName = 'General',
    this.enrolledCount = 0,
  });

  factory FacultyCourseRef.fromJson(Map<String, dynamic> json) {
    return FacultyCourseRef(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled Course',
      categoryName: json['category_name']?.toString() ?? 'General',
      enrolledCount: json['enrolled_count'] is int
          ? json['enrolled_count'] as int
          : 0,
    );
  }
}

class Faculty {
  final String id;
  final String? profileId;
  final String fullName;
  final String email;
  final String phone;
  final String qualifications;
  final String specialization;
  final int experienceYears;
  final String accountStatus; // 'active', 'suspended', 'inactive'
  final String? bio;
  final double rating;
  final int totalStudents;
  final int totalClasses;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<CourseCategory> assignedCategories;
  final List<String> assignedCourseIds;
  final List<FacultyCourseRef> assignedCourses;

  const Faculty({
    required this.id,
    this.profileId,
    required this.fullName,
    required this.email,
    required this.phone,
    this.qualifications = 'N/A',
    required this.specialization,
    this.experienceYears = 0,
    this.accountStatus = 'active',
    this.bio,
    this.rating = 0.0,
    this.totalStudents = 0,
    this.totalClasses = 0,
    required this.createdAt,
    this.updatedAt,
    this.assignedCategories = const [],
    this.assignedCourseIds = const [],
    this.assignedCourses = const [],
  });

  bool get isActive => accountStatus.toLowerCase() == 'active';

  factory Faculty.fromJson(
    Map<String, dynamic> json, {
    List<CourseCategory> assignedCategories = const [],
    List<String> assignedCourseIds = const [],
    List<FacultyCourseRef> assignedCourses = const [],
  }) {
    return Faculty(
      id: json['id']?.toString() ?? '',
      profileId: json['profile_id']?.toString(),
      fullName: json['full_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      qualifications: json['qualifications']?.toString() ?? 'N/A',
      specialization: json['specialization']?.toString() ?? '',
      experienceYears: json['experience_years'] is int
          ? json['experience_years'] as int
          : int.tryParse(json['experience_years']?.toString() ?? '0') ?? 0,
      accountStatus: json['account_status']?.toString() ?? 'active',
      bio: json['bio']?.toString(),
      rating: json['rating'] is num
          ? (json['rating'] as num).toDouble()
          : double.tryParse(json['rating']?.toString() ?? '0.0') ?? 0.0,
      totalStudents: json['total_students'] is int
          ? json['total_students'] as int
          : int.tryParse(json['total_students']?.toString() ?? '0') ?? 0,
      totalClasses: json['total_classes'] is int
          ? json['total_classes'] as int
          : int.tryParse(json['total_classes']?.toString() ?? '0') ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      assignedCategories: assignedCategories,
      assignedCourseIds: assignedCourseIds,
      assignedCourses: assignedCourses,
    );
  }

  Map<String, dynamic> toJson({bool includeId = false}) {
    final map = <String, dynamic>{
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'qualifications': qualifications,
      'specialization': specialization,
      'experience_years': experienceYears,
      'account_status': accountStatus,
      'bio': bio,
      'rating': rating,
      'total_students': totalStudents,
      'total_classes': totalClasses,
    };
    if (includeId && id.isNotEmpty) {
      map['id'] = id;
    }
    if (profileId != null && profileId!.isNotEmpty) {
      map['profile_id'] = profileId;
    }
    return map;
  }

  Faculty copyWith({
    String? id,
    String? profileId,
    String? fullName,
    String? email,
    String? phone,
    String? qualifications,
    String? specialization,
    int? experienceYears,
    String? accountStatus,
    String? bio,
    double? rating,
    int? totalStudents,
    int? totalClasses,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<CourseCategory>? assignedCategories,
    List<String>? assignedCourseIds,
    List<FacultyCourseRef>? assignedCourses,
  }) {
    return Faculty(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      qualifications: qualifications ?? this.qualifications,
      specialization: specialization ?? this.specialization,
      experienceYears: experienceYears ?? this.experienceYears,
      accountStatus: accountStatus ?? this.accountStatus,
      bio: bio ?? this.bio,
      rating: rating ?? this.rating,
      totalStudents: totalStudents ?? this.totalStudents,
      totalClasses: totalClasses ?? this.totalClasses,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      assignedCategories: assignedCategories ?? this.assignedCategories,
      assignedCourseIds: assignedCourseIds ?? this.assignedCourseIds,
      assignedCourses: assignedCourses ?? this.assignedCourses,
    );
  }
}
