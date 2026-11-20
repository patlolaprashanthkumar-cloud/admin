import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/models/student_payment.dart';

/// Modern Academic card representing an institutional fee transaction or receipt
/// in the Student Fee Status & Receipts portal.
class PaymentCard extends StatelessWidget {
  final StudentPayment payment;
  final VoidCallback onTap;

  const PaymentCard({super.key, required this.payment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dateFormatted = DateFormat('dd MMM yyyy').format(payment.paymentDate);

    final Color statusColor;
    final Color statusBgColor;
    final Color statusBorderColor;
    final IconData statusIcon;

    if (payment.isVerified) {
      statusColor = AppColors.success;
      statusBgColor = isDark
          ? AppColors.darkSurfaceElevated
          : AppColors.successSoft;
      statusBorderColor = AppColors.success.withValues(
        alpha: isDark ? 0.35 : 0.25,
      );
      statusIcon = Icons.check_circle_rounded;
    } else if (payment.isPending) {
      statusColor = AppColors.warning;
      statusBgColor = isDark
          ? AppColors.darkSurfaceElevated
          : AppColors.warningSoft;
      statusBorderColor = AppColors.warning.withValues(
        alpha: isDark ? 0.35 : 0.25,
      );
      statusIcon = Icons.hourglass_top_rounded;
    } else if (payment.isRefunded) {
      statusColor = AppColors.info;
      statusBgColor = isDark
          ? AppColors.darkSurfaceElevated
          : AppColors.infoSoft;
      statusBorderColor = AppColors.info.withValues(
        alpha: isDark ? 0.35 : 0.25,
      );
      statusIcon = Icons.replay_rounded;
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
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      borderRadius: AppConstants.radiusLg,
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Receipt Number Badge & Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Receipt Number Badge
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_outlined,
                            size: 13,
                            color: isDark
                                ? AppColors.accentOrangeLight
                                : AppColors.primaryNavy,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            payment.receiptNumber,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'monospace',
                              color: isDark
                                  ? AppColors.accentOrangeLight
                                  : AppColors.primaryNavy,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                  border: Border.all(color: statusBorderColor, width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 11.5, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      payment.displayStatus,
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
          const SizedBox(height: AppConstants.spacingSm + 2),

          // Amount & Payment Method Row (Responsive Wrap)
          Wrap(
            spacing: 12,
            runSpacing: 4,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                payment.formattedAmount,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 19,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceElevated
                      : AppColors.warmCreamLight,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.borderSubtle,
                    width: 0.8,
                  ),
                ),
                child: Text(
                  payment.formattedMethod,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Purpose / Course Name
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
                  payment.purposeDescription,
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

          // Footer: Transaction Ref & Date (Responsive Wrap)
          Wrap(
            spacing: 12,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ref: ',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    payment.transactionRef,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 12.5,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4.5),
                  Text(
                    dateFormatted,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
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
