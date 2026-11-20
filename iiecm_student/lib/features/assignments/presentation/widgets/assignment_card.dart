import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/models/student_assignment.dart';

/// Modern Academic card representing a clinical assignment or practical project
/// in the Student Assignments & Case Studies directory.
///
/// Features institutional branding, course taxonomy badges, responsive metadata,
/// evaluated score/feedback banners, and responsive non-overflowing action controls.
class AssignmentCard extends StatelessWidget {
  final StudentAssignment assignment;
  final VoidCallback onTap;

  const AssignmentCard({
    super.key,
    required this.assignment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final deadlineFormatted = assignment.deadline != null
        ? DateFormat('EEE, d MMM yyyy • h:mm a').format(assignment.deadline!)
        : 'No specific deadline';

    final statusColor = _getStatusColor(assignment);
    final statusBgColor = _getStatusBackgroundColor(assignment, isDark);
    final statusBorderColor = _getStatusBorderColor(assignment, isDark);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      borderRadius: AppConstants.radiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Course Badge, Project Tag, and Academic Status Badge
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
                        assignment.courseTitle.toUpperCase(),
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

                    // Clinical Project Tag
                    if (assignment.isProject)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkBackground
                              : AppColors.accentOrangeSoft,
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusSm,
                          ),
                          border: Border.all(
                            color: AppColors.accentOrange.withValues(
                              alpha: isDark ? 0.35 : 0.25,
                            ),
                            width: 0.8,
                          ),
                        ),
                        child: const Text(
                          'CLINICAL PROJECT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                            color: AppColors.terracotta,
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
                      _getStatusIcon(assignment),
                      size: 11.5,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4.5),
                    Text(
                      assignment.displayStatus,
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

          // Assignment Title
          Text(
            assignment.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 15.5,
              color: isDark ? Colors.white : AppColors.textPrimary,
              height: 1.25,
            ),
          ),

          // Assignment Brief Description
          if (assignment.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              assignment.description,
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

          // Metadata Row: Due Date & Total Marks
          Wrap(
            spacing: 14,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Deadline Pill
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    assignment.isOverdue
                        ? Icons.alarm_off_rounded
                        : Icons.event_available_outlined,
                    size: 13.5,
                    color: assignment.isOverdue
                        ? AppColors.error
                        : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Due: $deadlineFormatted',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: assignment.isOverdue
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: assignment.isOverdue
                          ? AppColors.error
                          : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary),
                    ),
                  ),
                ],
              ),

              // Total Marks & Passing Threshold
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
                  const SizedBox(width: 5),
                  Text(
                    '${assignment.totalMarks} Marks (Pass: ${assignment.passingMarks})',
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

          // Graded Evaluation Score Banner (when graded)
          if (assignment.isGraded) ...[
            const SizedBox(height: AppConstants.spacingSm + 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: assignment.isPassed == true
                    ? (isDark
                          ? AppColors.success.withValues(alpha: 0.15)
                          : AppColors.successSoft)
                    : (isDark
                          ? AppColors.error.withValues(alpha: 0.15)
                          : AppColors.errorSoft),
                borderRadius: BorderRadius.circular(AppConstants.radiusSm + 2),
                border: Border.all(
                  color: assignment.isPassed == true
                      ? AppColors.success.withValues(alpha: 0.3)
                      : AppColors.error.withValues(alpha: 0.3),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    assignment.isPassed == true
                        ? Icons.check_circle_rounded
                        : Icons.error_outline_rounded,
                    size: 14.5,
                    color: assignment.isPassed == true
                        ? AppColors.success
                        : AppColors.error,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'Awarded: ${assignment.score?.toStringAsFixed(1) ?? "0"} / ${assignment.totalMarks} (${assignment.percentage?.toStringAsFixed(0) ?? "0"}%)',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: assignment.isPassed == true
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

          // Faculty Feedback Callout (when feedback is provided)
          if (assignment.feedback != null &&
              assignment.feedback!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceElevated
                    : AppColors.warmCreamLight,
                borderRadius: BorderRadius.circular(AppConstants.radiusSm + 2),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
                  width: 0.8,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.rate_review_outlined,
                    size: 13,
                    color: AppColors.terracotta,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Feedback: "${assignment.feedback!}"',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                        height: 1.3,
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
                        color: assignment.isSubmitted
                            ? (isDark
                                  ? AppColors.accentOrange
                                  : AppColors.primaryNavy)
                            : (assignment.isOverdue
                                  ? AppColors.error
                                  : AppColors.accentOrange),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      assignment.isSubmitted
                          ? 'Submission Recorded'
                          : (assignment.isOverdue
                                ? 'Action Past Due'
                                : 'Submission Required'),
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

                // Action Button: Preserves exact text labels 'View Submission' and 'Open Assignment'
                AppButton(
                  label: assignment.isSubmitted
                      ? 'View Submission'
                      : 'Open Assignment',
                  icon: assignment.isSubmitted
                      ? Icons.visibility_outlined
                      : Icons.assignment_turned_in_outlined,
                  isFullWidth: false,
                  height: 38,
                  variant: assignment.isSubmitted
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

  Color _getStatusColor(StudentAssignment assignment) {
    if (assignment.isGraded) {
      return assignment.isPassed == true ? AppColors.success : AppColors.error;
    }
    if (assignment.isSubmitted) {
      return AppColors.info;
    }
    if (assignment.isOverdue) {
      return AppColors.error;
    }
    return AppColors.warning;
  }

  Color _getStatusBackgroundColor(StudentAssignment assignment, bool isDark) {
    if (assignment.isGraded) {
      return assignment.isPassed == true
          ? (isDark
                ? AppColors.success.withValues(alpha: 0.15)
                : AppColors.successSoft)
          : (isDark
                ? AppColors.error.withValues(alpha: 0.15)
                : AppColors.errorSoft);
    }
    if (assignment.isSubmitted) {
      return isDark
          ? AppColors.info.withValues(alpha: 0.18)
          : AppColors.infoSoft;
    }
    if (assignment.isOverdue) {
      return isDark
          ? AppColors.error.withValues(alpha: 0.15)
          : AppColors.errorSoft;
    }
    return isDark
        ? AppColors.warning.withValues(alpha: 0.15)
        : AppColors.warningSoft;
  }

  Color _getStatusBorderColor(StudentAssignment assignment, bool isDark) {
    final baseColor = _getStatusColor(assignment);
    return baseColor.withValues(alpha: isDark ? 0.35 : 0.25);
  }

  IconData _getStatusIcon(StudentAssignment assignment) {
    if (assignment.isGraded) {
      return assignment.isPassed == true
          ? Icons.check_circle_rounded
          : Icons.warning_amber_rounded;
    }
    if (assignment.isSubmitted) {
      return Icons.task_alt_rounded;
    }
    if (assignment.isOverdue) {
      return Icons.error_outline_rounded;
    }
    return Icons.pending_actions_rounded;
  }
}
