/// Question option presented to the student during an assessment attempt
class StudentQuestionOption {
  final String id;
  final String text;

  const StudentQuestionOption({
    required this.id,
    required this.text,
  });

  factory StudentQuestionOption.fromJson(Map<String, dynamic> json) {
    return StudentQuestionOption(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
    );
  }
}

/// Clinical question item loaded during an assessment attempt
class StudentQuestion {
  final String id;
  final String questionText;
  final List<StudentQuestionOption> options;
  final int marks;
  final String type;
  final int orderIndex;
  final String? correctOptionId; // Used strictly for client/server evaluation, not exposed to student UI

  const StudentQuestion({
    required this.id,
    required this.questionText,
    this.options = const [],
    this.marks = 1,
    this.type = 'mcq',
    this.orderIndex = 1,
    this.correctOptionId,
  });

  factory StudentQuestion.fromJson(
    Map<String, dynamic> json, {
    int orderIndex = 1,
  }) {
    List<StudentQuestionOption> parsedOptions = [];
    String? correctId;
    final optRaw = json['options'];
    if (optRaw is List) {
      for (final o in optRaw) {
        if (o is Map<String, dynamic>) {
          parsedOptions.add(StudentQuestionOption.fromJson(o));
          final isCorrect = o['is_correct'] == true || o['isCorrect'] == true;
          if (isCorrect) {
            correctId = o['id']?.toString();
          }
        }
      }
    }

    return StudentQuestion(
      id: json['id']?.toString() ?? '',
      questionText: json['question_text']?.toString() ?? '',
      options: parsedOptions,
      marks: (json['marks'] as num?)?.toInt() ?? 1,
      type: json['type']?.toString() ?? 'mcq',
      orderIndex: orderIndex,
      correctOptionId: correctId,
    );
  }
}

