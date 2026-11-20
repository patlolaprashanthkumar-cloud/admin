import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../providers/payments_provider.dart';
import '../providers/payments_state.dart';
import '../widgets/payment_card.dart';
import '../widgets/payment_filter_chips.dart';

/// Student Fee Status & Receipts directory screen
///
/// Follows the IIECM Modern Academic design language with institutional branding,
/// fee summary overview, live search & filtering, and structured payment transaction cards.
class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final paymentsState = ref.watch(studentPaymentsNotifierProvider);
    final paymentsNotifier = ref.read(studentPaymentsNotifierProvider.notifier);

    final filteredPayments = paymentsState.filteredPayments;
    final isLoading = paymentsState.isLoading && paymentsState.payments.isEmpty;
    final hasError = paymentsState.hasError && paymentsState.payments.isEmpty;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.backgroundWarmOffWhite,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.darkSurface
            : AppColors.backgroundWarmOffWhite,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: Row(
          children: [
            // Institutional Brand Emblem
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceElevated
                    : AppColors.forestSoft,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryNavy.withValues(alpha: 0.15),
                  width: 1.2,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.primaryNavy,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Fee Status & Receipts',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!paymentsState.isLoading &&
                          paymentsState.payments.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryNavy.withValues(
                              alpha: isDark ? 0.3 : 0.08,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${paymentsState.payments.length}',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? AppColors.accentOrangeLight
                                  : AppColors.primaryNavy,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    'Official Billing Records & Receipts',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Records',
            icon: const Icon(Icons.refresh_rounded),
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            onPressed: () => paymentsNotifier.refresh(),
          ),
          const SizedBox(width: AppConstants.spacingSm),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryNavy,
          onRefresh: () => paymentsNotifier.refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppConstants.spacingMd),
            children: [
              // 1. Institutional Financial Summary Hero Card
              _buildOverviewCard(paymentsState, isDark, theme),
              const SizedBox(height: AppConstants.spacingMd),

              // 2. Search Field
              TextField(
                controller: _searchController,
                onChanged: (val) {
                  paymentsNotifier.setSearchQuery(val);
                  setState(() {});
                },
                style: TextStyle(
                  fontSize: 13.5,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search receipt number, transaction ref, course...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textMuted,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.primaryNavy,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            paymentsNotifier.setSearchQuery('');
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark
                      ? AppColors.darkSurfaceElevated
                      : AppColors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                    borderSide: const BorderSide(
                      color: AppColors.primaryNavy,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingSm + 2),

              // 3. Status Filter Chips
              PaymentFilterChips(
                selectedFilter: paymentsState.filter,
                onFilterSelected: paymentsNotifier.setFilter,
                counts: {
                  PaymentFilterType.all: paymentsState.totalPaymentsCount,
                  PaymentFilterType.verified: paymentsState.verifiedCount,
                  PaymentFilterType.pending: paymentsState.pendingCount,
                  PaymentFilterType.failed: paymentsState.payments
                      .where((p) => p.isFailed || p.isRejected)
                      .length,
                  PaymentFilterType.refunded: paymentsState.payments
                      .where((p) => p.isRefunded)
                      .length,
                },
              ),
              const SizedBox(height: AppConstants.spacingMd),

              // 4. Content State Dispatcher
              if (isLoading)
                _buildLoadingState(isDark)
              else if (hasError)
                _buildErrorState(
                  paymentsState.errorMessage ?? 'Failed to load payments',
                )
              else if (filteredPayments.isEmpty)
                _buildEmptyState(context, paymentsState)
              else
                ...filteredPayments.map(
                  (payment) => PaymentCard(
                    payment: payment,
                    onTap: () => context.push('/payments/${payment.id}'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Institutional summary hero card displaying tuition and fee metrics
  Widget _buildOverviewCard(PaymentsState state, bool isDark, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkBackground
                      : AppColors.forestSoft,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppColors.primaryNavy,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tuition & Fee Records',
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Institutional billing transactions and official receipts',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  label: 'Total Verified Paid',
                  value: '₹${state.totalVerifiedAmount.toStringAsFixed(0)}',
                  color: AppColors.success,
                  icon: Icons.verified_outlined,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricItem(
                  label: 'Verified Invoices',
                  value: state.verifiedCount.toString(),
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  icon: Icons.receipt_rounded,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricItem(
                  label: 'Pending Invoices',
                  value: state.pendingCount.toString(),
                  color: state.pendingCount > 0
                      ? AppColors.accentOrange
                      : (isDark ? Colors.white : AppColors.textPrimary),
                  icon: Icons.hourglass_top_rounded,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.warmCreamLight,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder.withValues(alpha: 0.6)
              : AppColors.borderSubtle,
          width: 0.8,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Column(
      children: List.generate(
        3,
        (_) => Container(
          height: 120,
          margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.white,
            borderRadius: BorderRadius.circular(AppConstants.radiusLg),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryNavy),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return AppCard(
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.errorSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 32,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: AppConstants.spacingSm + 4),
          const Text(
            'Unable to Load Payments',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppConstants.spacingMd),
          AppButton(
            label: 'Retry Connection',
            icon: Icons.refresh_rounded,
            isFullWidth: false,
            height: 40,
            onPressed: () =>
                ref.read(studentPaymentsNotifierProvider.notifier).refresh(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, PaymentsState state) {
    final hasSearch = state.searchQuery.trim().isNotEmpty;
    final hasFilter = state.filter != PaymentFilterType.all;

    return AppCard(
      padding: const EdgeInsets.all(AppConstants.spacingXl),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: hasSearch || hasFilter
                  ? AppColors.terracottaSoft
                  : AppColors.forestSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasSearch || hasFilter
                  ? Icons.filter_alt_off_outlined
                  : Icons.receipt_long_outlined,
              size: 36,
              color: hasSearch || hasFilter
                  ? AppColors.terracotta
                  : AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Text(
            hasSearch || hasFilter
                ? 'No Matching Transactions'
                : 'No Payment Records on File',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            hasSearch || hasFilter
                ? 'Try adjusting your search criteria or reset the current status filter.'
                : 'No fee invoices or payment receipts have been recorded for your student account yet.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppConstants.spacingLg),
          if (hasSearch || hasFilter)
            AppButton(
              label: 'Reset Filters',
              icon: Icons.refresh_rounded,
              isFullWidth: false,
              height: 40,
              variant: AppButtonVariant.outline,
              onPressed: () {
                _searchController.clear();
                ref
                    .read(studentPaymentsNotifierProvider.notifier)
                    .setSearchQuery('');
                ref
                    .read(studentPaymentsNotifierProvider.notifier)
                    .setFilter(PaymentFilterType.all);
                setState(() {});
              },
            ),
        ],
      ),
    );
  }
}
