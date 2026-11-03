import 'package:flutter_test/flutter_test.dart';
import 'package:iiecm_admin/features/classes/domain/models/live_class.dart';

void main() {
  group('LiveClass Domain Model & Conflict Detection Tests', () {
    test('Constructs LiveClass correctly from JSON map', () {
      final json = {
        'id': 'cls-1',
        'title': 'Emergency Cardiology Lecture',
        'course_id': 'c-100',
        'course_name': 'Emergency Medicine',
        'instructor_id': 'i-200',
        'instructor_name': 'Dr. Sharma',
        'scheduled_at': '2026-11-05T14:00:00Z',
        'duration_minutes': 90,
        'status': 'upcoming',
        'meeting_link': 'https://meet.google.com/abc-def-ghi',
        'created_at': '2026-11-01T10:00:00Z',
      };

      final liveClass = LiveClass.fromJson(json);

      expect(liveClass.id, equals('cls-1'));
      expect(liveClass.title, equals('Emergency Cardiology Lecture'));
      expect(liveClass.durationMinutes, equals(90));
      expect(liveClass.isUpcoming, isTrue);
      expect(
        liveClass.meetingLink,
        equals('https://meet.google.com/abc-def-ghi'),
      );
      expect(
        liveClass.endTime,
        equals(
          DateTime.parse('2026-11-05T14:00:00Z')
              .add(const Duration(minutes: 90)),
        ),
      );
    });

    test('Accurately detects overlapping time intervals for conflicts', () {
      final baseClass = LiveClass(
        id: 'cls-base',
        title: 'Trauma Resuscitation',
        courseId: 'c-1',
        courseName: 'Trauma Course',
        instructorId: 'inst-1',
        instructorName: 'Dr. John',
        scheduledAt: DateTime(2026, 11, 10, 10, 0), // 10:00 - 11:30 (90 mins)
        durationMinutes: 90,
        createdAt: DateTime.now(),
      );

      // Overlap case 1: starts inside base class (10:30 - 11:30)
      expect(
        baseClass.overlapsWith(DateTime(2026, 11, 10, 10, 30), 60),
        isTrue,
      );

      // Overlap case 2: starts before base class and ends inside (09:30 - 10:30)
      expect(baseClass.overlapsWith(DateTime(2026, 11, 10, 9, 30), 60), isTrue);

      // Overlap case 3: completely wraps base class (09:00 - 12:00)
      expect(baseClass.overlapsWith(DateTime(2026, 11, 10, 9, 0), 180), isTrue);

      // Non-overlap case 1: finishes right before base starts (09:00 - 10:00)
      expect(baseClass.overlapsWith(DateTime(2026, 11, 10, 9, 0), 60), isFalse);

      // Non-overlap case 2: starts after base finishes (11:30 - 12:30)
      expect(
        baseClass.overlapsWith(DateTime(2026, 11, 10, 11, 30), 60),
        isFalse,
      );

      // Cancelled classes never trigger conflicts
      final cancelledClass = baseClass.copyWith(status: 'cancelled');
      expect(
        cancelledClass.overlapsWith(DateTime(2026, 11, 10, 10, 30), 60),
        isFalse,
      );
    });
  });
}
