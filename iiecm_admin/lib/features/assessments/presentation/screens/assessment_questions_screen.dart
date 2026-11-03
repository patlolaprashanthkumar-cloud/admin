import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../domain/models/question.dart';
import '../providers/assessment_provider.dart';
import '../widgets/add_question_sheet.dart';

class AssessmentQuestionsScreen extends ConsumerStatefulWidget {
  final String assessmentId;

  const AssessmentQuestionsScreen({super.key, required this.assessmentId});

  @override
  ConsumerState<AssessmentQuestionsScreen> createState() =>
      _AssessmentQuestionsScreenState();
}

class _AssessmentQuestionsScreenState
    extends ConsumerState<AssessmentQuestionsScreen> {
  void _confirmDeleteQuestion(Question q) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Question?'),
        content: Text(
          'Are you sure you want to remove question "${q.questionText}" from this assessment?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final repo = ref.read(assessmentRepositoryProvider);
              await repo.removeQuestionFromAssessment(
                widget.assessmentId,
                q.id,
              );
              ref.invalidate(assessmentQuestionsProvider(widget.assessmentId));
              ref.invalidate(assessmentDetailProvider(widget.assessmentId));
            },
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final assessmentAsync = ref.watch(
      assessmentDetailProvider(widget.assessmentId),
    );
    final questionsAsync = ref.watch(
      assessmentQuestionsProvider(widget.assessmentId),
    );

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      appBar: AppBar(
        title: const Text('Exam Question Bank'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(
              assessmentQuestionsProvider(widget.assessmentId),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryForest,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Question'),
        onPressed: () {
          questionsAsync.whenData((questions) {
            AddQuestionSheet.show(
              context,
              assessmentId: widget.assessmentId,
              nextOrderIndex: questions.length + 1,
            ).then((added) {
              if (added == true) {
                ref.invalidate(
                  assessmentQuestionsProvider(widget.assessmentId),
                );
                ref.invalidate(assessmentDetailProvider(widget.assessmentId));
              }
            });
          });
        },
      ),
      body: SafeArea(
        child: ResponsiveLayout(
          child: RefreshIndicator(
            onRefresh: () async => ref.invalidate(
              assessmentQuestionsProvider(widget.assessmentId),
            ),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: [
                // Assessment Summary Card
                assessmentAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (assessment) {
                    if (assessment == null) return const SizedBox.shrink();

                    return AppCard(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryForest.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  assessment.type.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryForest,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${assessment.durationMinutes} Mins • Max: ${assessment.totalMarks} Marks',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            assessment.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Questions List
                questionsAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(
                        color: AppColors.primaryForest,
                      ),
                    ),
                  ),
                  error: (err, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Error loading questions: $err'),
                    ),
                  ),
                  data: (questions) {
                    if (questions.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(32),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            Icon(
                              Icons.quiz_outlined,
                              size: 56,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No questions configured',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Tap "Add Question" to build MCQs, True/False, or Short Answer items.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: questions.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final q = questions[index];

                        return AppCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: AppColors.primaryForest
                                        .withValues(alpha: 0.15),
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primaryForest,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppColors.forestSoft,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                q.type
                                                    .replaceAll('_', ' ')
                                                    .toUpperCase(),
                                                style: const TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w700,
                                                  color:
                                                      AppColors.primaryForest,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${q.marks} Mark${q.marks > 1 ? 's' : ''}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.terracotta,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          q.questionText,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: const Icon(
                                      Icons.more_vert_rounded,
                                      size: 18,
                                    ),
                                    onSelected: (val) {
                                      if (val == 'edit') {
                                        AddQuestionSheet.show(
                                          context,
                                          assessmentId: widget.assessmentId,
                                          existingQuestion: q,
                                        ).then((_) {
                                          ref.invalidate(
                                            assessmentQuestionsProvider(
                                              widget.assessmentId,
                                            ),
                                          );
                                        });
                                      } else if (val == 'delete') {
                                        _confirmDeleteQuestion(q);
                                      }
                                    },
                                    itemBuilder: (ctx) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit_outlined, size: 16),
                                            SizedBox(width: 8),
                                            Text('Edit Question'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.delete_outline_rounded,
                                              size: 16,
                                              color: AppColors.error,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Remove',
                                              style: TextStyle(
                                                color: AppColors.error,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              // Options List with Checkmark for Correct Option
                              if (q.options.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                const Divider(height: 1),
                                const SizedBox(height: 8),

                                ...q.options.map((opt) {
                                  final isCorrect = opt.isCorrect;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isCorrect
                                              ? Icons.check_circle_rounded
                                              : Icons
                                                    .radio_button_unchecked_rounded,
                                          size: 16,
                                          color: isCorrect
                                              ? AppColors.primaryForest
                                              : Colors.grey,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            opt.text,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: isCorrect
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                              color: isCorrect
                                                  ? AppColors.primaryForest
                                                  : (isDark
                                                        ? AppColors
                                                              .darkTextPrimary
                                                        : AppColors
                                                              .textPrimary),
                                            ),
                                          ),
                                        ),
                                        if (isCorrect)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 1,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.forestSoft,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'CORRECT',
                                              style: TextStyle(
                                                fontSize: 8,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.primaryForest,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
