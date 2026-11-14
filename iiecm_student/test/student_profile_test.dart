import 'package:flutter_test/flutter_test.dart';
import 'package:iiecm_student/features/auth/domain/models/student_profile.dart';

void main() {
  group('StudentProfile Domain Model Tests', () {
    test('Correctly parses authoritative profiles and students database records', () {
      final profileMap = {
        'id': 'user-uuid-1234',
        'email': 'student@iiecm.org',
        'full_name': 'Dr. Rajesh Sharma',
        'role': 'student',
        'phone': '+91 9876543210',
        'avatar_url': 'https://storage.iiecm.org/avatars/rajesh.jpg',
        'last_login_at': '2026-11-13T10:00:00Z',
        'created_at': '2026-11-01T12:00:00Z',
      };

      final studentMap = {
        'id': 'student-record-5678',
        'profile_id': 'user-uuid-1234',
        'student_id': 'IIECM-2026-STU-089',
        'full_name': 'Dr. Rajesh Sharma',
        'email': 'student@iiecm.org',
        'phone': '+91 9876543210',
        'education_level': 'Postgraduate',
        'qualification': 'MBBS, MD (Emergency Medicine)',
        'preferred_category': 'Emergency Medicine & Critical Care',
        'account_status': 'active',
        'subscription_plan': '2026 Clinical Fellow',
        'subscription_status': 'active',
        'created_at': '2026-11-01T12:00:00Z',
      };

      final student = StudentProfile.fromData(
        profileMap: profileMap,
        studentMap: studentMap,
      );

      expect(student.userId, 'user-uuid-1234');
      expect(student.studentRecordId, 'student-record-5678');
      expect(student.studentId, 'IIECM-2026-STU-089');
      expect(student.fullName, 'Dr. Rajesh Sharma');
      expect(student.firstName, 'Dr.');
      expect(student.email, 'student@iiecm.org');
      expect(student.role, 'student');
      expect(student.accountStatus, 'active');
      expect(student.isActive, isTrue);
      expect(student.educationLevel, 'Postgraduate');
      expect(student.qualification, 'MBBS, MD (Emergency Medicine)');
      expect(student.preferredCategory, 'Emergency Medicine & Critical Care');
      expect(student.subscriptionPlan, '2026 Clinical Fellow');
    });

    test('Reports inactive when account_status is suspended', () {
      final profileMap = {
        'id': 'user-uuid-suspended',
        'role': 'student',
      };
      final studentMap = {
        'id': 'student-rec-suspended',
        'profile_id': 'user-uuid-suspended',
        'account_status': 'suspended',
      };

      final student = StudentProfile.fromData(
        profileMap: profileMap,
        studentMap: studentMap,
      );

      expect(student.accountStatus, 'suspended');
      expect(student.isActive, isFalse);
    });

    test('Handles null optional fields cleanly', () {
      final profileMap = {
        'id': 'user-uuid-nulls',
        'role': 'student',
      };
      final studentMap = {
        'id': 'student-rec-nulls',
        'profile_id': 'user-uuid-nulls',
      };

      final student = StudentProfile.fromData(
        profileMap: profileMap,
        studentMap: studentMap,
      );

      expect(student.avatarUrl, isNull);
      expect(student.educationLevel, isNull);
      expect(student.qualification, isNull);
      expect(student.preferredCategory, isNull);
      expect(student.subscriptionPlan, isNull);
      expect(student.subscriptionStatus, isNull);
    });
  });
}

