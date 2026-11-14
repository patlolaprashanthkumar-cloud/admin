import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../providers/results_provider.dart';
import '../providers/results_state.dart';
import '../widgets/result_card.dart';
import '../widgets/result_filter_chips.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
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

    final resultsState = ref.watch(studentResultsNotifierProvider);
    final resultsNotifier = ref.read(studentResultsNotifierProvider.notifier);

    final filteredResults = resultsState.filteredResults;
    final isLoading = resultsState.isLoading && resultsState.results.isEmpty;
    final hasError = resultsState.hasError && resultsState.results.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Results'),
        actions: [
          IconButton(
            tooltip: 'Refresh Results',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => resultsNotifier.refresh(),
          ),
          const SizedBox(width: AppConstants.spacingSm),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryForest,
          onRefresh: () => resultsNotifier.refresh(),
          child: ListView(
            padding: const EdgeInsets.all(AppConstants.spacingMd),
            children: [
              // 1. Institutional Academic Overview Hero Card
              _buildOverviewCard(resultsState, isDark, theme),
              const SizedBox(height: AppConstants.spacingMd),

              // 2. Search Field
              TextField(
                controller: _searchController,
                onChanged: resultsNotifier.setSearchQuery,
                decoration: InputDecoration(
                  hintText: 'Search assessments, courses, projects...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            resultsNotifier.setSearchQuery('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? AppColors.darkSurfaceElevated : AppColors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                      width: 1.6,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingSm),

              // 3. Category & Status Filter Chips
              ResultFilterChips(
                selectedFilter: resultsState.filter,
                onFilterSelected: resultsNotifier.setFilter,
              ),
              const SizedBox(height: AppConstants.spacingMd),

              // 4. Content State Dispatcher
              if (isLoading)
                _buildLoadingState(isDark)
              else if (hasError)
                _buildErrorState(resultsState.errorMessage ?? 'Failed to load results')
              else if (filteredResults.isEmpty)
                _buildEmptyState(context, resultsState)
              else
                ...filteredResults.map(
                  (result) => ResultCard(
                    result: result,
                    onTap: () => context.push('/results/${result.id}'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCard(
    ResultsState state,
    bool isDark,
    ThemeData theme,
  ) {
    return AppCard(
      backgroundColor: isDark ? AppColors.forestDark : AppColors.primaryForest,
      borderColor: isDark ? AppColors.forestLight : AppColors.forestDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.forestSoft,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.primaryForest,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Academic Performance Record',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 1),
                    const Text(
                      'Authoritative evaluations and examination checkpoints',
                      style: TextStyle(
                        color: AppColors.forestSoft,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingMd),
          const Divider(color: Color(0x33FFFFFF)),
          const SizedBox(height: AppConstants.spacingSm),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  label: 'Completed',
                  value: state.totalCount.toString(),
                  color: Colors.white,
                ),
              ),
              Container(
                height: 28,
                width: 1,
                color: const Color(0x33FFFFFF),
              ),
              Expanded(
                child: _buildMetricItem(
                  label: 'Passed',
                  value: state.passedCount.toString(),
                  color: const Color(0xFFA5D6A7),
                ),
              ),
              Container(
                height: 28,
                width: 1,
                color: const Color(0x33FFFFFF),
              ),
              Expanded(
                child: _buildMetricItem(
                  label: 'Average',
                  value: state.totalCount > 0
                      ? '${state.averagePercentage.toStringAsFixed(1)}%'
                      : 'N/A',
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.forestSoft,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Column(
      children: List.generate(
        3,
        (_) => Container(
          height: 110,
          margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.white,
            borderRadius: BorderRadius.circular(AppConstants.radiusLg),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryForest),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return AppCard(
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, size: 40, color: AppColors.error),
          const SizedBox(height: AppConstants.spacingSm),
          const Text(
            'Unable to Load Results',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppConstants.spacingMd),
          AppButton(
            label: 'Retry Connection',
            icon: Icons.refresh_rounded,
            isFullWidth: false,
            height: 38,
            onPressed: () => ref.read(studentResultsNotifierProvider.notifier).refresh(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ResultsState state) {
    final hasSearch = state.searchQuery.trim().isNotEmpty;
    final hasFilter = state.filter != ResultFilterType.all;

    return AppCard(
      padding: const EdgeInsets.all(AppConstants.spacingXl),
      child: Column(
        children: [
          Icon(
            hasSearch || hasFilter
                ? Icons.filter_alt_off_outlined
                : Icons.fact_check_outlined,
            size: 44,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            hasSearch || hasFilter
                ? 'No Matching Results'
                : 'No Examination Records Available',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            hasSearch || hasFilter
                ? 'Try adjusting your search criteria or clear the current active filter.'
                : 'You have not completed any examinations or submitted clinical assignments yet.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppConstants.spacingMd),
          if (hasSearch || hasFilter)
            AppButton(
              label: 'Reset Filters',
              icon: Icons.refresh_rounded,
              isFullWidth: false,
              height: 36,
              variant: AppButtonVariant.outline,
              onPressed: () {
                _searchController.clear();
                ref.read(studentResultsNotifierProvider.notifier).setSearchQuery('');
                ref.read(studentResultsNotifierProvider.notifier).setFilter(ResultFilterType.all);
              },
            )
          else
            AppButton(
              label: 'View Assessments',
              icon: Icons.quiz_outlined,
              isFullWidth: false,
              height: 38,
              onPressed: () => context.go('/assessments'),
            ),
        ],
      ),
    );
  }
}

