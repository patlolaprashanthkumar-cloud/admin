import 'package:flutter_test/flutter_test.dart';
import 'package:iiecm_student/features/auth/domain/models/student_profile.dart';
import 'package:iiecm_student/features/dashboard/domain/models/student_dashboard_data.dart';

void main() {
  group('StudentDashboardData Domain Tests', () {
    const testStudent = StudentProfile(
      userId: 'test-user-id',
      studentRecordId: 'test-student-rec',
      studentId: 'IIECM2026001',
      fullName: 'Dr. Anita Roy',
      email: 'anita.roy@iiecm.org',
      role: 'student',
      accountStatus: 'active',
    );

    test('Correctly identifies primary course and enrollment presence', () {
      final course = EnrolledCourseItem.fromData(
        courseMap: {
          'id': 'c-101',
          'title': 'Advanced Cardiac Life Support',
          'category_name': 'Cardiology',
          'format': 'hybrid',
          'duration_weeks': 8,
        },
        enrollmentMap: {
          'status': 'active',
          'enrolled_at': '2026-11-01T00:00:00Z',
        },
        instructorName: 'Dr. Suresh Verma',
      );

      final data = StudentDashboardData(
        student: testStudent,
        enrolledCourses: [course],
        totalEnrolledCourses: 1,
        inProgressCourses: 1,
        pendingAssignmentsCount: 2,
        upcomingAssessmentsCount: 1,
        evaluatedResultsCount: 3,
        averageGrade: 'Grade: A',
        lastRefreshed: DateTime.now(),
      );

      expect(data.hasEnrollments, isTrue);
      expect(data.primaryCourse, isNotNull);
      expect(data.primaryCourse!.title, 'Advanced Cardiac Life Support');
      expect(data.primaryCourse!.categoryName, 'Cardiology');
      expect(data.primaryCourse!.instructorName, 'Dr. Suresh Verma');
      expect(data.primaryCourse!.enrollmentStatus, 'active');
      expect(data.totalEnrolledCourses, 1);
      expect(data.pendingAssignmentsCount, 2);
      expect(data.upcomingAssessmentsCount, 1);
      expect(data.evaluatedResultsCount, 3);
      expect(data.averageGrade, 'Grade: A');
    });

    test('Handles zero enrollments cleanly with empty primaryCourse', () {
      final data = StudentDashboardData(
        student: testStudent,
        enrolledCourses: const [],
        totalEnrolledCourses: 0,
        inProgressCourses: 0,
        pendingAssignmentsCount: 0,
        upcomingAssessmentsCount: 0,
        evaluatedResultsCount: 0,
        lastRefreshed: DateTime.now(),
      );

      expect(data.hasEnrollments, isFalse);
      expect(data.primaryCourse, isNull);
    });

    test('LiveClassItem correctly parses scheduled live classes', () {
      final liveClass = LiveClassItem.fromJson({
        'id': 'lc-201',
        'title': 'Emergency Toxicology Grand Rounds',
        'course_id': 'c-101',
        'course_name': 'Emergency Medicine',
        'instructor_name': 'Prof. M. K. Rao',
        'scheduled_at': '2026-11-18T10:00:00Z',
        'duration_minutes': 90,
        'status': 'upcoming',
        'meeting_link': 'https://meet.iiecm.org/tox-201',
      });

      expect(liveClass.id, 'lc-201');
      expect(liveClass.title, 'Emergency Toxicology Grand Rounds');
      expect(liveClass.courseName, 'Emergency Medicine');
      expect(liveClass.instructorName, 'Prof. M. K. Rao');
      expect(liveClass.durationMinutes, 90);
      expect(liveClass.isLive, isFalse);
      expect(liveClass.meetingLink, 'https://meet.iiecm.org/tox-201');
    });
  });
}

