import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../providers/payment_providers.dart';
import '../screens/payment_receipt_preview_screen.dart';
import '../widgets/payment_detail_dialog.dart';
import '../widgets/record_payment_sheet.dart';

class StudentPaymentHistorySheet extends ConsumerWidget {
  final String studentId;

  const StudentPaymentHistorySheet({super.key, required this.studentId});

  static Future<void> show(BuildContext context, {required String studentId}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StudentPaymentHistorySheet(studentId: studentId),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'verified':
        return AppColors.primaryForest;
      case 'partially_paid':
      case 'pending':
        return AppColors.accentTerracotta;
      case 'overdue':
      case 'rejected':
      case 'failed':
        return Colors.red[700]!;
      case 'refunded':
      case 'partially_refunded':
        return Colors.indigo[700]!;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profileAsync = ref.watch(studentFeeProfileProvider(studentId));
    final mediaQuery = MediaQuery.of(context);
    final availableHeight = mediaQuery.size.height;

    return Container(
      constraints: BoxConstraints(maxHeight: availableHeight * 0.9),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusLarge),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.forestSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: AppColors.primaryForest,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Student Fee Ledger & History',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Institutional fee reconciliation and transaction audit',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Content
            Expanded(
              child: profileAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryForest,
                  ),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Error loading fee profile: $err'),
                  ),
                ),
                data: (profile) {
                  if (profile == null) {
                    return const Center(
                      child: Text('No fee profile records found.'),
                    );
                  }

                  final statusColor = _getStatusColor(profile.derivedStatus);

                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Student Summary Banner
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: AppColors.forestSoft,
                                    child: Text(
                                      profile.studentName.isNotEmpty
                                          ? profile.studentName[0]
                                          : 'S',
                                      style: const TextStyle(
                                        color: AppColors.primaryForest,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          profile.studentName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                          ),
                                        ),
                                        Text(
                                          'ID: ${profile.studentCode} · ${profile.email}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: statusColor.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      profile.derivedStatus
                                          .replaceAll('_', ' ')
                                          .toUpperCase(),
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Divider(height: 1),
                              const SizedBox(height: 14),

                              // Progress bar
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Fee Settlement Progress',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    '${profile.paymentCompletionPercentage.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: statusColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value:
                                      profile.paymentCompletionPercentage / 100,
                                  backgroundColor: Colors.grey.withValues(
                                    alpha: 0.15,
                                  ),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    statusColor,
                                  ),
                                  minHeight: 6,
                                ),
                              ),
                              const SizedBox(height: 14),

                              // KPI Row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatItem(
                                    'Total Fees',
                                    CurrencyFormatter.format(
                                      profile.totalCourseFee,
                                    ),
                                  ),
                                  _buildStatItem(
                                    'Paid To Date',
                                    CurrencyFormatter.format(profile.totalPaid),
                                    color: AppColors.primaryForest,
                                  ),
                                  _buildStatItem(
                                    'Outstanding',
                                    CurrencyFormatter.format(
                                      profile.outstandingBalance,
                                    ),
                                    color: profile.outstandingBalance > 0
                                        ? AppColors.accentTerracotta
                                        : AppColors.primaryForest,
                                    isBold: true,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // 2. Enrolled Courses & Associated Fees
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Enrolled Programs & Fee Structure',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '${profile.enrolledCourses.length} Enrolled',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        if (profile.enrolledCourses.isEmpty)
                          const AppCard(
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                'No enrolled courses found for this student.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          )
                        else
                          ...profile.enrolledCourses.map((c) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkSurfaceVariant
                                      : AppColors.warmCreamLight,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.grey.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.forestSoft,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(
                                        Icons.school_rounded,
                                        size: 16,
                                        color: AppColors.primaryForest,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            c.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12.5,
                                            ),
                                          ),
                                          Text(
                                            'Stream: ${c.categoryName} · Status: ${c.enrollmentStatus.toUpperCase()}',
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      CurrencyFormatter.format(c.fee),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                        color: AppColors.primaryForest,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),

                        const SizedBox(height: 20),

                        // 3. Transactions Ledger
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Payment Transactions (${profile.payments.length})',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (profile.outstandingBalance > 0)
                              FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primaryForest,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  minimumSize: const Size(0, 32),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  RecordPaymentSheet.show(
                                    context,
                                    initialStudentId: profile.studentId,
                                  );
                                },
                                icon: const Icon(Icons.add, size: 14),
                                label: const Text(
                                  'Record Payment',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        if (profile.payments.isEmpty)
                          const AppCard(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.receipt_outlined,
                                      size: 32,
                                      color: AppColors.textSecondary,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'No payment transactions recorded yet.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        else
                          ...profile.payments.map((p) {
                            final pStatusColor = _getStatusColor(p.status);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: InkWell(
                                onTap: () =>
                                    PaymentDetailDialog.show(context, p),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.darkSurfaceVariant
                                        : AppColors.warmCreamLight,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.grey.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: pStatusColor.withValues(
                                                alpha: 0.15,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Icon(
                                              Icons.payment_rounded,
                                              size: 16,
                                              color: pStatusColor,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  p.transactionRef,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontFamily: 'monospace',
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                Text(
                                                  '${p.formattedMethod} · ${DateFormat("dd MMM yyyy").format(p.paymentDate)}',
                                                  style: const TextStyle(
                                                    fontSize: 10.5,
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                CurrencyFormatter.format(
                                                  p.amount,
                                                ),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 13,
                                                  color: p.isVerified
                                                      ? AppColors.primaryForest
                                                      : AppColors.textPrimary,
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 1.5,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: pStatusColor
                                                      .withValues(alpha: 0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  p.status.toUpperCase(),
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w800,
                                                    color: pStatusColor,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          TextButton.icon(
                                            style: TextButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              minimumSize: const Size(0, 24),
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (ctx) =>
                                                      PaymentReceiptPreviewScreen(
                                                        payment: p,
                                                      ),
                                                ),
                                              );
                                            },
                                            icon: const Icon(
                                              Icons.receipt_long_rounded,
                                              size: 13,
                                            ),
                                            label: const Text(
                                              'View Receipt',
                                              style: TextStyle(fontSize: 10.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value, {
    Color? color,
    bool isBold = false,
  }) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 9.5,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
