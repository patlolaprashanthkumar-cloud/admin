import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

class QuickActionsBar extends StatelessWidget {
  const QuickActionsBar({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = [
      (
        label: 'Add Student',
        icon: Icons.person_add_alt_1_rounded,
        color: AppColors.primaryForest,
        bgColor: AppColors.forestSoft,
        onTap: () => context.go('/students'),
      ),
      (
        label: 'Create Course',
        icon: Icons.post_add_rounded,
        color: AppColors.forestLight,
        bgColor: AppColors.forestSoft,
        onTap: () => context.go('/courses'),
      ),
      (
        label: 'Faculty',
        icon: Icons.school_rounded,
        color: AppColors.forestDark,
        bgColor: AppColors.forestSoft,
        onTap: () => context.push('/faculty'),
      ),
      (
        label: 'Classes',
        icon: Icons.calendar_month_rounded,
        color: Colors.blueAccent,
        bgColor: Colors.blue.withValues(alpha: 0.12),
        onTap: () => context.push('/classes'),
      ),
      (
        label: 'Assignments',
        icon: Icons.assignment_outlined,
        color: AppColors.terracotta,
        bgColor: AppColors.terracottaSoft,
        onTap: () => context.push('/assignments'),
      ),
      (
        label: 'Exams',
        icon: Icons.quiz_outlined,
        color: Colors.purple,
        bgColor: Colors.purple.withValues(alpha: 0.12),
        onTap: () => context.push('/assessments'),
      ),
      (
        label: 'Categories',
        icon: Icons.category_rounded,
        color: AppColors.primaryForest,
        bgColor: AppColors.forestSoft,
        onTap: () => context.push('/categories'),
      ),
      (
        label: 'Review Fees',
        icon: Icons.receipt_long_rounded,
        color: AppColors.accentTerracotta,
        bgColor: AppColors.terracottaSoft,
        onTap: () => context.go('/payments'),
      ),
    ];

    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: actions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = actions[index];
          return _buildActionButton(context, item);
        },
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    ({String label, IconData icon, Color color, Color bgColor, VoidCallback onTap}) item,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark ? theme.colorScheme.surfaceContainerLow : Colors.white,
      borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        child: Container(
          width: 108,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.borderNeutral,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: isDark ? item.color.withValues(alpha: 0.2) : item.bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  item.icon,
                  size: 19,
                  color: item.color,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
