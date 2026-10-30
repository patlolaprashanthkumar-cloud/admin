/// Enum representing authoritative user roles from Supabase `public.user_role` enum
enum UserRole {
  superAdmin('super_admin', 'Super Administrator'),
  admin('admin', 'Administrator'),
  instructor('instructor', 'Instructor'),
  student('student', 'Student');

  final String value;
  final String label;

  const UserRole(this.value, this.label);

  /// Parse authoritative string value from public.profiles.role
  static UserRole? fromString(String? role) {
    if (role == null) return null;
    final normalized = role.trim().toLowerCase();
    for (final r in UserRole.values) {
      if (r.value == normalized) {
        return r;
      }
    }
    return null;
  }

  /// Returns true only if the role has administrative access in IIECM Admin
  bool get isAdmin => this == UserRole.superAdmin || this == UserRole.admin;

  /// Returns true only if the user is a Super Admin
  bool get isSuperAdmin => this == UserRole.superAdmin;
}

