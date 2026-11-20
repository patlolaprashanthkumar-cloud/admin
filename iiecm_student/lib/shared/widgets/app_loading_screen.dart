import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';

/// Institutional Splash and Session Verification Screen
///
/// Designed in accordance with the IIECM Modern Academic design language:
/// Deep institutional navy, secondary teal, terracotta accents,
/// warm off-white and dark surfaces, refined emblem presentation,
/// and smooth session initialization indicator.
class AppLoadingScreen extends StatelessWidget {
  final String? message;

  const AppLoadingScreen({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.backgroundWarmOffWhite,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Institutional Emblem with Concentric Border Rings
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceElevated
                      : AppColors.forestSoft,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryNavy.withValues(
                      alpha: isDark ? 0.4 : 0.2,
                    ),
                    width: 2.2,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.school_rounded,
                    size: 44,
                    color: isDark
                        ? AppColors.accentOrangeLight
                        : AppColors.primaryNavy,
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingLg),

              // Institutional App Title
              Text(
                AppConstants.appName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppConstants.spacingXs),

              // Student Portal Tagline
              Text(
                AppConstants.studentPortalTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.terracotta,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 36),

              // Modern Academic Spinner
              SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark
                        ? AppColors.accentOrangeLight
                        : AppColors.primaryNavy,
                  ),
                ),
              ),

              if (message != null) ...[
                const SizedBox(height: AppConstants.spacingMd),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],

              const Spacer(flex: 2),

              // Subdued Institutional Portal Footer
              Text(
                'IIECM Learning Hub • Academic Portal',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.darkTextSecondary.withValues(alpha: 0.6)
                      : AppColors.textMuted,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: AppConstants.spacingMd),
            ],
          ),
        ),
      ),
    );
  }
}
