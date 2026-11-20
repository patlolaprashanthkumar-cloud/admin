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
///
/// Follows the IIECM Modern Academic design language with a distraction-free examination view,
/// live countdown timer, visual question progress bar, accessible MCQ options,
/// answer-state confirmation dialogs, and evaluation outcome summaries.
class AssessmentAttemptScreen extends ConsumerStatefulWidget {
  final String assessmentId;

  const AssessmentAttemptScreen({super.key, required this.assessmentId});

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark
            ? AppColors.darkSurface
            : AppColors.backgroundWarmOffWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          side: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceElevated
                    : AppColors.forestSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_turned_in_rounded,
                color: AppColors.primaryNavy,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Submit Examination?',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceElevated
                    : AppColors.warmCreamLight,
                borderRadius: BorderRadius.circular(AppConstants.radiusSm + 2),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 16,
                    color: answeredCount == totalQuestions
                        ? AppColors.success
                        : AppColors.primaryNavy,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You have completed $answeredCount of $totalQuestions questions.',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (answeredCount < totalQuestions) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.warning.withValues(alpha: 0.15)
                      : AppColors.warningSoft,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 15,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Warning: You have ${totalQuestions - answeredCount} unanswered questions.',
                        style: const TextStyle(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'Once submitted, your responses will be evaluated and your score will be recorded.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: TextButton.styleFrom(
              foregroundColor: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
            child: const Text(
              'Review Answers',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryNavy,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusMd),
              ),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final result = await attemptNotifier.submitAttempt();
              if (!mounted) return;
              if (result != null) {
                _showResultDialog(result);
              }
            },
            child: const Text(
              'Submit Now',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _showResultDialog(AssessmentAttemptResult result) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark
            ? AppColors.darkSurface
            : AppColors.backgroundWarmOffWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          side: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: result.passed
                    ? (isDark
                          ? AppColors.success.withValues(alpha: 0.15)
                          : AppColors.successSoft)
                    : (isDark
                          ? AppColors.error.withValues(alpha: 0.15)
                          : AppColors.errorSoft),
                shape: BoxShape.circle,
              ),
              child: Icon(
                result.passed
                    ? Icons.check_circle_rounded
                    : Icons.info_outline_rounded,
                color: result.passed ? AppColors.success : AppColors.error,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                result.passed ? 'Examination Passed!' : 'Examination Completed',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: result.passed
                    ? (isDark
                          ? AppColors.success.withValues(alpha: 0.15)
                          : AppColors.successSoft)
                    : (isDark
                          ? AppColors.error.withValues(alpha: 0.15)
                          : AppColors.errorSoft),
                borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                border: Border.all(
                  color: result.passed
                      ? AppColors.success.withValues(alpha: 0.3)
                      : AppColors.error.withValues(alpha: 0.3),
                  width: 0.8,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '${result.score.toStringAsFixed(1)} / ${result.totalMarks.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: result.passed
                          ? (isDark
                                ? const Color(0xFF6EE7B7)
                                : AppColors.success)
                          : (isDark
                                ? const Color(0xFFFCA5A5)
                                : AppColors.error),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Overall Percentage: ${result.percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
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
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryNavy,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusMd),
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop(); // Close dialog
              Navigator.of(context).pop(); // Back to instructions
              ref.invalidate(assessmentDetailProvider(widget.assessmentId));
              ref.read(studentAssessmentsNotifierProvider.notifier).refresh();
            },
            child: const Text(
              'Return to Assessment',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final detailState = ref.watch(
      assessmentDetailProvider(widget.assessmentId),
    );
    final attemptState = ref.watch(
      assessmentAttemptProvider(widget.assessmentId),
    );
    final attemptNotifier = ref.read(
      assessmentAttemptProvider(widget.assessmentId).notifier,
    );

    final questions = detailState.questions;
    final totalQuestions = questions.length;
    final currentIndex = attemptState.currentQuestionIndex.clamp(
      0,
      totalQuestions > 0 ? totalQuestions - 1 : 0,
    );

    final isLowTime = attemptState.remainingSeconds < 300; // < 5 mins

    if (totalQuestions == 0) {
      return Scaffold(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.backgroundWarmOffWhite,
        appBar: AppBar(
          backgroundColor: isDark
              ? AppColors.darkSurface
              : AppColors.backgroundWarmOffWhite,
          elevation: 0,
          title: const Text('Examination Attempt'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacingLg),
            child: AppCard(
              padding: const EdgeInsets.all(AppConstants.spacingLg),
              borderRadius: AppConstants.radiusLg,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.warning.withValues(alpha: 0.15)
                          : AppColors.warningSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.quiz_outlined,
                        size: 30,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingMd),
                  Text(
                    'No Questions Available',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'The questions for this examination are currently being uploaded by the examination board.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingLg),
                  AppButton(
                    label: 'Back',
                    icon: Icons.arrow_back_rounded,
                    isFullWidth: false,
                    height: 38,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final currentQuestion = questions[currentIndex];
    final selectedOptionId = attemptState.selectedAnswers[currentQuestion.id];

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.backgroundWarmOffWhite,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.darkSurface
            : AppColors.backgroundWarmOffWhite,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: Text(
          'Question ${currentIndex + 1} of $totalQuestions',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        actions: [
          // Countdown Timer Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            margin: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: isLowTime
                  ? (isDark
                        ? AppColors.error.withValues(alpha: 0.2)
                        : AppColors.errorSoft)
                  : (isDark
                        ? AppColors.darkSurfaceElevated
                        : AppColors.forestSoft),
              borderRadius: BorderRadius.circular(AppConstants.radiusFull),
              border: Border.all(
                color: isLowTime
                    ? AppColors.error
                    : AppColors.primaryNavy.withValues(alpha: 0.3),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 14,
                  color: isLowTime ? AppColors.error : AppColors.primaryNavy,
                ),
                const SizedBox(width: 4.5),
                Text(
                  _formatTimer(attemptState.remainingSeconds),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                    color: isLowTime ? AppColors.error : AppColors.primaryNavy,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppConstants.spacingMd),
        ],
      ),
      body: Column(
        children: [
          // Question Progress Indicator
          LinearProgressIndicator(
            value: (currentIndex + 1) / totalQuestions,
            backgroundColor: isDark
                ? AppColors.darkBorder
                : AppColors.borderSubtle,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.primaryNavy,
            ),
            minHeight: 3.5,
          ),

          // Compact progress overview strip
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${attemptState.answeredCount} of $totalQuestions Answered',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
                Text(
                  '${totalQuestions - attemptState.answeredCount} Remaining',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.accentOrangeLight
                        : AppColors.terracotta,
                  ),
                ),
              ],
            ),
          ),

          // Question Content
          Expanded(
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppConstants.spacingMd),
              children: [
                // Question Header Card
                AppCard(
                  padding: const EdgeInsets.all(AppConstants.spacingMd + 2),
                  borderRadius: AppConstants.radiusLg,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurfaceElevated
                                  : AppColors.forestSoft,
                              borderRadius: BorderRadius.circular(
                                AppConstants.radiusSm,
                              ),
                              border: Border.all(
                                color: AppColors.primaryNavy.withValues(
                                  alpha: isDark ? 0.3 : 0.15,
                                ),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              'QUESTION #${currentIndex + 1}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: isDark
                                    ? AppColors.accentOrangeLight
                                    : AppColors.primaryNavy,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkBackground
                                  : AppColors.warmCream,
                              borderRadius: BorderRadius.circular(
                                AppConstants.radiusSm,
                              ),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : AppColors.border,
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              '${currentQuestion.marks} Mark${currentQuestion.marks > 1 ? "s" : ""}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
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
                          fontSize: 15.5,
                          height: 1.45,
                          color: isDark ? Colors.white : AppColors.textPrimary,
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
                      attemptNotifier.selectAnswer(
                        currentQuestion.id,
                        option.id,
                      );
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // Previous Button
                  Expanded(
                    child: AppButton(
                      label: 'Previous',
                      icon: Icons.arrow_back_rounded,
                      variant: AppButtonVariant.outline,
                      height: 44,
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
                            height: 44,
                            onPressed: () =>
                                attemptNotifier.goToQuestion(currentIndex + 1),
                          )
                        : AppButton(
                            label: 'Finish & Submit',
                            icon: Icons.check_circle_outline_rounded,
                            height: 44,
                            variant: AppButtonVariant.primary,
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
      margin: const EdgeInsets.only(bottom: AppConstants.spacingSm + 2),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark ? AppColors.darkSurfaceElevated : AppColors.forestSoft)
            : (isDark ? AppColors.darkSurface : AppColors.white),
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(
          color: isSelected
              ? AppColors.primaryNavy
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryNavy
                          : (isDark ? AppColors.darkBorder : AppColors.border),
                      width: 2,
                    ),
                    color: isSelected
                        ? AppColors.primaryNavy
                        : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Center(
                          child: Icon(
                            Icons.check,
                            size: 14,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    option.text,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                      height: 1.35,
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
