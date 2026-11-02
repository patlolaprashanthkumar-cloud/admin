import 'package:flutter_test/flutter_test.dart';
import 'package:iiecm_admin/features/categories/domain/models/course_category.dart';
import 'package:iiecm_admin/features/faculty/domain/models/faculty.dart';

void main() {
  group('Faculty Domain Model Tests', () {
    test('Constructs Faculty correctly from JSON map', () {
      final json = {
        'id': 'f101',
        'profile_id': 'p101',
        'full_name': 'Dr. Sarah Connor',
        'email': 'sarah@iiecm.com',
        'phone': '+91 9876543210',
        'qualifications': 'MBBS, MD',
        'specialization': 'Emergency Medicine',
        'experience_years': 10,
        'account_status': 'active',
        'bio': 'Senior consultant',
        'rating': 4.85,
        'total_students': 150,
        'total_classes': 45,
        'created_at': '2026-01-01T10:00:00Z',
      };

      final category = CourseCategory(
        id: 'cat-1',
        name: 'Critical Care',
        description: 'Critical Care stream',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final faculty = Faculty.fromJson(
        json,
        assignedCategories: [category],
        assignedCourseIds: ['c1'],
      );

      expect(faculty.id, equals('f101'));
      expect(faculty.fullName, equals('Dr. Sarah Connor'));
      expect(faculty.isActive, isTrue);
      expect(faculty.rating, equals(4.85));
      expect(faculty.assignedCategories.length, equals(1));
      expect(faculty.assignedCategories.first.name, equals('Critical Care'));
      expect(faculty.assignedCourseIds, contains('c1'));
    });

    test('Faculty.toJson produces correct Supabase columns', () {
      final faculty = Faculty(
        id: 'f102',
        fullName: 'Dr. John Watson',
        email: 'john@iiecm.com',
        phone: '+91 9999988888',
        specialization: 'Diagnostic Medicine',
        createdAt: DateTime.now(),
      );

      final json = faculty.toJson();
      expect(json['full_name'], equals('Dr. John Watson'));
      expect(json['email'], equals('john@iiecm.com'));
      expect(json['specialization'], equals('Diagnostic Medicine'));
      expect(json['account_status'], equals('active'));
    });

    test('Faculty.copyWith works immutably', () {
      final faculty = Faculty(
        id: 'f103',
        fullName: 'Dr. House',
        email: 'house@iiecm.com',
        phone: '+91 1234567890',
        specialization: 'Nephrology',
        createdAt: DateTime.now(),
      );

      final updated = faculty.copyWith(accountStatus: 'suspended');
      expect(updated.accountStatus, equals('suspended'));
      expect(updated.fullName, equals('Dr. House'));
    });
  });
}
