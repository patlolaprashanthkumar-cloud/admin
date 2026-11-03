import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/payment.dart';
import '../providers/payment_providers.dart';
import '../screens/payment_receipt_preview_screen.dart';

class PaymentDetailDialog extends ConsumerWidget {
  final Payment payment;

  const PaymentDetailDialog({super.key, required this.payment});

  static Future<void> show(BuildContext context, Payment payment) {
    return showDialog(
      context: context,
      builder: (context) => PaymentDetailDialog(payment: payment),
    );
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

  Future<void> _handleApprove(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verify Payment Transaction'),
        content: Text(
          'Confirm verification of ${CurrencyFormatter.format(payment.amount)} from ${payment.studentName}?\n\n'
          'This will authorize the payment and credit the student fee account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryForest,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Verify & Credit'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await ref
        .read(paymentActionsProvider.notifier)
        .verifyPayment(payment.id);

    if (context.mounted) {
      Navigator.pop(context); // Close dialog
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment transaction verified successfully.'),
            backgroundColor: AppColors.primaryForest,
          ),
        );
      }
    }
  }

  Future<void> _handleReject(BuildContext context, WidgetRef ref) async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Payment Transaction'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Provide institutional audit reason for rejecting ${payment.transactionRef}:',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText:
                      'e.g. UTR mismatch, invalid screenshot, cheque bounce...',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Rejection reason is required'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red[700]),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Reject Payment'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await ref
        .read(paymentActionsProvider.notifier)
        .rejectPayment(payment.id, reason: reasonController.text.trim());

    if (context.mounted) {
      Navigator.pop(context);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Payment transaction rejected.'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  Future<void> _handleRefund(BuildContext context, WidgetRef ref) async {
    final amountController = TextEditingController(
      text: payment.amount.toStringAsFixed(0),
    );
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Process Refund'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Record traceable refund for ${payment.studentName} (${payment.transactionRef}):',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Refund Amount (INR) *',
                  prefixIcon: Icon(Icons.currency_rupee, size: 16),
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final amt = double.tryParse(v ?? '');
                  if (amt == null || amt <= 0) return 'Enter a valid amount';
                  if (amt > payment.amount) {
                    return 'Cannot exceed original payment of ${payment.amount}';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: reasonController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Refund Reason *',
                  hintText: 'e.g. Admission cancellation within 7 days...',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Refund reason is required'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.indigo[700]),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Confirm Refund'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final refundAmt = double.parse(amountController.text.trim());
    final success = await ref
        .read(paymentActionsProvider.notifier)
        .processRefund(
          payment.id,
          amount: refundAmt,
          reason: reasonController.text.trim(),
        );

    if (context.mounted) {
      Navigator.pop(context);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Refund processed and audited.'),
            backgroundColor: Colors.indigo,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(payment.status);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transaction Details',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        SelectableText(
                          payment.transactionRef,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      payment.status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Key Data Grid
              _buildDataTile(
                'Student',
                '${payment.studentName} ${payment.studentCode != null ? "(${payment.studentCode})" : ""}',
              ),
              _buildDataTile(
                'Course / Program',
                payment.courseName ??
                    (payment.subscriptionPlan != null
                        ? 'Plan: ${payment.subscriptionPlan!.toUpperCase()}'
                        : 'Institutional Enrollment'),
              ),
              _buildDataTile(
                'Amount Received',
                CurrencyFormatter.format(payment.amount),
                isHighlight: true,
              ),
              _buildDataTile('Payment Method', payment.formattedMethod),
              _buildDataTile(
                'Payment Date',
                DateFormat('dd MMM yyyy, hh:mm a').format(payment.paymentDate),
              ),
              _buildDataTile('Receipt Number', payment.receiptNumber),

              if (payment.verifiedBy != null)
                _buildDataTile('Verified By', payment.verifiedBy!),

              if (payment.rejectionReason != null)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 16,
                        color: Colors.red[700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Rejection Reason: ${payment.rejectionReason}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.red[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (payment.notes != null && payment.notes!.isNotEmpty)
                _buildDataTile('Administrative Remarks', payment.notes!),

              if (payment.refundStatus == 'completed')
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.indigo[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.indigo[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 16,
                        color: Colors.indigo[700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Refund Audited: Status marked completed.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.indigo[800],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // Action Buttons
              if (payment.isPending) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red[700],
                          side: BorderSide(color: Colors.red[300]!),
                        ),
                        onPressed: () => _handleReject(context, ref),
                        icon: const Icon(Icons.cancel_outlined, size: 16),
                        label: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryForest,
                        ),
                        onPressed: () => _handleApprove(context, ref),
                        icon: const Icon(Icons.check_circle_outline, size: 16),
                        label: const Text('Verify Payment'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ] else if (payment.isVerified) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.indigo[700],
                          side: BorderSide(color: Colors.indigo[300]!),
                        ),
                        onPressed: () => _handleRefund(context, ref),
                        icon: const Icon(
                          Icons.currency_exchange_rounded,
                          size: 16,
                        ),
                        label: const Text('Issue Refund'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],

              // View PDF Receipt Button
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.forestSoft,
                    foregroundColor: AppColors.primaryForest,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) =>
                            PaymentReceiptPreviewScreen(payment: payment),
                      ),
                    );
                  },
                  icon: const Icon(Icons.receipt_long_rounded, size: 18),
                  label: const Text(
                    'View & Print PDF Receipt',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),

              const SizedBox(height: 6),
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataTile(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
                color: isHighlight
                    ? AppColors.primaryForest
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
