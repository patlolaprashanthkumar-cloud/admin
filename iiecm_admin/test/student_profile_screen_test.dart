import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iiecm_admin/app/theme/app_theme.dart';
import 'package:iiecm_admin/features/payments/domain/models/student_fee_profile.dart';
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
                  .overrideWith((ref) async => null as StudentFeeProfile?),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const StudentProfileScreen(studentId: 'std-with-format'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Dr. Sameer Khan'), findsOneWidget);
        expect(find.text('Online + Offline Classes'), findsOneWidget);
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
                  .overrideWith((ref) async => null as StudentFeeProfile?),
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

      final studentRecorded = Student(
        id: 'std-rec',
        studentId: 'IIECM-2026-005',
        fullName: 'Dr. Deepa Nair',
        email: 'deepa@hospital.org',
        phone: '+91 9876543214',
        educationLevel: 'Postgraduate',
        qualification: 'MBBS, DNB',
        preferredCategory: 'Toxicology',
        learningFormat: 'recorded',
        preferredSlot: 'Morning Clinical Batch (08:00 - 10:00 IST)',
        createdAt: DateTime(2026, 1, 1),
      );

      final liveAndRecordedOverrides = [
        studentDetailFamily('std-live')
            .overrideWith((ref) async => studentLive),
        studentLmsDetailsFamily('std-live')
            .overrideWith((ref) async => <StudentCategoryLmsGroup>[]),
        studentFeeProfileProvider('std-live')
            .overrideWith((ref) async => null as StudentFeeProfile?),
        studentDetailFamily('std-rec')
            .overrideWith((ref) async => studentRecorded),
        studentLmsDetailsFamily('std-rec')
            .overrideWith((ref) async => <StudentCategoryLmsGroup>[]),
        studentFeeProfileProvider('std-rec')
            .overrideWith((ref) async => null as StudentFeeProfile?),
      ];

      // 1. Verify Live Online Classes badge
      await tester.pumpWidget(
        ProviderScope(
          key: const ValueKey('live-scope'),
          overrides: liveAndRecordedOverrides,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const StudentProfileScreen(studentId: 'std-live'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Live Online Classes'), findsOneWidget);
      expect(
        find.text('Evening Executive Batch (18:00 - 20:00 IST)'),
        findsOneWidget,
      );

      // 2. Verify Recorded Classes badge with isolated scope
      await tester.pumpWidget(
        ProviderScope(
          key: const ValueKey('rec-scope'),
          overrides: liveAndRecordedOverrides,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const StudentProfileScreen(studentId: 'std-rec'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Recorded Classes'), findsOneWidget);
      expect(
        find.text('Morning Clinical Batch (08:00 - 10:00 IST)'),
        findsOneWidget,
      );
    });

    testWidgets('Displays Live + Recorded Classes label correctly', (
      tester,
    ) async {
      final studentLiveRecorded = Student(
        id: 'std-lr',
        studentId: 'IIECM-2026-004',
        fullName: 'Dr. Ananya Roy',
        email: 'ananya@hospital.org',
        phone: '+91 9876543213',
        educationLevel: 'Postgraduate',
        qualification: 'MD EM',
        preferredCategory: 'Critical Care',
        learningFormat: 'live_recorded',
        preferredSlot: 'Weekend Intensive (Saturday & Sunday)',
        createdAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            studentDetailFamily('std-lr')
                .overrideWith((ref) async => studentLiveRecorded),
            studentLmsDetailsFamily('std-lr')
                .overrideWith((ref) async => <StudentCategoryLmsGroup>[]),
            studentFeeProfileProvider('std-lr')
                .overrideWith((ref) async => null as StudentFeeProfile?),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const StudentProfileScreen(studentId: 'std-lr'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Live + Recorded Classes'), findsOneWidget);
      expect(
        find.text('Weekend Intensive (Saturday & Sunday)'),
        findsOneWidget,
      );
    });
  });
}
