import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../providers/results_state.dart';

/// Modern academic filter chips strip for filtering student academic results
class ResultFilterChips extends StatelessWidget {
  final ResultFilterType selectedFilter;
  final ValueChanged<ResultFilterType> onFilterSelected;
  final Map<ResultFilterType, int>? counts;

  const ResultFilterChips({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
    this.counts,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: ResultFilterType.values.map((filter) {
          final isSelected = filter == selectedFilter;
          final count = counts?[filter];

          return Padding(
            padding: const EdgeInsets.only(right: AppConstants.spacingSm),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    filter.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : (isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary),
                    ),
                  ),
                  if (count != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.22)
                            : (isDark
                                  ? AppColors.darkSurfaceElevated
                                  : AppColors.forestSoft),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                    ? AppColors.accentOrangeLight
                                    : AppColors.primaryNavy),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              selected: isSelected,
              onSelected: (_) => onFilterSelected(filter),
              backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
              selectedColor: isDark
                  ? AppColors.darkSurfaceElevated
                  : AppColors.primaryNavy,
              checkmarkColor: Colors.white,
              showCheckmark: false,
              elevation: 0,
              pressElevation: 0,
              side: BorderSide(
                color: isSelected
                    ? (isDark
                          ? AppColors.accentOrangeLight
                          : AppColors.primaryNavy)
                    : (isDark ? AppColors.darkBorder : AppColors.border),
                width: isSelected ? 1.2 : 1.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusFull),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
          );
        }).toList(),
      ),
    );
  }
}
