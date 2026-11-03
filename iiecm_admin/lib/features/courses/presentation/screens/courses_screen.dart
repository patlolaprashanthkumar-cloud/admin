import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../domain/models/course.dart';
import '../providers/courses_provider.dart';
import '../widgets/course_form_sheet.dart';

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
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      appBar: AppBar(
        title: const Text('Curricula & Courses'),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.warmCream,
        actions: [
          IconButton(
            tooltip: 'Course Taxonomies',
            icon: const Icon(
              Icons.category_rounded,
              color: AppColors.accentTerracotta,
            ),
            onPressed: () => context.push('/categories'),
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => notifier.loadCourses(),
          ),
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
              backgroundColor: AppColors.primaryForest,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Create'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: ResponsiveLayout(
          child: RefreshIndicator(
            onRefresh: () => notifier.loadCourses(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Search and Category Filter Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search bar
                        TextField(
                          onChanged: notifier.setSearchQuery,
                          decoration: InputDecoration(
                            hintText: 'Search courses by title, category, or syllabus...',
                            prefixIcon: const Icon(Icons.search_rounded),
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
                                : Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppConstants.radiusMedium,
                              ),
                              borderSide: BorderSide(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : AppColors.borderNeutral,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Dynamic Category Filters
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              FilterChip(
                                label: const Text('All Categories'),
                                selected: state.selectedCategoryId == 'all',
                                onSelected: (_) =>
                                    notifier.setSelectedCategory('all'),
                              ),
                              const SizedBox(width: 8),
                              ...categoriesState.categories.map((cat) {
                                final isSelected =
                                    state.selectedCategoryId == cat.id;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    avatar: Icon(
                                      Icons.category_rounded,
                                      size: 14,
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.primaryForest,
                                    ),
                                    label: Text(cat.name),
                                    selected: isSelected,
                                    onSelected: (_) =>
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
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusMedium,
                          ),
                        ),
                        child: Text(
                          state.errorMessage!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Loading
                if (state.isLoading && state.courses.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryForest,
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
                              padding: const EdgeInsets.all(18),
                              decoration: const BoxDecoration(
                                color: AppColors.forestSoft,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.menu_book_rounded,
                                size: 40,
                                color: AppColors.primaryForest,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              state.searchQuery.isNotEmpty
                                  ? 'No courses matching filter'
                                  : 'No curriculum courses yet',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Create medical curriculum programs and link them to dynamic categories.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
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
}

class _CourseCard extends ConsumerWidget {
  final Course course;

  const _CourseCard({required this.course});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notifier = ref.read(coursesNotifierProvider.notifier);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.forestSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: AppColors.primaryForest,
                  size: 22,
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
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.terracottaSoft,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            course.categoryName,
                            style: const TextStyle(
                              color: AppColors.accentTerracotta,
                              fontWeight: FontWeight.w700,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: course.status == 'published'
                                ? AppColors.forestSoft
                                : Colors.grey.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            course.status,
                            style: TextStyle(
                              color: course.status == 'published'
                                  ? AppColors.primaryForest
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
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
                        title: Text('Delete "${course.title}"?'),
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
                            child: const Text('Delete'),
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
                          Icons.video_library_rounded,
                          size: 18,
                          color: AppColors.primaryForest,
                        ),
                        SizedBox(width: 8),
                        Text('Curriculum & Videos'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Edit Course'),
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
                        SizedBox(width: 8),
                        Text(
                          'Delete',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            course.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
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
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryForest,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${course.durationWeeks} wks',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${course.enrolledCount} enrolled',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (course.instructorName != null &&
                      course.instructorName!.isNotEmpty) ...[
                    Text(
                      'Lead: ${course.instructorName}',
                      style: const TextStyle(
                        color: AppColors.accentTerracotta,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  OutlinedButton.icon(
                    onPressed: () =>
                        context.push('/courses/${course.id}/curriculum'),
                    icon: const Icon(Icons.video_library_rounded, size: 14),
                    label: const Text(
                      'Curriculum',
                      style: TextStyle(fontSize: 11),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
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
