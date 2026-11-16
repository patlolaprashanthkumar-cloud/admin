import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:iiecm_admin/app/theme/app_theme.dart';
import 'package:iiecm_admin/features/categories/domain/models/course_category.dart';
import 'package:iiecm_admin/features/categories/presentation/providers/category_provider.dart';
import 'package:iiecm_admin/features/courses/domain/models/course.dart';
import 'package:iiecm_admin/features/courses/presentation/providers/courses_provider.dart';
import 'package:iiecm_admin/features/students/presentation/providers/students_provider.dart';
import 'package:iiecm_admin/features/students/presentation/screens/add_student_wizard.dart';

import 'scrolling_and_forms_test.dart';

void main() {
  final testCategory = CourseCategory(
    id: 'cat-em-1',
    name: 'Emergency Medicine',
    description: 'Core EM',
    color: '#245B43',
    isActive: true,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  final testCourse = Course(
    id: 'crs-em-1',
    title: 'Advanced Trauma Care',
    description: 'Trauma protocols',
    categoryId: 'cat-em-1',
    categoryName: 'Emergency Medicine',
    durationWeeks: 12,
    fee: 25000.0,
    format: 'hybrid',
    status: 'published',
    createdAt: DateTime(2026, 1, 1),
  );

  group('AddStudentWizard Learning Format & Cohort Tests', () {
    testWidgets(
      'Step 5 contains all 4 learning format options, supports selection of Live, Recorded, Live+Recorded, and completes registration',
      (tester) async {
        final catRepo = MockTestCategoryRepo([testCategory]);
        final crsRepo = MockTestCourseRepo([testCourse]);
        final stdRepo = MockTestStudentRepo([]);

        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) =>
                  const Scaffold(body: Text('Root Shell')),
            ),
            GoRoute(
              path: '/wizard',
              builder: (context, state) => const AddStudentWizard(),
            ),
          ],
        );

        tester.view.physicalSize = const Size(800 * 2, 1000 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              categoryRepositoryProvider.overrideWithValue(catRepo),
              courseRepositoryProvider.overrideWithValue(crsRepo),
              studentRepositoryProvider.overrideWithValue(stdRepo),
            ],
            child: MaterialApp.router(
              theme: AppTheme.lightTheme,
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Push wizard into realistic GoRouter navigation stack
        router.push('/wizard');
        await tester.pumpAndSettle();

        // Fill Step 1
        final textFields = find.byType(TextFormField);
        await tester.enterText(textFields.at(0), 'Dr. Sunil Menon');
        await tester.enterText(textFields.at(1), 'sunil@hospital.org');
        await tester.enterText(textFields.at(2), '9876500001');
        await tester.enterText(textFields.at(3), 'Chennai');
        await tester.enterText(textFields.at(4), 'MBBS, MD');

        // Advance: Step 1 -> Step 2
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        expect(find.text('Step 2 of 6'), findsOneWidget);

        // Select Category on Step 2
        final checkbox = find.byType(Checkbox);
        expect(checkbox, findsOneWidget);
        await tester.tap(checkbox);
        await tester.pumpAndSettle();

        // Advance: Step 2 -> Step 3
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        expect(find.text('Step 3 of 6'), findsOneWidget);

        // Advance: Step 3 -> Step 4
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        expect(find.text('Step 4 of 6'), findsOneWidget);

        // Advance: Step 4 -> Step 5
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        expect(find.text('Step 5 of 6'), findsOneWidget);

        // On Step 5: Verify section heading and default is Hybrid (Online + Offline Classes)
        expect(find.text('Class Format & Schedule'), findsOneWidget);
        expect(find.text('Online + Offline Classes'), findsOneWidget);

        // Verify Preferred Slot is present and default is untouched
        expect(find.text('Preferred Timetable Slot'), findsOneWidget);
        expect(find.text('Morning Batch (08:00 - 10:00 IST)'), findsOneWidget);

        // Open Learning Format Dropdown
        await tester.tap(find.text('Online + Offline Classes'));
        await tester.pumpAndSettle();

        // Verify all 4 options are present in the dropdown menu with simplified labels
        expect(find.text('Online + Offline Classes'), findsWidgets);
        expect(find.text('Live Online Classes'), findsOneWidget);
        expect(find.text('Recorded Classes'), findsOneWidget);
        expect(find.text('Live + Recorded Classes'), findsOneWidget);

        // 1. Test selecting Live Online Classes
        await tester.tap(find.text('Live Online Classes').last);
        await tester.pumpAndSettle();

        // Advance to Step 6 (Review) and verify Live option appears
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        expect(find.text('Step 6 of 6'), findsOneWidget);
        expect(find.text('Class Format & Schedule'), findsOneWidget);
        expect(find.textContaining('Live Online Classes'), findsOneWidget);

        // Step back to Step 5
        await tester.tap(find.text('Previous'));
        await tester.pumpAndSettle();
        expect(find.text('Step 5 of 6'), findsOneWidget);

        // 2. Test selecting Recorded Classes
        await tester.tap(find.text('Live Online Classes'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Recorded Classes').last);
        await tester.pumpAndSettle();

        // Advance to Step 6 (Review) and verify Recorded option appears
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        expect(find.text('Step 6 of 6'), findsOneWidget);
        expect(find.text('Class Format & Schedule'), findsOneWidget);
        expect(find.textContaining('Recorded Classes'), findsOneWidget);

        // Step back to Step 5
        await tester.tap(find.text('Previous'));
        await tester.pumpAndSettle();
        expect(find.text('Step 5 of 6'), findsOneWidget);

        // 3. Test selecting the fourth option: Live + Recorded Classes
        await tester.tap(find.text('Recorded Classes'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Live + Recorded Classes').last);
        await tester.pumpAndSettle();

        // Advance: Step 5 -> Step 6 (Review)
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        expect(find.text('Step 6 of 6'), findsOneWidget);
        expect(find.text('Class Format & Schedule'), findsOneWidget);

        // Verify final registration review screen displays the human-readable label
        expect(find.textContaining('Live + Recorded Classes'), findsOneWidget);

        // Submit registration (Confirm & Register Student)
        await tester.tap(find.text('Confirm & Register Student'));
        await tester.pumpAndSettle();

        // Verify navigation popped back to Root Shell via GoRouter context
        expect(find.text('Root Shell'), findsOneWidget);

        // Verify repository received the registered student with live_recorded
        expect(stdRepo.list.length, 1);
        final registered = stdRepo.list.first;
        expect(registered.fullName, 'Dr. Sunil Menon');
        expect(registered.learningFormat, 'live_recorded');
        expect(
          registered.preferredSlot,
          'Morning Clinical Batch (08:00 - 10:00 IST)',
        );
      },
    );

    testWidgets(
      'Step 5 preserves default Hybrid selection through to review and submission',
      (tester) async {
        final catRepo = MockTestCategoryRepo([testCategory]);
        final crsRepo = MockTestCourseRepo([testCourse]);
        final stdRepo = MockTestStudentRepo([]);

        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) =>
                  const Scaffold(body: Text('Root Shell')),
            ),
            GoRoute(
              path: '/wizard',
              builder: (context, state) => const AddStudentWizard(),
            ),
          ],
        );

        tester.view.physicalSize = const Size(800 * 2, 1000 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              categoryRepositoryProvider.overrideWithValue(catRepo),
              courseRepositoryProvider.overrideWithValue(crsRepo),
              studentRepositoryProvider.overrideWithValue(stdRepo),
            ],
            child: MaterialApp.router(
              theme: AppTheme.lightTheme,
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();

        router.push('/wizard');
        await tester.pumpAndSettle();

        // Fill Step 1
        final textFields = find.byType(TextFormField);
        await tester.enterText(textFields.at(0), 'Dr. Priya Nair');
        await tester.enterText(textFields.at(1), 'priya@hospital.org');
        await tester.enterText(textFields.at(2), '9876500002');
        await tester.enterText(textFields.at(3), 'Kochi');
        await tester.enterText(textFields.at(4), 'MBBS');

        // Advance: Step 1 -> Step 2
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        expect(find.text('Step 2 of 6'), findsOneWidget);

        // Select Category Step 2
        await tester.tap(find.byType(Checkbox));
        await tester.pumpAndSettle();

        // Advance: Step 2 -> Step 3
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        expect(find.text('Step 3 of 6'), findsOneWidget);

        // Advance: Step 3 -> Step 4
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        expect(find.text('Step 4 of 6'), findsOneWidget);

        // Advance: Step 4 -> Step 5
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        expect(find.text('Step 5 of 6'), findsOneWidget);

        // On Step 5: Verify section heading and default Hybrid (Online + Offline Classes)
        expect(find.text('Class Format & Schedule'), findsOneWidget);
        expect(find.text('Online + Offline Classes'), findsOneWidget);

        // Verify Preferred Slot options
        expect(find.text('Preferred Timetable Slot'), findsOneWidget);
        expect(find.text('Morning Batch (08:00 - 10:00 IST)'), findsOneWidget);

        // Step back: Step 5 -> Step 4 to test navigation retention
        await tester.tap(find.text('Previous'));
        await tester.pumpAndSettle();
        expect(find.text('Step 4 of 6'), findsOneWidget);

        // Return forward: Step 4 -> Step 5
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        expect(find.text('Step 5 of 6'), findsOneWidget);
        expect(find.text('Online + Offline Classes'), findsOneWidget);

        // Advance to Step 6 without modifying default
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        expect(find.text('Step 6 of 6'), findsOneWidget);
        expect(find.text('Class Format & Schedule'), findsOneWidget);

        // Verify review displays Hybrid
        expect(find.textContaining('Online + Offline Classes'), findsOneWidget);
        expect(
          find.textContaining('Morning Clinical Batch (08:00 - 10:00 IST)'),
          findsOneWidget,
        );

        // Step back: Step 6 -> Step 5 and return forward to Step 6
        await tester.tap(find.text('Previous'));
        await tester.pumpAndSettle();
        expect(find.text('Step 5 of 6'), findsOneWidget);
        expect(find.text('Online + Offline Classes'), findsOneWidget);

        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        expect(find.text('Step 6 of 6'), findsOneWidget);
        expect(find.textContaining('Online + Offline Classes'), findsOneWidget);

        // Submit registration
        await tester.tap(find.text('Confirm & Register Student'));
        await tester.pumpAndSettle();

        // Verify navigation popped back to Root Shell
        expect(find.text('Root Shell'), findsOneWidget);

        expect(stdRepo.list.length, 1);
        final registered = stdRepo.list.first;
        expect(registered.fullName, 'Dr. Priya Nair');
        expect(registered.learningFormat, 'hybrid');
        expect(
          registered.preferredSlot,
          'Morning Clinical Batch (08:00 - 10:00 IST)',
        );
      },
    );
  });
}
