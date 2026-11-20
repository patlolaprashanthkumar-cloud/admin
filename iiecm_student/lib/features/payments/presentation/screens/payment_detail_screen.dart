import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../domain/models/student_payment.dart';
import '../providers/payments_provider.dart';
import '../widgets/payment_receipt_card.dart';

/// Modern Academic individual fee transaction detail and receipt voucher screen
class PaymentDetailScreen extends ConsumerWidget {
  final String paymentId;

  const PaymentDetailScreen({super.key, required this.paymentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // First check in-memory list from studentPaymentsNotifierProvider for instant display
    final paymentsState = ref.watch(studentPaymentsNotifierProvider);
    final cachedPayment = paymentsState.payments
        .where((p) => p.id == paymentId)
        .firstOrNull;

    final asyncPayment = ref.watch(studentPaymentDetailProvider(paymentId));

    final StudentPayment? payment = cachedPayment ?? asyncPayment.valueOrNull;

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
        title: const Text('Fee Receipt Voucher'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Refresh Voucher',
            icon: const Icon(Icons.refresh_rounded),
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            onPressed: () =>
                ref.refresh(studentPaymentDetailProvider(paymentId)),
          ),
          const SizedBox(width: AppConstants.spacingSm),
        ],
      ),
      body: SafeArea(
        child: asyncPayment.isLoading && payment == null
            ? _buildLoadingView(isDark)
            : asyncPayment.hasError && payment == null
            ? _buildErrorView(
                context,
                ref,
                asyncPayment.error.toString(),
                isDark,
              )
            : payment == null
            ? _buildNotFoundView(context, isDark)
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppConstants.spacingMd),
                children: [PaymentReceiptCard(payment: payment)],
              ),
      ),
    );
  }

  Widget _buildLoadingView(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            strokeWidth: 2.2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryNavy),
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Text(
            'Retrieving receipt voucher...',
            style: TextStyle(
              fontSize: 12.5,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(
    BuildContext context,
    WidgetRef ref,
    String error,
    bool isDark,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: AppColors.errorSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 36,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            const Text(
              'Error Loading Transaction',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: AppConstants.spacingLg),
            AppButton(
              label: 'Retry',
              icon: Icons.refresh_rounded,
              isFullWidth: false,
              height: 40,
              onPressed: () =>
                  ref.refresh(studentPaymentDetailProvider(paymentId)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundView(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: AppColors.terracottaSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 36,
                color: AppColors.terracotta,
              ),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            const Text(
              'Payment Record Not Found',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              'The requested payment transaction could not be located in your student account record.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: AppConstants.spacingLg),
            AppButton(
              label: 'Back to Payments',
              icon: Icons.arrow_back_rounded,
              isFullWidth: false,
              height: 40,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
