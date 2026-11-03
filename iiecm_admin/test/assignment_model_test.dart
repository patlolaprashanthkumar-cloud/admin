import 'package:flutter_test/flutter_test.dart';
import 'package:iiecm_admin/features/assignments/domain/models/assignment.dart';
import 'package:iiecm_admin/features/assignments/domain/models/assignment_submission.dart';

void main() {
  group('Assignment Domain Model & Grading Tests', () {
    test('Constructs Assignment correctly from JSON map', () {
      final json = {
        'id': 'ass-1',
        'title': 'Clinical Resuscitation Protocol',
        'description': 'Submit full audit of cardiac resuscitation...',
        'type': 'assignment',
        'total_marks': 100,
        'passing_marks': 50,
        'duration_minutes': 2880,
        'status': 'active',
        'scheduled_at': '2026-11-20T23:59:59Z',
        'created_by': 'admin',
        'created_at': '2026-11-01T10:00:00Z',
      };

      const course = AssignmentCourseRef(
        id: 'c1',
        title: 'Critical Care Fellowship',
      );

      final assignment = Assignment.fromJson(
        json,
        assignedCourses: [course],
        totalSubmissions: 5,
        gradedSubmissions: 3,
      );

      expect(assignment.id, equals('ass-1'));
      expect(assignment.title, equals('Clinical Resuscitation Protocol'));
      expect(assignment.totalMarks, equals(100));
      expect(assignment.passingMarks, equals(50));
      expect(assignment.isActive, isTrue);
      expect(assignment.assignedCourses.length, equals(1));
      expect(assignment.totalSubmissions, equals(5));
      expect(assignment.gradedSubmissions, equals(3));
    });

    test('AssignmentSubmission deserialization and grading calculations', () {
      final subJson = {
        'id': 'sub-1',
        'assessment_id': 'ass-1',
        'assessment_title': 'Clinical Resuscitation Protocol',
        'student_id': 'stud-1',
        'student_name': 'Dr. Robert Langdon',
        'score': 85.0,
        'total_marks': 100.0,
        'percentage': 85.0,
        'passed': true,
        'completed_at': '2026-11-02T12:00:00Z',
        'answers': {'feedback': 'Excellent clinical rationale'},
      };

      final sub = AssignmentSubmission.fromJson(subJson);
      expect(sub.isGraded, isTrue);
      expect(sub.passed, isTrue);
      expect(sub.score, equals(85.0));
      expect(sub.feedback, equals('Excellent clinical rationale'));

      final payload = sub.toGradingPayload();
      expect(payload['score'], equals(85.0));
      expect(payload['passed'], isTrue);
      expect(
        (payload['answers'] as Map)['feedback'],
        equals('Excellent clinical rationale'),
      );
    });
  });
}
