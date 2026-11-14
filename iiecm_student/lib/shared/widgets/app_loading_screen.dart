import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';

/// Institutional splash and loading screen shown during initial student session verification
class AppLoadingScreen extends StatelessWidget {
  final String? message;

  const AppLoadingScreen({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Institutional Emblem
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.forestDark : AppColors.forestSoft,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? AppColors.forestLight : AppColors.primaryForest.withValues(alpha: 0.25),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.school_rounded,
                  size: 42,
                  color: isDark ? AppColors.forestLight : AppColors.primaryForest,
                ),
              ),
              const SizedBox(height: AppConstants.spacingLg),
              Text(
                AppConstants.appName,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: AppConstants.spacingXs),
              Text(
                AppConstants.studentPortalTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.terracotta,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 36),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryForest),
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: AppConstants.spacingMd),
                Text(
                  message!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

