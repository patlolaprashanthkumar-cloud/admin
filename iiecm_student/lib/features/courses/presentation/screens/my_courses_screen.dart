import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../providers/courses_provider.dart';
import '../widgets/course_card.dart';

/// My Courses screen displaying all academic modules the student is enrolled in
class MyCoursesScreen extends ConsumerStatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  ConsumerState<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends ConsumerState<MyCoursesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final coursesState = ref.watch(enrolledCoursesNotifierProvider);
    final notifier = ref.read(enrolledCoursesNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Enrolled Courses',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            Text(
              'Academic Curriculum & Clinical Training',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Courses',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => notifier.refresh(),
          ),
          const SizedBox(width: AppConstants.spacingSm),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primaryForest,
        onRefresh: () => notifier.refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Search and Category Filter Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      onChanged: (val) => notifier.setSearchQuery(val),
                      decoration: InputDecoration(
                        hintText: 'Search course title, faculty, category...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textMuted,
                        ),
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  notifier.setSearchQuery('');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: isDark ? AppColors.darkSurface : AppColors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                          borderSide: BorderSide(
                            color: isDark ? AppColors.darkBorder : AppColors.border,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                          borderSide: BorderSide(
                            color: isDark ? AppColors.darkBorder : AppColors.border,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                          borderSide: const BorderSide(
                            color: AppColors.primaryForest,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingSm),

                    // Category Filter Pills
                    if (coursesState.availableCategories.isNotEmpty)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip(
                              label: 'All',
                              isSelected: coursesState.selectedCategory == null,
                              onTap: () => notifier.selectCategory('All'),
                              isDark: isDark,
                            ),
                            ...coursesState.availableCategories.map((cat) {
                              final isSelected = coursesState.selectedCategory == cat;
                              return _buildFilterChip(
                                label: cat,
                                isSelected: isSelected,
                                onTap: () => notifier.selectCategory(cat),
                                isDark: isDark,
                              );
                            }),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Content Area depending on state
            if (coursesState.isLoading && coursesState.courses.isEmpty)
              SliverFillRemaining(
                child: _buildLoadingState(isDark),
              )
            else if (coursesState.hasError && coursesState.courses.isEmpty)
              SliverFillRemaining(
                child: _buildErrorState(context, coursesState.errorMessage, notifier, isDark, theme),
              )
            else if (coursesState.courses.isEmpty)
              SliverFillRemaining(
                child: _buildEmptyEnrollments(context, notifier, isDark, theme),
              )
            else if (coursesState.filteredCourses.isEmpty)
              SliverFillRemaining(
                child: _buildNoMatches(context, notifier, isDark, theme),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingMd),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final course = coursesState.filteredCourses[index];
                      return CourseCard(
                        course: course,
                        onTap: () => context.push('/courses/${course.id}'),
                      );
                    },
                    childCount: coursesState.filteredCourses.length,
                  ),
                ),
              ),

            // Bottom Spacing for shell nav bar
            const SliverToBoxAdapter(
              child: SizedBox(height: AppConstants.spacingXl),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primaryForest,
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.warmCream,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected
              ? Colors.white
              : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
        ),
        checkmarkColor: Colors.white,
        side: BorderSide(
          color: isSelected
              ? AppColors.primaryForest
              : (isDark ? AppColors.darkBorder : AppColors.border),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusFull),
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryForest),
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Text(
            'Loading your academic courses...',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    String? errorMessage,
    EnrolledCoursesNotifier notifier,
    bool isDark,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      child: Center(
        child: AppCard(
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 44),
              const SizedBox(height: AppConstants.spacingSm),
              Text(
                'Unable to Load Courses',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                errorMessage ?? 'A network or server error occurred. Please try again.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppConstants.spacingMd),
              AppButton(
                label: 'Retry Connection',
                icon: Icons.refresh_rounded,
                isFullWidth: false,
                height: 38,
                onPressed: () => notifier.refresh(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyEnrollments(
    BuildContext context,
    EnrolledCoursesNotifier notifier,
    bool isDark,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      child: Center(
        child: AppCard(
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.school_outlined,
                size: 48,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textMuted,
              ),
              const SizedBox(height: AppConstants.spacingMd),
              Text(
                'No Course Enrollments Found',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You are not currently enrolled in any academic courses. Once the registrar assigns your training curriculum, it will appear here automatically.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppConstants.spacingLg),
              AppButton(
                label: 'Refresh Status',
                icon: Icons.refresh_rounded,
                isFullWidth: false,
                height: 38,
                variant: AppButtonVariant.outline,
                onPressed: () => notifier.refresh(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoMatches(
    BuildContext context,
    EnrolledCoursesNotifier notifier,
    bool isDark,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 42,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textMuted,
            ),
            const SizedBox(height: AppConstants.spacingSm),
            Text(
              'No Matching Courses',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'No enrolled courses match your current search criteria.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            TextButton.icon(
              icon: const Icon(Icons.clear_all_rounded, size: 16),
              label: const Text('Clear All Filters'),
              onPressed: () {
                _searchController.clear();
                notifier.setSearchQuery('');
                notifier.selectCategory('All');
              },
            ),
          ],
        ),
      ),
    );
  }
}

