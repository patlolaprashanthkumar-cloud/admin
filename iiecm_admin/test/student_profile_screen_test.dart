import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iiecm_admin/app/theme/app_theme.dart';
import 'package:iiecm_admin/features/payments/presentation/providers/payment_providers.dart';
import 'package:iiecm_admin/features/students/domain/models/student.dart';
import 'package:iiecm_admin/features/students/presentation/providers/students_provider.dart';
import 'package:iiecm_admin/features/students/presentation/screens/student_profile_screen.dart';

void main() {
  group('StudentProfileScreen Delivery Format & Cohort Display', () {
    testWidgets(
      'Displays formatted learning format and preferred cohort badge when present',
      (tester) async {
        final student = Student(
          id: 'std-with-format',
          studentId: 'IIECM-2026-001',
          fullName: 'Dr. Sameer Khan',
          email: 'sameer@hospital.org',
          phone: '+91 9876543210',
          educationLevel: 'Postgraduate',
          qualification: 'MD Emergency Medicine',
          preferredCategory: 'Trauma',
          city: 'Hyderabad',
          country: 'India',
          learningFormat: 'hybrid',
          preferredSlot: 'Morning Clinical Batch (08:00 - 10:00 IST)',
          createdAt: DateTime(2026, 1, 1),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              studentDetailFamily('std-with-format')
                  .overrideWith((ref) async => student),
              studentLmsDetailsFamily('std-with-format')
                  .overrideWith((ref) async => <StudentCategoryLmsGroup>[]),
              studentFeeProfileProvider('std-with-format')
                  .overrideWith((ref) async => null),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const StudentProfileScreen(studentId: 'std-with-format'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Dr. Sameer Khan'), findsOneWidget);
        expect(
          find.text('Hybrid (Virtual Lecture + Clinical Onsite)'),
          findsOneWidget,
        );
        expect(
          find.text('Morning Clinical Batch (08:00 - 10:00 IST)'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Handles NULL or empty learning format and preferred slot without layout errors',
      (tester) async {
        final studentNullFields = Student(
          id: 'std-null-fields',
          studentId: 'IIECM-2026-002',
          fullName: 'Dr. Leela Rao',
          email: 'leela@hospital.org',
          phone: '+91 9876543211',
          educationLevel: 'Resident',
          qualification: 'MBBS',
          preferredCategory: 'Emergency Medicine',
          city: 'Bengaluru',
          country: 'India',
          learningFormat: null,
          preferredSlot: null,
          createdAt: DateTime(2026, 1, 1),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              studentDetailFamily('std-null-fields')
                  .overrideWith((ref) async => studentNullFields),
              studentLmsDetailsFamily('std-null-fields')
                  .overrideWith((ref) async => <StudentCategoryLmsGroup>[]),
              studentFeeProfileProvider('std-null-fields')
                  .overrideWith((ref) async => null),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const StudentProfileScreen(studentId: 'std-null-fields'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Dr. Leela Rao'), findsOneWidget);
        expect(find.byIcon(Icons.school_outlined), findsNothing);
        expect(find.byIcon(Icons.access_time_rounded), findsNothing);
      },
    );

    testWidgets('Displays Live and Recorded readable labels correctly', (
      tester,
    ) async {
      final studentLive = Student(
        id: 'std-live',
        studentId: 'IIECM-2026-003',
        fullName: 'Dr. Vivek Verma',
        email: 'vivek@hospital.org',
        phone: '+91 9876543212',
        educationLevel: 'Fellow',
        qualification: 'MBBS, MEM',
        preferredCategory: 'Pediatric EM',
        learningFormat: 'live',
        preferredSlot: 'Evening Executive Batch (18:00 - 20:00 IST)',
        createdAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            studentDetailFamily('std-live')
                .overrideWith((ref) async => studentLive),
            studentLmsDetailsFamily('std-live')
                .overrideWith((ref) async => <StudentCategoryLmsGroup>[]),
            studentFeeProfileProvider('std-live')
                .overrideWith((ref) async => null),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const StudentProfileScreen(studentId: 'std-live'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Live Virtual Synchronous'), findsOneWidget);
      expect(
        find.text('Evening Executive Batch (18:00 - 20:00 IST)'),
        findsOneWidget,
      );
    });
  });
}
