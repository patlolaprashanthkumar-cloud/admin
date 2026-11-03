import 'package:flutter/material.dart';

/// Official IIECM Institutional Brand Design System Palette
class AppColors {
  // --- Core Brand Colors ---
  /// Primary forest green: anchor institutional identity
  static const Color primaryForest = Color(0xFF245B43);
  static const Color forestDark = Color(0xFF1A4331);
  static const Color forestLight = Color(0xFF337357);
  static const Color forestSoft = Color(0xFFE8F1EC);

  /// Warm cream background & neutral wash
  static const Color warmCream = Color(0xFFF5F0E5);
  static const Color warmCreamLight = Color(0xFFFAF7F0);
  static const Color surfaceWarmWhite = Color(0xFFFCFBF9);

  /// Terracotta accent for highlights, secondary actions, and alerts
  static const Color accentTerracotta = Color(0xFFC87552);
  static const Color terracottaDark = Color(0xFFA55735);
  static const Color terracottaLight = Color(0xFFDC8C6B);
  static const Color terracottaSoft = Color(0xFFF8EDE8);

  // --- Dark Neutrals & Typography ---
  /// Dark neutral text for maximum readability
  static const Color textPrimary = Color(0xFF292D29);
  static const Color textSecondary = Color(0xFF5F665E);
  static const Color textMuted = Color(0xFF8D948C);

  // --- Borders, Dividers & Outlines ---
  static const Color borderNeutral = Color(0xFFE2DDD1);
  static const Color borderSubtle = Color(0xFFECE7DC);
  static const Color dividerColor = Color(0xFFE8E3D8);

  // --- Status & Feedback Colors (Brand Harmonized) ---
  static const Color success = Color(0xFF245B43); // Forest Green
  static const Color warning = Color(0xFFD97706); // Warm Amber
  static const Color error = Color(0xFFC53030); // Deep Red
  static const Color info = Color(0xFF2E6F8E); // Slate Blue

  // --- Backwards Compatibility Aliases ---
  static const Color primaryNavy = primaryForest;
  static const Color secondaryTeal = forestLight;
  static const Color accentCoral = accentTerracotta;
  static const Color accentAmber = warning;
  static const Color terracotta = accentTerracotta;
  static const Color surface = lightSurface;
  static const Color divider = dividerColor;

  static const Color lightBackground = warmCream;
  static const Color lightSurface = Colors.white;
  static const Color lightSurfaceContainerLow = surfaceWarmWhite;
  static const Color lightTextPrimary = textPrimary;
  static const Color lightTextSecondary = textSecondary;
  static const Color lightBorder = borderNeutral;

  // Dark Scheme (Preserved for system theme compatibility)
  static const Color darkBackground = Color(0xFF191F1C);
  static const Color darkSurface = Color(0xFF232A26);
  static const Color darkSurfaceContainerLow = Color(0xFF1E2521);
  static const Color darkSurfaceVariant = darkSurfaceContainerLow;
  static const Color darkTextPrimary = Color(0xFFF5F0E5);
  static const Color darkTextSecondary = Color(0xFFA4ADA3);
  static const Color darkBorder = Color(0xFF38423B);
}
