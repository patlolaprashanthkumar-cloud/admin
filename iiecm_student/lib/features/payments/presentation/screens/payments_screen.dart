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
      appBar: AppBar(
        title: const Text('Fee Status & Receipts'),
        actions: [
          IconButton(
            tooltip: 'Refresh Records',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => paymentsNotifier.refresh(),
          ),
          const SizedBox(width: AppConstants.spacingSm),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryForest,
          onRefresh: () => paymentsNotifier.refresh(),
          child: ListView(
            padding: const EdgeInsets.all(AppConstants.spacingMd),
            children: [
              // 1. Institutional Financial Summary Hero Card
              _buildOverviewCard(paymentsState, isDark, theme),
              const SizedBox(height: AppConstants.spacingMd),

              // 2. Search Field
              TextField(
                controller: _searchController,
                onChanged: paymentsNotifier.setSearchQuery,
                decoration: InputDecoration(
                  hintText: 'Search receipt number, transaction ref, course...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            paymentsNotifier.setSearchQuery('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? AppColors.darkSurfaceElevated : AppColors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                      color: AppColors.primaryForest,
                      width: 1.6,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingSm),

              // 3. Status Filter Chips
              PaymentFilterChips(
                selectedFilter: paymentsState.filter,
                onFilterSelected: paymentsNotifier.setFilter,
              ),
              const SizedBox(height: AppConstants.spacingMd),

              // 4. Content State Dispatcher
              if (isLoading)
                _buildLoadingState(isDark)
              else if (hasError)
                _buildErrorState(paymentsState.errorMessage ?? 'Failed to load payments')
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

  Widget _buildOverviewCard(
    PaymentsState state,
    bool isDark,
    ThemeData theme,
  ) {
    return AppCard(
      backgroundColor: isDark ? AppColors.forestDark : AppColors.primaryForest,
      borderColor: isDark ? AppColors.forestLight : AppColors.forestDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.forestSoft,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppColors.primaryForest,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tuition & Fee Records',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 1),
                    const Text(
                      'Institutional billing transactions and official receipts',
                      style: TextStyle(
                        color: AppColors.forestSoft,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingMd),
          const Divider(color: Color(0x33FFFFFF)),
          const SizedBox(height: AppConstants.spacingSm),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  label: 'Total Verified Paid',
                  value: '₹${state.totalVerifiedAmount.toStringAsFixed(0)}',
                  color: const Color(0xFFA5D6A7),
                ),
              ),
              Container(
                height: 28,
                width: 1,
                color: const Color(0x33FFFFFF),
              ),
              Expanded(
                child: _buildMetricItem(
                  label: 'Verified Invoices',
                  value: state.verifiedCount.toString(),
                  color: Colors.white,
                ),
              ),
              Container(
                height: 28,
                width: 1,
                color: const Color(0x33FFFFFF),
              ),
              Expanded(
                child: _buildMetricItem(
                  label: 'Pending',
                  value: state.pendingCount.toString(),
                  color: state.pendingCount > 0 ? const Color(0xFFFFCC80) : Colors.white,
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
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.forestSoft,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Column(
      children: List.generate(
        3,
        (_) => Container(
          height: 110,
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
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryForest),
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
          const Icon(Icons.error_outline_rounded, size: 40, color: AppColors.error),
          const SizedBox(height: AppConstants.spacingSm),
          const Text(
            'Unable to Load Payments',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppConstants.spacingMd),
          AppButton(
            label: 'Retry Connection',
            icon: Icons.refresh_rounded,
            isFullWidth: false,
            height: 38,
            onPressed: () => ref.read(studentPaymentsNotifierProvider.notifier).refresh(),
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
          Icon(
            hasSearch || hasFilter
                ? Icons.filter_alt_off_outlined
                : Icons.receipt_long_outlined,
            size: 44,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            hasSearch || hasFilter
                ? 'No Matching Transactions'
                : 'No Payment Records on File',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            hasSearch || hasFilter
                ? 'Try adjusting your search criteria or reset the current status filter.'
                : 'No fee invoices or payment receipts have been recorded for your student account yet.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppConstants.spacingMd),
          if (hasSearch || hasFilter)
            AppButton(
              label: 'Reset Filters',
              icon: Icons.refresh_rounded,
              isFullWidth: false,
              height: 36,
              variant: AppButtonVariant.outline,
              onPressed: () {
                _searchController.clear();
                ref.read(studentPaymentsNotifierProvider.notifier).setSearchQuery('');
                ref.read(studentPaymentsNotifierProvider.notifier).setFilter(PaymentFilterType.all);
              },
            ),
        ],
      ),
    );
  }
}

