import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/models/assessment_attempt_result.dart';
import '../../domain/models/assessment_question.dart';
import '../providers/assessments_provider.dart';

/// Full interactive timed examination attempt screen supporting MCQ question navigation
class AssessmentAttemptScreen extends ConsumerStatefulWidget {
  final String assessmentId;

  const AssessmentAttemptScreen({
    super.key,
    required this.assessmentId,
  });

  @override
  ConsumerState<AssessmentAttemptScreen> createState() =>
      _AssessmentAttemptScreenState();
}

class _AssessmentAttemptScreenState
    extends ConsumerState<AssessmentAttemptScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSession();
    });
  }

  void _initSession() {
    final detailState = ref.read(assessmentDetailProvider(widget.assessmentId));
    final duration = detailState.assessment?.durationMinutes ?? 60;
    ref
        .read(assessmentAttemptProvider(widget.assessmentId).notifier)
        .startSession(duration);
  }

  String _formatTimer(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showSubmitDialog(
    int totalQuestions,
    int answeredCount,
    AssessmentAttemptNotifier attemptNotifier,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.assignment_turned_in_rounded, color: AppColors.primaryForest),
            SizedBox(width: 8),
            Text('Submit Examination?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You have completed $answeredCount of $totalQuestions questions.',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            if (answeredCount < totalQuestions)
              Text(
                'Warning: You have ${totalQuestions - answeredCount} unanswered questions.',
                style: const TextStyle(color: AppColors.warning, fontSize: 12),
              ),
            const SizedBox(height: 8),
            const Text(
              'Once submitted, your responses will be evaluated and your score will be recorded.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Review Answers'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryForest,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final result = await attemptNotifier.submitAttempt();
              if (!mounted) return;
              if (result != null) {
                _showResultDialog(result);
              }
            },
            child: const Text('Submit Now'),
          ),
        ],
      ),
    );
  }

  void _showResultDialog(AssessmentAttemptResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              result.passed ? Icons.check_circle_rounded : Icons.info_outline_rounded,
              color: result.passed ? AppColors.success : AppColors.error,
            ),
            const SizedBox(width: 8),
            Text(result.passed ? 'Examination Passed!' : 'Examination Completed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: result.passed ? AppColors.successSoft : AppColors.errorSoft,
                borderRadius: BorderRadius.circular(AppConstants.radiusMd),
              ),
              child: Column(
                children: [
                  Text(
                    '${result.score.toStringAsFixed(1)} / ${result.totalMarks.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: result.passed ? AppColors.success : AppColors.error,
                    ),
                  ),
                  Text(
                    'Overall Percentage: ${result.percentage.toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              result.passed
                  ? 'Congratulations! You have satisfied the clinical passing requirements for this examination checkpoint.'
                  : 'Your assessment attempt has been recorded. Review clinical protocols with your lead faculty mentor.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryForest,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop(); // Close dialog
              Navigator.of(context).pop(); // Back to instructions
              ref.invalidate(assessmentDetailProvider(widget.assessmentId));
              ref.read(studentAssessmentsNotifierProvider.notifier).refresh();
            },
            child: const Text('Return to Assessment'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final detailState = ref.watch(assessmentDetailProvider(widget.assessmentId));
    final attemptState = ref.watch(assessmentAttemptProvider(widget.assessmentId));
    final attemptNotifier =
        ref.read(assessmentAttemptProvider(widget.assessmentId).notifier);

    final questions = detailState.questions;
    final totalQuestions = questions.length;
    final currentIndex = attemptState.currentQuestionIndex.clamp(
      0,
      totalQuestions > 0 ? totalQuestions - 1 : 0,
    );

    final isLowTime = attemptState.remainingSeconds < 300; // < 5 mins

    if (totalQuestions == 0) {
      return Scaffold(
        appBar: AppBar(title: const Text('Examination Attempt')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacingLg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.quiz_outlined, size: 48, color: AppColors.warning),
                const SizedBox(height: 12),
                const Text(
                  'No Questions Available',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 6),
                const Text(
                  'The questions for this examination are currently being uploaded by the examination board.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Back',
                  isFullWidth: false,
                  height: 38,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentQuestion = questions[currentIndex];
    final selectedOptionId = attemptState.selectedAnswers[currentQuestion.id];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Question ${currentIndex + 1} of $totalQuestions',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        actions: [
          // Countdown Timer Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isLowTime
                  ? AppColors.errorSoft
                  : (isDark ? AppColors.darkSurfaceElevated : AppColors.forestSoft),
              borderRadius: BorderRadius.circular(AppConstants.radiusFull),
              border: Border.all(
                color: isLowTime ? AppColors.error : AppColors.primaryForest,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 14,
                  color: isLowTime ? AppColors.error : AppColors.primaryForest,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatTimer(attemptState.remainingSeconds),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                    color: isLowTime ? AppColors.error : AppColors.primaryForest,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppConstants.spacingSm),
        ],
      ),
      body: Column(
        children: [
          // Question Progress Indicator
          LinearProgressIndicator(
            value: (currentIndex + 1) / totalQuestions,
            backgroundColor: isDark ? AppColors.darkBorder : AppColors.border,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryForest),
            minHeight: 4,
          ),

          // Question Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppConstants.spacingMd),
              children: [
                // Question Header Card
                AppCard(
                  padding: const EdgeInsets.all(AppConstants.spacingMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurfaceElevated : AppColors.forestSoft,
                              borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                            ),
                            child: Text(
                              'QUESTION #${currentIndex + 1}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryForest,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkBackground : AppColors.warmCream,
                              borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                            ),
                            child: Text(
                              '${currentQuestion.marks} Mark${currentQuestion.marks > 1 ? "s" : ""}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.spacingMd),
                      Text(
                        currentQuestion.questionText,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          height: 1.4,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppConstants.spacingMd),

                // Options List
                ...currentQuestion.options.map((option) {
                  final isSelected = selectedOptionId == option.id;
                  return _buildOptionTile(
                    option: option,
                    isSelected: isSelected,
                    onTap: () {
                      attemptNotifier.selectAnswer(currentQuestion.id, option.id);
                    },
                    isDark: isDark,
                  );
                }),
              ],
            ),
          ),

          // Bottom Action Navigation Bar
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingMd),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                ),
              ),
            ),
            child: Row(
              children: [
                // Previous Button
                Expanded(
                  child: AppButton(
                    label: 'Previous',
                    icon: Icons.arrow_back_rounded,
                    variant: AppButtonVariant.outline,
                    height: 42,
                    onPressed: currentIndex > 0
                        ? () => attemptNotifier.goToQuestion(currentIndex - 1)
                        : null,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingMd),

                // Next or Submit Button
                Expanded(
                  child: currentIndex < totalQuestions - 1
                      ? AppButton(
                          label: 'Next',
                          icon: Icons.arrow_forward_rounded,
                          height: 42,
                          onPressed: () =>
                              attemptNotifier.goToQuestion(currentIndex + 1),
                        )
                      : AppButton(
                          label: 'Finish & Submit',
                          icon: Icons.check_circle_outline_rounded,
                          height: 42,
                          variant: AppButtonVariant.secondary,
                          onPressed: () => _showSubmitDialog(
                            totalQuestions,
                            attemptState.answeredCount,
                            attemptNotifier,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required StudentQuestionOption option,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingSm),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark ? AppColors.darkSurfaceElevated : AppColors.forestSoft)
            : (isDark ? AppColors.darkSurface : AppColors.white),
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(
          color: isSelected
              ? AppColors.primaryForest
              : (isDark ? AppColors.darkBorder : AppColors.border),
          width: isSelected ? 1.6 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryForest
                          : (isDark ? AppColors.darkBorder : AppColors.border),
                      width: 2,
                    ),
                    color: isSelected ? AppColors.primaryForest : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Center(
                          child: Icon(Icons.check, size: 14, color: Colors.white),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    option.text,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

