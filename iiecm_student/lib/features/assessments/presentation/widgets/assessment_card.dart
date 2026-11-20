import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/models/student_assessment.dart';

/// Modern Academic card representing a clinical examination or MCQ quiz
/// in the Student Examinations & Checkpoints directory.
///
/// Features institutional branding, course taxonomy badges, responsive metadata,
/// completed evaluation banners, and responsive non-overflowing action controls.
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
    final statusBgColor = _getStatusBackgroundColor(assessment, isDark);
    final statusBorderColor = _getStatusBorderColor(assessment, isDark);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      borderRadius: AppConstants.radiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Course Badge, Assessment Type, and Academic Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Institutional Course Badge
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

                    // Assessment Type Tag
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

              // Academic Status Badge
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
          const SizedBox(height: AppConstants.spacingSm + 2),

          // Examination Title
          Text(
            assessment.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 15.5,
              color: isDark ? Colors.white : AppColors.textPrimary,
              height: 1.25,
            ),
          ),

          // Examination Description
          if (assessment.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              assessment.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12.5,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ],

          const SizedBox(height: AppConstants.spacingMd),

          // Metadata Row: Schedule, Duration, Questions & Marks
          Wrap(
            spacing: 14,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Schedule / Availability Pill
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    assessment.isUpcoming
                        ? Icons.schedule_rounded
                        : (assessment.isAvailable
                              ? Icons.event_available_outlined
                              : Icons.calendar_today_rounded),
                    size: 13.5,
                    color: assessment.isUpcoming
                        ? AppColors.terracotta
                        : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    scheduleFormatted,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: assessment.isUpcoming
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: assessment.isUpcoming
                          ? AppColors.terracotta
                          : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary),
                    ),
                  ),
                ],
              ),

              // Duration Pill
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    size: 13.5,
                    color: AppColors.terracotta,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${assessment.durationMinutes} min',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.terracotta,
                    ),
                  ),
                ],
              ),

              // Question Count
              if (assessment.questionCount > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.quiz_outlined,
                      size: 13.5,
                      color: isDark
                          ? AppColors.accentOrangeLight
                          : AppColors.primaryNavy,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${assessment.questionCount} Questions',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.accentOrangeLight
                            : AppColors.primaryNavy,
                      ),
                    ),
                  ],
                ),

              // Total Marks & Passing Threshold
              if (assessment.totalMarks > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.workspace_premium_outlined,
                      size: 13.5,
                      color: isDark
                          ? AppColors.accentOrangeLight
                          : AppColors.primaryNavy,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${assessment.totalMarks} Marks (Pass: ${assessment.passingMarks})',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.accentOrangeLight
                            : AppColors.primaryNavy,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Completed Evaluation Score Summary Banner
          if (assessment.isCompleted) ...[
            const SizedBox(height: AppConstants.spacingSm + 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: assessment.isPassed == true
                    ? (isDark
                          ? AppColors.success.withValues(alpha: 0.15)
                          : AppColors.successSoft)
                    : (isDark
                          ? AppColors.error.withValues(alpha: 0.15)
                          : AppColors.errorSoft),
                borderRadius: BorderRadius.circular(AppConstants.radiusSm + 2),
                border: Border.all(
                  color: assessment.isPassed == true
                      ? AppColors.success.withValues(alpha: 0.3)
                      : AppColors.error.withValues(alpha: 0.3),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    assessment.isPassed == true
                        ? Icons.check_circle_rounded
                        : Icons.info_outline_rounded,
                    size: 14.5,
                    color: assessment.isPassed == true
                        ? AppColors.success
                        : AppColors.error,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'Score: ${assessment.score?.toStringAsFixed(1) ?? "0"} / ${assessment.totalMarks} (${assessment.percentage?.toStringAsFixed(0) ?? "0"}%)',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: assessment.isPassed == true
                            ? (isDark
                                  ? const Color(0xFF6EE7B7)
                                  : AppColors.success)
                            : (isDark
                                  ? const Color(0xFFFCA5A5)
                                  : AppColors.error),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppConstants.spacingMd),
          Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
          ),
          const SizedBox(height: AppConstants.spacingMd - 2),

          // Action Section: Status Indicator & Button (Responsive Wrap prevents RenderFlex overflow)
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              runAlignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppConstants.spacingSm,
              runSpacing: AppConstants.spacingSm + 2,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7.5,
                      height: 7.5,
                      decoration: BoxDecoration(
                        color: assessment.isCompleted
                            ? (assessment.isPassed == true
                                  ? AppColors.success
                                  : AppColors.info)
                            : (assessment.isUpcoming
                                  ? AppColors.terracotta
                                  : (assessment.isAvailable
                                        ? AppColors.primaryNavy
                                        : AppColors.textSecondary)),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      assessment.isCompleted
                          ? 'Evaluation Recorded'
                          : (assessment.isUpcoming
                                ? 'Scheduled Checkpoint'
                                : (assessment.isAvailable
                                      ? 'Examination Open'
                                      : 'Assessment Inactive')),
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

                // Action Button: Preserves exact text labels 'View Evaluation', 'Start Examination', 'View Schedule'
                AppButton(
                  label: assessment.isCompleted
                      ? 'View Evaluation'
                      : (assessment.isAvailable
                            ? 'Start Examination'
                            : 'View Schedule'),
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
