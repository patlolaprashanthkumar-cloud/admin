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

/// StudentProfileScreen
///
/// Comprehensive institutional dossier for an enrolled student.
/// Displays academic credentials, learning delivery format, timetable cohort,
/// multi-category stream assignments, fee settlement ledger, and active LMS cohorts.
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
      return AppColors.primaryNavy;
    }
  }

  String _formatLearningFormat(String format) {
    switch (format.trim().toLowerCase()) {
      case 'hybrid':
        return 'Online + Offline Classes';
      case 'live':
        return 'Live Online Classes';
      case 'recorded':
        return 'Recorded Classes';
      case 'live_recorded':
        return 'Live + Recorded Classes';
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
                    backgroundColor: AppColors.primaryNavy,
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
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.backgroundWarmOffWhite,
      appBar: AppBar(
        title: const Text('Student Academic Profile'),
        backgroundColor: isDark
            ? AppColors.darkSurface
            : AppColors.backgroundWarmOffWhite,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Refresh Profile',
            icon: Icon(
              Icons.refresh_rounded,
              color: isDark ? Colors.white : AppColors.primaryNavy,
            ),
            onPressed: () {
              ref.invalidate(studentDetailFamily(studentId));
              ref.invalidate(studentLmsDetailsFamily(studentId));
              ref.invalidate(studentFeeProfileProvider(studentId));
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: studentAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryNavy),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Error loading student: $err',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ),
        data: (student) {
          if (student == null) {
            return const Center(child: Text('Student record not found'));
          }

          final isActive = student.accountStatus.toLowerCase() == 'active';

          return ResponsiveLayout(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Student Academic Header Card
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface
                          : AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.borderNeutral,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.25 : 0.04,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Avatar
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.primaryNavy.withValues(
                                        alpha: 0.35,
                                      )
                                    : AppColors.forestSoft,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primaryNavy.withValues(
                                    alpha: 0.18,
                                  ),
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  student.fullName.isNotEmpty
                                      ? student.fullName
                                            .substring(0, 1)
                                            .toUpperCase()
                                      : 'S',
                                  style: TextStyle(
                                    color: isDark
                                        ? AppColors.accentOrangeLight
                                        : AppColors.primaryNavy,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 22,
                                  ),
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
                                                fontSize: 17,
                                                color: isDark
                                                    ? AppColors.darkTextPrimary
                                                    : AppColors.textPrimary,
                                              ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isActive
                                              ? (isDark
                                                    ? AppColors.success
                                                          .withValues(
                                                            alpha: 0.2,
                                                          )
                                                    : AppColors.successSoft)
                                              : (isDark
                                                    ? Colors.white.withValues(
                                                        alpha: 0.08,
                                                      )
                                                    : Colors.grey.withValues(
                                                        alpha: 0.15,
                                                      )),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: isActive
                                                ? AppColors.success.withValues(
                                                    alpha: 0.35,
                                                  )
                                                : AppColors.borderNeutral,
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Text(
                                          student.accountStatus,
                                          style: TextStyle(
                                            color: isActive
                                                ? (isDark
                                                      ? const Color(0xFF34D399)
                                                      : AppColors.success)
                                                : (isDark
                                                      ? AppColors
                                                            .darkTextSecondary
                                                      : AppColors
                                                            .textSecondary),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),

                                  // Student ID & Qualifications
                                  Text(
                                    '${student.studentId} · ${student.qualification} · ${student.educationLevel}',
                                    style: TextStyle(
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 3),

                                  // Contact
                                  Text(
                                    '${student.email} · ${student.phone} · ${student.city ?? "India"}',
                                    style: TextStyle(
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                                .withValues(alpha: 0.8)
                                          : AppColors.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),

                                  // Learning Format & Timetable Badges (Preserved for tests)
                                  if ((student.learningFormat != null &&
                                          student.learningFormat!
                                              .trim()
                                              .isNotEmpty) ||
                                      (student.preferredSlot != null &&
                                          student.preferredSlot!
                                              .trim()
                                              .isNotEmpty)) ...[
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: [
                                        if (student.learningFormat != null &&
                                            student.learningFormat!
                                                .trim()
                                                .isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? AppColors.primaryNavy
                                                        .withValues(alpha: 0.25)
                                                  : AppColors.forestSoft,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: AppColors.primaryNavy
                                                    .withValues(alpha: 0.25),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.school_outlined,
                                                  size: 13,
                                                  color: isDark
                                                      ? AppColors
                                                            .accentOrangeLight
                                                      : AppColors.primaryNavy,
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  _formatLearningFormat(
                                                    student.learningFormat!,
                                                  ),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color: isDark
                                                        ? AppColors
                                                              .accentOrangeLight
                                                        : AppColors.primaryNavy,
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
                                              vertical: 3.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? AppColors.info.withValues(
                                                      alpha: 0.2,
                                                    )
                                                  : AppColors.infoSoft,
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
                                                const SizedBox(width: 5),
                                                Text(
                                                  student.preferredSlot!.trim(),
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
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
                        Divider(
                          height: 1,
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.borderNeutral,
                        ),
                        const SizedBox(height: 12),

                        // Assigned Multi-Categories Header Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Assigned Academic Streams (${student.assignedCategories.length})',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12.5,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.textPrimary,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => _showManageCategoriesDialog(
                                context,
                                ref,
                                student,
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primaryNavy,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                              ),
                              icon: const Icon(Icons.edit_rounded, size: 14),
                              label: const Text(
                                'Manage Streams',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (student.assignedCategories.isEmpty)
                          Text(
                            'Legacy category: ${student.preferredCategory}',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
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
                                  alpha: isDark ? 0.2 : 0.12,
                                ),
                                label: Text(
                                  c.name,
                                  style: TextStyle(
                                    color: catColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  side: BorderSide(
                                    color: catColor.withValues(alpha: 0.3),
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

                  // 3. Curriculum Streams & LMS Cohorts
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryNavy,
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
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  lmsGroupsAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(
                          color: AppColors.primaryNavy,
                        ),
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
                color: AppColors.primaryNavy,
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

        Color statusColor = AppColors.success;
        if (profile.derivedStatus == 'partially_paid') {
          statusColor = AppColors.accentOrange;
        } else if (profile.derivedStatus == 'overdue') {
          statusColor = AppColors.error;
        } else if (profile.derivedStatus == 'pending') {
          statusColor = AppColors.accentOrange;
        } else if (profile.derivedStatus.contains('refund')) {
          statusColor = Colors.indigo[700]!;
        }

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.cardWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primaryNavy.withValues(
                alpha: isDark ? 0.4 : 0.25,
              ),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
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
                          color: isDark
                              ? AppColors.primaryNavy.withValues(alpha: 0.3)
                              : AppColors.forestSoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 16,
                          color: isDark
                              ? AppColors.accentOrangeLight
                              : AppColors.primaryNavy,
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
                      color: statusColor.withValues(alpha: isDark ? 0.2 : 0.12),
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
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 14),

              // 3 Figures
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildFeeStat(
                    'Total Fees',
                    CurrencyFormatter.format(profile.totalCourseFee),
                    isDark: isDark,
                  ),
                  _buildFeeStat(
                    'Paid To Date',
                    CurrencyFormatter.format(profile.totalPaid),
                    color: AppColors.success,
                    isDark: isDark,
                  ),
                  _buildFeeStat(
                    'Outstanding',
                    CurrencyFormatter.format(profile.outstandingBalance),
                    color: profile.outstandingBalance > 0
                        ? AppColors.accentOrange
                        : AppColors.success,
                    isBold: true,
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(
                height: 1,
                color: isDark ? AppColors.darkBorder : AppColors.borderNeutral,
              ),
              const SizedBox(height: 10),

              // Actions Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        side: BorderSide(
                          color: AppColors.primaryNavy.withValues(alpha: 0.4),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => StudentPaymentHistorySheet.show(
                        context,
                        studentId: student.id,
                      ),
                      icon: const Icon(Icons.history_rounded, size: 15),
                      label: const Text(
                        'View Full Ledger',
                        style: TextStyle(fontSize: 11.5),
                      ),
                    ),
                  ),
                  if (profile.outstandingBalance > 0) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryNavy,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => RecordPaymentSheet.show(
                          context,
                          initialStudentId: student.id,
                        ),
                        icon: const Icon(Icons.add_card_rounded, size: 15),
                        label: const Text(
                          'Record Fee',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
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
    bool isDark = false,
  }) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
            color:
                color ??
                (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
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
      return AppColors.primaryNavy;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catColor = _parseHex(group.category.color);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: catColor.withValues(alpha: isDark ? 0.45 : 0.35),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: isDark ? 0.2 : 0.12),
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
                    color: isDark
                        ? AppColors.primaryNavy.withValues(alpha: 0.3)
                        : AppColors.forestSoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${group.courses.length} Courses Enrolled',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.accentOrangeLight
                          : AppColors.primaryNavy,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Courses under this Category
            Text(
              'Courses in Stream',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            if (group.courses.isEmpty)
              Text(
                'No courses enrolled under this stream yet',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                  fontSize: 11,
                ),
              )
            else
              ...group.courses.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : AppColors.forestSoft.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.borderSubtle,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.book_rounded,
                          size: 14,
                          color: isDark
                              ? AppColors.accentOrangeLight
                              : AppColors.primaryNavy,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            c['title']?.toString() ?? 'Course',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '${c['duration_weeks'] ?? 8} wks · Fee: ${CurrencyFormatter.format((c['fee'] as num?)?.toDouble() ?? 0)}',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
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
              Text(
                'Assigned Stream Instructors',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
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
                      color: AppColors.accentOrange,
                    ),
                    label: Text(
                      '${ins['full_name']} (${ins['specialization']})',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: isDark
                        ? AppColors.accentOrange.withValues(alpha: 0.15)
                        : AppColors.accentOrangeSoft,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: BorderSide(
                        color: AppColors.accentOrange.withValues(alpha: 0.25),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
            ],

            // Timetable & Live Classes
            if (group.liveClasses.isNotEmpty) ...[
              Text(
                'Live Clinical Lectures & Timetable',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              ...group.liveClasses.map(
                (lc) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.videocam_rounded,
                        size: 14,
                        color: isDark
                            ? AppColors.accentOrangeLight
                            : AppColors.primaryNavy,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${lc['title']} (${lc['course_name']})',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        lc['scheduled_at']?.toString().substring(0, 10) ?? '',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
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
              Text(
                'Stream Assessments & Evaluations',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
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
                        color: AppColors.accentOrange,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${asm['title']} · ${asm['total_marks'] ?? 100} Marks',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          ),
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
