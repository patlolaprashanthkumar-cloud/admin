import 'package:flutter_test/flutter_test.dart';
import 'package:iiecm_admin/features/assessments/domain/models/assessment.dart';
import 'package:iiecm_admin/features/assessments/domain/models/question.dart';

void main() {
  group('Assessment & Question Bank Domain Model Tests', () {
    test('Constructs Assessment from JSON correctly', () {
      final json = {
        'id': 'asm-1',
        'title': 'Trauma MCQ Exam',
        'description': 'Comprehensive exam for Advanced Trauma protocols',
        'type': 'mcq',
        'total_marks': 50,
        'passing_marks': 25,
        'duration_minutes': 45,
        'status': 'active',
        'scheduled_at': '2026-11-15T09:00:00Z',
        'created_by': 'admin',
        'created_at': '2026-11-01T10:00:00Z',
      };

      final assessment = Assessment.fromJson(
        json,
        questionCount: 25,
        totalAttempts: 12,
        passedAttempts: 10,
      );

      expect(assessment.id, equals('asm-1'));
      expect(assessment.title, equals('Trauma MCQ Exam'));
      expect(assessment.type, equals('mcq'));
      expect(assessment.totalMarks, equals(50));
      expect(assessment.passingMarks, equals(25));
      expect(assessment.durationMinutes, equals(45));
      expect(assessment.questionCount, equals(25));
      expect(assessment.totalAttempts, equals(12));
      expect(assessment.passedAttempts, equals(10));
    });

    test('Question and QuestionOption parse JSONB options correctly', () {
      final qJson = {
        'id': 'q-1',
        'question_text':
            'What is the standard chest compression depth in adult CPR?',
        'type': 'mcq',
        'marks': 2,
        'options': [
          {'id': 'opt_1', 'text': '1 to 2 cm', 'is_correct': false},
          {'id': 'opt_2', 'text': '5 to 6 cm', 'is_correct': true},
          {'id': 'opt_3', 'text': '8 to 9 cm', 'is_correct': false},
        ],
        'created_at': '2026-11-01T10:00:00Z',
      };

      final question = Question.fromJson(qJson);

      expect(question.id, equals('q-1'));
      expect(question.isMcq, isTrue);
      expect(question.marks, equals(2));
      expect(question.options.length, equals(3));
      expect(question.options[1].text, equals('5 to 6 cm'));
      expect(question.options[1].isCorrect, isTrue);
      expect(question.options[0].isCorrect, isFalse);

      final payload = question.toJson();
      expect(payload['question_text'], contains('chest compression'));
      expect((payload['options'] as List).length, equals(3));
    });
  });
}
