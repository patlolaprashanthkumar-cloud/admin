import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/models/student_result.dart';
import '../providers/results_provider.dart';

/// Modern Academic individual examination result detail and transcript screen
///
/// Features institutional credential styling, responsive score presentation,
/// evaluation metric breakdown, conditional feedback panels, and academic integrity safeguards.
class ResultDetailScreen extends ConsumerWidget {
  final String resultId;

  const ResultDetailScreen({super.key, required this.resultId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // First check in-memory list from studentResultsNotifierProvider for instant display
    final resultsState = ref.watch(studentResultsNotifierProvider);
    final cachedResult = resultsState.results
        .where((r) => r.id == resultId)
        .firstOrNull;

    final asyncResult = ref.watch(studentResultDetailProvider(resultId));

    final StudentResult? result = cachedResult ?? asyncResult.valueOrNull;

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
        title: const Text('Examination Transcript'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Refresh Transcript',
            icon: const Icon(Icons.refresh_rounded),
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            onPressed: () => ref.refresh(studentResultDetailProvider(resultId)),
          ),
          const SizedBox(width: AppConstants.spacingSm),
        ],
      ),
      body: SafeArea(
        child: asyncResult.isLoading && result == null
            ? _buildLoadingView(isDark)
            : asyncResult.hasError && result == null
            ? _buildErrorView(context, ref, asyncResult.error.toString())
            : result == null
            ? _buildNotFoundView(context)
            : _buildContent(context, result, isDark, theme),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    StudentResult result,
    bool isDark,
    ThemeData theme,
  ) {
    final isPassed = result.passed;
    final isEvaluated = result.isEvaluated;
    final dateFormatted = DateFormat('dd MMMM yyyy, hh:mm a')
        .format(result.completedAt);

    final Color statusColor;
    final Color statusBgColor;
    final Color statusBorderColor;
    final IconData statusIcon;

    if (!isEvaluated) {
      statusColor = AppColors.warning;
      statusBgColor = isDark
          ? AppColors.darkSurfaceElevated
          : AppColors.warningSoft;
      statusBorderColor = AppColors.warning.withValues(
        alpha: isDark ? 0.35 : 0.25,
      );
      statusIcon = Icons.hourglass_top_rounded;
    } else if (isPassed) {
      statusColor = AppColors.success;
      statusBgColor = isDark
          ? AppColors.darkSurfaceElevated
          : AppColors.successSoft;
      statusBorderColor = AppColors.success.withValues(
        alpha: isDark ? 0.35 : 0.25,
      );
      statusIcon = Icons.check_circle_rounded;
    } else {
      statusColor = AppColors.error;
      statusBgColor = isDark
          ? AppColors.darkSurfaceElevated
          : AppColors.errorSoft;
      statusBorderColor = AppColors.error.withValues(
        alpha: isDark ? 0.35 : 0.25,
      );
      statusIcon = Icons.cancel_rounded;
    }

    return ListView(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      children: [
        // 1. Performance Hero Banner
        AppCard(
          backgroundColor: isDark
              ? AppColors.darkSurfaceElevated
              : AppColors.white,
          borderRadius: AppConstants.radiusLg,
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          child: Column(
            children: [
              // Type and Status Header
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
                                ? AppColors.darkBackground
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
                            result.type.displayName.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                              color: isDark
                                  ? AppColors.accentOrangeLight
                                  : AppColors.primaryNavy,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusSm,
                      ),
                      border: Border.all(color: statusBorderColor, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 13, color: statusColor),
                        const SizedBox(width: 4.5),
                        Text(
                          result.displayStatus,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingLg),

              // Academic Seal / Grade Indicator
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? AppColors.darkSurface
                      : (isPassed
                            ? AppColors.successSoft
                            : AppColors.terracottaSoft),
                  border: Border.all(
                    color: (isPassed ? AppColors.success : AppColors.terracotta)
                        .withValues(alpha: isDark ? 0.6 : 0.75),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (isPassed ? AppColors.success : AppColors.terracotta)
                              .withValues(alpha: isDark ? 0.2 : 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        result.formattedPercentage,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: isPassed
                              ? (isDark
                                    ? const Color(0xFFA5D6A7)
                                    : AppColors.success)
                              : (isDark
                                    ? AppColors.accentOrangeLight
                                    : AppColors.terracotta),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'GRADE',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingMd),

              // Examination Title
              Text(
                result.title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 6),

              // Course Taxonomy
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 14,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      result.courseTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppConstants.spacingMd),

        // 2. Score Breakdown Card
        AppCard(
          borderRadius: AppConstants.radiusLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkBackground
                          : AppColors.forestSoft,
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusSm,
                      ),
                    ),
                    child: const Icon(
                      Icons.analytics_outlined,
                      size: 16,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Evaluation Metrics',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingMd),
              _buildMetricRow(
                'Marks Obtained',
                result.score.toStringAsFixed(1),
                statusColor,
                isDark,
              ),
              _buildDivider(isDark),
              _buildMetricRow(
                'Total Possible Marks',
                result.totalMarks.toStringAsFixed(0),
                null,
                isDark,
              ),
              if (result.passingMarks != null) ...[
                _buildDivider(isDark),
                _buildMetricRow(
                  'Passing Threshold',
                  '${result.passingMarks} Marks',
                  null,
                  isDark,
                ),
              ],
              _buildDivider(isDark),
              _buildMetricRow(
                'Overall Percentage',
                result.formattedPercentage,
                null,
                isDark,
              ),
              _buildDivider(isDark),
              _buildMetricRow('Date Recorded', dateFormatted, null, isDark),
            ],
          ),
        ),
        const SizedBox(height: AppConstants.spacingMd),

        // 3. Faculty Feedback Section (if present)
        if (result.feedback != null && result.feedback!.isNotEmpty) ...[
          AppCard(
            borderRadius: AppConstants.radiusLg,
            backgroundColor: isDark
                ? AppColors.darkSurfaceElevated
                : AppColors.forestSoft.withValues(alpha: 0.35),
            borderColor: AppColors.primaryNavy.withValues(
              alpha: isDark ? 0.3 : 0.15,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkBackground
                            : AppColors.forestSoft,
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusSm,
                        ),
                      ),
                      child: const Icon(
                        Icons.feedback_outlined,
                        size: 16,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Faculty Mentor Feedback',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: isDark
                            ? AppColors.accentOrangeLight
                            : AppColors.primaryNavy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingSm + 2),
                Text(
                  result.feedback!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.45,
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spacingMd),
        ],

        // 4. Student Submission Notes (for assignments if present)
        if (result.submissionNotes != null &&
            result.submissionNotes!.isNotEmpty) ...[
          AppCard(
            borderRadius: AppConstants.radiusLg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceElevated
                            : AppColors.forestSoft,
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusSm,
                        ),
                      ),
                      child: Icon(
                        Icons.notes_rounded,
                        size: 16,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Student Submission Remarks',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingSm + 2),
                Text(
                  result.submissionNotes!,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spacingMd),
        ],

        // 5. Academic Integrity & Examination Safeguard Card
        Container(
          padding: const EdgeInsets.all(AppConstants.spacingMd),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.warmCreamLight,
            borderRadius: BorderRadius.circular(AppConstants.radiusLg),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceElevated
                      : AppColors.forestSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  size: 18,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Official Examination Record',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      result.type.isAssessment
                          ? 'This digital transcript confirms the completion of ${result.answeredQuestionsCount ?? "all"} questions in accordance with IIECM examination protocols. Secure answer keys are safeguarded by the Examination Registry.'
                          : 'This transcript confirms the evaluation of your submitted clinical assignment by the faculty examination board.',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricRow(
    String label,
    String value,
    Color? valueColor,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color:
                    valueColor ??
                    (isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
    );
  }

  Widget _buildLoadingView(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            strokeWidth: 2.2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryNavy),
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Text(
            'Retrieving transcript...',
            style: TextStyle(
              fontSize: 12.5,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: AppColors.errorSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 36,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            const Text(
              'Error Loading Result',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: AppConstants.spacingLg),
            AppButton(
              label: 'Retry',
              icon: Icons.refresh_rounded,
              isFullWidth: false,
              height: 40,
              onPressed: () =>
                  ref.refresh(studentResultDetailProvider(resultId)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: AppColors.terracottaSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 36,
                color: AppColors.terracotta,
              ),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            const Text(
              'Result Record Not Found',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              'The requested examination record does not exist or you do not have permission to access it.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: AppConstants.spacingLg),
            AppButton(
              label: 'Back to Results',
              icon: Icons.arrow_back_rounded,
              isFullWidth: false,
              height: 40,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
