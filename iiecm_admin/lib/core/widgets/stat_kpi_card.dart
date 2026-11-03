import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../constants/app_constants.dart';

/// Reusable Institutional KPI Card matching IIECM Brand Design Tokens
class StatKpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;
  final String? trendLabel;
  final bool isTrendPositive;
  final VoidCallback? onTap;

  const StatKpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
    this.trendLabel,
    this.isTrendPositive = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardContent = Container(
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerLow : Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.borderNeutral,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle top brand accent bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 3.5,
            child: Container(
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppConstants.radiusLarge),
                  topRight: Radius.circular(AppConstants.radiusLarge),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7.5),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusMedium,
                        ),
                      ),
                      child: Icon(icon, size: 20, color: accentColor),
                    ),
                    if (onTap != null)
                      Icon(
                        Icons.arrow_outward_rounded,
                        size: 15,
                        color: AppColors.textMuted,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                if (trendLabel != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isTrendPositive
                          ? AppColors.forestSoft
                          : AppColors.terracottaSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isTrendPositive
                              ? Icons.trending_up_rounded
                              : Icons.info_outline_rounded,
                          size: 12,
                          color: isTrendPositive
                              ? AppColors.primaryForest
                              : AppColors.accentTerracotta,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            trendLabel!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isTrendPositive
                                  ? AppColors.primaryForest
                                  : AppColors.accentTerracotta,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}
