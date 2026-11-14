import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/models/student_assignment.dart';

/// Institutional card representing a clinical assignment or project in the Assignments list
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

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Course / Project Type Tag & Status Badge
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
                        assignment.courseTitle.toUpperCase(),
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
                    if (assignment.isProject)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkBackground : AppColors.warmCream,
                          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.border,
                          ),
                        ),
                        child: const Text(
                          'CLINICAL PROJECT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.terracotta,
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
                      _getStatusIcon(assignment),
                      size: 11,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
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
          const SizedBox(height: AppConstants.spacingSm),

          // Assignment Title
          Text(
            assignment.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              height: 1.25,
            ),
          ),

          if (assignment.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              assignment.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ],

          const SizedBox(height: AppConstants.spacingMd),

          // Metadata Row: Deadline & Marks
          Wrap(
            spacing: 12,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.alarm_rounded,
                    size: 13,
                    color: assignment.isOverdue
                        ? AppColors.error
                        : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Due: $deadlineFormatted',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: assignment.isOverdue ? FontWeight.w700 : FontWeight.w500,
                      color: assignment.isOverdue
                          ? AppColors.error
                          : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.grade_outlined,
                    size: 13,
                    color: AppColors.primaryForest,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${assignment.totalMarks} Marks (Pass: ${assignment.passingMarks})',
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

          // If evaluated, show score banner
          if (assignment.isGraded) ...[
            const SizedBox(height: AppConstants.spacingSm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: assignment.isPassed == true
                    ? AppColors.successSoft
                    : AppColors.errorSoft,
                borderRadius: BorderRadius.circular(AppConstants.radiusSm),
              ),
              child: Row(
                children: [
                  Icon(
                    assignment.isPassed == true
                        ? Icons.check_circle_rounded
                        : Icons.error_outline_rounded,
                    size: 14,
                    color: assignment.isPassed == true
                        ? AppColors.success
                        : AppColors.error,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Awarded: ${assignment.score?.toStringAsFixed(1) ?? "0"} / ${assignment.totalMarks} (${assignment.percentage?.toStringAsFixed(0) ?? "0"}%)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: assignment.isPassed == true
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
                label: assignment.isSubmitted ? 'View Submission' : 'Open Assignment',
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

