import '../../../categories/domain/models/course_category.dart';

class Student {
  final String id;
  final String studentId;
  final String fullName;
  final String email;
  final String phone;
  final String educationLevel;
  final String qualification;
  final String preferredCategory;
  final String? city;
  final String country;
  final String subscriptionPlan;
  final String subscriptionStatus;
  final String accountStatus;
  final DateTime createdAt;
  final List<CourseCategory> assignedCategories;
  final List<String> enrolledCourseIds;

  const Student({
    required this.id,
    required this.studentId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.educationLevel,
    required this.qualification,
    required this.preferredCategory,
    this.city,
    this.country = 'India',
    this.subscriptionPlan = 'basic',
    this.subscriptionStatus = 'active',
    this.accountStatus = 'active',
    required this.createdAt,
    this.assignedCategories = const [],
    this.enrolledCourseIds = const [],
  });

  factory Student.fromJson(
    Map<String, dynamic> json, {
    List<CourseCategory> assignedCategories = const [],
    List<String> enrolledCourseIds = const [],
  }) {
    return Student(
      id: json['id']?.toString() ?? '',
      studentId: json['student_id']?.toString() ?? 'N/A',
      fullName: json['full_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      educationLevel: json['education_level']?.toString() ?? '',
      qualification: json['qualification']?.toString() ?? '',
      preferredCategory: json['preferred_category']?.toString() ?? 'General',
      city: json['city']?.toString(),
      country: json['country']?.toString() ?? 'India',
      subscriptionPlan: json['subscription_plan']?.toString() ?? 'basic',
      subscriptionStatus: json['subscription_status']?.toString() ?? 'active',
      accountStatus: json['account_status']?.toString() ?? 'active',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      assignedCategories: assignedCategories,
      enrolledCourseIds: enrolledCourseIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'education_level': educationLevel,
      'qualification': qualification,
      'preferred_category': preferredCategory,
      'city': city,
      'country': country,
      'subscription_plan': subscriptionPlan,
      'subscription_status': subscriptionStatus,
      'account_status': accountStatus,
    };
  }
}

class StudentCategoryLmsGroup {
  final CourseCategory category;
  final List<Map<String, dynamic>> courses;
  final List<Map<String, dynamic>> instructors;
  final List<Map<String, dynamic>> liveClasses;
  final List<Map<String, dynamic>> assessments;
  final double progressPercentage;

  const StudentCategoryLmsGroup({
    required this.category,
    required this.courses,
    required this.instructors,
    required this.liveClasses,
    required this.assessments,
    this.progressPercentage = 0.0,
  });
}
