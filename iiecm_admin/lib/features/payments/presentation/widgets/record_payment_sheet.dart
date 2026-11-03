import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../providers/payment_providers.dart';

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
  }

  void _generateReference() {
    final now = DateTime.now();
    final dateCode = DateFormat('yyyyMMdd').format(now);
    final randomDigits = math.Random().nextInt(9000) + 1000;
    _txnRefController.text = 'TXN-$dateCode-$randomDigits';
  }

  @override
  void dispose() {
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

                          // 4. Payment Date & Method Row
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                          setState(() => _paymentDate = picked);
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
}
