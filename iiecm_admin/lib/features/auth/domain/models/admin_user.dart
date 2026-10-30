import 'user_role.dart';

/// Represents an authenticated Administrator profile from `public.profiles`
class AdminUser {
  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final String? phone;
  final String? avatarUrl;
  final DateTime? lastLoginAt;
  final DateTime? createdAt;

  const AdminUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.phone,
    this.avatarUrl,
    this.lastLoginAt,
    this.createdAt,
  });

  /// Factory constructor parsing authoritative row from `public.profiles`
  factory AdminUser.fromProfileJson(
    Map<String, dynamic> json, {
    String? emailFallback,
  }) {
    final roleStr = json['role'] as String?;
    final parsedRole = UserRole.fromString(roleStr) ?? UserRole.student;

    final email = (json['email'] as String?)?.trim() ?? (emailFallback ?? '');
    final fullName = (json['full_name'] as String?)?.trim() ?? 'Administrator';

    DateTime? lastLogin;
    if (json['last_login_at'] != null) {
      lastLogin = DateTime.tryParse(json['last_login_at'].toString());
    }

    DateTime? created;
    if (json['created_at'] != null) {
      created = DateTime.tryParse(json['created_at'].toString());
    }

    return AdminUser(
      id: json['id'] as String,
      email: email,
      fullName: fullName.isEmpty ? 'Administrator' : fullName,
      role: parsedRole,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      lastLoginAt: lastLogin,
      createdAt: created,
    );
  }

  AdminUser copyWith({
    String? id,
    String? email,
    String? fullName,
    UserRole? role,
    String? phone,
    String? avatarUrl,
    DateTime? lastLoginAt,
    DateTime? createdAt,
  }) {
    return AdminUser(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminUser &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          role == other.role;

  @override
  int get hashCode => id.hashCode ^ email.hashCode ^ role.hashCode;
}

