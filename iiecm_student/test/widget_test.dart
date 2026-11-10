import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iiecm_student/app/app.dart';

void main() {
  testWidgets('IIECM Student App smoke test and shell navigation', (WidgetTester tester) async {
    // Set a phone screen size for tests
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    // Build the application inside ProviderScope
    await tester.pumpWidget(
      const ProviderScope(
        child: IIECMStudentApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Dashboard screen renders
    expect(find.text('IIECM Student Portal'), findsOneWidget);
    expect(find.text('Welcome back, Student'), findsOneWidget);

    // Locate NavigationBar
    final navBarFinder = find.byType(NavigationBar);
    expect(navBarFinder, findsOneWidget);

    // Verify Bottom Navigation items exist within NavigationBar
    expect(
      find.descendant(of: navBarFinder, matching: find.text('Home')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: navBarFinder, matching: find.text('My Courses')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: navBarFinder, matching: find.text('Assessments')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: navBarFinder, matching: find.text('Profile')),
      findsOneWidget,
    );

    // Tap 'My Courses' navigation destination inside NavigationBar
    await tester.tap(
      find.descendant(of: navBarFinder, matching: find.text('My Courses')),
    );
    await tester.pumpAndSettle();

    // Verify Courses placeholder screen appears
    expect(find.text('Course Curriculum • Phase 2'), findsOneWidget);
  });
}
