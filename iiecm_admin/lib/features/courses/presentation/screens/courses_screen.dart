import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../domain/models/course.dart';
import '../providers/courses_provider.dart';
import '../widgets/course_form_sheet.dart';

/// Institutional Curricula & Courses Management Screen
///
/// Provides executive administration for medical training programs,
/// syllabus taxonomies, tuition structures, and direct curriculum builders.
class CoursesScreen extends ConsumerWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(coursesNotifierProvider);
    final notifier = ref.read(coursesNotifierProvider.notifier);
    final categoriesState = ref.watch(categoryNotifierProvider);

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
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceContainerLow
                    : AppColors.forestSoft,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryNavy.withValues(alpha: 0.15),
                  width: 1.2,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.menu_book_rounded,
                  color: AppColors.primaryNavy,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Curricula & Courses',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!state.isLoading) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryNavy.withValues(
                              alpha: isDark ? 0.3 : 0.08,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${state.filteredCourses.length}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? AppColors.accentOrangeLight
                                  : AppColors.primaryNavy,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    'Academic Programs · Syllabus Management',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Course Taxonomies',
            icon: const Icon(
              Icons.category_rounded,
              color: AppColors.accentOrange,
              size: 22,
            ),
            onPressed: () => context.push('/categories'),
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: Icon(
              Icons.refresh_rounded,
              color: isDark ? Colors.white : AppColors.primaryNavy,
              size: 22,
            ),
            onPressed: () => notifier.loadCourses(),
          ),
          const SizedBox(width: 4),
          FilledButton.icon(
            onPressed: () {
              CourseFormSheet.show(
                context,
                onSave:
                    ({
                      required String title,
                      required String description,
                      required String categoryId,
                      required String categoryName,
                      String? instructorId,
                      int durationWeeks = 8,
                      double fee = 0.0,
                      String format = 'hybrid',
                      String status = 'draft',
                    }) => notifier.createCourse(
                      title: title,
                      description: description,
                      categoryId: categoryId,
                      categoryName: categoryName,
                      instructorId: instructorId,
                      durationWeeks: durationWeeks,
                      fee: fee,
                      format: format,
                      status: status,
                    ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryNavy,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text(
              'Create',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          const SizedBox(width: 14),
        ],
      ),
      body: SafeArea(
        child: ResponsiveLayout(
          child: RefreshIndicator(
            color: AppColors.primaryNavy,
            onRefresh: () => notifier.loadCourses(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Search and Category Filter Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search bar with Modern Academic styling
                        Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.2 : 0.035,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            onChanged: notifier.setSearchQuery,
                            decoration: InputDecoration(
                              hintText: 'Search courses by title, category, or syllabus...',
                              hintStyle: TextStyle(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textMuted,
                                fontSize: 13,
                              ),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: isDark
                                    ? AppColors.accentOrangeLight
                                    : AppColors.primaryNavy,
                                size: 20,
                              ),
                              suffixIcon: state.searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.clear_rounded,
                                        size: 18,
                                      ),
                                      onPressed: () =>
                                          notifier.setSearchQuery(''),
                                    )
                                  : null,
                              filled: true,
                              fillColor: isDark
                                  ? AppColors.darkSurface
                                  : AppColors.cardWhite,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.borderNeutral,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.borderNeutral,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.primaryNavy,
                                  width: 1.6,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Dynamic Category Filter Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              _buildCategoryFilterChip(
                                label: 'All Categories',
                                isSelected: state.selectedCategoryId == 'all',
                                icon: Icons.apps_rounded,
                                isDark: isDark,
                                onSelected: () =>
                                    notifier.setSelectedCategory('all'),
                              ),
                              const SizedBox(width: 8),
                              ...categoriesState.categories.map((cat) {
                                final isSelected =
                                    state.selectedCategoryId == cat.id;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _buildCategoryFilterChip(
                                    label: cat.name,
                                    isSelected: isSelected,
                                    icon: Icons.category_rounded,
                                    isDark: isDark,
                                    onSelected: () =>
                                        notifier.setSelectedCategory(
                                          isSelected ? 'all' : cat.id,
                                        ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Error State
                if (state.errorMessage != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.error,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                state.errorMessage!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Loading State
                if (state.isLoading && state.courses.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryNavy,
                      ),
                    ),
                  )
                // Empty State
                else if (state.filteredCourses.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkSurface
                                    : AppColors.forestSoft,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primaryNavy.withValues(
                                    alpha: 0.12,
                                  ),
                                ),
                              ),
                              child: const Icon(
                                Icons.menu_book_rounded,
                                size: 40,
                                color: AppColors.primaryNavy,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              state.searchQuery.isNotEmpty
                                  ? 'No courses matching filter'
                                  : 'No curriculum courses yet',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Create medical curriculum programs and link them to dynamic categories.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                // Courses List
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final course = state.filteredCourses[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _CourseCard(course: course),
                        );
                      }, childCount: state.filteredCourses.length),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilterChip({
    required String label,
    required bool isSelected,
    required IconData icon,
    required bool isDark,
    required VoidCallback onSelected,
  }) {
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryNavy
              : (isDark ? AppColors.darkSurface : AppColors.cardWhite),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryNavy
                : (isDark ? AppColors.darkBorder : AppColors.borderNeutral),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryNavy.withValues(alpha: 0.22),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? Colors.white
                  : (isDark
                        ? AppColors.accentOrangeLight
                        : AppColors.secondaryBlue),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white : AppColors.textPrimary),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseCard extends ConsumerWidget {
  final Course course;

  const _CourseCard({required this.course});

  Color _getStatusBgColor(String status, bool isDark) {
    switch (status.toLowerCase()) {
      case 'published':
        return isDark ? const Color(0xFF064E3B) : AppColors.successSoft;
      case 'draft':
        return isDark ? const Color(0xFF78350F) : AppColors.warningSoft;
      case 'archived':
      default:
        return isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'published':
        return AppColors.success;
      case 'draft':
        return AppColors.warning;
      case 'archived':
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatDeliveryType(String format) {
    switch (format.toLowerCase()) {
      case 'hybrid':
        return 'HYBRID';
      case 'live':
        return 'LIVE VIRTUAL';
      case 'recorded':
        return 'SELF-PACED';
      default:
        return format.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final notifier = ref.read(coursesNotifierProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.borderNeutral,
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Emblem, Title, Badges, and Popup Menu
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceContainerLow
                      : AppColors.forestSoft,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primaryNavy.withValues(alpha: 0.12),
                    width: 1,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.menu_book_rounded,
                    color: AppColors.primaryNavy,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontSize: 15.5,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Category Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurfaceContainerLow
                                : AppColors.accentOrangeSoft,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.accentOrange.withValues(
                                alpha: 0.25,
                              ),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            course.categoryName,
                            style: const TextStyle(
                              color: AppColors.accentOrange,
                              fontWeight: FontWeight.w700,
                              fontSize: 10.5,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        // Delivery Format Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurfaceContainerLow
                                : AppColors.infoSoft,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.secondaryBlue.withValues(
                                alpha: 0.2,
                              ),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            _formatDeliveryType(course.format),
                            style: const TextStyle(
                              color: AppColors.secondaryBlue,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        // Publication Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusBgColor(course.status, isDark),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: _getStatusTextColor(course.status),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                course.status.toUpperCase(),
                                style: TextStyle(
                                  color: _getStatusTextColor(course.status),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 9.5,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // 3-Dot Popup Menu Button
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                  size: 20,
                ),
                tooltip: 'Course Options',
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                onSelected: (val) {
                  if (val == 'edit') {
                    CourseFormSheet.show(
                      context,
                      initialCourse: course,
                      onSave:
                          ({
                            required String title,
                            required String description,
                            required String categoryId,
                            required String categoryName,
                            String? instructorId,
                            int durationWeeks = 8,
                            double fee = 0.0,
                            String format = 'hybrid',
                            String status = 'draft',
                          }) => notifier.updateCourse(
                            course.id,
                            title: title,
                            description: description,
                            categoryId: categoryId,
                            categoryName: categoryName,
                            instructorId: instructorId,
                            durationWeeks: durationWeeks,
                            fee: fee,
                            format: format,
                            status: status,
                          ),
                    );
                  } else if (val == 'curriculum') {
                    context.push('/courses/${course.id}/curriculum');
                  } else if (val == 'delete') {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        title: Text(
                          'Delete "${course.title}"?',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        content: const Text(
                          'Are you sure you want to permanently remove this course?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.error,
                            ),
                            onPressed: () {
                              notifier.deleteCourse(course.id);
                              Navigator.pop(context);
                            },
                            child: const Text('Delete Course'),
                          ),
                        ],
                      ),
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'curriculum',
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_stories_rounded,
                          size: 18,
                          color: AppColors.primaryNavy,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Curriculum & Content',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_rounded,
                          size: 18,
                          color: AppColors.secondaryBlue,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Edit Course',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: AppColors.error,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Delete Course',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (course.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              course.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.borderNeutral,
          ),
          const SizedBox(height: 10),
          // Bottom Metadata & Curriculum Navigation
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    CurrencyFormatter.format(course.fee),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.accentOrangeLight
                          : AppColors.primaryNavy,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 13,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${course.durationWeeks} wks',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.people_outline_rounded,
                        size: 14,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${course.enrolledCount} enrolled',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (course.instructorName != null &&
                      course.instructorName!.isNotEmpty) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.person_pin_rounded,
                          size: 14,
                          color: AppColors.accentOrange,
                        ),
                        const SizedBox(width: 4),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 130),
                          child: Text(
                            'Lead: ${course.instructorName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.accentOrange,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                  ],
                  OutlinedButton.icon(
                    onPressed: () =>
                        context.push('/courses/${course.id}/curriculum'),
                    icon: const Icon(Icons.video_library_rounded, size: 14),
                    label: const Text(
                      'Curriculum',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark
                          ? Colors.white
                          : AppColors.primaryNavy,
                      side: BorderSide(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.primaryNavy.withValues(alpha: 0.35),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
