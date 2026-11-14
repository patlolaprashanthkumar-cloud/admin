import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iiecm_student/features/results/domain/models/student_result.dart';
import 'package:iiecm_student/features/results/presentation/providers/results_state.dart';
import 'package:iiecm_student/features/results/presentation/widgets/result_card.dart';
import 'package:iiecm_student/features/results/presentation/widgets/result_filter_chips.dart';

void main() {
  group('StudentResult Model Tests', () {
    test('Parses MCQ assessment result correctly', () {
      final result = StudentResult.fromData(
        resultJson: {
          'id': 'res-101',
          'assessment_id': 'ass-1',
          'assessment_title': 'Basic Life Support Exam',
          'score': 85.0,
          'total_marks': 100.0,
          'percentage': 85.0,
          'passed': true,
          'completed_at': '2026-11-10T10:30:00Z',
          'answers': {'q1': 'opt_a', 'q2': 'opt_b'},
        },
        assessmentJson: {
          'type': 'mcq',
          'passing_marks': 50,
          'title': 'Basic Life Support Exam',
        },
        courseTitle: 'Emergency Medicine',
        courseId: 'c-1',
      );

      expect(result.id, 'res-101');
      expect(result.assessmentId, 'ass-1');
      expect(result.type, ResultType.mcq);
      expect(result.isAssessment, isTrue);
      expect(result.isAssignment, isFalse);
      expect(result.score, 85.0);
      expect(result.totalMarks, 100.0);
      expect(result.percentage, 85.0);
      expect(result.passed, isTrue);
      expect(result.displayStatus, 'PASSED');
      expect(result.formattedPercentage, '85.0%');
      expect(result.formattedScore, '85 / 100');
      expect(result.answeredQuestionsCount, 2);
    });

    test('Parses Assignment submission result with feedback and notes', () {
      final result = StudentResult.fromData(
        resultJson: {
          'id': 'res-202',
          'assessment_id': 'ass-2',
          'score': 90.0,
          'total_marks': 100.0,
          'percentage': 90.0,
          'passed': true,
          'completed_at': '2026-11-12T14:00:00Z',
          'answers': {
            'submission_text': 'Case study analysis on myocardial infarction.',
            'feedback': 'Excellent clinical rationale provided.',
          },
        },
        assessmentJson: {
          'type': 'assignment',
          'passing_marks': 60,
          'title': 'Clinical Case Presentation',
        },
        courseTitle: 'Acute Cardiac Care',
      );

      expect(result.id, 'res-202');
      expect(result.type, ResultType.assignment);
      expect(result.isAssignment, isTrue);
      expect(result.feedback, 'Excellent clinical rationale provided.');
      expect(result.submissionNotes, 'Case study analysis on myocardial infarction.');
      expect(result.isEvaluated, isTrue);
      expect(result.passed, isTrue);
      expect(result.displayStatus, 'PASSED');
    });

    test('Identifies pending evaluation for ungraded assignment', () {
      final result = StudentResult.fromData(
        resultJson: {
          'id': 'res-303',
          'assessment_id': 'ass-3',
          'score': 0.0,
          'total_marks': 100.0,
          'percentage': 0.0,
          'passed': false,
          'completed_at': '2026-11-13T09:00:00Z',
          'answers': {
            'submission_text': 'Draft protocol submitted for review.',
          },
        },
        assessmentJson: {
          'type': 'project',
          'passing_marks': 50,
          'title': 'Disaster Management Protocol',
        },
      );

      expect(result.isEvaluated, isFalse);
      expect(result.displayStatus, 'PENDING EVALUATION');
    });
  });

  group('ResultsState Filtering Tests', () {
    final res1 = StudentResult(
      id: '1',
      assessmentId: 'a1',
      title: 'Airway MCQ Exam',
      type: ResultType.mcq,
      courseTitle: 'Emergency Care',
      score: 80,
      totalMarks: 100,
      percentage: 80,
      passed: true,
      completedAt: DateTime.now(),
    );

    final res2 = StudentResult(
      id: '2',
      assessmentId: 'a2',
      title: 'Pediatric Life Support Quiz',
      type: ResultType.quiz,
      courseTitle: 'Pediatric Care',
      score: 35,
      totalMarks: 100,
      percentage: 35,
      passed: false,
      completedAt: DateTime.now(),
    );

    final res3 = StudentResult(
      id: '3',
      assessmentId: 'a3',
      title: 'Trauma Life Support Case Assignment',
      type: ResultType.assignment,
      courseTitle: 'Trauma Care',
      score: 90,
      totalMarks: 100,
      percentage: 90,
      passed: true,
      completedAt: DateTime.now(),
    );

    final state = ResultsState(
      status: ResultsStatus.loaded,
      results: [res1, res2, res3],
    );

    test('Filters by assessments', () {
      final filtered = state.copyWith(filter: ResultFilterType.assessments).filteredResults;
      expect(filtered.length, 2);
      expect(filtered.every((r) => r.isAssessment), isTrue);
    });

    test('Filters by assignments', () {
      final filtered = state.copyWith(filter: ResultFilterType.assignments).filteredResults;
      expect(filtered.length, 1);
      expect(filtered.first.id, '3');
    });

    test('Filters by passed status', () {
      final filtered = state.copyWith(filter: ResultFilterType.passed).filteredResults;
      expect(filtered.length, 2);
      expect(filtered.every((r) => r.passed), isTrue);
    });

    test('Filters by failed status', () {
      final filtered = state.copyWith(filter: ResultFilterType.failed).filteredResults;
      expect(filtered.length, 1);
      expect(filtered.first.id, '2');
    });

    test('Filters by search query', () {
      final filtered = state.copyWith(searchQuery: 'Trauma').filteredResults;
      expect(filtered.length, 1);
      expect(filtered.first.title, contains('Trauma'));
    });

    test('Calculates aggregate metrics', () {
      expect(state.totalCount, 3);
      expect(state.passedCount, 2);
      expect(state.failedCount, 1);
      expect(state.averagePercentage, closeTo((80 + 35 + 90) / 3, 0.01));
    });
  });

  group('Result Widgets Tests', () {
    testWidgets('ResultCard renders title, course, score and status badge', (tester) async {
      final result = StudentResult(
        id: 'r1',
        assessmentId: 'a1',
        title: 'Toxicology Final Checkpoint',
        type: ResultType.mcq,
        courseTitle: 'Clinical Toxicology',
        score: 78.5,
        totalMarks: 100.0,
        percentage: 78.5,
        passed: true,
        completedAt: DateTime(2026, 11, 10),
      );

      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResultCard(
              result: result,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Toxicology Final Checkpoint'), findsOneWidget);
      expect(find.text('Clinical Toxicology'), findsOneWidget);
      expect(find.text('78.5%'), findsOneWidget);
      expect(find.text('PASSED'), findsOneWidget);

      await tester.tap(find.byType(ResultCard));
      expect(tapped, isTrue);
    });

    testWidgets('ResultFilterChips renders all filter options', (tester) async {
      ResultFilterType selected = ResultFilterType.all;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResultFilterChips(
              selectedFilter: selected,
              onFilterSelected: (f) => selected = f,
            ),
          ),
        ),
      );

      expect(find.text('All Results'), findsOneWidget);
      expect(find.text('Assessments'), findsOneWidget);
      expect(find.text('Assignments'), findsOneWidget);
      expect(find.text('Passed'), findsOneWidget);
      expect(find.text('Needs Revision'), findsOneWidget);

      await tester.tap(find.text('Assessments'));
      expect(selected, ResultFilterType.assessments);
    });
  });
}

