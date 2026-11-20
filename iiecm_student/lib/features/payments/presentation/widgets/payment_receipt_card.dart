import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../domain/models/student_payment.dart';

/// Modern Academic digital receipt certificate card representing an authoritative
/// institutional fee payment voucher for IIECM students.
class PaymentReceiptCard extends StatelessWidget {
  final StudentPayment payment;

  const PaymentReceiptCard({super.key, required this.payment});

  void _copyReceiptToClipboard(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final formattedDate = dateFormat.format(payment.paymentDate);

    final receiptText =
        '''
======================================================
INDIAN INSTITUTE OF EMERGENCY & CRITICAL CARE MEDICINE
OFFICIAL DIGITAL FEE RECEIPT
======================================================
Receipt No:     ${payment.receiptNumber}
Transaction ID: ${payment.transactionRef}
Date & Time:    $formattedDate
Student Name:   ${payment.studentName}
Registration:   ${payment.studentCode ?? 'ENROLLED'}
Particulars:    ${payment.purposeDescription}
Payment Method: ${payment.formattedMethod}
Amount Paid:    ${payment.formattedAmount} (${payment.currency})
Status:         ${payment.displayStatus}
======================================================
Generated via IIECM Student Academic Portal
''';

    Clipboard.setData(ClipboardData(text: receiptText));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Receipt details copied to clipboard.'),
        duration: Duration(seconds: 2),
        backgroundColor: AppColors.primaryNavy,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final formattedDate = dateFormat.format(payment.paymentDate);

    final isVerified = payment.isVerified;
    final isPending = payment.isPending;
    final isRefunded = payment.isRefunded;

    final Color statusColor;
    final Color statusBgColor;
    final Color statusBorderColor;
    final IconData statusIcon;

    if (isVerified) {
      statusColor = AppColors.success;
      statusBgColor = isDark
          ? AppColors.darkSurfaceElevated
          : AppColors.successSoft;
      statusBorderColor = AppColors.success.withValues(
        alpha: isDark ? 0.35 : 0.25,
      );
      statusIcon = Icons.check_circle_rounded;
    } else if (isPending) {
      statusColor = AppColors.warning;
      statusBgColor = isDark
          ? AppColors.darkSurfaceElevated
          : AppColors.warningSoft;
      statusBorderColor = AppColors.warning.withValues(
        alpha: isDark ? 0.35 : 0.25,
      );
      statusIcon = Icons.hourglass_top_rounded;
    } else if (isRefunded) {
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

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(
          color: isVerified
              ? AppColors.primaryNavy.withValues(alpha: isDark ? 0.4 : 0.3)
              : (isDark ? AppColors.darkBorder : AppColors.border),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Institutional Banner Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceElevated
                  : AppColors.forestSoft,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppConstants.radiusLg - 1),
                topRight: Radius.circular(AppConstants.radiusLg - 1),
              ),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // Institutional Crest / Seal
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryNavy,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.accentOrange.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryNavy.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'IIECM',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Indian Institute of Emergency & Critical Care Medicine',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                          color: isDark ? Colors.white : AppColors.primaryNavy,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Apex Academic Institute of Critical Care & Emergency Medicine',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Receipt Title & Reference Section
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingMd,
              vertical: 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Indicator Row: Official Label & Academic Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified_outlined,
                          size: 14,
                          color: AppColors.primaryNavy,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'OFFICIAL FEE RECEIPT',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: isDark
                                ? AppColors.accentOrangeLight
                                : AppColors.primaryNavy,
                          ),
                        ),
                      ],
                    ),
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
                            payment.displayStatus,
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

                // Monospace Receipt Number Display
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkBackground
                        : AppColors.warmCreamLight,
                    borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.borderSubtle,
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        payment.receiptNumber,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      Icon(
                        Icons.tag_rounded,
                        size: 16,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Divider(
                  height: 1,
                  color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
                ),
                const SizedBox(height: 6),

                // 3. Responsive Key Receipt Details Table
                _buildReceiptRow(
                  'Transaction Ref',
                  payment.transactionRef,
                  isDark,
                  isMonospace: true,
                ),
                _buildReceiptRow('Receipt Date & Time', formattedDate, isDark),
                _buildReceiptRow(
                  'Student Legal Name',
                  payment.studentName,
                  isDark,
                ),
                if (payment.studentCode != null &&
                    payment.studentCode!.isNotEmpty)
                  _buildReceiptRow(
                    'Student Reg ID',
                    payment.studentCode!,
                    isDark,
                    isMonospace: true,
                  ),
                _buildReceiptRow(
                  'Payment Method',
                  payment.formattedMethod,
                  isDark,
                ),
                _buildReceiptRow(
                  'Fee Description',
                  payment.purposeDescription,
                  isDark,
                ),
                if (payment.verifiedBy != null &&
                    payment.verifiedBy!.isNotEmpty)
                  _buildReceiptRow('Verified By', payment.verifiedBy!, isDark),

                const SizedBox(height: 6),
                Divider(
                  height: 1,
                  color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
                ),
                const SizedBox(height: 10),

                // 4. Prominent Total Amount Highlight Card
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceElevated
                        : AppColors.warmCreamLight,
                    borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.borderSubtle,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TOTAL AMOUNT PAID',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            payment.currency,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        payment.formattedAmount,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: isVerified
                              ? (isDark
                                    ? AppColors.accentOrangeLight
                                    : AppColors.primaryNavy)
                              : statusColor,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // 5. Copy Action Button
                AppButton(
                  label: 'Copy Receipt Voucher',
                  icon: Icons.copy_rounded,
                  variant: AppButtonVariant.outline,
                  height: 38,
                  onPressed: () => _copyReceiptToClipboard(context),
                ),
                const SizedBox(height: 10),

                // 6. Institutional Registry Limitation Notice
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceElevated.withValues(alpha: 0.6)
                        : AppColors.forestSoft.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder.withValues(alpha: 0.6)
                          : AppColors.borderSubtle,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        size: 15,
                        color: AppColors.primaryNavy,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This digital fee voucher reflects the financial records stored in the IIECM Registry. Official stamped physical certificates or sealed tax receipts may be requested directly from the IIECM Accounts & Registry Office using transaction reference ${payment.transactionRef}.',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Responsive key/value row replacing rigid fixed width with flexible proportions
  Widget _buildReceiptRow(
    String label,
    String value,
    bool isDark, {
    bool isMonospace = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                fontFamily: isMonospace ? 'monospace' : null,
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
}
