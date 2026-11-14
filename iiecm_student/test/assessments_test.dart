import 'package:flutter_test/flutter_test.dart';
import 'package:iiecm_student/features/assessments/domain/models/assessment_question.dart';
import 'package:iiecm_student/features/assessments/domain/models/student_assessment.dart';
import 'package:iiecm_student/features/assessments/presentation/providers/assessments_state.dart';

void main() {
  group('StudentAssessment Model Tests', () {
    test('parses available active assessment correctly', () {
      final json = {
        'id': 'exam-1',
        'title': 'Advanced Airway Clinical MCQ Examination',
        'description': 'Online MCQ checkpoint for endotracheal and surgical airway.',
        'type': 'mcq',
        'total_marks': 50,
        'passing_marks': 25,
        'duration_minutes': 45,
        'status': 'active',
        'scheduled_at': '2026-01-01T10:00:00Z',
        'created_at': '2026-01-01T00:00:00Z',
      };

      final assessment = StudentAssessment.fromData(
        assessmentJson: json,
        courseTitle: 'Fellowship in Emergency Medicine',
        questionCount: 25,
      );

      expect(assessment.id, 'exam-1');
      expect(assessment.title, 'Advanced Airway Clinical MCQ Examination');
      expect(assessment.isMcq, isTrue);
      expect(assessment.questionCount, 25);
      expect(assessment.isCompleted, isFalse);
      expect(assessment.isAvailable, isTrue);
      expect(assessment.isUpcoming, isFalse);
      expect(assessment.displayStatus, 'AVAILABLE');
    });

    test('parses completed assessment with evaluated score', () {
      final assessmentJson = {
        'id': 'exam-2',
        'title': 'Cardiopulmonary Resuscitation Checkpoint Quiz',
        'type': 'quiz',
        'total_marks': 20,
        'passing_marks': 10,
        'status': 'active',
        'created_at': '2026-01-01T00:00:00Z',
      };

      final resultJson = {
        'id': 'res-1',
        'score': 18.0,
        'percentage': 90.0,
        'passed': true,
        'completed_at': '2026-02-15T11:00:00Z',
      };

      final assessment = StudentAssessment.fromData(
        assessmentJson: assessmentJson,
        resultJson: resultJson,
      );

      expect(assessment.isCompleted, isTrue);
      expect(assessment.isPassed, isTrue);
      expect(assessment.score, 18.0);
      expect(assessment.percentage, 90.0);
      expect(assessment.displayStatus, 'PASSED');
    });

    test('detects upcoming scheduled assessment in future', () {
      final futureDate = DateTime.now().add(const Duration(days: 7));
      final json = {
        'id': 'exam-3',
        'title': 'Midterm Clinical Examination',
        'status': 'scheduled',
        'scheduled_at': futureDate.toIso8601String(),
        'created_at': '2026-01-01T00:00:00Z',
      };

      final assessment = StudentAssessment.fromData(assessmentJson: json);

      expect(assessment.isUpcoming, isTrue);
      expect(assessment.isAvailable, isFalse);
      expect(assessment.displayStatus, 'SCHEDULED');
    });
  });

  group('StudentQuestion Model Tests', () {
    test('parses options and identifies correct answer internally while presenting clean option text', () {
      final json = {
        'id': 'q-101',
        'question_text': 'What is the first-line medication for anaphylaxis in the emergency setting?',
        'marks': 2,
        'type': 'mcq',
        'options': [
          {'id': 'opt-1', 'text': 'Intravenous Diphenhydramine', 'is_correct': false},
          {'id': 'opt-2', 'text': 'Intramuscular Epinephrine (1:1000)', 'is_correct': true},
          {'id': 'opt-3', 'text': 'Oral Prednisolone', 'is_correct': false},
          {'id': 'opt-4', 'text': 'Inhaled Salbutamol', 'is_correct': false},
        ],
      };

      final question = StudentQuestion.fromJson(json, orderIndex: 1);

      expect(question.id, 'q-101');
      expect(question.marks, 2);
      expect(question.orderIndex, 1);
      expect(question.options.length, 4);
      expect(question.options[1].text, 'Intramuscular Epinephrine (1:1000)');
      expect(question.correctOptionId, 'opt-2');
    });
  });

  group('AssessmentsListState Filtering Tests', () {
    final assessments = [
      StudentAssessment(
        id: '1',
        title: 'Airway MCQ Exam',
        courseTitle: 'Trauma Care',
        createdAt: DateTime.now(),
        status: 'active',
        scheduledAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      StudentAssessment(
        id: '2',
        title: 'Scheduled OSCE Quiz',
        courseTitle: 'Emergency Protocols',
        createdAt: DateTime.now(),
        status: 'scheduled',
        scheduledAt: DateTime.now().add(const Duration(days: 4)),
      ),
      StudentAssessment(
        id: '3',
        title: 'Completed Triage Exam',
        courseTitle: 'Pediatric Care',
        createdAt: DateTime.now(),
        isCompleted: true,
        isPassed: true,
      ),
    ];

    test('filters by status: available', () {
      final state = AssessmentsListState(
        assessments: assessments,
        activeFilter: AssessmentFilter.available,
      );

      expect(state.filteredAssessments.length, 1);
      expect(state.filteredAssessments.first.id, '1');
    });

    test('filters by status: scheduled', () {
      final state = AssessmentsListState(
        assessments: assessments,
        activeFilter: AssessmentFilter.scheduled,
      );

      expect(state.filteredAssessments.length, 1);
      expect(state.filteredAssessments.first.id, '2');
    });

    test('filters by status: completed', () {
      final state = AssessmentsListState(
        assessments: assessments,
        activeFilter: AssessmentFilter.completed,
      );

      expect(state.filteredAssessments.length, 1);
      expect(state.filteredAssessments.first.id, '3');
    });
  });
}

