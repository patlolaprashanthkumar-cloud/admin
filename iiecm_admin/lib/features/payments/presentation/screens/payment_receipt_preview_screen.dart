import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../domain/models/payment.dart';
import '../widgets/receipt_generator.dart';

class PaymentReceiptPreviewScreen extends StatefulWidget {
  final Payment payment;
  final double previousBalance;
  final double remainingBalance;

  const PaymentReceiptPreviewScreen({
    super.key,
    required this.payment,
    this.previousBalance = 0.0,
    this.remainingBalance = 0.0,
  });

  @override
  State<PaymentReceiptPreviewScreen> createState() =>
      _PaymentReceiptPreviewScreenState();
}

class _PaymentReceiptPreviewScreenState
    extends State<PaymentReceiptPreviewScreen> {
  bool _isGeneratingPdf = false;

  Future<void> _downloadOrSavePdf() async {
    if (!widget.payment.isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cannot export official PDF: Transaction is not yet verified and captured.',
          ),
          backgroundColor: AppColors.accentTerracotta,
        ),
      );
      return;
    }

    setState(() => _isGeneratingPdf = true);
    try {
      final pdfBytes = await ReceiptGenerator.generateReceiptPdf(
        payment: widget.payment,
        previousBalance: widget.previousBalance,
        remainingBalance: widget.remainingBalance,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'PDF Document generated (${(pdfBytes.lengthInBytes / 1024).toStringAsFixed(1)} KB). Ready for archiving.',
          ),
          backgroundColor: AppColors.primaryForest,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: $e'),
          backgroundColor: AppColors.accentTerracotta,
        ),
      );
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  void _copyReceiptToClipboard() {
    final text = ReceiptGenerator.formatReceiptPlainText(
      payment: widget.payment,
      previousBalance: widget.previousBalance,
      remainingBalance: widget.remainingBalance,
    );
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Audited receipt copied to clipboard.'),
        backgroundColor: AppColors.primaryForest,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final p = widget.payment;
    final formattedDate = DateFormat('dd MMM yyyy, hh:mm a')
        .format(p.paymentDate);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      appBar: AppBar(
        title: Text(
          'Receipt ${p.receiptNumber}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.warmCream,
        actions: [
          IconButton(
            tooltip: 'Copy Receipt Details',
            icon: const Icon(Icons.copy_rounded),
            onPressed: _copyReceiptToClipboard,
          ),
          IconButton(
            tooltip: 'Generate PDF Bytes',
            icon: _isGeneratingPdf
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_rounded),
            onPressed: _isGeneratingPdf ? null : _downloadOrSavePdf,
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveLayout(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primaryForest.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Unverified Transaction Warning Banner
                  if (!p.isVerified) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber[400]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.amber[900],
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'PROVISIONAL TRANSACTION: Status is ${p.status.toUpperCase()}. This document is NOT an official verified tax/fee receipt.',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Institutional Banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.forestSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
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
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Indian Institute of Emergency & Critical Care Medicine',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  color: AppColors.forestDark,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Apex Academic Institute of Critical Care Medicine',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                'admin@iiecm.org | +91 98765 43210',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Receipt Meta Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'OFFICIAL FEE RECEIPT',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primaryForest,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Receipt: ${p.receiptNumber}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Date: $formattedDate',
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Txn: ${p.transactionRef}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 14),

                  // Student & Program Details Box
                  Container(
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
                        _buildRow(
                          'Student Full Name',
                          p.studentName,
                          'Student ID',
                          p.studentCode ?? 'N/A',
                        ),
                        const SizedBox(height: 8),
                        _buildRow(
                          'Academic Program',
                          p.courseName ??
                              (p.subscriptionPlan != null
                                  ? 'Plan: ${p.subscriptionPlan!.toUpperCase()}'
                                  : 'Institutional Enrollment'),
                          'Payment Mode',
                          p.formattedMethod,
                        ),
                        const SizedBox(height: 8),
                        _buildRow(
                          'Currency',
                          p.currency,
                          'Authorized By',
                          p.verifiedBy ?? 'System Verified',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Table of fees
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.25),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.forestSoft.withValues(alpha: 0.6),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(7),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                'DESCRIPTION',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.forestDark,
                                ),
                              ),
                              Text(
                                'AMOUNT (INR)',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.forestDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Tuition & Clinical Training Fee installment for ${p.courseName ?? "Institutional Program"}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                CurrencyFormatter.format(p.amount),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryForest,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Balances Box
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 250,
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
                          if (widget.previousBalance > 0) ...[
                            _buildMiniRow(
                              'Previous Balance',
                              CurrencyFormatter.format(widget.previousBalance),
                            ),
                            const SizedBox(height: 4),
                          ],
                          _buildMiniRow(
                            'Amount Paid Now',
                            CurrencyFormatter.format(p.amount),
                            isBold: true,
                            textColor: AppColors.primaryForest,
                          ),
                          const SizedBox(height: 4),
                          const Divider(height: 1),
                          const SizedBox(height: 4),
                          _buildMiniRow(
                            'Remaining Balance',
                            CurrencyFormatter.format(widget.remainingBalance),
                            isBold: true,
                            textColor: widget.remainingBalance > 0
                                ? AppColors.accentTerracotta
                                : AppColors.primaryForest,
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (p.notes != null && p.notes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Administrative Remarks:',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(p.notes!, style: const TextStyle(fontSize: 11.5)),
                  ],

                  const SizedBox(height: 24),

                  // Signatures Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.forestSoft,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.primaryForest.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: const Text(
                          'ELECTRONICALLY AUDITED & VERIFIED',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryForest,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 130,
                            height: 1,
                            color: isDark ? Colors.white38 : Colors.black45,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Authorized Signatory',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Text(
                            'Finance & Accounts, IIECM',
                            style: TextStyle(
                              fontSize: 8.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String l1, String v1, String l2, String v2) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l1.toUpperCase(),
                style: const TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                v1,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l2.toUpperCase(),
                style: const TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                v2,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniRow(
    String label,
    String value, {
    bool isBold = false,
    Color? textColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: textColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
