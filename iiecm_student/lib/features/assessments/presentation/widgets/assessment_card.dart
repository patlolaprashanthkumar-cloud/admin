import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/models/student_assessment.dart';

/// Clean institutional card representing a clinical examination or quiz
class AssessmentCard extends StatelessWidget {
  final StudentAssessment assessment;
  final VoidCallback onTap;

  const AssessmentCard({
    super.key,
    required this.assessment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final scheduleFormatted = assessment.scheduledAt != null
        ? DateFormat('EEE, d MMM yyyy • h:mm a').format(assessment.scheduledAt!)
        : 'Open Availability';

    final statusColor = _getStatusColor(assessment);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Course Tag & Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceElevated : AppColors.forestSoft,
                        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                      ),
                      child: Text(
                        assessment.courseTitle.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: AppColors.primaryForest,
                        ),
                      ),
                    ),
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
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getStatusIcon(assessment),
                      size: 11,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
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
          const SizedBox(height: AppConstants.spacingSm),

          // Title
          Text(
            assessment.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              height: 1.25,
            ),
          ),

          if (assessment.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              assessment.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ],

          const SizedBox(height: AppConstants.spacingMd),

          // Metadata Row: Schedule, Duration & Questions
          Wrap(
            spacing: 12,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 13,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    scheduleFormatted,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_outlined, size: 13, color: AppColors.terracotta),
                  const SizedBox(width: 4),
                  Text(
                    '${assessment.durationMinutes} min',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.terracotta,
                    ),
                  ),
                ],
              ),
              if (assessment.questionCount > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.quiz_outlined, size: 13, color: AppColors.primaryForest),
                    const SizedBox(width: 4),
                    Text(
                      '${assessment.questionCount} Questions',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryForest,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // If completed, show score summary banner
          if (assessment.isCompleted) ...[
            const SizedBox(height: AppConstants.spacingSm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: assessment.isPassed == true
                    ? AppColors.successSoft
                    : AppColors.errorSoft,
                borderRadius: BorderRadius.circular(AppConstants.radiusSm),
              ),
              child: Row(
                children: [
                  Icon(
                    assessment.isPassed == true
                        ? Icons.check_circle_rounded
                        : Icons.info_outline_rounded,
                    size: 14,
                    color: assessment.isPassed == true
                        ? AppColors.success
                        : AppColors.error,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Score: ${assessment.score?.toStringAsFixed(1) ?? "0"} / ${assessment.totalMarks} (${assessment.percentage?.toStringAsFixed(0) ?? "0"}%)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: assessment.isPassed == true
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppConstants.spacingMd),

          // Action Button
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton(
                label: assessment.isCompleted
                    ? 'View Evaluation'
                    : (assessment.isAvailable ? 'Start Examination' : 'View Schedule'),
                icon: assessment.isCompleted
                    ? Icons.verified_outlined
                    : (assessment.isAvailable
                        ? Icons.play_arrow_rounded
                        : Icons.event_note_rounded),
                isFullWidth: false,
                height: 38,
                variant: assessment.isCompleted
                    ? AppButtonVariant.outline
                    : AppButtonVariant.primary,
                onPressed: onTap,
              ),
            ],
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
      return AppColors.primaryForest;
    }
    return AppColors.textSecondary;
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

