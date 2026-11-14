import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/models/payment.dart';
import '../providers/payment_providers.dart';
import 'payment_detail_dialog.dart';
import 'record_payment_sheet.dart';

class PaymentTransactionsTab extends ConsumerStatefulWidget {
  const PaymentTransactionsTab({super.key});

  @override
  ConsumerState<PaymentTransactionsTab> createState() =>
      _PaymentTransactionsTabState();
}

class _PaymentTransactionsTabState
    extends ConsumerState<PaymentTransactionsTab> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return AppColors.primaryForest;
      case 'pending':
        return AppColors.accentTerracotta;
      case 'rejected':
      case 'failed':
        return Colors.red[700]!;
      case 'refunded':
        return Colors.indigo[700]!;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final paymentsAsync = ref.watch(paymentsListProvider);
    final filter = ref.watch(paymentFilterProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryForest,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_card_rounded, size: 20),
        label: const Text(
          'Record Payment',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        onPressed: () => RecordPaymentSheet.show(context),
      ),
      body: RefreshIndicator(
        color: AppColors.primaryForest,
        onRefresh: () async {
          ref.invalidate(paymentsListProvider);
          ref.invalidate(paymentSummaryProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by student, ID, UTR ref, receipt...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            ref
                                .read(paymentFilterProvider.notifier)
                                .setSearchQuery('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark
                      ? AppColors.darkSurfaceVariant
                      : AppColors.warmCreamLight,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                onChanged: (val) {
                  ref
                      .read(paymentFilterProvider.notifier)
                      .setSearchQuery(val.trim());
                },
              ),

              const SizedBox(height: 12),

              // Filter & Sort Bar
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Status Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceVariant
                            : AppColors.forestSoft.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.25),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: filter.status ?? 'all',
                          icon: const Icon(Icons.filter_list_rounded, size: 16),
                          items: const [
                            DropdownMenuItem(
                              value: 'all',
                              child: Text(
                                'All Statuses',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'verified',
                              child: Text(
                                'Verified Only',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'pending',
                              child: Text(
                                'Pending Approval',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'rejected',
                              child: Text(
                                'Rejected',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'refunded',
                              child: Text(
                                'Refunded',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            ref
                                .read(paymentFilterProvider.notifier)
                                .setStatus(val);
                          },
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Method Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceVariant
                            : AppColors.forestSoft.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.25),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: filter.paymentMethod ?? 'all',
                          icon: const Icon(Icons.payment_rounded, size: 16),
                          items: const [
                            DropdownMenuItem(
                              value: 'all',
                              child: Text(
                                'All Methods',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'bank_transfer',
                              child: Text(
                                'Bank Transfer',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'upi',
                              child: Text(
                                'UPI Direct',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'card',
                              child: Text(
                                'Card',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'cash',
                              child: Text(
                                'Campus Cash',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'razorpay',
                              child: Text(
                                'Razorpay',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            ref
                                .read(paymentFilterProvider.notifier)
                                .setPaymentMethod(val);
                          },
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Sort By Action Chip
                    ActionChip(
                      avatar: Icon(
                        filter.sortDescending
                            ? Icons.arrow_downward_rounded
                            : Icons.arrow_upward_rounded,
                        size: 14,
                      ),
                      label: Text(
                        filter.sortBy == 'amount' ? 'By Amount' : 'By Date',
                        style: const TextStyle(fontSize: 11),
                      ),
                      onPressed: () {
                        if (filter.sortBy == 'date') {
                          ref
                              .read(paymentFilterProvider.notifier)
                              .setSorting(sortBy: 'amount', descending: true);
                        } else {
                          ref
                              .read(paymentFilterProvider.notifier)
                              .setSorting(
                                sortBy: 'date',
                                descending: !filter.sortDescending,
                              );
                        }
                      },
                    ),

                    if (filter.status != null ||
                        filter.paymentMethod != null ||
                        filter.searchQuery.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(0, 32),
                        ),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(paymentFilterProvider.notifier)
                              .resetFilters();
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 14),
                        label: const Text(
                          'Clear Filters',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Payments List
              paymentsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(
                      color: AppColors.primaryForest,
                    ),
                  ),
                ),
                error: (err, _) => AppCard(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text('Error loading payments: $err'),
                    ),
                  ),
                ),
                data: (payments) {
                  if (payments.isEmpty) {
                    return AppCard(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 36),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 40,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No payment records match criteria',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Try clearing filters or recording a new fee receipt.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${payments.length} Transaction Records',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: payments.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final p = payments[index];
                          return _buildTransactionCard(
                            context,
                            p,
                            isDark,
                            theme,
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(
    BuildContext context,
    Payment p,
    bool isDark,
    ThemeData theme,
  ) {
    final statusColor = _getStatusColor(p.status);

    return AppCard(
      child: InkWell(
        onTap: () => PaymentDetailDialog.show(context, p),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top line: Ref & Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.pin_rounded,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            p.transactionRef,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      p.status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 9.5,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Middle: Student & Amount
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.forestSoft,
                    child: Text(
                      p.studentName.isNotEmpty ? p.studentName[0] : 'S',
                      style: const TextStyle(
                        color: AppColors.primaryForest,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.studentName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${p.courseName ?? "Institutional Program"} · ID: ${p.studentCode ?? "N/A"}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyFormatter.format(p.amount),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: p.isVerified
                              ? AppColors.primaryForest
                              : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        DateFormat('dd MMM yyyy').format(p.paymentDate),
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Bottom details row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.account_balance_rounded,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            p.formattedMethod,
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Receipt: ${p.receiptNumber}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
