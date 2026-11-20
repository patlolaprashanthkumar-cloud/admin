import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../providers/assignments_provider.dart';
import '../providers/assignments_state.dart';
import '../widgets/assignment_card.dart';

/// Assignments screen displaying enrolled course assignments and projects
///
/// Follows the IIECM Modern Academic design language with institutional branding,
/// assignment overview metrics, live search & filtering, and structured assignment cards.
class AssignmentsScreen extends ConsumerStatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  ConsumerState<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends ConsumerState<AssignmentsScreen> {
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
    final state = ref.watch(studentAssignmentsNotifierProvider);
    final notifier = ref.read(studentAssignmentsNotifierProvider.notifier);

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
            // Institutional Brand Emblem
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
                  Icons.task_alt_rounded,
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
                          'Assignments & Case Studies',
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
                      if (!state.isLoading && state.assignments.isNotEmpty) ...[
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
                            '${state.assignments.length}',
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
                    'Clinical Tasks & Practical Deliverables',
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
            tooltip: 'Refresh Assignments',
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
            // Search, Overview Metrics and Filter Header
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
                    // Institutional Academic Overview Hero Card (when assignments loaded)
                    if (!state.isLoading && state.assignments.isNotEmpty) ...[
                      _buildOverviewCard(state, isDark, theme),
                      const SizedBox(height: AppConstants.spacingMd),
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
                        hintText: 'Search assignment title, course, topic...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textMuted,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.primaryNavy,
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
                            ? AppColors.darkSurfaceElevated
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

                    // Status Filter Pills Strip
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(
                            label: 'All (${state.assignments.length})',
                            isSelected:
                                state.activeFilter == AssignmentFilter.all,
                            onTap: () =>
                                notifier.setFilter(AssignmentFilter.all),
                            isDark: isDark,
                          ),
                          _buildFilterChip(
                            label: 'Pending (${state.pendingCount})',
                            isSelected:
                                state.activeFilter == AssignmentFilter.pending,
                            onTap: () =>
                                notifier.setFilter(AssignmentFilter.pending),
                            isDark: isDark,
                          ),
                          _buildFilterChip(
                            label: 'Submitted (${state.submittedCount})',
                            isSelected:
                                state.activeFilter ==
                                AssignmentFilter.submitted,
                            onTap: () =>
                                notifier.setFilter(AssignmentFilter.submitted),
                            isDark: isDark,
                          ),
                          _buildFilterChip(
                            label: 'Evaluated (${state.evaluatedCount})',
                            isSelected:
                                state.activeFilter ==
                                AssignmentFilter.evaluated,
                            onTap: () =>
                                notifier.setFilter(AssignmentFilter.evaluated),
                            isDark: isDark,
                          ),
                          if (state.overdueCount > 0)
                            _buildFilterChip(
                              label: 'Overdue (${state.overdueCount})',
                              isSelected:
                                  state.activeFilter ==
                                  AssignmentFilter.overdue,
                              onTap: () =>
                                  notifier.setFilter(AssignmentFilter.overdue),
                              isDark: isDark,
                              isWarning: true,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content Area
            if (state.isLoading && state.assignments.isEmpty)
              SliverFillRemaining(child: _buildLoadingState(isDark))
            else if (state.hasError && state.assignments.isEmpty)
              SliverFillRemaining(
                child: _buildErrorState(
                  context,
                  state.errorMessage,
                  notifier,
                  isDark,
                  theme,
                ),
              )
            else if (state.assignments.isEmpty)
              SliverFillRemaining(
                child: _buildEmptyState(context, notifier, isDark, theme),
              )
            else if (state.filteredAssignments.isEmpty)
              SliverFillRemaining(
                child: _buildNoMatchesState(context, notifier, isDark, theme),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingMd,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final assignment = state.filteredAssignments[index];
                    return AssignmentCard(
                      assignment: assignment,
                      onTap: () =>
                          context.push('/assignments/${assignment.id}'),
                    );
                  }, childCount: state.filteredAssignments.length),
                ),
              ),

            const SliverToBoxAdapter(
              child: SizedBox(height: AppConstants.spacingXl),
            ),
          ],
        ),
      ),
    );
  }

  /// Institutional summary hero card displaying delivery metrics
  Widget _buildOverviewCard(
    AssignmentsListState state,
    bool isDark,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkBackground
                      : AppColors.forestSoft,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                ),
                child: const Icon(
                  Icons.assignment_turned_in_outlined,
                  size: 16,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Clinical Deliverables Tracker',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Official Course Submissions & Evaluations',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Row(
            children: [
              _buildMetricTile(
                label: 'Total',
                count: state.assignments.length,
                color: isDark ? Colors.white : AppColors.textPrimary,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildMetricTile(
                label: 'Pending',
                count: state.pendingCount,
                color: AppColors.terracotta,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildMetricTile(
                label: 'Submitted',
                count: state.submittedCount,
                color: AppColors.info,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildMetricTile(
                label: 'Evaluated',
                count: state.evaluatedCount,
                color: AppColors.success,
                isDark: isDark,
              ),
              if (state.overdueCount > 0) ...[
                const SizedBox(width: 8),
                _buildMetricTile(
                  label: 'Overdue',
                  count: state.overdueCount,
                  color: AppColors.error,
                  isDark: isDark,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required int count,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : AppColors.warmCreamLight,
          borderRadius: BorderRadius.circular(AppConstants.radiusSm + 2),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
            width: 0.8,
          ),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
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
    bool isWarning = false,
  }) {
    final activeColor = isWarning ? AppColors.error : AppColors.primaryNavy;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: activeColor,
        backgroundColor: isDark
            ? AppColors.darkSurfaceElevated
            : AppColors.white,
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
              ? activeColor
              : (isDark ? AppColors.darkBorder : AppColors.border),
          width: 0.8,
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
            'Loading course assignments...',
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
    StudentAssignmentsNotifier notifier,
    bool isDark,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      child: Center(
        child: AppCard(
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          borderRadius: AppConstants.radiusLg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.error.withValues(alpha: 0.15)
                      : AppColors.errorSoft,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.error,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingMd),
              Text(
                'Unable to Load Assignments',
                style: theme.textTheme.titleSmall?.copyWith(
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
              const SizedBox(height: AppConstants.spacingMd + 4),
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

  Widget _buildEmptyState(
    BuildContext context,
    StudentAssignmentsNotifier notifier,
    bool isDark,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      child: Center(
        child: AppCard(
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          borderRadius: AppConstants.radiusLg,
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
                ),
                child: Center(
                  child: Icon(
                    Icons.task_alt_rounded,
                    size: 32,
                    color: isDark
                        ? AppColors.accentOrangeLight
                        : AppColors.primaryNavy,
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingMd),
              Text(
                'No Assignments Assigned',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You do not have any pending practical assignments or project submissions in your enrolled courses.',
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

  Widget _buildNoMatchesState(
    BuildContext context,
    StudentAssignmentsNotifier notifier,
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
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceElevated
                    : AppColors.forestSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 28,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Text(
              'No Matching Assignments',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'No assignments match the selected filter criteria.',
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
              label: const Text('Reset Filter to All'),
              style: TextButton.styleFrom(
                foregroundColor: isDark
                    ? AppColors.accentOrange
                    : AppColors.primaryNavy,
              ),
              onPressed: () {
                _searchController.clear();
                notifier.setSearchQuery('');
                notifier.setFilter(AssignmentFilter.all);
              },
            ),
          ],
        ),
      ),
    );
  }
}
