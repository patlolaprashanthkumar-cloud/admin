/// Authoritative student domain entity combining `public.profiles` and `public.students` data
class StudentProfile {
  /// Auth user ID and profile ID (`profiles.id` / `auth.users.id`)
  final String userId;

  /// Primary key in `public.students` table
  final String studentRecordId;

  /// Institutional Student Registration ID (e.g. `STU-2026-089` or `IIECM-2026-STU-001`)
  final String studentId;

  /// Student full legal name
  final String fullName;

  /// Registered email address
  final String email;

  /// Role assigned in `public.profiles` (must be `student`)
  final String role;

  /// Contact phone number
  final String? phone;

  /// Profile photo or avatar URL
  final String? avatarUrl;

  /// Institutional account status (`active`, `suspended`, `pending`, etc.)
  final String accountStatus;

  /// Education level or qualification (e.g. MBBS, MD, Diploma)
  final String? educationLevel;

  /// Primary academic qualification
  final String? qualification;

  /// Preferred medical or operational department / category
  final String? preferredCategory;

  /// Subscription tier or package
  final String? subscriptionPlan;

  /// Subscription payment status (`active`, `past_due`, `cancelled`, etc.)
  final String? subscriptionStatus;

  /// Timestamp of last successful login
  final DateTime? lastLoginAt;

  /// Timestamp of registration / record creation
  final DateTime? createdAt;

  const StudentProfile({
    required this.userId,
    required this.studentRecordId,
    required this.studentId,
    required this.fullName,
    required this.email,
    required this.role,
    this.phone,
    this.avatarUrl,
    required this.accountStatus,
    this.educationLevel,
    this.qualification,
    this.preferredCategory,
    this.subscriptionPlan,
    this.subscriptionStatus,
    this.lastLoginAt,
    this.createdAt,
  });

  /// Factory constructor assembling authoritative data from `public.profiles` and `public.students`
  factory StudentProfile.fromData({
    required Map<String, dynamic> profileMap,
    required Map<String, dynamic> studentMap,
    String? emailFallback,
  }) {
    final userId = profileMap['id']?.toString() ?? studentMap['profile_id']?.toString() ?? '';
    final email = (profileMap['email']?.toString() ?? studentMap['email']?.toString() ?? emailFallback ?? '').trim();
    final fullName = (studentMap['full_name']?.toString() ?? profileMap['full_name']?.toString() ?? 'Student').trim();
    final studentId = (studentMap['student_id']?.toString() ?? 'STU-$userId').trim();
    final studentRecordId = studentMap['id']?.toString() ?? '';
    final role = (profileMap['role']?.toString() ?? 'student').toLowerCase().trim();
    final phone = (studentMap['phone']?.toString() ?? profileMap['phone']?.toString())?.trim();
    final avatarUrl = profileMap['avatar_url']?.toString().trim();
    final accountStatus = (studentMap['account_status']?.toString() ?? 'active').toLowerCase().trim();
    final educationLevel = studentMap['education_level']?.toString().trim();
    final qualification = studentMap['qualification']?.toString().trim();
    final preferredCategory = studentMap['preferred_category']?.toString().trim();
    final subscriptionPlan = studentMap['subscription_plan']?.toString().trim();
    final subscriptionStatus = studentMap['subscription_status']?.toString().trim();

    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      return DateTime.tryParse(value.toString());
    }

    final lastLoginAt = parseDateTime(profileMap['last_login_at']);
    final createdAt = parseDateTime(studentMap['created_at'] ?? profileMap['created_at']);

    return StudentProfile(
      userId: userId,
      studentRecordId: studentRecordId,
      studentId: studentId,
      fullName: fullName,
      email: email,
      role: role,
      phone: phone,
      avatarUrl: avatarUrl,
      accountStatus: accountStatus,
      educationLevel: educationLevel,
      qualification: qualification,
      preferredCategory: preferredCategory,
      subscriptionPlan: subscriptionPlan,
      subscriptionStatus: subscriptionStatus,
      lastLoginAt: lastLoginAt,
      createdAt: createdAt,
    );
  }

  /// User's first name for informal portal greetings
  String get firstName {
    if (fullName.isEmpty) return 'Student';
    final parts = fullName.split(' ');
    return parts.first;
  }

  /// Whether the student account is currently active
  bool get isActive => accountStatus == 'active';
}

