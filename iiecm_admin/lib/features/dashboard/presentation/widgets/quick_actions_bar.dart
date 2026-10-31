import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';

class QuickActionsBar extends StatelessWidget {
  const QuickActionsBar({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = [
      (
        label: 'Add Student',
        icon: Icons.person_add_alt_1_rounded,
        color: const Color(0xFF0F2744),
        onTap: () => context.go('/students'),
      ),
      (
        label: 'Create Course',
        icon: Icons.post_add_rounded,
        color: const Color(0xFF064B3E),
        onTap: () => context.go('/courses'),
      ),
      (
        label: 'Faculty',
        icon: Icons.school_rounded,
        color: const Color(0xFF028090),
        onTap: () => context.go('/hubs'),
      ),
      (
        label: 'Review Fees',
        icon: Icons.receipt_long_rounded,
        color: const Color(0xFFFF8E53),
        onTap: () => context.go('/payments'),
      ),
    ];

    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: actions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = actions[index];
          return _buildActionButton(context, item);
        },
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    ({String label, IconData icon, Color color, VoidCallback onTap}) item,
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
          width: 110,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  item.icon,
                  size: 20,
                  color: item.color,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
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
