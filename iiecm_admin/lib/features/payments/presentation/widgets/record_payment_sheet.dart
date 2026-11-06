import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/currency_formatter.dart';

import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../domain/models/payment.dart';
import '../../domain/models/razorpay_models.dart';
import '../providers/payment_providers.dart';
import '../screens/payment_receipt_preview_screen.dart';
import '../services/razorpay_checkout_service.dart';

class RecordPaymentSheet extends ConsumerStatefulWidget {
  final String? initialStudentId;

  const RecordPaymentSheet({super.key, this.initialStudentId});

  static Future<void> show(BuildContext context, {String? initialStudentId}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          RecordPaymentSheet(initialStudentId: initialStudentId),
    );
  }

  @override
  ConsumerState<RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends ConsumerState<RecordPaymentSheet> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedStudentId;
  Map<String, dynamic>? _selectedStudent;
  Map<String, dynamic>? _selectedCourse;

  final _amountController = TextEditingController();
  final _txnRefController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _paymentDate = DateTime.now();
  String _paymentMethod = 'bank_transfer';
  String _status = 'verified'; // Admin can record as verified or pending

  // Razorpay Gateway State
  bool _isRazorpayMode = false;
  final _razorpayService = RazorpayCheckoutService();
  bool _isRazorpayProcessing = false;
  String? _activeRazorpayOrderId;
  String? _activePaymentId;
  String? _razorpayStatusMessage;

  final List<Map<String, String>> _methods = [
    {'id': 'bank_transfer', 'label': 'Bank Transfer (NEFT/RTGS/IMPS)'},
    {'id': 'upi', 'label': 'UPI (GPay / PhonePe / Paytm)'},
    {'id': 'card', 'label': 'Debit / Credit Card'},
    {'id': 'cash', 'label': 'Cash at Campus Desk'},
    {'id': 'cheque', 'label': 'Cheque / Demand Draft'},
    {'id': 'razorpay', 'label': 'Razorpay / Gateway Direct'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedStudentId = widget.initialStudentId;
    _generateReference();
    _razorpayService.initialize(
      onSuccess: _onRazorpaySuccess,
      onFailure: _onRazorpayFailure,
      onWallet: _onRazorpayWallet,
    );
  }

  void _generateReference() {
    final now = DateTime.now();
    final dateCode = DateFormat('yyyyMMdd').format(now);
    final randomDigits = math.Random().nextInt(9000) + 1000;
    _txnRefController.text = 'TXN-$dateCode-$randomDigits';
  }

  @override
  void dispose() {
    _razorpayService.dispose();
    _amountController.dispose();
    _txnRefController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onStudentSelected(
    Map<String, dynamic> student,
    List<Map<String, dynamic>> allStudents,
  ) {
    setState(() {
      _selectedStudent = student;
      _selectedStudentId = student['id'];

      final courses = (student['courses'] as List<dynamic>?) ?? [];
      if (courses.isNotEmpty) {
        _selectedCourse = courses.first as Map<String, dynamic>;
        final balance =
            (_selectedCourse?['balance'] as num?)?.toDouble() ?? 0.0;
        if (balance > 0) {
          _amountController.text = balance.toStringAsFixed(0);
        }
      } else {
        _selectedCourse = null;
        _amountController.clear();
      }
    });
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStudent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an active student first.'),
          backgroundColor: AppColors.accentTerracotta,
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment amount must be greater than zero.'),
          backgroundColor: AppColors.accentTerracotta,
        ),
      );
      return;
    }

    // Confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Payment Receipt'),
        content: Text(
          'Record ${CurrencyFormatter.format(amount)} received from ${_selectedStudent!['full_name']} via ${_paymentMethod.replaceAll('_', ' ').toUpperCase()}?\n\n'
          'Reference: ${_txnRefController.text.trim()}',
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
            child: const Text('Confirm & Record'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await ref
        .read(paymentActionsProvider.notifier)
        .recordPayment(
          studentId: _selectedStudent!['id'].toString(),
          studentName: _selectedStudent!['full_name'].toString(),
          studentCode: _selectedStudent!['student_id']?.toString(),
          courseId: _selectedCourse?['id']?.toString(),
          courseName: _selectedCourse?['title']?.toString(),
          amount: amount,
          paymentMethod: _paymentMethod,
          status: _status,
          paymentDate: _paymentDate,
          transactionRef: _txnRefController.text.trim(),
          notes: _notesController.text.trim(),
        );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment of ${CurrencyFormatter.format(amount)} recorded successfully.',
          ),
          backgroundColor: AppColors.primaryForest,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final error = ref.read(paymentActionsProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Failed to record payment transaction.'),
          backgroundColor: AppColors.accentTerracotta,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _initiateRazorpayPayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStudent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an active student first.'),
          backgroundColor: AppColors.accentTerracotta,
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment amount must be greater than zero.'),
          backgroundColor: AppColors.accentTerracotta,
        ),
      );
      return;
    }

    setState(() {
      _isRazorpayProcessing = true;
      _razorpayStatusMessage = 'Creating secure Razorpay order on server...';
    });

    try {
      final request = RazorpayOrderRequest(
        studentId: _selectedStudent!['id'].toString(),
        courseId: _selectedCourse?['id']?.toString(),
        amount: amount,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      final orderResponse = await ref
          .read(paymentActionsProvider.notifier)
          .createRazorpayOrder(request);

      if (orderResponse == null || !mounted) {
        setState(() {
          _isRazorpayProcessing = false;
          _razorpayStatusMessage = null;
        });
        return;
      }

      _activeRazorpayOrderId = orderResponse.orderId;
      _activePaymentId = orderResponse.paymentId;

      setState(() {
        _razorpayStatusMessage = 'Launching official Razorpay checkout...';
      });

      _razorpayService.openCheckout(
        keyId: orderResponse.keyId,
        orderId: orderResponse.orderId,
        amountPaise: orderResponse.amountPaise,
        studentName: _selectedStudent!['full_name'].toString(),
        studentEmail: _selectedStudent!['email']?.toString(),
        studentPhone: _selectedStudent!['phone']?.toString(),
        courseTitle: _selectedCourse?['title']?.toString(),
      );
    } catch (e) {
      _razorpayService.resetActiveState();
      if (!mounted) return;
      setState(() {
        _isRazorpayProcessing = false;
        _razorpayStatusMessage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to initiate Razorpay order: $e'),
          backgroundColor: AppColors.accentTerracotta,
        ),
      );
    }
  }

  Future<void> _onRazorpaySuccess(PaymentSuccessResponse response) async {
    if (!mounted) return;

    setState(() {
      _isRazorpayProcessing = true;
      _razorpayStatusMessage =
          'Cryptographically verifying payment with server...';
    });

    final verificationRequest = RazorpayVerificationRequest(
      paymentId: _activePaymentId ?? '',
      razorpayPaymentId: response.paymentId ?? '',
      razorpayOrderId: response.orderId ?? _activeRazorpayOrderId ?? '',
      razorpaySignature: response.signature ?? '',
    );

    final result = await ref
        .read(paymentActionsProvider.notifier)
        .verifyRazorpayPayment(verificationRequest);

    if (!mounted) return;

    setState(() {
      _isRazorpayProcessing = false;
      _razorpayStatusMessage = null;
    });

    if (result.success && result.payment != null) {
      Navigator.pop(context); // Close bottom sheet
      _showPaymentSuccessDialog(result.payment!, result.receiptNumber);
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: AppColors.accentTerracotta,
              ),
              SizedBox(width: 8),
              Text('Verification Pending / Failed'),
            ],
          ),
          content: Text(
            result.error ?? 'Payment was captured by gateway, but backend cryptographic verification reported an issue. Transaction remains pending audit.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryForest,
              ),
              child: const Text('Acknowledge'),
            ),
          ],
        ),
      );
    }
  }

  void _onRazorpayFailure(PaymentFailureResponse response) {
    _razorpayService.resetActiveState();
    if (!mounted) return;
    setState(() {
      _isRazorpayProcessing = false;
      _razorpayStatusMessage = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Razorpay payment cancelled or failed: ${response.message ?? 'User cancelled'} (Code ${response.code})',
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onRazorpayWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected external wallet: ${response.walletName}'),
        backgroundColor: AppColors.primaryForest,
      ),
    );
  }

  void _showPaymentSuccessDialog(Payment payment, String? receiptNumber) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.forestSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primaryForest,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Payment Verified & Captured',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Successfully received ${CurrencyFormatter.format(payment.amount)} from ${payment.studentName}.',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warmCream,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Receipt No: ${receiptNumber ?? payment.receiptNumber}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gateway ID: ${payment.transactionRef}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryForest,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PaymentReceiptPreviewScreen(payment: payment),
                ),
              );
            },
            icon: const Icon(Icons.receipt_rounded, size: 16),
            label: const Text('View Official Receipt'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final availableHeight = mediaQuery.size.height;
    final maxSheetHeight = (availableHeight - bottomInset).clamp(
      320.0,
      availableHeight,
    );

    final studentsAsync = ref.watch(studentsWithEnrollmentsProvider);
    final actionState = ref.watch(paymentActionsProvider);

    return Container(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusLarge),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Modal Handle
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

            // Header Row
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
                      Icons.add_card_rounded,
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
                          'Record Fee Payment',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Issue institutional invoice and reconcile balance',
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

            // Form Body
            Expanded(
              child: studentsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryForest,
                  ),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Error loading eligible students: $err'),
                  ),
                ),
                data: (allStudents) {
                  // Preselect initial student if specified
                  if (_selectedStudent == null &&
                      _selectedStudentId != null &&
                      allStudents.isNotEmpty) {
                    final match = allStudents.firstWhere(
                      (s) => s['id'] == _selectedStudentId,
                      orElse: () => allStudents.first,
                    );
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _onStudentSelected(match, allStudents);
                    });
                  }

                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Payment Mode Selector Tab (Manual vs Online Razorpay)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurfaceVariant
                                  : AppColors.warmCream,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildModeTab(
                                    label: 'Manual Payment',
                                    icon: Icons.receipt_long_rounded,
                                    isSelected: !_isRazorpayMode,
                                    onTap: () =>
                                        setState(() => _isRazorpayMode = false),
                                    isDark: isDark,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: _buildModeTab(
                                    label: 'Razorpay Online',
                                    icon: Icons.flash_on_rounded,
                                    isSelected: _isRazorpayMode,
                                    onTap: () =>
                                        setState(() => _isRazorpayMode = true),
                                    isDark: isDark,
                                    badge: 'GATEWAY',
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // 1. Select Student
                          Text(
                            'SELECT STUDENT *',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryForest,
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedStudentId,
                            isExpanded: true,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: isDark
                                  ? AppColors.darkSurfaceVariant
                                  : AppColors.warmCreamLight,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            hint: const Text('Choose enrolled student'),
                            items: allStudents.map((s) {
                              return DropdownMenuItem<String>(
                                value: s['id']?.toString(),
                                child: Text(
                                  '${s['full_name']} (${s['student_id']})',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                final s = allStudents.firstWhere(
                                  (st) => st['id'] == val,
                                );
                                _onStudentSelected(s, allStudents);
                              }
                            },
                            validator: (v) => v == null
                                ? 'Student selection is required'
                                : null,
                          ),

                          if (_selectedStudent != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.forestSoft.withValues(
                                  alpha: 0.4,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.primaryForest.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.school_rounded,
                                    size: 16,
                                    color: AppColors.primaryForest,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'ID: ${_selectedStudent!['student_id']} · ${_selectedStudent!['email']}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 18),

                          // 2. Select Course or Enrollment
                          Text(
                            'SELECT COURSE / ENROLLMENT',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryForest,
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedCourse?['id']?.toString(),
                            isExpanded: true,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: isDark
                                  ? AppColors.darkSurfaceVariant
                                  : AppColors.warmCreamLight,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            hint: const Text('Institutional Fee / All Courses'),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text(
                                  'General Institutional Program / Subscription',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                              if (_selectedStudent != null)
                                ...((_selectedStudent!['courses']
                                            as List<dynamic>?) ??
                                        [])
                                    .map((c) {
                                      final cMap = c as Map<String, dynamic>;
                                      return DropdownMenuItem<String>(
                                        value: cMap['id']?.toString(),
                                        child: Text(
                                          '${cMap['title']} (Fee: ${CurrencyFormatter.format(cMap['fee'] as double)})',
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      );
                                    }),
                            ],
                            onChanged: (val) {
                              setState(() {
                                if (val == null) {
                                  _selectedCourse = null;
                                } else {
                                  final courses =
                                      (_selectedStudent?['courses']
                                          as List<dynamic>?) ??
                                      [];
                                  _selectedCourse = courses.firstWhere(
                                    (c) => c['id'] == val,
                                    orElse: () => null,
                                  ) as Map<String, dynamic>?;
                                  final bal =
                                      (_selectedCourse?['balance'] as num?)
                                          ?.toDouble() ??
                                      0.0;
                                  if (bal > 0) {
                                    _amountController.text = bal
                                        .toStringAsFixed(0);
                                  }
                                }
                              });
                            },
                          ),

                          // Billing Telemetry Breakdown Box
                          if (_selectedStudent != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.terracottaSoft.withValues(
                                  alpha: 0.5,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.accentTerracotta.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildBalanceItem(
                                    'Total Fee',
                                    CurrencyFormatter.format(
                                      _selectedCourse != null
                                          ? (_selectedCourse!['fee'] as double)
                                          : (_selectedStudent!['total_fee']
                                                as double),
                                    ),
                                  ),
                                  _buildBalanceItem(
                                    'Already Paid',
                                    CurrencyFormatter.format(
                                      _selectedCourse != null
                                          ? (_selectedCourse!['paid'] as double)
                                          : (_selectedStudent!['total_paid']
                                                as double),
                                    ),
                                    color: AppColors.primaryForest,
                                  ),
                                  _buildBalanceItem(
                                    'Outstanding',
                                    CurrencyFormatter.format(
                                      _selectedCourse != null
                                          ? (_selectedCourse!['balance']
                                                as double)
                                          : (_selectedStudent!['outstanding_balance']
                                                as double),
                                    ),
                                    color: AppColors.accentTerracotta,
                                    isBold: true,
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 18),

                          // 3. Payment Amount
                          Text(
                            'PAYMENT AMOUNT (INR) *',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryForest,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                Icons.currency_rupee_rounded,
                                size: 18,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? AppColors.darkSurfaceVariant
                                  : AppColors.warmCreamLight,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              hintText: 'e.g. 25000',
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Please enter payment amount';
                              }
                              final val = double.tryParse(v.trim());
                              if (val == null || val <= 0) {
                                return 'Amount must be greater than zero';
                              }
                              // Soft check on balance
                              if (_selectedStudent != null) {
                                final maxBal = _selectedCourse != null
                                    ? (_selectedCourse!['balance'] as double)
                                    : (_selectedStudent!['outstanding_balance']
                                          as double);
                                if (maxBal > 0 && val > maxBal * 1.5) {
                                  return 'Amount exceeds outstanding balance substantially.';
                                }
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 18),

                          if (!_isRazorpayMode) ...[
                            // 4. Payment Date & Method Row
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'PAYMENT DATE *',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.primaryForest,
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      InkWell(
                                        onTap: () async {
                                          final picked = await showDatePicker(
                                            context: context,
                                            initialDate: _paymentDate,
                                            firstDate: DateTime(2020),
                                            lastDate: DateTime.now().add(
                                              const Duration(days: 30),
                                            ),
                                          );
                                          if (picked != null) {
                                            setState(
                                              () => _paymentDate = picked,
                                            );
                                          }
                                        },
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? AppColors.darkSurfaceVariant
                                                : AppColors.warmCreamLight,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color: Colors.grey.withValues(
                                                alpha: 0.4,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.calendar_today_rounded,
                                                size: 16,
                                                color: AppColors.primaryForest,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  DateFormat('dd MMM yyyy')
                                                      .format(_paymentDate),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'VERIFICATION STATUS',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.primaryForest,
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      DropdownButtonFormField<String>(
                                        initialValue: _status,
                                        isExpanded: true,
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: isDark
                                              ? AppColors.darkSurfaceVariant
                                              : AppColors.warmCreamLight,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 10,
                                              ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                        items: const [
                                          DropdownMenuItem(
                                            value: 'verified',
                                            child: Text(
                                              'Verified (Credit)',
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                              style: TextStyle(fontSize: 11),
                                            ),
                                          ),
                                          DropdownMenuItem(
                                            value: 'pending',
                                            child: Text(
                                              'Pending Approval',
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                              style: TextStyle(fontSize: 11),
                                            ),
                                          ),
                                        ],
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() => _status = val);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),

                            // 5. Payment Method
                            Text(
                              'PAYMENT METHOD *',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryForest,
                              ),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              initialValue: _paymentMethod,
                              isExpanded: true,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: isDark
                                    ? AppColors.darkSurfaceVariant
                                    : AppColors.warmCreamLight,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              items: _methods.map((m) {
                                return DropdownMenuItem(
                                  value: m['id'],
                                  child: Text(
                                    m['label']!,
                                    style: const TextStyle(fontSize: 12.5),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _paymentMethod = val);
                                }
                              },
                            ),

                            const SizedBox(height: 18),

                            // 6. Transaction Reference Number
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'TRANSACTION / REFERENCE ID *',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryForest,
                                  ),
                                ),
                                TextButton(
                                  onPressed: _generateReference,
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(50, 24),
                                  ),
                                  child: const Text(
                                    'Generate Ref',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _txnRefController,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  Icons.pin_rounded,
                                  size: 18,
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? AppColors.darkSurfaceVariant
                                    : AppColors.warmCreamLight,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                hintText: 'e.g. UTR / Razorpay payment ID / Cash slip #',
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Transaction reference is mandatory';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 18),

                            // 7. Notes / Remarks
                            Text(
                              'ADMINISTRATIVE REMARKS / PROOF NOTES',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryForest,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _notesController,
                              maxLines: 2,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: isDark
                                    ? AppColors.darkSurfaceVariant
                                    : AppColors.warmCreamLight,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                hintText: 'Optional UTR verification notes or scholarship details...',
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: actionState.isLoading
                                    ? null
                                    : _submitPayment,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primaryForest,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: actionState.isLoading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.check_circle_outline_rounded,
                                        size: 18,
                                      ),
                                label: Text(
                                  actionState.isLoading
                                      ? 'Recording Transaction...'
                                      : 'Confirm & Issue Receipt',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ] else ...[
                            // Razorpay Online Gateway Panel
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkSurfaceVariant
                                    : AppColors.warmCream,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primaryForest.withValues(
                                    alpha: 0.25,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryForest,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: const Text(
                                          'RAZORPAY STANDARD CHECKOUT',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.forestSoft,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: const Text(
                                          'TEST / LIVE',
                                          style: TextStyle(
                                            color: AppColors.primaryForest,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Supported Payment Methods',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      _buildMethodBadge('UPI / QR'),
                                      _buildMethodBadge('Google Pay'),
                                      _buildMethodBadge('PhonePe'),
                                      _buildMethodBadge('Credit Cards'),
                                      _buildMethodBadge('Debit Cards'),
                                      _buildMethodBadge('Net Banking'),
                                      _buildMethodBadge('Wallets'),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Divider(height: 1),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.verified_user_rounded,
                                        size: 15,
                                        color: AppColors.primaryForest,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Cryptographic HMAC SHA-256 signature verification enabled on Supabase Edge Function.',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            color: isDark
                                                ? AppColors.darkTextSecondary
                                                : AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Notes / Remarks for online order
                            Text(
                              'OPTIONAL ORDER NOTES / REMARKS',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryForest,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _notesController,
                              maxLines: 2,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: isDark
                                    ? AppColors.darkSurfaceVariant
                                    : AppColors.warmCreamLight,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                hintText: 'Optional notes associated with this online transaction...',
                              ),
                            ),

                            const SizedBox(height: 18),

                            // Processing Status Banner
                            if (_isRazorpayProcessing &&
                                _razorpayStatusMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: AppColors.forestSoft,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.primaryForest.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primaryForest,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _razorpayStatusMessage!,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primaryForest,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Razorpay Launch Button
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed:
                                    (_isRazorpayProcessing ||
                                        actionState.isLoading)
                                    ? null
                                    : _initiateRazorpayPayment,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primaryForest,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon:
                                    (_isRazorpayProcessing ||
                                        actionState.isLoading)
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.flash_on_rounded,
                                        size: 18,
                                      ),
                                label: Text(
                                  _isRazorpayProcessing
                                      ? 'Processing Gateway...'
                                      : 'Pay with Razorpay (${_amountController.text.trim().isNotEmpty ? CurrencyFormatter.format(double.tryParse(_amountController.text.trim()) ?? 0.0) : "Enter Amount"})',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
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

  Widget _buildBalanceItem(
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
            fontSize: 12,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildModeTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    String? badge,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.darkSurfaceVariant : AppColors.forestSoft)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryForest
                : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? AppColors.primaryForest
                  : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? AppColors.primaryForest
                      : (isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary),
                ),
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 1.5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryForest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMethodBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
