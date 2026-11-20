import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/models/student_result.dart';

/// Modern Academic card representing an academic examination or clinical assignment result
/// in the Student Academic Results portal.
class ResultCard extends StatelessWidget {
  final StudentResult result;
  final VoidCallback onTap;

  const ResultCard({super.key, required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dateFormatted = DateFormat('dd MMM yyyy').format(result.completedAt);

    final isPassed = result.passed;
    final isEvaluated = result.isEvaluated;

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

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      borderRadius: AppConstants.radiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Type Badge, Status Badge & Percentage Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Result Type Badge
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

                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusSm,
                        ),
                        border: Border.all(
                          color: statusBorderColor,
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 11.5, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            result.displayStatus,
                            style: TextStyle(
                              fontSize: 10,
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
              ),
              const SizedBox(width: 8),

              // Percentage Pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceElevated
                      : (isPassed
                            ? AppColors.successSoft
                            : AppColors.terracottaSoft),
                  borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                  border: Border.all(
                    color: (isPassed ? AppColors.success : AppColors.terracotta)
                        .withValues(alpha: isDark ? 0.4 : 0.5),
                    width: 1.0,
                  ),
                ),
                child: Text(
                  result.formattedPercentage,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isPassed
                        ? (isDark ? const Color(0xFFA5D6A7) : AppColors.success)
                        : (isDark
                              ? AppColors.accentOrangeLight
                              : AppColors.terracotta),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingSm + 2),

          // Examination or Assignment Title
          Text(
            result.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 15.5,
              color: isDark ? Colors.white : AppColors.textPrimary,
              height: 1.25,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),

          // Course Taxonomy Row
          Row(
            children: [
              Icon(
                Icons.school_outlined,
                size: 13.5,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  result.courseTitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingSm),
          Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
          ),
          const SizedBox(height: AppConstants.spacingSm + 2),

          // Bottom Details: Score & Completion Date (Responsive Wrap)
          Wrap(
            spacing: 12,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Score breakdown
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkBackground
                          : AppColors.forestSoft,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.military_tech_outlined,
                      size: 13,
                      color: isDark
                          ? AppColors.accentOrangeLight
                          : AppColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Score: ',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    result.formattedScore,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                ],
              ),

              // Date & Details Arrow
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.event_available_outlined,
                    size: 13.5,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    dateFormatted,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textMuted,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
