import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Material 3 Themes for IIECM Admin application adhering to official brand tokens
class AppTheme {
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primaryForest,
      onPrimary: Colors.white,
      primaryContainer: AppColors.forestSoft,
      onPrimaryContainer: AppColors.forestDark,
      secondary: AppColors.accentTerracotta,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.terracottaSoft,
      onSecondaryContainer: AppColors.terracottaDark,
      tertiary: AppColors.forestLight,
      onTertiary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: const Color(0xFFFDE8E8),
      onErrorContainer: const Color(0xFF9B1C1C),
      surface: Colors.white,
      onSurface: AppColors.textPrimary,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: AppColors.surfaceWarmWhite,
      surfaceContainer: AppColors.warmCreamLight,
      surfaceContainerHigh: AppColors.warmCream,
      surfaceContainerHighest: const Color(0xFFEBE5D8),
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.borderNeutral,
      outlineVariant: AppColors.borderSubtle,
      shadow: Colors.black.withValues(alpha: 0.06),
    );

    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.warmCream,
    );

    final textTheme = AppTypography.createTextTheme(baseTheme.textTheme).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    return baseTheme.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.warmCream,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.warmCream,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          side: const BorderSide(color: AppColors.borderNeutral, width: 1),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryForest,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryForest,
          side: const BorderSide(color: AppColors.borderNeutral, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryForest,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        labelStyle: TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(color: AppColors.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          borderSide: const BorderSide(color: AppColors.borderNeutral),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          borderSide: const BorderSide(color: AppColors.borderNeutral),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          borderSide: const BorderSide(
            color: AppColors.primaryForest,
            width: 1.8,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        indicatorColor: AppColors.forestSoft,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
          final isSelected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            color: isSelected ? AppColors.primaryForest : AppColors.textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 22,
            color: isSelected ? AppColors.primaryForest : AppColors.textMuted,
          );
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerColor,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusXLarge),
          side: const BorderSide(color: AppColors.borderNeutral),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.forestLight,
      onPrimary: Colors.white,
      primaryContainer: AppColors.forestDark,
      onPrimaryContainer: AppColors.forestSoft,
      secondary: AppColors.accentTerracotta,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.terracottaDark,
      onSecondaryContainer: AppColors.terracottaSoft,
      tertiary: const Color(0xFF68B08B),
      onTertiary: Colors.black,
      error: const Color(0xFFE57373),
      onError: Colors.black,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      surfaceContainerLowest: AppColors.darkBackground,
      surfaceContainerLow: AppColors.darkSurfaceContainerLow,
      surfaceContainer: AppColors.darkSurface,
      onSurfaceVariant: AppColors.darkTextSecondary,
      outline: AppColors.darkBorder,
    );

    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
    );

    return baseTheme.copyWith(
      textTheme: AppTypography.createTextTheme(baseTheme.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: AppTypography.createTextTheme(baseTheme.textTheme)
            .titleLarge
            ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.forestLight,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
    );
  }
}
