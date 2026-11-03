import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/models/student_fee_profile.dart';
import '../providers/payment_providers.dart';
import '../screens/student_payment_history_sheet.dart';

class PaymentReportsTab extends ConsumerStatefulWidget {
  const PaymentReportsTab({super.key});

  @override
  ConsumerState<PaymentReportsTab> createState() => _PaymentReportsTabState();
}

class _PaymentReportsTabState extends ConsumerState<PaymentReportsTab> {
  String _selectedReportType =
      'student_dues'; // 'student_dues', 'course_wise', 'monthly', 'methods'

  Future<void> _exportCsv({
    required List<StudentFeeProfile> profiles,
    required Map<String, double> courseWise,
  }) async {
    final buffer = StringBuffer();

    if (_selectedReportType == 'student_dues') {
      buffer.writeln(
        'Student ID,Full Name,Email,Phone,Total Fee,Total Paid,Outstanding Balance,Status',
      );
      for (final p in profiles) {
        buffer.writeln(
          '"${p.studentCode}","${p.studentName}","${p.email}","${p.phone}",${p.totalCourseFee},${p.totalPaid},${p.outstandingBalance},"${p.derivedStatus}"',
        );
      }
    } else if (_selectedReportType == 'course_wise') {
      buffer.writeln('Course Name,Total Verified Collections (INR)');
      for (final e in courseWise.entries) {
        buffer.writeln('"${e.key}",${e.value}');
      }
    }

    final csvString = buffer.toString();
    await Clipboard.setData(ClipboardData(text: csvString));

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('CSV Report Generated'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Report CSV data has been copied to your clipboard and is ready to paste into Excel or Google Sheets.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(maxHeight: 180),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: SingleChildScrollView(
                child: Text(
                  csvString,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summaryAsync = ref.watch(paymentSummaryProvider);
    final profilesAsync = ref.watch(allStudentFeeProfilesProvider);

    return RefreshIndicator(
      color: AppColors.primaryForest,
      onRefresh: () async {
        ref.invalidate(paymentSummaryProvider);
        ref.invalidate(allStudentFeeProfilesProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report Category Selector Bar
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Audit & Reconciliation Reports',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      profilesAsync.when(
                        data: (profiles) => summaryAsync.when(
                          data: (summary) => TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              minimumSize: const Size(0, 32),
                            ),
                            onPressed: () => _exportCsv(
                              profiles: profiles,
                              courseWise: summary.courseWiseCollections,
                            ),
                            icon: const Icon(Icons.download_rounded, size: 16),
                            label: const Text(
                              'Export / Share',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, _) => const SizedBox.shrink(),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildReportChip(
                          id: 'student_dues',
                          label: 'Student Dues & Aging',
                          icon: Icons.people_outline_rounded,
                        ),
                        const SizedBox(width: 8),
                        _buildReportChip(
                          id: 'course_wise',
                          label: 'Course Collections',
                          icon: Icons.menu_book_rounded,
                        ),
                        const SizedBox(width: 8),
                        _buildReportChip(
                          id: 'monthly',
                          label: 'Monthly Run-Rate',
                          icon: Icons.calendar_today_rounded,
                        ),
                        const SizedBox(width: 8),
                        _buildReportChip(
                          id: 'methods',
                          label: 'Payment Methods',
                          icon: Icons.pie_chart_rounded,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Dynamic Report Content
            if (_selectedReportType == 'student_dues') ...[
              profilesAsync.when(
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
                    child: Text('Error loading student fee profiles: $err'),
                  ),
                ),
                data: (profiles) {
                  final withDues = profiles
                      .where((p) => p.outstandingBalance > 0)
                      .toList();
                  final fullyPaid = profiles
                      .where((p) => p.outstandingBalance == 0)
                      .toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Outstanding Fee Accounts (${withDues.length})',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '${fullyPaid.length} Fully Paid',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.primaryForest,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (withDues.isEmpty)
                        const AppCard(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(
                              child: Text(
                                'All active students have fully settled their accounts.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primaryForest,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: withDues.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final p = withDues[index];
                            final isOverdue = p.derivedStatus == 'overdue';

                            return AppCard(
                              child: InkWell(
                                onTap: () => StudentPaymentHistorySheet.show(
                                  context,
                                  studentId: p.studentId,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: isOverdue
                                            ? AppColors.terracottaSoft
                                            : AppColors.forestSoft,
                                        child: Icon(
                                          isOverdue
                                              ? Icons.warning_amber_rounded
                                              : Icons.person_outline_rounded,
                                          size: 18,
                                          color: isOverdue
                                              ? AppColors.accentTerracotta
                                              : AppColors.primaryForest,
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
                                                fontSize: 13,
                                              ),
                                            ),
                                            Text(
                                              'ID: ${p.studentCode} · Paid: ${CurrencyFormatter.format(p.totalPaid)} / ${CurrencyFormatter.format(p.totalCourseFee)}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            CurrencyFormatter.format(
                                              p.outstandingBalance,
                                            ),
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w900,
                                              color: isOverdue
                                                  ? AppColors.accentTerracotta
                                                  : AppColors.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            isOverdue
                                                ? 'OVERDUE'
                                                : '${p.paymentCompletionPercentage.toStringAsFixed(0)}% paid',
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w800,
                                              color: isOverdue
                                                  ? AppColors.accentTerracotta
                                                  : AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  );
                },
              ),
            ] else if (_selectedReportType == 'course_wise') ...[
              summaryAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryForest,
                  ),
                ),
                error: (err, _) => AppCard(child: Text('Error: $err')),
                data: (summary) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Course-Wise Fee Collections',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (summary.courseWiseCollections.isEmpty)
                        const AppCard(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(
                              child: Text(
                                'No course collections recorded in current timeframe.',
                              ),
                            ),
                          ),
                        )
                      else
                        ...summary.courseWiseCollections.entries.map((e) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: AppCard(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.menu_book_rounded,
                                          size: 16,
                                          color: AppColors.primaryForest,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            e.key,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.format(e.value),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: AppColors.primaryForest,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  );
                },
              ),
            ] else if (_selectedReportType == 'monthly') ...[
              summaryAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryForest,
                  ),
                ),
                error: (err, _) => AppCard(child: Text('Error: $err')),
                data: (summary) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monthly Revenue History',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (summary.monthlyCollections.isEmpty)
                        const AppCard(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(
                              child: Text('No historical monthly collections.'),
                            ),
                          ),
                        )
                      else
                        ...summary.monthlyCollections.entries.map((e) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: AppCard(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_month_rounded,
                                        size: 16,
                                        color: AppColors.primaryForest,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        e.key,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    CurrencyFormatter.format(e.value),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: AppColors.primaryForest,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  );
                },
              ),
            ] else if (_selectedReportType == 'methods') ...[
              summaryAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryForest,
                  ),
                ),
                error: (err, _) => AppCard(child: Text('Error: $err')),
                data: (summary) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Channels & Gateway Auditing',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...summary.methodBreakdown.entries.map((e) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: AppCard(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.account_balance_wallet_rounded,
                                      size: 16,
                                      color: AppColors.primaryForest,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      e.key,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  CurrencyFormatter.format(e.value),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: AppColors.primaryForest,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReportChip({
    required String id,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedReportType == id;
    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 14,
        color: isSelected ? Colors.white : AppColors.primaryForest,
      ),
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
        setState(() => _selectedReportType = id);
      },
    );
  }
}
