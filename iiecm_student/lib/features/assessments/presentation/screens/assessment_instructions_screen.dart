import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/models/student_assessment.dart';
import '../providers/assessments_provider.dart';

/// Assessment Instructions and Evaluation Overview screen
class AssessmentInstructionsScreen extends ConsumerWidget {
  final String assessmentId;

  const AssessmentInstructionsScreen({
    super.key,
    required this.assessmentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(assessmentDetailProvider(assessmentId));
    final notifier = ref.read(assessmentDetailProvider(assessmentId).notifier);

    final assessment = state.assessment;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          assessment?.title ?? 'Examination Instructions',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => notifier.refresh(),
          ),
          const SizedBox(width: AppConstants.spacingSm),
        ],
      ),
      body: state.isLoading && assessment == null
          ? _buildLoadingState(isDark)
          : state.hasError && assessment == null
              ? _buildErrorState(context, state.errorMessage, notifier, isDark, theme)
              : assessment == null
                  ? _buildNotFoundState(context, isDark, theme)
                  : RefreshIndicator(
                      color: AppColors.primaryForest,
                      onRefresh: () => notifier.refresh(),
                      child: ListView(
                        padding: const EdgeInsets.all(AppConstants.spacingMd),
                        children: [
                          // 1. Overview Header Card
                          _buildHeaderCard(assessment, state.questions.length, isDark, theme),
                          const SizedBox(height: AppConstants.spacingMd),

                          // 2. Evaluation / Result Banner (if completed)
                          if (assessment.isCompleted) ...[
                            _buildResultCard(assessment, isDark, theme),
                            const SizedBox(height: AppConstants.spacingMd),
                          ],

                          // 3. Instructions & Guidelines Card
                          _buildInstructionsCard(assessment, isDark, theme),
                          const SizedBox(height: AppConstants.spacingLg),

                          // 4. Action Button
                          if (!assessment.isCompleted) ...[
                            if (assessment.isAvailable)
                              AppButton(
                                label: 'Start Examination Attempt',
                                icon: Icons.play_arrow_rounded,
                                onPressed: () {
                                  context.push('/assessments/$assessmentId/attempt');
                                },
                              )
                            else
                              AppButton(
                                label: 'Examination Scheduled (Locked)',
                                icon: Icons.lock_clock_rounded,
                                variant: AppButtonVariant.outline,
                                onPressed: null,
                              ),
                          ],

                          const SizedBox(height: AppConstants.spacingXl),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryForest),
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Text(
            'Loading examination instructions...',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    String? errorMessage,
    AssessmentDetailNotifier notifier,
    bool isDark,
    ThemeData theme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: AppCard(
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 44),
              const SizedBox(height: AppConstants.spacingSm),
              Text(
                'Unable to Load Examination',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                errorMessage ?? 'A network or server error occurred.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppConstants.spacingMd),
              AppButton(
                label: 'Retry Connection',
                icon: Icons.refresh_rounded,
                isFullWidth: false,
                height: 38,
                onPressed: () => notifier.refresh(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotFoundState(BuildContext context, bool isDark, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: isDark ? AppColors.darkTextSecondary : AppColors.textMuted),
            const SizedBox(height: AppConstants.spacingMd),
            Text(
              'Examination Not Found',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'This assessment could not be located or you are not enrolled in its course.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppConstants.spacingLg),
            AppButton(
              label: 'Back to Examinations',
              icon: Icons.arrow_back_rounded,
              isFullWidth: false,
              height: 38,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(
    StudentAssessment assessment,
    int resolvedQuestionCount,
    bool isDark,
    ThemeData theme,
  ) {
    final scheduleFormatted = assessment.scheduledAt != null
        ? DateFormat('EEEE, d MMMM yyyy • h:mm a').format(assessment.scheduledAt!)
        : 'Open Availability Window';

    final qCount = resolvedQuestionCount > 0
        ? resolvedQuestionCount
        : assessment.questionCount;

    return AppCard(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceElevated : AppColors.forestSoft,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                ),
                child: Text(
                  assessment.courseTitle.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryForest,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBackground : AppColors.warmCream,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                ),
                child: Text(
                  assessment.type.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: assessment.isCompleted
                      ? AppColors.successSoft
                      : (assessment.isAvailable ? AppColors.forestSoft : AppColors.warningSoft),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                ),
                child: Text(
                  assessment.displayStatus,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: assessment.isCompleted
                        ? AppColors.success
                        : (assessment.isAvailable ? AppColors.primaryForest : AppColors.warning),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingSm),

          Text(
            assessment.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              height: 1.25,
            ),
          ),
          const SizedBox(height: AppConstants.spacingMd),

          const Divider(height: 1),
          const SizedBox(height: AppConstants.spacingSm),

          // Stat Metrics
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricColumn(
                icon: Icons.timer_outlined,
                value: '${assessment.durationMinutes} min',
                label: 'Duration',
                isDark: isDark,
              ),
              _buildDivider(isDark),
              _buildMetricColumn(
                icon: Icons.quiz_outlined,
                value: '$qCount Qs',
                label: 'Questions',
                isDark: isDark,
              ),
              _buildDivider(isDark),
              _buildMetricColumn(
                icon: Icons.grade_outlined,
                value: '${assessment.totalMarks} Mks',
                label: 'Pass: ${assessment.passingMarks}',
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingSm),
          const Divider(height: 1),
          const SizedBox(height: AppConstants.spacingSm),

          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.terracotta),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Scheduled: $scheduleFormatted',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricColumn({
    required IconData icon,
    required String value,
    required String label,
    required bool isDark,
  }) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryForest),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
        Text(label, style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      height: 24,
      width: 1,
      color: isDark ? AppColors.darkBorder : AppColors.border,
    );
  }

  Widget _buildResultCard(
    StudentAssessment assessment,
    bool isDark,
    ThemeData theme,
  ) {
    final completedFormatted = assessment.completedAt != null
        ? DateFormat('EEEE, d MMMM yyyy • h:mm a').format(assessment.completedAt!)
        : 'Completed';

    final isPassed = assessment.isPassed == true;

    return AppCard(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPassed ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                size: 20,
                color: isPassed ? AppColors.success : AppColors.error,
              ),
              const SizedBox(width: 8),
              Text(
                'Evaluation Result',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isPassed ? AppColors.successSoft : AppColors.errorSoft,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                ),
                child: Text(
                  isPassed ? 'PASSED' : 'NEEDS REVISION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isPassed ? AppColors.success : AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingSm),

          Text(
            'Completed and evaluated on $completedFormatted',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppConstants.spacingMd),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceElevated : AppColors.warmCreamLight,
              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Score Recorded:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(
                  '${assessment.score?.toStringAsFixed(1) ?? "0"} / ${assessment.totalMarks} (${assessment.percentage?.toStringAsFixed(0) ?? "0"}%)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isPassed ? AppColors.success : AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard(
    StudentAssessment assessment,
    bool isDark,
    ThemeData theme,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rule_rounded, size: 18, color: AppColors.primaryForest),
              const SizedBox(width: 8),
              Text(
                'Examination Guidelines & Protocol',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingSm),

          _buildRuleItem('1', 'This is a timed assessment (${assessment.durationMinutes} minutes). A real-time timer will count down once started.', isDark),
          _buildRuleItem('2', 'Select one option per question. You can navigate back and forth to revise answers before final submission.', isDark),
          _buildRuleItem('3', 'Ensure a stable internet connection. If the timer reaches 00:00, the examination will automatically submit all answered questions.', isDark),
          _buildRuleItem('4', 'Passing threshold is ${assessment.passingMarks} out of ${assessment.totalMarks} marks (${((assessment.passingMarks / (assessment.totalMarks > 0 ? assessment.totalMarks : 100)) * 100).toStringAsFixed(0)}%).', isDark),
          _buildRuleItem('5', 'Only one official attempt is permitted. Submissions are permanently saved to your academic transcript.', isDark),
        ],
      ),
    );
  }

  Widget _buildRuleItem(String num, String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceElevated : AppColors.forestSoft,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                num,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primaryForest),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

