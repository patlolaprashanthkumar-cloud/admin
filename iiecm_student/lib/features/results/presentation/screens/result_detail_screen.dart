import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/models/student_result.dart';
import '../providers/results_provider.dart';

class ResultDetailScreen extends ConsumerWidget {
  final String resultId;

  const ResultDetailScreen({
    super.key,
    required this.resultId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // First check in-memory list from studentResultsNotifierProvider for instant display
    final resultsState = ref.watch(studentResultsNotifierProvider);
    final cachedResult = resultsState.results.where((r) => r.id == resultId).firstOrNull;

    final asyncResult = ref.watch(studentResultDetailProvider(resultId));

    final StudentResult? result = cachedResult ?? asyncResult.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Examination Transcript'),
      ),
      body: SafeArea(
        child: asyncResult.isLoading && result == null
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryForest),
                ),
              )
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
    final dateFormatted =
        DateFormat('dd MMMM yyyy, hh:mm a').format(result.completedAt);

    final statusColor = isPassed ? AppColors.success : AppColors.error;
    final statusBgColor = isPassed ? AppColors.successSoft : AppColors.errorSoft;

    return ListView(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      children: [
        // 1. Performance Hero Banner
        AppCard(
          backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.white,
          child: Column(
            children: [
              // Type and Status Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.forestSoft,
                      borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                    ),
                    child: Text(
                      result.type.displayName.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryForest,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPassed ? Icons.check_circle_rounded : Icons.cancel_rounded,
                          size: 14,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          result.displayStatus,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingLg),

              // Large Percentage Indicator
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? AppColors.darkSurface : AppColors.forestSoft,
                  border: Border.all(
                    color: isPassed ? AppColors.primaryForest : AppColors.terracotta,
                    width: 3,
                  ),
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
                          color: isPassed ? AppColors.primaryForest : AppColors.terracotta,
                        ),
                      ),
                      const Text(
                        'GRADE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingMd),

              // Title and Course
              Text(
                result.title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                result.courseTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppConstants.spacingMd),

        // 2. Score Breakdown Card
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Evaluation Metrics',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppConstants.spacingMd),
              _buildMetricRow('Marks Obtained', result.score.toStringAsFixed(1), statusColor),
              _buildDivider(),
              _buildMetricRow('Total Possible Marks', result.totalMarks.toStringAsFixed(0), null),
              if (result.passingMarks != null) ...[
                _buildDivider(),
                _buildMetricRow('Passing Threshold', '${result.passingMarks} Marks', null),
              ],
              _buildDivider(),
              _buildMetricRow('Overall Percentage', result.formattedPercentage, null),
              _buildDivider(),
              _buildMetricRow('Date Recorded', dateFormatted, null),
            ],
          ),
        ),
        const SizedBox(height: AppConstants.spacingMd),

        // 3. Faculty Feedback Section (if present)
        if (result.feedback != null && result.feedback!.isNotEmpty) ...[
          AppCard(
            backgroundColor: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFF0F7F4),
            borderColor: AppColors.primaryForest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.feedback_outlined, size: 18, color: AppColors.primaryForest),
                    SizedBox(width: 8),
                    Text(
                      'Faculty Mentor Feedback',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.primaryForest,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingSm),
                Text(
                  result.feedback!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spacingMd),
        ],

        // 4. Student Submission Notes (for assignments if present)
        if (result.submissionNotes != null && result.submissionNotes!.isNotEmpty) ...[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.notes_rounded, size: 18, color: AppColors.textSecondary),
                    SizedBox(width: 8),
                    Text(
                      'Student Submission Remarks',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingSm),
                Text(
                  result.submissionNotes!,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.verified_user_outlined,
                size: 20,
                color: AppColors.primaryForest,
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Official Examination Record',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: AppColors.primaryForest,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      result.type.isAssessment
                          ? 'This digital transcript confirms the completion of ${result.answeredQuestionsCount ?? "all"} questions in accordance with IIECM examination protocols. Secure answer keys are safeguarded by the Examination Registry.'
                          : 'This transcript confirms the evaluation of your submitted clinical assignment by the faculty examination board.',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
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

  Widget _buildMetricRow(String label, String value, Color? valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1);
  }

  Widget _buildErrorView(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 44, color: AppColors.error),
            const SizedBox(height: AppConstants.spacingSm),
            const Text(
              'Error Loading Result',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            AppButton(
              label: 'Retry',
              icon: Icons.refresh_rounded,
              isFullWidth: false,
              height: 38,
              onPressed: () => ref.refresh(studentResultDetailProvider(resultId)),
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
            const Icon(Icons.search_off_rounded, size: 44, color: AppColors.textSecondary),
            const SizedBox(height: AppConstants.spacingSm),
            const Text(
              'Result Record Not Found',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 4),
            const Text(
              'The requested examination record does not exist or you do not have permission to access it.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            AppButton(
              label: 'Back to Results',
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
}

