import 'package:flutter_test/flutter_test.dart';
import 'package:iiecm_admin/features/auth/domain/models/admin_user.dart';
import 'package:iiecm_admin/features/auth/domain/models/user_role.dart';

void main() {
  group('UserRole Unit Tests', () {
    test('Correctly maps strings to authoritative roles', () {
      expect(UserRole.fromString('super_admin'), UserRole.superAdmin);
      expect(UserRole.fromString('admin'), UserRole.admin);
      expect(UserRole.fromString('instructor'), UserRole.instructor);
      expect(UserRole.fromString('student'), UserRole.student);
      expect(UserRole.fromString('ADMIN'), UserRole.admin);
      expect(UserRole.fromString('SUPER_ADMIN'), UserRole.superAdmin);
      expect(UserRole.fromString(null), isNull);
      expect(UserRole.fromString('hacker'), isNull);
    });

    test('Identifies admin privileges accurately', () {
      expect(UserRole.superAdmin.isAdmin, isTrue);
      expect(UserRole.admin.isAdmin, isTrue);
      expect(UserRole.instructor.isAdmin, isFalse);
      expect(UserRole.student.isAdmin, isFalse);
    });

    test('Identifies super admin privilege', () {
      expect(UserRole.superAdmin.isSuperAdmin, isTrue);
      expect(UserRole.admin.isSuperAdmin, isFalse);
    });
  });

  group('AdminUser Profile Model Tests', () {
    test('Constructs AdminUser from valid public.profiles JSON row', () {
      final json = {
        'id': 'a3c8e411-9f22-4a0b-8012-32a76dcfa211',
        'email': 'director@iiecm.org',
        'full_name': 'Dr. Sharma',
        'role': 'super_admin',
        'phone': '+91 9876543210',
        'avatar_url': 'https://example.com/avatar.jpg',
        'created_at': '2026-01-15T09:30:00Z',
        'last_login_at': '2026-03-30T10:00:00Z',
      };

      final user = AdminUser.fromProfileJson(json);
      expect(user.id, 'a3c8e411-9f22-4a0b-8012-32a76dcfa211');
      expect(user.email, 'director@iiecm.org');
      expect(user.fullName, 'Dr. Sharma');
      expect(user.role, UserRole.superAdmin);
      expect(user.phone, '+91 9876543210');
      expect(user.avatarUrl, 'https://example.com/avatar.jpg');
      expect(user.createdAt, DateTime.parse('2026-01-15T09:30:00Z'));
      expect(user.lastLoginAt, DateTime.parse('2026-03-30T10:00:00Z'));
    });

    test('Gracefully uses emailFallback if profile email is omitted', () {
      final json = {
        'id': 'b1c2e3-test',
        'full_name': 'Admin User',
        'role': 'admin',
      };

      final user = AdminUser.fromProfileJson(json, emailFallback: 'fallback@iiecm.org');
      expect(user.email, 'fallback@iiecm.org');
      expect(user.role, UserRole.admin);
    });
  });
}

