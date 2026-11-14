import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iiecm_student/features/auth/domain/models/student_profile.dart';
import 'package:iiecm_student/features/auth/presentation/providers/auth_provider.dart';
import 'package:iiecm_student/features/auth/presentation/providers/auth_state.dart';
import 'package:iiecm_student/features/dashboard/domain/models/student_dashboard_data.dart';
import 'package:iiecm_student/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:iiecm_student/features/dashboard/presentation/dashboard_screen.dart';
import 'package:iiecm_student/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:iiecm_student/features/dashboard/presentation/widgets/live_class_detail_dialog.dart';

class MockAuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  MockAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeDashboardRepository implements DashboardRepository {
  final LiveClassItem? session;

  FakeDashboardRepository({this.session});

  @override
  Future<StudentDashboardData> getDashboardData(StudentProfile student) async {
    return StudentDashboardData(
      student: student,
      enrolledCourses: const [
        EnrolledCourseItem(
          courseId: 'c-101',
          title: 'Advanced Trauma Care',
          categoryName: 'Emergency Medicine',
          enrollmentStatus: 'active',
          format: 'hybrid',
          durationWeeks: 8,
        ),
      ],
      totalEnrolledCourses: 1,
      inProgressCourses: 1,
      pendingAssignmentsCount: 0,
      upcomingAssessmentsCount: 0,
      evaluatedResultsCount: 0,
      nextScheduledSession: session,
      lastRefreshed: DateTime.now(),
    );
  }
}

const testStudent = StudentProfile(
  userId: 'user-101',
  studentRecordId: 'rec-101',
  studentId: 'IIECM2026001',
  fullName: 'Dr. Anita Roy',
  email: 'anita.roy@iiecm.org',
  role: 'student',
  accountStatus: 'active',
);

void main() {
  group('LiveClassItem Domain Model Tests', () {
    test('Correctly computes endsAt from scheduledAt and durationMinutes', () {
      final start = DateTime(2026, 11, 20, 10, 0);
      final item = LiveClassItem(
        id: 'lc-1',
        title: 'Trauma Grand Rounds',
        courseId: 'c-101',
        courseName: 'Emergency Medicine',
        instructorName: 'Dr. Suresh Verma',
        scheduledAt: start,
        durationMinutes: 90,
        status: 'upcoming',
        meetingLink: 'https://meet.iiecm.org/trauma-1',
        specialization: 'Emergency Medicine',
      );

      expect(item.endsAt, DateTime(2026, 11, 20, 11, 30));
      expect(item.isLive, isFalse);
    });

    test('Parses JSON with specialization and category_name fallback', () {
      final itemWithSpec = LiveClassItem.fromJson({
        'id': 'lc-2',
        'title': 'Cardiac Resuscitation Sim',
        'course_id': 'c-102',
        'course_name': 'Cardiology Care',
        'instructor_name': 'Dr. K. Patel',
        'scheduled_at': '2026-11-21T14:00:00Z',
        'duration_minutes': 60,
        'status': 'live',
        'specialization': 'Interventional Cardiology',
      });

      expect(itemWithSpec.specialization, 'Interventional Cardiology');
      expect(itemWithSpec.isLive, isTrue);

      final itemWithCategoryFallback = LiveClassItem.fromJson({
        'id': 'lc-3',
        'title': 'Pediatric Triage',
        'course_id': 'c-103',
        'course_name': 'Pediatrics',
        'instructor_name': 'Dr. M. Sen',
        'scheduled_at': '2026-11-22T09:00:00Z',
        'category_name': 'Pediatric Emergency',
      });

      expect(itemWithCategoryFallback.specialization, 'Pediatric Emergency');
      expect(itemWithCategoryFallback.isLive, isFalse);
    });
  });

  group('LiveClassDetailDialog Widget Tests', () {
    testWidgets(
      'Renders all live class details when all fields are populated',
      (tester) async {
        final session = LiveClassItem(
          id: 'lc-1',
          title: 'Emergency Airway & Intubation Masterclass',
          courseId: 'c-101',
          courseName: 'Advanced Trauma Care',
          instructorName: 'Prof. Ramesh Sharma',
          scheduledAt: DateTime(2026, 11, 20, 10, 0),
          durationMinutes: 90,
          status: 'upcoming',
          meetingLink: 'https://meet.iiecm.org/airway-101',
          specialization: 'Critical Care Trauma',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () =>
                      LiveClassDetailDialog.show(context, session: session),
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        );

        // Open dialog
        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Verify header and badge
        expect(find.text('UPCOMING CLINICAL CLASS'), findsOneWidget);
        expect(
          find.text('Emergency Airway & Intubation Masterclass'),
          findsOneWidget,
        );
        expect(find.text('Advanced Trauma Care'), findsWidgets);

        // Verify badges
        expect(find.text('1 hr 30 mins'), findsOneWidget);
        expect(find.text('Critical Care Trauma'), findsWidgets);
        expect(find.text('Academic Session'), findsOneWidget);

        // Verify info rows
        expect(find.text('Scheduled Date'), findsOneWidget);
        expect(find.textContaining('November 2026'), findsOneWidget);
        expect(find.text('Time Window'), findsOneWidget);
        expect(
          find.textContaining('10:00 AM – 11:30 AM (IST)'),
          findsOneWidget,
        );
        expect(find.text('Class Duration'), findsOneWidget);
        expect(find.text('90 Minutes (1 hr 30 mins)'), findsOneWidget);
        expect(find.text('Faculty Consultant'), findsOneWidget);
        expect(find.text('Prof. Ramesh Sharma'), findsOneWidget);
        expect(find.text('Curriculum Course'), findsOneWidget);
        expect(find.text('Specialization Stream'), findsOneWidget);

        // Verify meeting link
        expect(find.text('Teleconference / Live Class Link'), findsOneWidget);
        expect(find.text('https://meet.iiecm.org/airway-101'), findsOneWidget);
        expect(find.text('Open Meeting Link'), findsOneWidget);
        expect(find.text('Close'), findsOneWidget);
      },
    );

    testWidgets('Handles missing optional fields gracefully', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final sessionWithoutOptionals = LiveClassItem(
        id: 'lc-2',
        title: 'Trauma Simulation Ward Round',
        courseId: 'c-102',
        courseName: 'General Clinical Curriculum',
        instructorName: 'Dr. Anita Roy',
        scheduledAt: DateTime(2026, 11, 21, 14, 0),
        durationMinutes: 45,
        status: 'upcoming',
        meetingLink: null,
        specialization: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => LiveClassDetailDialog.show(
                  context,
                  session: sessionWithoutOptionals,
                ),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Basic details render
      expect(find.text('Trauma Simulation Ward Round'), findsOneWidget);
      expect(find.text('45 mins'), findsOneWidget);

      // Specialization stream row should NOT be rendered
      expect(find.text('Specialization Stream'), findsNothing);

      // Pending meeting link notice should be rendered
      expect(find.text('Teleconference Access Link Pending'), findsOneWidget);
      expect(find.text('Open Meeting Link'), findsNothing);
      expect(find.text('Close'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Trauma Simulation Ward Round'), findsNothing);
    });

    testWidgets('Renders LIVE SESSION NOW badge when isLive is true', (
      tester,
    ) async {
      final liveSession = LiveClassItem(
        id: 'lc-3',
        title: 'Live Cardiac Arrest Protocol',
        courseId: 'c-103',
        courseName: 'Resuscitation Protocols',
        instructorName: 'Dr. Ramesh Kumar',
        scheduledAt: DateTime.now(),
        durationMinutes: 60,
        status: 'live',
        meetingLink: 'https://meet.iiecm.org/live-cardiac',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () =>
                    LiveClassDetailDialog.show(context, session: liveSession),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('LIVE SESSION NOW'), findsOneWidget);
      expect(find.text('Live Cardiac Arrest Protocol'), findsOneWidget);
    });

    testWidgets(
      'Copies meeting link to clipboard and presents SnackBar on action tap',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final session = LiveClassItem(
          id: 'lc-4',
          title: 'Toxicology Case Conference',
          courseId: 'c-104',
          courseName: 'Medical Toxicology',
          instructorName: 'Dr. Sen',
          scheduledAt: DateTime(2026, 11, 22, 11, 0),
          durationMinutes: 60,
          meetingLink: 'https://meet.iiecm.org/tox-conf',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () =>
                      LiveClassDetailDialog.show(context, session: session),
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Tap Open Meeting Link button
        await tester.tap(find.text('Open Meeting Link'));
        await tester.pump();

        // SnackBar should be displayed
        expect(
          find.text(
            'Meeting link copied to clipboard. Open in your browser or conferencing app.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'DashboardScreen opens LiveClassDetailDialog when upcoming class card is tapped',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final session = LiveClassItem(
          id: 'lc-10',
          title: 'Emergency Ultrasound Grand Rounds',
          courseId: 'c-101',
          courseName: 'Advanced Trauma Care',
          instructorName: 'Prof. Suresh Verma',
          scheduledAt: DateTime(2026, 11, 25, 10, 0),
          durationMinutes: 60,
          meetingLink: 'https://meet.iiecm.org/us-10',
          specialization: 'Emergency Ultrasound',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authNotifierProvider.overrideWith(
                (ref) => MockAuthNotifier(
                  const AuthState.authenticated(testStudent),
                ),
              ),
              dashboardRepositoryProvider.overrideWithValue(
                FakeDashboardRepository(session: session),
              ),
            ],
            child: const MaterialApp(home: DashboardScreen()),
          ),
        );

        await tester.pumpAndSettle();

        // Verify upcoming class card is rendered on dashboard
        expect(find.text('Emergency Ultrasound Grand Rounds'), findsOneWidget);
        expect(find.textContaining('Prof. Suresh Verma'), findsOneWidget);

        // Tap the class card
        await tester.tap(find.text('Emergency Ultrasound Grand Rounds'));
        await tester.pumpAndSettle();

        // Verify LiveClassDetailDialog opened
        expect(find.byType(LiveClassDetailDialog), findsOneWidget);
        expect(find.text('Teleconference / Live Class Link'), findsOneWidget);
        expect(find.text('https://meet.iiecm.org/us-10'), findsOneWidget);
        expect(find.text('Emergency Ultrasound'), findsWidgets);

        // Close dialog
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
        expect(find.byType(LiveClassDetailDialog), findsNothing);
      },
    );
  });
}
