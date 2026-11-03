class QuestionOption {
  final String id;
  final String text;
  final bool isCorrect;

  const QuestionOption({
    required this.id,
    required this.text,
    this.isCorrect = false,
  });

  factory QuestionOption.fromJson(Map<String, dynamic> json) {
    return QuestionOption(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      isCorrect: json['is_correct'] is bool
          ? json['is_correct'] as bool
          : (json['isCorrect'] is bool ? json['isCorrect'] as bool : false),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'text': text, 'is_correct': isCorrect};
  }

  QuestionOption copyWith({String? id, String? text, bool? isCorrect}) {
    return QuestionOption(
      id: id ?? this.id,
      text: text ?? this.text,
      isCorrect: isCorrect ?? this.isCorrect,
    );
  }
}

class Question {
  final String id;
  final String? categoryId;
  final String questionText;
  final List<QuestionOption> options;
  final int marks;
  final String type; // 'mcq', 'true_false', 'short_answer'
  final DateTime createdAt;
  final int orderIndex;

  const Question({
    required this.id,
    this.categoryId,
    required this.questionText,
    this.options = const [],
    this.marks = 1,
    this.type = 'mcq',
    required this.createdAt,
    this.orderIndex = 1,
  });

  bool get isMcq => type == 'mcq';
  bool get isTrueFalse => type == 'true_false';
  bool get isShortAnswer => type == 'short_answer';

  factory Question.fromJson(Map<String, dynamic> json, {int orderIndex = 1}) {
    List<QuestionOption> parsedOptions = [];
    final optRaw = json['options'];
    if (optRaw is List) {
      parsedOptions = optRaw
          .whereType<Map<String, dynamic>>()
          .map((o) => QuestionOption.fromJson(o))
          .toList();
    }

    return Question(
      id: json['id']?.toString() ?? '',
      categoryId: json['category_id']?.toString(),
      questionText: json['question_text']?.toString() ?? '',
      options: parsedOptions,
      marks: json['marks'] is int
          ? json['marks'] as int
          : int.tryParse(json['marks']?.toString() ?? '1') ?? 1,
      type: json['type']?.toString() ?? 'mcq',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      orderIndex: orderIndex,
    );
  }

  Map<String, dynamic> toJson({bool includeId = false}) {
    final map = <String, dynamic>{
      'question_text': questionText,
      'options': options.map((o) => o.toJson()).toList(),
      'marks': marks,
      'type': type,
    };
    if (categoryId != null && categoryId!.isNotEmpty) {
      map['category_id'] = categoryId;
    }
    if (includeId && id.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }

  Question copyWith({
    String? id,
    String? categoryId,
    String? questionText,
    List<QuestionOption>? options,
    int? marks,
    String? type,
    DateTime? createdAt,
    int? orderIndex,
  }) {
    return Question(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      questionText: questionText ?? this.questionText,
      options: options ?? this.options,
      marks: marks ?? this.marks,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }
}
