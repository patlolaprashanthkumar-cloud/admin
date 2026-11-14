import 'package:flutter_test/flutter_test.dart';
import 'package:iiecm_student/features/assignments/domain/models/student_assignment.dart';
import 'package:iiecm_student/features/assignments/presentation/providers/assignments_state.dart';

void main() {
  group('StudentAssignment Model Tests', () {
    test('parses active pending assignment correctly', () {
      final json = {
        'id': 'ass-1',
        'title': 'Emergency Triage & Airway Synthesis',
        'description': 'Submit clinical protocol write-up for trauma resuscitation.',
        'type': 'assignment',
        'total_marks': 100,
        'passing_marks': 50,
        'duration_minutes': 1440,
        'status': 'active',
        'scheduled_at': '2026-12-31T23:59:59Z',
        'created_at': '2026-01-01T00:00:00Z',
      };

      final assignment = StudentAssignment.fromData(
        assessmentJson: json,
        courseTitle: 'Fellowship in Emergency Medicine',
      );

      expect(assignment.id, 'ass-1');
      expect(assignment.title, 'Emergency Triage & Airway Synthesis');
      expect(assignment.totalMarks, 100);
      expect(assignment.passingMarks, 50);
      expect(assignment.isSubmitted, isFalse);
      expect(assignment.isGraded, isFalse);
      expect(assignment.isOverdue, isFalse);
      expect(assignment.displayStatus, 'PENDING');
    });

    test('parses evaluated assignment with feedback and score', () {
      final assessmentJson = {
        'id': 'ass-2',
        'title': 'Trauma Resuscitation Case Analysis',
        'type': 'project',
        'total_marks': 50,
        'passing_marks': 25,
        'status': 'active',
        'created_at': '2026-01-01T00:00:00Z',
      };

      final submissionJson = {
        'id': 'sub-1',
        'score': 42.5,
        'percentage': 85.0,
        'passed': true,
        'completed_at': '2026-02-10T14:30:00Z',
        'answers': {
          'feedback': 'Excellent clinical rationale provided for needle decompression.',
          'submission_text': 'Case analysis summary and diagnostic rationale...',
        },
      };

      final assignment = StudentAssignment.fromData(
        assessmentJson: assessmentJson,
        submissionJson: submissionJson,
      );

      expect(assignment.isSubmitted, isTrue);
      expect(assignment.isGraded, isTrue);
      expect(assignment.isPassed, isTrue);
      expect(assignment.score, 42.5);
      expect(assignment.percentage, 85.0);
      expect(assignment.displayStatus, 'PASSED');
      expect(assignment.feedback, contains('needle decompression'));
      expect(assignment.isProject, isTrue);
    });

    test('correctly identifies graded assignment when score is 0 but instructor provided feedback', () {
      final assessmentJson = {
        'id': 'ass-zero',
        'title': 'Clinical Resuscitation Protocol',
        'type': 'assignment',
        'total_marks': 100,
        'passing_marks': 50,
      };

      final submissionJson = {
        'id': 'sub-zero',
        'score': 0.0,
        'percentage': 0.0,
        'passed': false,
        'completed_at': '2026-03-01T10:00:00Z',
        'answers': {
          'feedback': 'Protocol failed safety check. Please revise and resubmit.',
          'submission_text': 'Draft attempt...',
        },
      };

      final assignment = StudentAssignment.fromData(
        assessmentJson: assessmentJson,
        submissionJson: submissionJson,
      );

      expect(assignment.isSubmitted, isTrue);
      expect(assignment.isGraded, isTrue);
      expect(assignment.isPassed, isFalse);
      expect(assignment.displayStatus, 'NEEDS REVISION');
      expect(assignment.feedback, contains('Protocol failed safety check'));
    });

    test('correctly detects overdue assignment when past deadline and not submitted', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 3));
      final json = {
        'id': 'ass-3',
        'title': 'Overdue Case Log',
        'scheduled_at': pastDate.toIso8601String(),
        'created_at': '2026-01-01T00:00:00Z',
      };

      final assignment = StudentAssignment.fromData(assessmentJson: json);

      expect(assignment.isSubmitted, isFalse);
      expect(assignment.isOverdue, isTrue);
      expect(assignment.displayStatus, 'OVERDUE');
    });
  });

  group('AssignmentsListState Filtering Tests', () {
    final assignments = [
      StudentAssignment(
        id: '1',
        title: 'Pending Case Study',
        courseTitle: 'Trauma Care',
        createdAt: DateTime.now(),
        deadline: DateTime.now().add(const Duration(days: 5)),
      ),
      StudentAssignment(
        id: '2',
        title: 'Submitted Project Report',
        courseTitle: 'Critical Care',
        createdAt: DateTime.now(),
        isSubmitted: true,
        isGraded: false,
      ),
      StudentAssignment(
        id: '3',
        title: 'Evaluated ECG Analysis',
        courseTitle: 'Cardiology',
        createdAt: DateTime.now(),
        isSubmitted: true,
        isGraded: true,
        isPassed: true,
        score: 90.0,
      ),
      StudentAssignment(
        id: '4',
        title: 'Overdue Protocol Assignment',
        courseTitle: 'Emergency Protocols',
        createdAt: DateTime.now(),
        deadline: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];

    test('calculates filter counts accurately', () {
      final state = AssignmentsListState(assignments: assignments);

      expect(state.pendingCount, 1);
      expect(state.submittedCount, 1);
      expect(state.evaluatedCount, 1);
      expect(state.overdueCount, 1);
    });

    test('filters by status: pending', () {
      final state = AssignmentsListState(
        assignments: assignments,
        activeFilter: AssignmentFilter.pending,
      );

      expect(state.filteredAssignments.length, 1);
      expect(state.filteredAssignments.first.id, '1');
    });

    test('filters by status: evaluated', () {
      final state = AssignmentsListState(
        assignments: assignments,
        activeFilter: AssignmentFilter.evaluated,
      );

      expect(state.filteredAssignments.length, 1);
      expect(state.filteredAssignments.first.id, '3');
    });

    test('filters by search query matching title or course', () {
      final state = AssignmentsListState(
        assignments: assignments,
        searchQuery: 'cardiology',
      );

      expect(state.filteredAssignments.length, 1);
      expect(state.filteredAssignments.first.id, '3');
    });
  });
}

