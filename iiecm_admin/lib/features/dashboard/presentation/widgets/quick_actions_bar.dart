import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

/// Quick Actions 2x3 Grid matching the IIECM Learning Hub Left Phone Reference
class QuickActionsBar extends StatelessWidget {
  const QuickActionsBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final row1 = [
      (
        label: 'Add Student',
        icon: Icons.person_add_alt_1_outlined,
        onTap: () => context.push('/students/add'),
      ),
      (
        label: 'Faculty',
        icon: Icons.school_outlined,
        onTap: () => context.push('/faculty'),
      ),
      (
        label: 'Courses',
        icon: Icons.menu_book_outlined,
        onTap: () => context.go('/courses'),
      ),
    ];

    final row2 = [
      (
        label: 'Timetable',
        icon: Icons.calendar_month_outlined,
        onTap: () => context.push('/classes'),
      ),
      (
        label: 'Assignments',
        icon: Icons.assignment_outlined,
        onTap: () => context.push('/assignments'),
      ),
      (
        label: 'Exams',
        icon: Icons.quiz_outlined,
        onTap: () => context.push('/assessments'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header matching reference
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Quick Actions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontSize: 17,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/hubs'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                foregroundColor: isDark ? AppColors.accentOrange : AppColors.primaryNavy,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View All',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(width: 3),
                  Icon(Icons.arrow_forward_rounded, size: 14),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Row 1 (3 items)
        Row(
          children: [
            for (int i = 0; i < row1.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              _buildActionCard(context, row1[i], isDark, theme),
            ],
          ],
        ),
        const SizedBox(height: 10),

        // Row 2 (3 items)
        Row(
          children: [
            for (int i = 0; i < row2.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              _buildActionCard(context, row2[i], isDark, theme),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    ({String label, IconData icon, VoidCallback onTap}) item,
    bool isDark,
    ThemeData theme,
  ) {
    return Expanded(
      child: Material(
        color: isDark ? theme.colorScheme.surfaceContainerLow : Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        child: InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.borderNeutral,
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.025),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  item.icon,
                  size: 24,
                  color: isDark ? Colors.white : AppColors.primaryNavy,
                ),
                const SizedBox(height: 8),
                Text(
                  item.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
