import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../payments/presentation/providers/payment_providers.dart';
import '../../../payments/presentation/screens/student_payment_history_sheet.dart';
import '../../../payments/presentation/widgets/record_payment_sheet.dart';
import '../../domain/models/student.dart';
import '../providers/students_provider.dart';

class StudentProfileScreen extends ConsumerWidget {
  final String studentId;

  const StudentProfileScreen({super.key, required this.studentId});

  Color _parseHex(String hex) {
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return AppColors.primaryForest;
    }
  }

  String _formatLearningFormat(String format) {
    switch (format.trim().toLowerCase()) {
      case 'hybrid':
        return 'Hybrid (Virtual Lecture + Clinical Onsite)';
      case 'live':
        return 'Live Virtual Synchronous';
      case 'recorded':
        return 'Asynchronous / Recorded LMS Modules';
      default:
        return format.trim();
    }
  }

  void _showManageCategoriesDialog(
    BuildContext context,
    WidgetRef ref,
    Student student,
  ) {
    final allCategories = ref.read(categoryNotifierProvider).categories;
    final selectedCategoryIds = student.assignedCategories
        .map((c) => c.id)
        .toSet();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Manage Assigned Categories'),
              content: SizedBox(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.5,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: allCategories.length,
                  itemBuilder: (context, index) {
                    final cat = allCategories[index];
                    final isChecked = selectedCategoryIds.contains(cat.id);
                    final catColor = _parseHex(cat.color);

                    return CheckboxListTile(
                      value: isChecked,
                      activeColor: catColor,
                      title: Text(
                        cat.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        cat.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11),
                      ),
                      onChanged: (val) {
                        setDialogState(() {
                          if (val == true) {
                            selectedCategoryIds.add(cat.id);
                          } else {
                            selectedCategoryIds.remove(cat.id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryForest,
                  ),
                  onPressed: () async {
                    await ref
                        .read(studentsNotifierProvider.notifier)
                        .updateStudentCategories(
                          student.id,
                          selectedCategoryIds.toList(),
                        );
                    ref.invalidate(studentDetailFamily(student.id));
                    ref.invalidate(studentLmsDetailsFamily(student.id));
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Save Categories'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final studentAsync = ref.watch(studentDetailFamily(studentId));
    final lmsGroupsAsync = ref.watch(studentLmsDetailsFamily(studentId));

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      appBar: AppBar(
        title: const Text('Student Academic Profile'),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.warmCream,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(studentDetailFamily(studentId));
              ref.invalidate(studentLmsDetailsFamily(studentId));
            },
          ),
        ],
      ),
      body: studentAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryForest),
        ),
        error: (err, _) => Center(child: Text('Error loading student: $err')),
        data: (student) {
          if (student == null) {
            return const Center(child: Text('Student record not found'));
          }

          return ResponsiveLayout(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Student Header Card
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: AppColors.forestSoft,
                              child: Text(
                                student.fullName.isNotEmpty
                                    ? student.fullName.substring(0, 1)
                                    : 'S',
                                style: const TextStyle(
                                  color: AppColors.primaryForest,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 22,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          student.fullName,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.textPrimary,
                                              ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              student.accountStatus == 'active'
                                              ? AppColors.forestSoft
                                              : Colors.grey.withValues(
                                                  alpha: 0.15,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          student.accountStatus,
                                          style: TextStyle(
                                            color:
                                                student.accountStatus ==
                                                    'active'
                                                ? AppColors.primaryForest
                                                : AppColors.textSecondary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${student.studentId} · ${student.qualification} · ${student.educationLevel}',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${student.email} · ${student.phone} · ${student.city ?? "India"}',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                  if ((student.learningFormat != null &&
                                          student.learningFormat!
                                              .trim()
                                              .isNotEmpty) ||
                                      (student.preferredSlot != null &&
                                          student.preferredSlot!
                                              .trim()
                                              .isNotEmpty)) ...[
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        if (student.learningFormat != null &&
                                            student.learningFormat!
                                                .trim()
                                                .isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.forestSoft,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: AppColors.primaryForest
                                                    .withValues(alpha: 0.25),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.school_outlined,
                                                  size: 13,
                                                  color:
                                                      AppColors.primaryForest,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _formatLearningFormat(
                                                    student.learningFormat!,
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        AppColors.primaryForest,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        if (student.preferredSlot != null &&
                                            student.preferredSlot!
                                                .trim()
                                                .isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.info.withValues(
                                                alpha: 0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: AppColors.info
                                                    .withValues(alpha: 0.25),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.access_time_rounded,
                                                  size: 13,
                                                  color: AppColors.info,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  student.preferredSlot!.trim(),
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.info,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(height: 1),
                        const SizedBox(height: 12),

                        // Assigned Multi-Categories Header Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Assigned Academic Streams (${student.assignedCategories.length})',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => _showManageCategoriesDialog(
                                context,
                                ref,
                                student,
                              ),
                              icon: const Icon(Icons.edit_rounded, size: 14),
                              label: const Text(
                                'Manage Streams',
                                style: TextStyle(fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (student.assignedCategories.isEmpty)
                          Text(
                            'Legacy category: ${student.preferredCategory}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          )
                        else
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: student.assignedCategories.map((c) {
                              final catColor = _parseHex(c.color);
                              return Chip(
                                avatar: Icon(
                                  Icons.category_rounded,
                                  size: 13,
                                  color: catColor,
                                ),
                                backgroundColor: catColor.withValues(
                                  alpha: 0.12,
                                ),
                                label: Text(
                                  c.name,
                                  style: TextStyle(
                                    color: catColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. Financial Ledger & Billing Status
                  _buildStudentFeeCard(context, ref, student, theme, isDark),
                  const SizedBox(height: 20),

                  // 3. CRITICAL REQUIREMENT: Information Organized by Category
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryForest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.view_agenda_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Curriculum Streams & LMS Cohorts',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  lmsGroupsAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (err, _) => AppCard(
                      child: Text('Error loading category LMS data: $err'),
                    ),
                    data: (groups) {
                      if (groups.isEmpty) {
                        return const AppCard(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                'No active courses or category cohorts found for this student.',
                              ),
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: groups
                            .map((grp) => _CategoryLmsCard(group: grp))
                            .toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStudentFeeCard(
    BuildContext context,
    WidgetRef ref,
    Student student,
    ThemeData theme,
    bool isDark,
  ) {
    final feeProfileAsync = ref.watch(studentFeeProfileProvider(student.id));

    return feeProfileAsync.when(
      loading: () => const AppCard(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryForest,
              ),
            ),
          ),
        ),
      ),
      error: (err, _) => AppCard(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text('Financial ledger unavailable: $err'),
        ),
      ),
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();

        Color statusColor = AppColors.primaryForest;
        if (profile.derivedStatus == 'partially_paid') {
          statusColor = AppColors.accentTerracotta;
        } else if (profile.derivedStatus == 'overdue') {
          statusColor = Colors.red[700]!;
        } else if (profile.derivedStatus == 'pending') {
          statusColor = AppColors.accentTerracotta;
        } else if (profile.derivedStatus.contains('refund')) {
          statusColor = Colors.indigo[700]!;
        }

        return AppCard(
          borderSide: BorderSide(
            color: AppColors.primaryForest.withValues(alpha: 0.3),
            width: 1.2,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.forestSoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 16,
                          color: AppColors.primaryForest,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Fee Ledger & Tuition Settlement',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      profile.derivedStatus.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 9.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: profile.paymentCompletionPercentage / 100,
                  backgroundColor: Colors.grey.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  minHeight: 5,
                ),
              ),
              const SizedBox(height: 12),

              // 3 Figures
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildFeeStat(
                    'Total Fees',
                    CurrencyFormatter.format(profile.totalCourseFee),
                  ),
                  _buildFeeStat(
                    'Paid To Date',
                    CurrencyFormatter.format(profile.totalPaid),
                    color: AppColors.primaryForest,
                  ),
                  _buildFeeStat(
                    'Outstanding',
                    CurrencyFormatter.format(profile.outstandingBalance),
                    color: profile.outstandingBalance > 0
                        ? AppColors.accentTerracotta
                        : AppColors.primaryForest,
                    isBold: true,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Actions Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        side: BorderSide(
                          color: AppColors.primaryForest.withValues(alpha: 0.4),
                        ),
                      ),
                      onPressed: () => StudentPaymentHistorySheet.show(
                        context,
                        studentId: student.id,
                      ),
                      icon: const Icon(Icons.history_rounded, size: 14),
                      label: const Text(
                        'View Full Ledger',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                  if (profile.outstandingBalance > 0) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryForest,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onPressed: () => RecordPaymentSheet.show(
                          context,
                          initialStudentId: student.id,
                        ),
                        icon: const Icon(Icons.add_card_rounded, size: 14),
                        label: const Text(
                          'Record Fee',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeeStat(
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
            fontSize: 9,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _CategoryLmsCard extends StatelessWidget {
  final StudentCategoryLmsGroup group;

  const _CategoryLmsCard({required this.group});

  Color _parseHex(String hex) {
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return AppColors.primaryForest;
    }
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _parseHex(group.category.color);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        borderSide: BorderSide(
          color: catColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.category_rounded,
                    color: catColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    group.category.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: catColor,
                      fontSize: 15,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.forestSoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${group.courses.length} Courses Enrolled',
                    style: const TextStyle(
                      color: AppColors.primaryForest,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Courses under this Category
            const Text(
              'Courses in Stream',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
            const SizedBox(height: 6),
            if (group.courses.isEmpty)
              const Text(
                'No courses enrolled under this stream yet',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              )
            else
              ...group.courses.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.forestSoft.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.book_rounded,
                          size: 14,
                          color: AppColors.primaryForest,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            c['title']?.toString() ?? 'Course',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Text(
                          '${c['duration_weeks'] ?? 8} wks · Fee: ${CurrencyFormatter.format((c['fee'] as num?)?.toDouble() ?? 0)}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 10),

            // Assigned Instructors for this Category
            if (group.instructors.isNotEmpty) ...[
              const Text(
                'Assigned Stream Instructors',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: group.instructors.map((ins) {
                  return Chip(
                    avatar: const Icon(
                      Icons.person_pin_rounded,
                      size: 14,
                      color: AppColors.accentTerracotta,
                    ),
                    label: Text(
                      '${ins['full_name']} (${ins['specialization']})',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: AppColors.terracottaSoft,
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
            ],

            // Timetable & Live Classes
            if (group.liveClasses.isNotEmpty) ...[
              const Text(
                'Live Clinical Lectures & Timetable',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              ),
              const SizedBox(height: 4),
              ...group.liveClasses.map(
                (lc) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.videocam_rounded,
                        size: 14,
                        color: AppColors.primaryForest,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${lc['title']} (${lc['course_name']})',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      Text(
                        lc['scheduled_at']?.toString().substring(0, 10) ?? '',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Assessments & Assignments
            if (group.assessments.isNotEmpty) ...[
              const Text(
                'Stream Assessments & Evaluations',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              ),
              const SizedBox(height: 4),
              ...group.assessments.map(
                (asm) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.assignment_turned_in_rounded,
                        size: 14,
                        color: AppColors.accentTerracotta,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${asm['title']} · ${asm['total_marks'] ?? 100} Marks',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
