import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../courses/presentation/providers/courses_provider.dart';
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
    final allCourses = ref.read(coursesNotifierProvider).courses;
    final selectedCategoryIds = student.assignedCategories
        .map((c) => c.id)
        .toSet();
    final selectedCourseIds = student.enrolledCourseIds.toSet();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return AlertDialog(
              title: const Text('Manage Streams & Courses'),
              content: SizedBox(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.6,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: allCategories.length,
                  itemBuilder: (context, index) {
                    final cat = allCategories[index];
                    final isChecked = selectedCategoryIds.contains(cat.id);
                    final catColor = _parseHex(cat.color);
                    final catCourses = allCourses
                        .where((c) => c.categoryId == cat.id)
                        .toList();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0,
                      color: isChecked
                          ? catColor.withValues(alpha: isDark ? 0.15 : 0.06)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : Colors.grey.withValues(alpha: 0.06)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isChecked
                              ? catColor.withValues(alpha: 0.4)
                              : Colors.transparent,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CheckboxListTile(
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
                                    // When unselecting a stream, automatically unselect all its courses
                                    for (final c in catCourses) {
                                      selectedCourseIds.remove(c.id);
                                    }
                                  }
                                });
                              },
                            ),
                            if (isChecked && catCourses.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 20,
                                  right: 12,
                                  bottom: 6,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Registered Courses in Stream:',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    ...catCourses.map((course) {
                                      final isCourseSelected =
                                          selectedCourseIds.contains(course.id);
                                      return CheckboxListTile(
                                        dense: true,
                                        visualDensity: VisualDensity.compact,
                                        contentPadding: EdgeInsets.zero,
                                        value: isCourseSelected,
                                        activeColor: AppColors.primaryNavy,
                                        title: Text(
                                          course.title,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        subtitle: Text(
                                          '${course.durationWeeks} wks · Fee: ${CurrencyFormatter.format(course.fee)}',
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                        onChanged: (cVal) {
                                          setDialogState(() {
                                            if (cVal == true) {
                                              selectedCourseIds.add(course.id);
                                            } else {
                                              selectedCourseIds.remove(course.id);
                                            }
                                          });
                                        },
                                      );
                                    }),
                                  ],
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
                        .updateStudentStreamsAndCourses(
                          student.id,
                          selectedCategoryIds.toList(),
                          selectedCourseIds.toList(),
                        );
                    ref.invalidate(studentDetailFamily(student.id));
                    ref.invalidate(studentLmsDetailsFamily(student.id));
                    ref.invalidate(studentFeeProfileProvider(student.id));
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showUnenrollCourseDialog(
    BuildContext context,
    WidgetRef ref,
    String studentId,
    String courseId,
    String courseTitle,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Unenroll Course Registration'),
          content: Text(
            'Are you sure you want to unenroll this student from "$courseTitle"?\n\n'
            'This removes the active course enrollment. If this was the student\'s only registered course, permanent deletion can then proceed.',
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await ref
                      .read(studentsNotifierProvider.notifier)
                      .unenrollCourse(studentId, courseId);
                  ref.invalidate(studentDetailFamily(studentId));
                  ref.invalidate(studentLmsDetailsFamily(studentId));
                  ref.invalidate(studentFeeProfileProvider(studentId));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Unenrolled from "$courseTitle".'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to unenroll: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              child: const Text('Unenroll Course'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final authState = ref.watch(authNotifierProvider);
    final isSuperAdmin = authState.adminUser?.role.isSuperAdmin ?? false;

    final studentAsync = ref.watch(studentDetailFamily(studentId));
    final lmsGroupsAsync = ref.watch(studentLmsDetailsFamily(studentId));
    final currentStudent = studentAsync.asData?.value;

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
          if (isSuperAdmin && currentStudent != null)
            IconButton(
              tooltip: 'Permanently Delete Student',
              icon: const Icon(
                Icons.delete_forever_rounded,
                color: AppColors.error,
              ),
              onPressed: () => _showPermanentDeleteConfirmation(
                context,
                ref,
                currentStudent,
              ),
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
                            .map((grp) => _CategoryLmsCard(
                                  group: grp,
                                  onUnenrollCourse: (courseId, courseTitle) =>
                                      _showUnenrollCourseDialog(
                                    context,
                                    ref,
                                    student.id,
                                    courseId,
                                    courseTitle,
                                  ),
                                ))
                            .toList(),
                      );
                    },
                  ),
                  if (isSuperAdmin) ...[
                    const SizedBox(height: 24),
                    _buildSuperAdminDangerZone(context, ref, student, isDark),
                  ],
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

  // ===========================================================================
  // Super Admin Permanent Student Deletion & Guardrail Dialogs
  // ===========================================================================

  void _showPermanentDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    Student student,
  ) {
    bool isDeleting = false;
    String? dialogError;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: AppColors.error.withValues(alpha: 0.3),
                  width: 1.2,
                ),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_rounded,
                      color: AppColors.error,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Permanent Deletion',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Are you sure you want to permanently delete student ${student.fullName} (${student.studentId})?',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Critical Guardrails:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.error,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '• This action is permanent and CANNOT be undone.\n'
                            '• Protected financial ledgers (payments) and academic history (enrollments, examinations, submissions) strictly prevent deletion.\n'
                            '• If eligible, all database records and Supabase Auth credentials will be permanently erased.',
                            style: TextStyle(fontSize: 12, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    if (dialogError != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.error),
                        ),
                        child: Text(
                          dialogError!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isDeleting
                      ? null
                      : () async {
                          setDialogState(() {
                            isDeleting = true;
                            dialogError = null;
                          });

                          // 1. Optional Preflight Dependency Eligibility Check
                          try {
                            final preflight = await ref
                                .read(studentRepositoryProvider)
                                .checkStudentDeletionEligibility(student.id);

                            if (preflight['is_eligible'] == false) {
                              final reasons =
                                  (preflight['reasons'] as List?)
                                      ?.map((r) => r.toString())
                                      .toList() ??
                                  [
                                    'Student is ineligible for permanent deletion due to existing dependencies.',
                                  ];
                              final counts = preflight['counts'] is Map
                                  ? Map<String, dynamic>.from(
                                      preflight['counts'] as Map,
                                    )
                                  : null;

                              if (!dialogCtx.mounted) return;
                              Navigator.pop(dialogCtx);

                              if (context.mounted) {
                                _showDependencyBlockedDialog(
                                  context,
                                  student,
                                  StudentDeletionException(
                                    message: reasons.join('\n• '),
                                    statusCode: 409,
                                    code: 'PROTECTED_DEPENDENCIES_EXIST',
                                    studentId: student.id,
                                    counts: counts,
                                  ),
                                );
                              }
                              return;
                            }
                          } catch (_) {
                            // If preflight check encounters an issue, proceed to authoritative Edge Function.
                          }

                          // 2. Authoritative Administrative Deletion via Edge Function
                          try {
                            final result = await ref
                                .read(studentsNotifierProvider.notifier)
                                .deleteStudent(student.id);

                            if (!dialogCtx.mounted) return;
                            Navigator.pop(dialogCtx);

                            if (result.isCompleted) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Student "${student.fullName}" (${student.studentId}) permanently deleted.',
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: AppColors.success,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                Navigator.of(context).pop();
                              }
                            } else if (result.isFailedAuth) {
                              if (context.mounted) {
                                _showPartialFailureDialog(
                                  context,
                                  ref,
                                  student,
                                  result,
                                );
                              }
                            }
                          } on StudentDeletionException catch (e) {
                            if (!dialogCtx.mounted) return;
                            Navigator.pop(dialogCtx);

                            if (context.mounted) {
                              if (e.isConflict) {
                                _showDependencyBlockedDialog(
                                  context,
                                  student,
                                  e,
                                );
                              } else {
                                _showDeletionErrorDialog(context, e.message);
                              }
                            }
                          } catch (e) {
                            if (!dialogCtx.mounted) return;
                            Navigator.pop(dialogCtx);

                            if (context.mounted) {
                              _showDeletionErrorDialog(
                                context,
                                'An unexpected error occurred during student deletion: $e',
                              );
                            }
                          }
                        },
                  child: isDeleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Permanently Delete',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showPartialFailureDialog(
    BuildContext context,
    WidgetRef ref,
    Student student,
    StudentDeletionResult initialResult,
  ) {
    bool isRetrying = false;
    String? currentDeletionRecordId = initialResult.deletionRecordId;
    String? currentErrorMessage = initialResult.message;
    String? retryError;
    int retryAttempt = 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(
                  color: AppColors.accentOrange,
                  width: 1.5,
                ),
              ),
              title: Row(
                children: const [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.accentOrange,
                    size: 26,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Partial Deletion — Auth Recovery Required',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accentOrange,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Student "${student.fullName}" (${student.studentId}) was permanently removed from the database.',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'However, Supabase Auth account cleanup failed during the initial attempt. '
                      'The student database record is permanently purged, but Auth credentials require recovery cleanup. '
                      'You can use the original Student UUID to manually retry Auth cleanup, or retain the Recovery Record ID for audit and support.',
                      style: TextStyle(fontSize: 12.5, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Original Student UUID (for Recovery):',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          SelectableText(
                            student.id,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (currentDeletionRecordId != null) ...[
                            const SizedBox(height: 10),
                            const Text(
                              'Recovery Record ID (Audit & Tracking):',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            SelectableText(
                              currentDeletionRecordId!,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (currentErrorMessage != null &&
                        currentErrorMessage!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Status Detail: $currentErrorMessage',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    if (retryError != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          retryError!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isRetrying
                      ? null
                      : () {
                          Navigator.pop(ctx);
                          Navigator.of(context).pop();
                        },
                  child: const Text('Acknowledge and Exit'),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accentOrange,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isRetrying
                      ? null
                      : () async {
                          setDialogState(() {
                            isRetrying = true;
                            retryError = null;
                          });

                          try {
                            // Call the existing deletion operation using the ORIGINAL student.id (UUID).
                            // The backend Edge Function locates the durable recovery record and retries Auth deletion.
                            final retryResult = await ref
                                .read(studentsNotifierProvider.notifier)
                                .deleteStudent(student.id);

                            if (!dialogContext.mounted) return;

                            if (retryResult.isCompleted) {
                              Navigator.pop(ctx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Auth cleanup completed for "${student.fullName}". Account permanently purged.',
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: AppColors.success,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                Navigator.of(context).pop();
                              }
                            } else if (retryResult.isFailedAuth) {
                              setDialogState(() {
                                isRetrying = false;
                                retryAttempt++;
                                if (retryResult.deletionRecordId != null) {
                                  currentDeletionRecordId =
                                      retryResult.deletionRecordId;
                                }
                                currentErrorMessage = retryResult.message;
                                retryError =
                                    'Auth cleanup attempt $retryAttempt failed: ${retryResult.message}. You may retry again or acknowledge and exit.';
                              });
                            }
                          } on StudentDeletionException catch (e) {
                            if (!dialogContext.mounted) return;
                            setDialogState(() {
                              isRetrying = false;
                              retryAttempt++;
                              retryError =
                                  'Auth recovery attempt $retryAttempt failed: ${e.message}';
                            });
                          } catch (e) {
                            if (!dialogContext.mounted) return;
                            setDialogState(() {
                              isRetrying = false;
                              retryAttempt++;
                              retryError =
                                  'Unexpected error during Auth recovery: $e';
                            });
                          }
                        },
                  icon: isRetrying
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text(
                    'Retry Auth Cleanup',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDependencyBlockedDialog(
    BuildContext context,
    Student student,
    StudentDeletionException exception,
  ) {
    final counts = exception.counts;
    final List<String> blockingItems = [];
    if (counts != null) {
      if ((counts['payments'] as num? ?? 0) > 0) {
        blockingItems.add('${counts['payments']} Payment Transaction(s)');
      }
      if ((counts['course_enrollments'] as num? ?? 0) > 0) {
        blockingItems.add(
          '${counts['course_enrollments']} Course Enrollment(s)',
        );
      }
      if ((counts['assessment_results'] as num? ?? 0) > 0) {
        blockingItems.add(
          '${counts['assessment_results']} Examination Result(s)',
        );
      }
      if ((counts['student_subscriptions'] as num? ?? 0) > 0) {
        blockingItems.add(
          '${counts['student_subscriptions']} Subscription Record(s)',
        );
      }
      if ((counts['career_appointments'] as num? ?? 0) > 0) {
        blockingItems.add(
          '${counts['career_appointments']} Career Appointment(s)',
        );
      }
      if ((counts['career_action_plans'] as num? ?? 0) > 0) {
        blockingItems.add(
          '${counts['career_action_plans']} Career Action Plan(s)',
        );
      }
      if ((counts['lesson_progress'] as num? ?? 0) > 0) {
        blockingItems.add(
          '${counts['lesson_progress']} Lesson Progress Record(s)',
        );
      }
      if ((counts['live_class_attendees'] as num? ?? 0) > 0) {
        blockingItems.add(
          '${counts['live_class_attendees']} Live Class Attendance Record(s)',
        );
      }
      if ((counts['assignment_submissions'] as num? ?? 0) > 0) {
        blockingItems.add(
          '${counts['assignment_submissions']} Assignment Submission(s)',
        );
      }
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: AppColors.primaryNavy.withValues(alpha: 0.3),
            ),
          ),
          title: Row(
            children: const [
              Icon(
                Icons.shield_outlined,
                color: AppColors.primaryNavy,
                size: 26,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Permanent Deletion Blocked',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryNavy,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Student "${student.fullName}" (${student.studentId}) cannot be permanently deleted because protected historical records exist.',
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
                if (blockingItems.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'Protected Dependencies:',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  ...blockingItems.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(left: 6, bottom: 2),
                      child: Text(
                        '• $item',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryNavy.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primaryNavy.withValues(alpha: 0.15),
                    ),
                  ),
                  child: const Text(
                    'Institutional Compliance Requirement:\n'
                    'Financial ledgers, academic examinations, and enrollment history must remain immutable. '
                    'To restrict student access, deactivate or suspend the account instead.',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showDeletionErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: const [
              Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'Deletion Failed',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSuperAdminDangerZone(
    BuildContext context,
    WidgetRef ref,
    Student student,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withValues(alpha: 0.05),
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
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: AppColors.error,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Super Administrator Danger Zone',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Permanent account removal purges this student record from the database and permanently deletes associated Supabase Auth credentials. '
            'Students with existing payments, course enrollments, or academic records are strictly restricted from deletion.',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.delete_forever_rounded, size: 18),
              label: const Text(
                'Permanently Delete Student',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              onPressed: () =>
                  _showPermanentDeleteConfirmation(context, ref, student),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryLmsCard extends StatelessWidget {
  final StudentCategoryLmsGroup group;
  final void Function(String courseId, String courseTitle)? onUnenrollCourse;

  const _CategoryLmsCard({
    required this.group,
    this.onUnenrollCourse,
  });

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
                        if (onUnenrollCourse != null) ...[
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(
                              Icons.remove_circle_outline_rounded,
                              size: 16,
                              color: AppColors.error,
                            ),
                            tooltip: 'Unenroll Course',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => onUnenrollCourse!(
                              c['id']?.toString() ?? '',
                              c['title']?.toString() ?? 'Course',
                            ),
                          ),
                        ],
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
