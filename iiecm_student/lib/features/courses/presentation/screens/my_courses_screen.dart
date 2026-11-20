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
///
/// Follows the IIECM Modern Academic design language with institutional branding,
/// enrollment summary, curriculum taxonomy search & filtering, and structured course cards.
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
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.backgroundWarmOffWhite,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.darkSurface
            : AppColors.backgroundWarmOffWhite,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceElevated
                    : AppColors.forestSoft,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryNavy.withValues(alpha: 0.15),
                  width: 1.2,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.school_rounded,
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
                          'My Enrolled Courses',
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
                      if (!coursesState.isLoading &&
                          coursesState.courses.isNotEmpty) ...[
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
                            '${coursesState.courses.length}',
                            style: TextStyle(
                              fontSize: 10.5,
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
                    'Academic Curriculum & Clinical Training',
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
            tooltip: 'Refresh Courses',
            icon: const Icon(Icons.refresh_rounded),
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
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
                padding: const EdgeInsets.fromLTRB(
                  AppConstants.spacingMd,
                  AppConstants.spacingMd,
                  AppConstants.spacingMd,
                  AppConstants.spacingSm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Institutional Enrollment Overview Strip (when courses loaded)
                    if (!coursesState.isLoading &&
                        coursesState.courses.isNotEmpty) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurfaceElevated
                              : AppColors.forestSoft,
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusMd,
                          ),
                          border: Border.all(
                            color: AppColors.primaryNavy.withValues(
                              alpha: 0.12,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.verified_user_outlined,
                              size: 16,
                              color: AppColors.primaryNavy,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${coursesState.courses.length} Registered Medical Curricula · Official Training Hub',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.primaryNavy,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Search Bar
                    TextField(
                      controller: _searchController,
                      onChanged: (val) => notifier.setSearchQuery(val),
                      style: TextStyle(
                        fontSize: 13.5,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search course title, faculty, category...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textMuted,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: AppColors.primaryNavy,
                        ),
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
                        fillColor: isDark
                            ? AppColors.darkSurface
                            : AppColors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusMd,
                          ),
                          borderSide: BorderSide(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.border,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusMd,
                          ),
                          borderSide: BorderSide(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.border,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusMd,
                          ),
                          borderSide: const BorderSide(
                            color: AppColors.primaryNavy,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingSm + 2),

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
                              final isSelected =
                                  coursesState.selectedCategory == cat;
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
              SliverFillRemaining(child: _buildLoadingState(isDark))
            else if (coursesState.hasError && coursesState.courses.isEmpty)
              SliverFillRemaining(
                child: _buildErrorState(
                  context,
                  coursesState.errorMessage,
                  notifier,
                  isDark,
                  theme,
                ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingMd,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final course = coursesState.filteredCourses[index];
                    return CourseCard(
                      course: course,
                      onTap: () => context.push('/courses/${course.id}'),
                    );
                  }, childCount: coursesState.filteredCourses.length),
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
        selectedColor: AppColors.primaryNavy,
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          color: isSelected
              ? Colors.white
              : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
        ),
        checkmarkColor: Colors.white,
        side: BorderSide(
          color: isSelected
              ? AppColors.primaryNavy
              : (isDark ? AppColors.darkBorder : AppColors.border),
          width: isSelected ? 1.4 : 1.0,
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
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryNavy),
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Text(
            'Loading your academic courses...',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
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
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: AppColors.errorSoft,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.error,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingMd),
              Text(
                'Unable to Load Courses',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                errorMessage ??
                    'A network or server error occurred. Please try again.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                  height: 1.4,
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
          padding: const EdgeInsets.all(AppConstants.spacingLg + 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceElevated
                      : AppColors.forestSoft,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryNavy.withValues(alpha: 0.15),
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.school_outlined,
                    size: 32,
                    color: AppColors.primaryNavy,
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingMd),
              Text(
                'No Course Enrollments Found',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You are not currently enrolled in any academic courses. Once the registrar assigns your training curriculum, it will appear here automatically.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
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
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceElevated
                    : AppColors.forestSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 26,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppConstants.spacingSm + 2),
            Text(
              'No Matching Courses',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'No enrolled courses match your current search criteria.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            TextButton.icon(
              icon: const Icon(Icons.clear_all_rounded, size: 16),
              label: const Text(
                'Clear All Filters',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryNavy,
              ),
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
