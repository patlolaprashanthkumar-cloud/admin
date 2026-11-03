import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/models/payment_filter.dart';
import '../providers/payment_providers.dart';
import 'payment_detail_dialog.dart';
import 'record_payment_sheet.dart';

class PaymentDashboardTab extends ConsumerWidget {
  const PaymentDashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final summaryAsync = ref.watch(paymentSummaryProvider);
    final currentFilter = ref.watch(paymentFilterProvider);

    return RefreshIndicator(
      color: AppColors.primaryForest,
      onRefresh: () async {
        ref.invalidate(paymentSummaryProvider);
        ref.invalidate(paymentsListProvider);
        ref.invalidate(allStudentFeeProfilesProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Date Range Filter Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildDatePill(
                    context,
                    ref,
                    label: 'All Time',
                    type: PaymentDateFilterType.allTime,
                    isSelected:
                        currentFilter.dateFilterType ==
                        PaymentDateFilterType.allTime,
                  ),
                  const SizedBox(width: 8),
                  _buildDatePill(
                    context,
                    ref,
                    label: 'Today',
                    type: PaymentDateFilterType.today,
                    isSelected:
                        currentFilter.dateFilterType ==
                        PaymentDateFilterType.today,
                  ),
                  const SizedBox(width: 8),
                  _buildDatePill(
                    context,
                    ref,
                    label: 'This Week',
                    type: PaymentDateFilterType.thisWeek,
                    isSelected:
                        currentFilter.dateFilterType ==
                        PaymentDateFilterType.thisWeek,
                  ),
                  const SizedBox(width: 8),
                  _buildDatePill(
                    context,
                    ref,
                    label: 'This Month',
                    type: PaymentDateFilterType.thisMonth,
                    isSelected:
                        currentFilter.dateFilterType ==
                        PaymentDateFilterType.thisMonth,
                  ),
                  const SizedBox(width: 8),
                  _buildDatePill(
                    context,
                    ref,
                    label: 'Last Month',
                    type: PaymentDateFilterType.lastMonth,
                    isSelected:
                        currentFilter.dateFilterType ==
                        PaymentDateFilterType.lastMonth,
                  ),
                  const SizedBox(width: 8),
                  _buildCustomDatePill(context, ref, currentFilter),
                ],
              ),
            ),

            const SizedBox(height: 16),

            summaryAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(
                    color: AppColors.primaryForest,
                  ),
                ),
              ),
              error: (err, _) => AppCard(
                child: Column(
                  children: [
                    Text('Error loading financial telemetry: $err'),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () => ref.invalidate(paymentSummaryProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (summary) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Action: Record Payment Callout
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.forestSoft,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primaryForest.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primaryForest,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.add_card_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Record New Fee Receipt',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryForest,
                                  ),
                                ),
                                const Text(
                                  'Direct fee credit, bank slip reconciliation, or offline cash entry',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primaryForest,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            onPressed: () => RecordPaymentSheet.show(context),
                            child: const Text(
                              'Record',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Primary KPI Cards Grid
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 500;
                        final crossAxisCount = isWide ? 4 : 2;

                        return GridView.count(
                          crossAxisCount: crossAxisCount,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: isWide ? 1.4 : 1.35,
                          children: [
                            _buildKpiCard(
                              label: 'Total Collected',
                              value: CurrencyFormatter.format(
                                summary.totalFeesCollected,
                              ),
                              subValue:
                                  '${summary.totalPaymentsReceived} verified txns',
                              icon: Icons.payments_rounded,
                              accentColor: AppColors.primaryForest,
                              isDark: isDark,
                            ),
                            _buildKpiCard(
                              label: 'Outstanding Dues',
                              value: CurrencyFormatter.format(
                                summary.totalOutstandingAmount,
                              ),
                              subValue:
                                  '${summary.partiallyPaidStudentsCount} partial payers',
                              icon: Icons.pending_actions_rounded,
                              accentColor: AppColors.accentTerracotta,
                              isDark: isDark,
                            ),
                            _buildKpiCard(
                              label: 'Pending Approval',
                              value: '${summary.pendingPaymentsCount}',
                              subValue: CurrencyFormatter.format(
                                summary.pendingPaymentsAmount,
                              ),
                              icon: Icons.hourglass_top_rounded,
                              accentColor: Colors.amber[800]!,
                              isDark: isDark,
                            ),
                            _buildKpiCard(
                              label: 'Total Refunded',
                              value: CurrencyFormatter.format(
                                summary.refundTotal,
                              ),
                              subValue: 'Reconciled & audited',
                              icon: Icons.currency_exchange_rounded,
                              accentColor: Colors.indigo[700]!,
                              isDark: isDark,
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Secondary Telemetry Bar
                    AppCard(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildTelemetryItem(
                            'Monthly Run-Rate',
                            CurrencyFormatter.format(summary.monthlyRevenue),
                            Icons.trending_up_rounded,
                            AppColors.primaryForest,
                          ),
                          _buildTelemetryItem(
                            'Overdue Accounts',
                            '${summary.overduePaymentsCount} Students',
                            Icons.warning_amber_rounded,
                            AppColors.accentTerracotta,
                          ),
                          _buildTelemetryItem(
                            'Partial Payers',
                            '${summary.partiallyPaidStudentsCount} Students',
                            Icons.pie_chart_outline_rounded,
                            AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Payment Method Breakdown Card
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Payment Method Breakdown',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const Icon(
                                Icons.donut_large_rounded,
                                size: 18,
                                color: AppColors.primaryForest,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (summary.methodBreakdown.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: Text(
                                  'No verified collections in this filter period.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            )
                          else
                            ...summary.methodBreakdown.entries.map((e) {
                              final total = summary.totalFeesCollected > 0
                                  ? summary.totalFeesCollected
                                  : 1.0;
                              final pct = (e.value / total) * 100;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          e.key,
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          '${CurrencyFormatter.format(e.value)} (${pct.toStringAsFixed(1)}%)',
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primaryForest,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: (pct / 100).clamp(0.0, 1.0),
                                        backgroundColor: Colors.grey.withValues(
                                          alpha: 0.15,
                                        ),
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                              AppColors.primaryForest,
                                            ),
                                        minHeight: 5,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Recent Payment Transactions Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Payment Transactions',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${summary.recentTransactions.length} Latest',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (summary.recentTransactions.isEmpty)
                      const AppCard(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: Text(
                              'No recent payment transactions found.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      ...summary.recentTransactions.map((p) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: () => PaymentDetailDialog.show(context, p),
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
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: p.isVerified
                                        ? AppColors.forestSoft
                                        : (p.isPending
                                              ? AppColors.terracottaSoft
                                              : Colors.grey.withValues(
                                                  alpha: 0.1,
                                                )),
                                    child: Icon(
                                      p.isVerified
                                          ? Icons.check_circle_rounded
                                          : (p.isPending
                                                ? Icons.hourglass_empty_rounded
                                                : Icons.receipt_rounded),
                                      size: 18,
                                      color: p.isVerified
                                          ? AppColors.primaryForest
                                          : (p.isPending
                                                ? AppColors.accentTerracotta
                                                : AppColors.textSecondary),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.studentName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                        Text(
                                          '${p.courseName ?? "Institutional Program"} · ${p.transactionRef}',
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            color: AppColors.textSecondary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
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
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                          color: p.isVerified
                                              ? AppColors.primaryForest
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        DateFormat('dd MMM')
                                            .format(p.paymentDate),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.textSecondary,
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
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePill(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required PaymentDateFilterType type,
    required bool isSelected,
  }) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.white : AppColors.textPrimary,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primaryForest,
      backgroundColor: AppColors.forestSoft.withValues(alpha: 0.5),
      onSelected: (_) {
        ref.read(paymentFilterProvider.notifier).setDateFilter(type);
      },
    );
  }

  Widget _buildCustomDatePill(
    BuildContext context,
    WidgetRef ref,
    PaymentFilter filter,
  ) {
    final isCustom = filter.dateFilterType == PaymentDateFilterType.custom;
    final label = isCustom && filter.customStartDate != null
        ? '${DateFormat("dd/MM").format(filter.customStartDate!)} - ${DateFormat("dd/MM").format(filter.customEndDate ?? DateTime.now())}'
        : 'Custom Range';

    return ActionChip(
      avatar: const Icon(Icons.date_range_rounded, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      backgroundColor: isCustom
          ? AppColors.primaryForest.withValues(alpha: 0.15)
          : AppColors.forestSoft.withValues(alpha: 0.5),
      onPressed: () async {
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 30)),
        );
        if (picked != null) {
          ref
              .read(paymentFilterProvider.notifier)
              .setDateFilter(
                PaymentDateFilterType.custom,
                customStart: picked.start,
                customEnd: picked.end,
              );
        }
      },
    );
  }

  Widget _buildKpiCard({
    required String label,
    required String value,
    required String subValue,
    required IconData icon,
    required Color accentColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              Icon(icon, size: 18, color: accentColor),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: accentColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                subValue,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 9.5, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
