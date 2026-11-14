import '../../../categories/domain/models/course_category.dart';

class Student {
  final String id;
  final String? profileId;
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
    this.profileId,
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
      profileId: json['profile_id']?.toString(),
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
      if (profileId != null) 'profile_id': profileId,
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

/// Represents the complete outcome of student provisioning via admin-create-user Edge Function
class StudentRegistrationResult {
  final Student student;
  final int statusCode; // 201 (new account) or 200 (existing account re-linked)
  final bool isExistingUser;
  final bool invitationSent;
  final String message;
  final bool hasAssignmentWarning;
  final String? assignmentWarning;

  const StudentRegistrationResult({
    required this.student,
    this.statusCode = 201,
    this.isExistingUser = false,
    this.invitationSent = true,
    required this.message,
    this.hasAssignmentWarning = false,
    this.assignmentWarning,
  });
}

/// Explicit domain exception representing failure during Edge Function student provisioning
class StudentProvisioningException implements Exception {
  final String message;
  final int statusCode;
  final bool isPartialFailure;

  const StudentProvisioningException({
    required this.message,
    this.statusCode = 500,
    this.isPartialFailure = false,
  });

  bool get isConflict => statusCode == 409;
  bool get isInvitationFailure => statusCode == 502;
  bool get isConfigurationError => statusCode == 500 && !isPartialFailure;
  bool get isNetworkError => statusCode == 0;

  @override
  String toString() => message;
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
