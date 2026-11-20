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
///
/// Follows the IIECM Modern Academic design language with institutional branding,
/// examination metadata breakdown, academic guidelines & protocols,
/// evaluation results history, and examination attempt dispatch.
class AssessmentInstructionsScreen extends ConsumerWidget {
  final String assessmentId;

  const AssessmentInstructionsScreen({super.key, required this.assessmentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(assessmentDetailProvider(assessmentId));
    final notifier = ref.read(assessmentDetailProvider(assessmentId).notifier);

    final assessment = state.assessment;

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
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              assessment?.title ?? 'Examination Instructions',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            Text(
              assessment?.courseTitle ?? 'Clinical Curriculum',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            onPressed: () => notifier.refresh(),
          ),
          const SizedBox(width: AppConstants.spacingSm),
        ],
      ),
      body: state.isLoading && assessment == null
          ? _buildLoadingState(isDark)
          : state.hasError && assessment == null
          ? _buildErrorState(
              context,
              state.errorMessage,
              notifier,
              isDark,
              theme,
            )
          : assessment == null
          ? _buildNotFoundState(context, isDark, theme)
          : RefreshIndicator(
              color: AppColors.primaryForest,
              onRefresh: () => notifier.refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppConstants.spacingMd),
                children: [
                  // 1. Overview Header Card
                  _buildHeaderCard(
                    assessment,
                    state.questions.length,
                    isDark,
                    theme,
                  ),
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
                  ] else ...[
                    AppButton(
                      label: 'Back to Examinations',
                      icon: Icons.arrow_back_rounded,
                      variant: AppButtonVariant.outline,
                      onPressed: () => Navigator.of(context).pop(),
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
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryNavy),
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Text(
            'Loading examination instructions...',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
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
          borderRadius: AppConstants.radiusLg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.error.withValues(alpha: 0.15)
                      : AppColors.errorSoft,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.error,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingMd),
              Text(
                'Unable to Load Examination',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                errorMessage ?? 'A network or server error occurred.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppConstants.spacingMd + 4),
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

  Widget _buildNotFoundState(
    BuildContext context,
    bool isDark,
    ThemeData theme,
  ) {
    return Center(
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
                      ? AppColors.darkSurfaceElevated
                      : AppColors.forestSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: 28,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: AppConstants.spacingMd),
              Text(
                'Examination Not Found',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'This assessment could not be located or you are not enrolled in its course.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                  height: 1.4,
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
        ? DateFormat('EEEE, d MMMM yyyy • h:mm a')
              .format(assessment.scheduledAt!)
        : 'Open Availability Window';

    final qCount = resolvedQuestionCount > 0
        ? resolvedQuestionCount
        : assessment.questionCount;

    final statusColor = _getStatusColor(assessment);
    final statusBgColor = _getStatusBackgroundColor(assessment, isDark);
    final statusBorderColor = _getStatusBorderColor(assessment, isDark);

    return AppCard(
      padding: const EdgeInsets.all(AppConstants.spacingMd + 2),
      borderRadius: AppConstants.radiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course Badge, Type, and Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
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
                            alpha: isDark ? 0.25 : 0.12,
                          ),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        assessment.courseTitle.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: isDark
                              ? AppColors.accentOrangeLight
                              : AppColors.primaryNavy,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
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
                        assessment.type.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Academic Status Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                  border: Border.all(color: statusBorderColor, width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getStatusIcon(assessment),
                      size: 11.5,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4.5),
                    Text(
                      assessment.displayStatus,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingSm + 4),

          // Title
          Text(
            assessment.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 17.5,
              color: isDark ? Colors.white : AppColors.textPrimary,
              height: 1.25,
            ),
          ),
          const SizedBox(height: AppConstants.spacingMd),

          Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
          ),
          const SizedBox(height: AppConstants.spacingMd),

          // Examination Stat Metrics
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricColumn(
                icon: Icons.timer_outlined,
                value: '${assessment.durationMinutes} min',
                label: 'Duration',
                color: AppColors.terracotta,
                isDark: isDark,
              ),
              _buildDivider(isDark),
              _buildMetricColumn(
                icon: Icons.quiz_outlined,
                value: '$qCount Qs',
                label: 'Questions',
                color: isDark
                    ? AppColors.accentOrangeLight
                    : AppColors.primaryNavy,
                isDark: isDark,
              ),
              _buildDivider(isDark),
              _buildMetricColumn(
                icon: Icons.workspace_premium_outlined,
                value: '${assessment.totalMarks} Marks',
                label: 'Pass: ${assessment.passingMarks}',
                color: AppColors.success,
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
          ),
          const SizedBox(height: AppConstants.spacingSm + 2),

          // Schedule Details
          Row(
            children: [
              Icon(
                assessment.isUpcoming
                    ? Icons.schedule_rounded
                    : (assessment.isAvailable
                          ? Icons.event_available_outlined
                          : Icons.calendar_today_rounded),
                size: 14,
                color: assessment.isUpcoming
                    ? AppColors.terracotta
                    : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Scheduled: $scheduleFormatted',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: assessment.isUpcoming
                        ? AppColors.terracotta
                        : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary),
                  ),
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
    required Color color,
    required bool isDark,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      height: 32,
      width: 1,
      color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
    );
  }

  Widget _buildResultCard(
    StudentAssessment assessment,
    bool isDark,
    ThemeData theme,
  ) {
    final completedFormatted = assessment.completedAt != null
        ? DateFormat('EEEE, d MMMM yyyy • h:mm a')
              .format(assessment.completedAt!)
        : 'Completed';

    final isPassed = assessment.isPassed == true;

    return AppCard(
      padding: const EdgeInsets.all(AppConstants.spacingMd + 2),
      borderRadius: AppConstants.radiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isPassed
                      ? (isDark
                            ? AppColors.success.withValues(alpha: 0.15)
                            : AppColors.successSoft)
                      : (isDark
                            ? AppColors.error.withValues(alpha: 0.15)
                            : AppColors.errorSoft),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPassed
                      ? Icons.check_circle_rounded
                      : Icons.info_outline_rounded,
                  size: 16,
                  color: isPassed ? AppColors.success : AppColors.error,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Evaluation Result',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: isPassed
                      ? (isDark
                            ? AppColors.success.withValues(alpha: 0.15)
                            : AppColors.successSoft)
                      : (isDark
                            ? AppColors.error.withValues(alpha: 0.15)
                            : AppColors.errorSoft),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                  border: Border.all(
                    color: isPassed
                        ? AppColors.success.withValues(alpha: 0.3)
                        : AppColors.error.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  isPassed ? 'PASSED' : 'NEEDS REVISION',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: isPassed
                        ? (isDark ? const Color(0xFF6EE7B7) : AppColors.success)
                        : (isDark ? const Color(0xFFFCA5A5) : AppColors.error),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingSm + 2),

          Text(
            'Completed and evaluated on $completedFormatted',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppConstants.spacingMd),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceElevated
                  : AppColors.warmCreamLight,
              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Score Recorded:',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${assessment.score?.toStringAsFixed(1) ?? "0"} / ${assessment.totalMarks} (${assessment.percentage?.toStringAsFixed(0) ?? "0"}%)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isPassed
                        ? (isDark ? const Color(0xFF6EE7B7) : AppColors.success)
                        : (isDark ? const Color(0xFFFCA5A5) : AppColors.error),
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
      padding: const EdgeInsets.all(AppConstants.spacingMd + 2),
      borderRadius: AppConstants.radiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceElevated
                      : AppColors.forestSoft,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                ),
                child: const Icon(
                  Icons.rule_rounded,
                  size: 16,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Examination Guidelines & Protocol',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingMd),

          _buildRuleItem(
            '1',
            'This is a timed assessment (${assessment.durationMinutes} minutes). A real-time timer will count down once started.',
            isDark,
          ),
          _buildRuleItem(
            '2',
            'Select one option per question. You can navigate back and forth to revise answers before final submission.',
            isDark,
          ),
          _buildRuleItem(
            '3',
            'Ensure a stable internet connection. If the timer reaches 00:00, the examination will automatically submit all answered questions.',
            isDark,
          ),
          _buildRuleItem(
            '4',
            'Passing threshold is ${assessment.passingMarks} out of ${assessment.totalMarks} marks (${((assessment.passingMarks / (assessment.totalMarks > 0 ? assessment.totalMarks : 100)) * 100).toStringAsFixed(0)}%).',
            isDark,
          ),
          _buildRuleItem(
            '5',
            'Only one official attempt is permitted. Submissions are permanently saved to your academic transcript.',
            isDark,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem(
    String num,
    String text,
    bool isDark, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceElevated
                  : AppColors.forestSoft,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primaryNavy.withValues(
                  alpha: isDark ? 0.3 : 0.15,
                ),
                width: 0.8,
              ),
            ),
            child: Center(
              child: Text(
                num,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.accentOrangeLight
                      : AppColors.primaryNavy,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(StudentAssessment assessment) {
    if (assessment.isCompleted) {
      return assessment.isPassed == true ? AppColors.success : AppColors.info;
    }
    if (assessment.isUpcoming) {
      return AppColors.terracotta;
    }
    if (assessment.isAvailable) {
      return AppColors.primaryNavy;
    }
    return AppColors.textSecondary;
  }

  Color _getStatusBackgroundColor(StudentAssessment assessment, bool isDark) {
    if (assessment.isCompleted) {
      return assessment.isPassed == true
          ? (isDark
                ? AppColors.success.withValues(alpha: 0.15)
                : AppColors.successSoft)
          : (isDark
                ? AppColors.info.withValues(alpha: 0.18)
                : AppColors.infoSoft);
    }
    if (assessment.isUpcoming) {
      return isDark
          ? AppColors.accentOrange.withValues(alpha: 0.15)
          : AppColors.accentOrangeSoft;
    }
    if (assessment.isAvailable) {
      return isDark
          ? AppColors.primaryNavy.withValues(alpha: 0.25)
          : AppColors.forestSoft;
    }
    return isDark ? AppColors.darkSurfaceElevated : AppColors.warmCream;
  }

  Color _getStatusBorderColor(StudentAssessment assessment, bool isDark) {
    final baseColor = _getStatusColor(assessment);
    return baseColor.withValues(alpha: isDark ? 0.35 : 0.25);
  }

  IconData _getStatusIcon(StudentAssessment assessment) {
    if (assessment.isCompleted) {
      return assessment.isPassed == true
          ? Icons.check_circle_rounded
          : Icons.done_all_rounded;
    }
    if (assessment.isUpcoming) {
      return Icons.schedule_rounded;
    }
    if (assessment.isAvailable) {
      return Icons.play_circle_filled_rounded;
    }
    return Icons.lock_clock_rounded;
  }
}
