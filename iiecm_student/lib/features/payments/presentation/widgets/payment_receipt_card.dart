import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../domain/models/student_payment.dart';

class PaymentReceiptCard extends StatelessWidget {
  final StudentPayment payment;

  const PaymentReceiptCard({
    super.key,
    required this.payment,
  });

  void _copyReceiptToClipboard(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final formattedDate = dateFormat.format(payment.paymentDate);

    final receiptText = '''
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
        backgroundColor: AppColors.primaryForest,
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
    final statusColor = isVerified ? AppColors.success : (payment.isPending ? AppColors.warning : AppColors.error);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(
          color: isVerified ? AppColors.primaryForest : (isDark ? AppColors.darkBorder : AppColors.border),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Institutional Banner Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.forestDark : AppColors.forestSoft,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppConstants.radiusLg - 1),
                    topRight: Radius.circular(AppConstants.radiusLg - 1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryForest,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          'IIECM',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: 0.5,
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
                              fontSize: 12,
                              color: isDark ? Colors.white : AppColors.forestDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Apex Academic Institute of Critical Care & Emergency Medicine',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Receipt Title & Reference Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'OFFICIAL FEE RECEIPT',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: AppColors.primaryForest,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isVerified ? AppColors.successSoft : AppColors.warningSoft,
                            borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                          ),
                          child: Text(
                            payment.displayStatus,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.spacingSm),
                    Text(
                      payment.receiptNumber,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingSm),
                    const Divider(height: 1),
                    const SizedBox(height: AppConstants.spacingSm),

                    // 3. Key Receipt Details Table
                    _buildReceiptRow('Transaction Ref', payment.transactionRef, isMonospace: true),
                    _buildReceiptRow('Receipt Date & Time', formattedDate),
                    _buildReceiptRow('Student Legal Name', payment.studentName),
                    if (payment.studentCode != null && payment.studentCode!.isNotEmpty)
                      _buildReceiptRow('Student Reg ID', payment.studentCode!, isMonospace: true),
                    _buildReceiptRow('Payment Method', payment.formattedMethod),
                    _buildReceiptRow('Fee Description', payment.purposeDescription),
                    if (payment.verifiedBy != null && payment.verifiedBy!.isNotEmpty)
                      _buildReceiptRow('Verified By', payment.verifiedBy!),

                    const SizedBox(height: AppConstants.spacingSm),
                    const Divider(height: 1),
                    const SizedBox(height: AppConstants.spacingSm),

                    // 4. Total Amount Highlight
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceElevated : AppColors.warmCream,
                        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TOTAL AMOUNT PAID',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            payment.formattedAmount,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: isVerified ? AppColors.primaryForest : statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingSm),

                    // 5. Actions
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: 'Copy Receipt Voucher',
                            icon: Icons.copy_rounded,
                            variant: AppButtonVariant.outline,
                            height: 38,
                            onPressed: () => _copyReceiptToClipboard(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.spacingSm),

                    // 6. Institutional Registry Limitation Notice
                    Container(
                      padding: const EdgeInsets.all(AppConstants.spacingSm),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceElevated : AppColors.warmCreamLight,
                        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'This digital fee voucher reflects the financial records stored in the IIECM Registry. Official stamped physical certificates or sealed tax receipts may be requested directly from the IIECM Accounts & Registry Office using transaction reference ${payment.transactionRef}.',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
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
          );

          if (constraints.maxHeight.isFinite) {
            return SingleChildScrollView(
              child: content,
            );
          }

          return content;
        },
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isMonospace = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFamily: isMonospace ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

