import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iiecm_student/features/auth/domain/models/student_profile.dart';
import 'package:iiecm_student/features/auth/presentation/providers/auth_provider.dart';
import 'package:iiecm_student/features/auth/presentation/providers/auth_state.dart';
import 'package:iiecm_student/features/notifications/domain/models/student_notification.dart';
import 'package:iiecm_student/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:iiecm_student/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:iiecm_student/features/notifications/presentation/providers/notifications_state.dart';
import 'package:iiecm_student/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:iiecm_student/features/notifications/presentation/widgets/notification_card.dart';

class FakeNotificationsRepository implements NotificationsRepository {
  List<StudentNotification> items = [];
  bool shouldThrow = false;
  final List<String> markedReadIds = [];
  bool allMarkedRead = false;

  @override
  Future<List<StudentNotification>> getStudentNotifications({
    required String userId,
  }) async {
    if (shouldThrow) {
      throw Exception('Simulated network error');
    }
    return List.from(items);
  }

  @override
  Future<void> markAsRead({
    required String notificationId,
    required String userId,
  }) async {
    markedReadIds.add(notificationId);
  }

  @override
  Future<void> markAllAsRead({required String userId}) async {
    allMarkedRead = true;
  }
}

final sampleNotifications = [
  StudentNotification(
    id: 'notif-1',
    userId: 'user-123',
    title: 'Urgent: Trauma Protocol Workshop',
    message: 'Your practical live session has been scheduled for tomorrow at 10:00 AM.',
    type: NotificationType.liveClass,
    priority: NotificationPriority.high,
    read: false,
    actionUrl: '/courses/c-1',
    createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
  ),
  StudentNotification(
    id: 'notif-2',
    userId: 'user-123',
    title: 'Tuition Receipt Generated',
    message: 'Payment of ₹15,000 for Emergency Ultrasound Module confirmed.',
    type: NotificationType.payment,
    priority: NotificationPriority.medium,
    read: true,
    actionUrl: '/payments',
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  StudentNotification(
    id: 'notif-3',
    userId: null, // Broadcast
    title: 'Institutional Notice: Campus Maintenance',
    message: 'The online simulation lab will undergo server maintenance on Sunday.',
    type: NotificationType.system,
    priority: NotificationPriority.low,
    read: false,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
];

const mockStudent = StudentProfile(
  userId: 'user-123',
  studentRecordId: 'rec-456',
  studentId: 'IIECM-2026-STU-001',
  fullName: 'Dr. Anita Roy',
  email: 'anita.roy@iiecm.org',
  role: 'student',
  accountStatus: 'active',
);

void main() {
  group('StudentNotification Model Tests', () {
    test('Parses database notification record correctly', () {
      final map = {
        'id': 'notif-uuid-1',
        'user_id': 'user-123',
        'title': 'New Assignment Available',
        'message': 'Advanced Triage Assignment is now active.',
        'type': 'course',
        'priority': 'high',
        'read': false,
        'action_url': '/assignments/a-1',
        'created_at': '2026-11-13T10:00:00Z',
      };

      final notif = StudentNotification.fromMap(map);

      expect(notif.id, 'notif-uuid-1');
      expect(notif.userId, 'user-123');
      expect(notif.isBroadcast, isFalse);
      expect(notif.title, 'New Assignment Available');
      expect(notif.type, NotificationType.course);
      expect(notif.priority, NotificationPriority.high);
      expect(notif.read, isFalse);
      expect(notif.actionUrl, '/assignments/a-1');
    });

    test('Correctly identifies broadcast notification when user_id is null', () {
      final map = {
        'id': 'broadcast-1',
        'user_id': null,
        'title': 'Registry Announcement',
        'message': 'All students must verify their clinical logbooks.',
        'type': 'system',
        'priority': 'low',
        'read': false,
        'created_at': '2026-11-13T10:00:00Z',
      };

      final notif = StudentNotification.fromMap(map);
      expect(notif.isBroadcast, isTrue);
      expect(notif.userId, isNull);
      expect(notif.type, NotificationType.system);
    });
  });

  group('NotificationsState Unit Tests', () {
    test('Calculates unreadCount accurately considering localReadIds', () {
      final state = NotificationsState(
        notifications: sampleNotifications,
        localReadIds: {},
      );

      // notif-1 is unread (read: false), notif-2 is read (read: true), notif-3 is unread (read: false)
      expect(state.unreadCount, 2);

      // Locally mark notif-3 as read
      final state2 = state.copyWith(localReadIds: {'notif-3'});
      expect(state2.unreadCount, 1);
    });

    test('Filters notifications by category tabs', () {
      final state = NotificationsState(
        notifications: sampleNotifications,
      );

      // All
      expect(state.filteredNotifications.length, 3);

      // Unread
      final unreadState = state.copyWith(selectedCategory: NotificationCategory.unread);
      expect(unreadState.filteredNotifications.length, 2);

      // Academic (course + class)
      final academicState = state.copyWith(selectedCategory: NotificationCategory.academic);
      expect(academicState.filteredNotifications.length, 1);
      expect(academicState.filteredNotifications.first.id, 'notif-1');

      // Payments
      final paymentsState = state.copyWith(selectedCategory: NotificationCategory.payments);
      expect(paymentsState.filteredNotifications.length, 1);
      expect(paymentsState.filteredNotifications.first.id, 'notif-2');

      // System / Institutional
      final systemState = state.copyWith(selectedCategory: NotificationCategory.system);
      expect(systemState.filteredNotifications.length, 1);
      expect(systemState.filteredNotifications.first.id, 'notif-3');
    });
  });

  group('Notification Widgets Tests', () {
    testWidgets('NotificationCard renders details, badges, and read status', (tester) async {
      bool markedRead = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationCard(
              notification: sampleNotifications[0],
              isRead: false,
              onMarkAsRead: () {
                markedRead = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Urgent: Trauma Protocol Workshop'), findsOneWidget);
      expect(find.textContaining('Your practical live session has been scheduled'), findsOneWidget);
      expect(find.text('Class Schedule'), findsOneWidget);
      expect(find.text('URGENT'), findsOneWidget);
      expect(find.text('Mark Read'), findsOneWidget);
      expect(find.text('Open Link'), findsOneWidget);

      await tester.tap(find.text('Mark Read'));
      await tester.pumpAndSettle();
      expect(markedRead, isTrue);
    });

    testWidgets('NotificationsScreen displays unread count, list, and filter chips', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fakeRepo = FakeNotificationsRepository()..items = sampleNotifications;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(
              (ref) => AuthNotifier(ref.watch(authRepositoryProvider))
                ..state = const AuthState.authenticated(mockStudent),
            ),
            notificationsRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: NotificationsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bulletins & Notifications'), findsOneWidget);
      expect(find.textContaining('unread institutional alert'), findsOneWidget);
      expect(find.text('Mark All Read'), findsOneWidget);

      // Verify category chips
      expect(find.text('All (3)'), findsOneWidget);
      expect(find.text('Unread (2)'), findsOneWidget);
      expect(find.text('Curriculum & Classes'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Fee & Receipts'), findsOneWidget);
      expect(find.text('Institutional Alerts'), findsOneWidget);

      // Verify notification items rendered
      expect(find.text('Urgent: Trauma Protocol Workshop'), findsOneWidget);
      expect(find.text('Tuition Receipt Generated'), findsOneWidget);
      expect(find.text('Institutional Notice: Campus Maintenance'), findsOneWidget);

      // Tap 'Unread (2)' filter
      await tester.tap(find.text('Unread (2)'));
      await tester.pumpAndSettle();

      expect(find.text('Urgent: Trauma Protocol Workshop'), findsOneWidget);
      expect(find.text('Institutional Notice: Campus Maintenance'), findsOneWidget);
      expect(find.text('Tuition Receipt Generated'), findsNothing);

      // Tap 'Mark All Read'
      await tester.tap(find.text('Mark All Read'));
      await tester.pumpAndSettle();

      expect(fakeRepo.allMarkedRead, isTrue);
    });

    testWidgets('NotificationsScreen displays empty view when no notifications', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fakeRepo = FakeNotificationsRepository()..items = [];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(
              (ref) => AuthNotifier(ref.watch(authRepositoryProvider))
                ..state = const AuthState.authenticated(mockStudent),
            ),
            notificationsRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: NotificationsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Bulletins Found'), findsOneWidget);
      expect(find.textContaining('There are currently no institutional bulletins'), findsOneWidget);
    });
  });
}
