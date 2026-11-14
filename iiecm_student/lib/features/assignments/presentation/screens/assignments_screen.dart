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
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assignments & Case Studies',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            Text(
              'Clinical Tasks & Practical Deliverables',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Assignments',
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
            // Search and Filter Header
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
                        hintText: 'Search assignment title, course, topic...',
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

                    // Filter Pills
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(
                            label: 'All (${state.assignments.length})',
                            isSelected: state.activeFilter == AssignmentFilter.all,
                            onTap: () => notifier.setFilter(AssignmentFilter.all),
                            isDark: isDark,
                          ),
                          _buildFilterChip(
                            label: 'Pending (${state.pendingCount})',
                            isSelected: state.activeFilter == AssignmentFilter.pending,
                            onTap: () => notifier.setFilter(AssignmentFilter.pending),
                            isDark: isDark,
                          ),
                          _buildFilterChip(
                            label: 'Submitted (${state.submittedCount})',
                            isSelected: state.activeFilter == AssignmentFilter.submitted,
                            onTap: () => notifier.setFilter(AssignmentFilter.submitted),
                            isDark: isDark,
                          ),
                          _buildFilterChip(
                            label: 'Evaluated (${state.evaluatedCount})',
                            isSelected: state.activeFilter == AssignmentFilter.evaluated,
                            onTap: () => notifier.setFilter(AssignmentFilter.evaluated),
                            isDark: isDark,
                          ),
                          if (state.overdueCount > 0)
                            _buildFilterChip(
                              label: 'Overdue (${state.overdueCount})',
                              isSelected: state.activeFilter == AssignmentFilter.overdue,
                              onTap: () => notifier.setFilter(AssignmentFilter.overdue),
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
              SliverFillRemaining(
                child: _buildLoadingState(isDark),
              )
            else if (state.hasError && state.assignments.isEmpty)
              SliverFillRemaining(
                child: _buildErrorState(context, state.errorMessage, notifier, isDark, theme),
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
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingMd),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final assignment = state.filteredAssignments[index];
                      return AssignmentCard(
                        assignment: assignment,
                        onTap: () => context.push('/assignments/${assignment.id}'),
                      );
                    },
                    childCount: state.filteredAssignments.length,
                  ),
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

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    bool isWarning = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: isWarning ? AppColors.error : AppColors.primaryForest,
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
              ? (isWarning ? AppColors.error : AppColors.primaryForest)
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
            'Loading course assignments...',
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
    StudentAssignmentsNotifier notifier,
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
                'Unable to Load Assignments',
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.task_alt_rounded,
                size: 48,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textMuted,
              ),
              const SizedBox(height: AppConstants.spacingMd),
              Text(
                'No Assignments Assigned',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You do not have any pending practical assignments or project submissions in your enrolled courses.',
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
            Icon(
              Icons.search_off_rounded,
              size: 42,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textMuted,
            ),
            const SizedBox(height: AppConstants.spacingSm),
            Text(
              'No Matching Assignments',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'No assignments match the selected filter criteria.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            TextButton.icon(
              icon: const Icon(Icons.clear_all_rounded, size: 16),
              label: const Text('Reset Filter to All'),
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

