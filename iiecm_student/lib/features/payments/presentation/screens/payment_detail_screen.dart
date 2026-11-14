import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../domain/models/student_payment.dart';
import '../providers/payments_provider.dart';
import '../widgets/payment_receipt_card.dart';

class PaymentDetailScreen extends ConsumerWidget {
  final String paymentId;

  const PaymentDetailScreen({
    super.key,
    required this.paymentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // First check in-memory list from studentPaymentsNotifierProvider for instant display
    final paymentsState = ref.watch(studentPaymentsNotifierProvider);
    final cachedPayment =
        paymentsState.payments.where((p) => p.id == paymentId).firstOrNull;

    final asyncPayment = ref.watch(studentPaymentDetailProvider(paymentId));

    final StudentPayment? payment = cachedPayment ?? asyncPayment.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fee Receipt Voucher'),
      ),
      body: SafeArea(
        child: asyncPayment.isLoading && payment == null
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryForest),
                ),
              )
            : asyncPayment.hasError && payment == null
                ? _buildErrorView(context, ref, asyncPayment.error.toString())
                : payment == null
                    ? _buildNotFoundView(context)
                    : ListView(
                        padding: const EdgeInsets.all(AppConstants.spacingMd),
                        children: [
                          PaymentReceiptCard(payment: payment),
                        ],
                      ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 44, color: AppColors.error),
            const SizedBox(height: AppConstants.spacingSm),
            const Text(
              'Error Loading Transaction',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            AppButton(
              label: 'Retry',
              icon: Icons.refresh_rounded,
              isFullWidth: false,
              height: 38,
              onPressed: () => ref.refresh(studentPaymentDetailProvider(paymentId)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 44, color: AppColors.textSecondary),
            const SizedBox(height: AppConstants.spacingSm),
            const Text(
              'Payment Record Not Found',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 4),
            const Text(
              'The requested payment transaction could not be located in your student account record.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            AppButton(
              label: 'Back to Payments',
              icon: Icons.arrow_back_rounded,
              isFullWidth: false,
              height: 38,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

