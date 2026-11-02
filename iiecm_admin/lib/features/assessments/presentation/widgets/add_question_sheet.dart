import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../domain/models/question.dart';
import '../providers/assessment_provider.dart';

class AddQuestionSheet extends ConsumerStatefulWidget {
  final String assessmentId;
  final Question? existingQuestion;
  final int nextOrderIndex;

  const AddQuestionSheet({
    super.key,
    required this.assessmentId,
    this.existingQuestion,
    this.nextOrderIndex = 1,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String assessmentId,
    Question? existingQuestion,
    int nextOrderIndex = 1,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddQuestionSheet(
        assessmentId: assessmentId,
        existingQuestion: existingQuestion,
        nextOrderIndex: nextOrderIndex,
      ),
    );
  }

  @override
  ConsumerState<AddQuestionSheet> createState() => _AddQuestionSheetState();
}

class _AddQuestionSheetState extends ConsumerState<AddQuestionSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _questionTextController;
  late TextEditingController _marksController;
  late String _type;

  final List<TextEditingController> _optionControllers = [];
  int _correctOptionIndex = 0;
  bool _isSubmitting = false;

  bool get isEditing => widget.existingQuestion != null;

  @override
  void initState() {
    super.initState();
    final q = widget.existingQuestion;
    _questionTextController = TextEditingController(text: q?.questionText ?? '');
    _marksController = TextEditingController(text: q != null ? q.marks.toString() : '1');
    _type = q?.type ?? 'mcq';

    if (q != null && q.options.isNotEmpty) {
      for (int i = 0; i < q.options.length; i++) {
        _optionControllers.add(TextEditingController(text: q.options[i].text));
        if (q.options[i].isCorrect) {
          _correctOptionIndex = i;
        }
      }
    } else {
      // Defaults for MCQ
      if (_type == 'mcq') {
        _optionControllers.add(TextEditingController());
        _optionControllers.add(TextEditingController());
        _optionControllers.add(TextEditingController());
        _optionControllers.add(TextEditingController());
      } else if (_type == 'true_false') {
        _optionControllers.add(TextEditingController(text: 'True'));
        _optionControllers.add(TextEditingController(text: 'False'));
      }
    }
  }

  @override
  void dispose() {
    _questionTextController.dispose();
    _marksController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_optionControllers.length < 6) {
      setState(() {
        _optionControllers.add(TextEditingController());
      });
    }
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        final removed = _optionControllers.removeAt(index);
        removed.dispose();
        if (_correctOptionIndex >= _optionControllers.length) {
          _correctOptionIndex = 0;
        }
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final List<QuestionOption> options = [];
    if (_type == 'mcq' || _type == 'true_false') {
      for (int i = 0; i < _optionControllers.length; i++) {
        final text = _optionControllers[i].text.trim();
        if (text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please fill Option ${String.fromCharCode(65 + i)}')),
          );
          return;
        }
        options.add(QuestionOption(
          id: 'opt_${i + 1}',
          text: text,
          isCorrect: i == _correctOptionIndex,
        ));
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(assessmentRepositoryProvider);
      final marks = int.tryParse(_marksController.text.trim()) ?? 1;

      final question = Question(
        id: widget.existingQuestion?.id ?? '',
        questionText: _questionTextController.text.trim(),
        options: options,
        marks: marks,
        type: _type,
        orderIndex: widget.existingQuestion?.orderIndex ?? widget.nextOrderIndex,
        createdAt: widget.existingQuestion?.createdAt ?? DateTime.now(),
      );

      if (isEditing) {
        await repo.updateQuestion(question);
      } else {
        await repo.addQuestionToAssessment(
          widget.assessmentId,
          question,
          widget.nextOrderIndex,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Question updated' : 'Question added to assessment'),
          backgroundColor: AppColors.primaryForest,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final availableHeight = mediaQuery.size.height - mediaQuery.padding.top;
    final effectiveHeight = (availableHeight - bottomInset) * 0.90;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: effectiveHeight.clamp(320.0, availableHeight),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppConstants.radiusLarge),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Handle Bar
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryForest.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.help_outline_rounded, color: AppColors.primaryForest, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Edit Question' : 'Add Question to Exam',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Configure question stem, options, and designated correct answer',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  children: [
                    // Question Type & Marks
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _type,
                            decoration: const InputDecoration(
                              labelText: 'Question Type',
                              prefixIcon: Icon(Icons.format_list_bulleted_rounded),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'mcq', child: Text('Multiple Choice (MCQ)')),
                              DropdownMenuItem(value: 'true_false', child: Text('True / False')),
                              DropdownMenuItem(value: 'short_answer', child: Text('Short Answer')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _type = val;
                                  if (val == 'true_false') {
                                    _optionControllers.clear();
                                    _optionControllers.add(TextEditingController(text: 'True'));
                                    _optionControllers.add(TextEditingController(text: 'False'));
                                    _correctOptionIndex = 0;
                                  } else if (val == 'mcq' && _optionControllers.length < 4) {
                                    while (_optionControllers.length < 4) {
                                      _optionControllers.add(TextEditingController());
                                    }
                                  }
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _marksController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Marks Awarded *',
                              prefixIcon: Icon(Icons.grade_outlined),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              if (int.tryParse(v) == null) return 'Must be a number';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Question Text
                    TextFormField(
                      controller: _questionTextController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Question Stem / Prompt *',
                        hintText: 'e.g. Which of the following is the first-line vasopressor in septic shock?',
                        alignLabelWithHint: true,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter question text' : null,
                    ),
                    const SizedBox(height: 20),

                    // Options Builder
                    if (_type == 'mcq' || _type == 'true_false') ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Options & Correct Answer',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                          ),
                          if (_type == 'mcq' && _optionControllers.length < 6)
                            TextButton.icon(
                              onPressed: _addOption,
                              icon: const Icon(Icons.add_rounded, size: 14),
                              label: const Text('Add Option', style: TextStyle(fontSize: 11)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select the radio button next to the correct answer choice.',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _optionControllers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final label = String.fromCharCode(65 + i);
                          final isCorrect = _correctOptionIndex == i;

                          return Row(
                            children: [
                              Radio<int>(
                                value: i,
                                groupValue: _correctOptionIndex,
                                activeColor: AppColors.primaryForest,
                                onChanged: (val) {
                                  if (val != null) setState(() => _correctOptionIndex = val);
                                },
                              ),
                              Expanded(
                                child: TextFormField(
                                  controller: _optionControllers[i],
                                  readOnly: _type == 'true_false',
                                  decoration: InputDecoration(
                                    labelText: 'Option $label ${isCorrect ? '(Correct Answer)' : ''}',
                                    suffixIcon: isCorrect
                                        ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryForest)
                                        : null,
                                  ),
                                ),
                              ),
                              if (_type == 'mcq' && _optionControllers.length > 2) ...[
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.error, size: 20),
                                  onPressed: () => _removeOption(i),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.warmCream,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.divider),
                        ),
                        child: const Text(
                          'Candidates will type in their written response. Faculty can evaluate answers during grading.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Sticky Bottom Actions
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.surface,
                  border: Border(
                    top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.divider),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryForest,
                          foregroundColor: Colors.white,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(isEditing ? 'Save Changes' : 'Add Question'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

