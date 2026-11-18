import 'package:flutter/material.dart';

/// Institutional Brand Colors for IIECM LEARNING HUB Student Application
class AppColors {
  AppColors._();

  // Core Brand Tokens (IIECM LEARNING HUB)
  static const Color primaryNavy = Color(0xFF063B56);
  static const Color deepNavy = Color(0xFF082F49);
  static const Color secondaryBlue = Color(0xFF155B78);
  static const Color accentOrange = Color(0xFFFF9B38);
  static const Color accentOrangeLight = Color(0xFFFFB266);
  static const Color accentOrangeSoft = Color(0xFFFFF4E8);

  // Background & Surface Warm Neutrals
  static const Color warmOffWhite = Color(0xFFFAF8F4);
  static const Color backgroundWarmOffWhite = Color(0xFFFAF8F4);
  static const Color white = Color(0xFFFFFFFF);

  // Backward-Compatibility Aliases (Preserves all existing references)
  static const Color primaryForest = primaryNavy;
  static const Color forestDark = deepNavy;
  static const Color forestLight = secondaryBlue;
  static const Color forestSoft = Color(0xFFE6EFF5);

  static const Color warmCream = backgroundWarmOffWhite;
  static const Color warmCreamLight = Color(0xFFFAF7F0);

  static const Color terracotta = accentOrange;
  static const Color terracottaSoft = accentOrangeSoft;

  // Typography & Content Neutrals
  static const Color textPrimary = Color(0xFF102D46);
  static const Color textSecondary = Color(0xFF637487);
  static const Color textMuted = Color(0xFF8A9BA8);

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderSubtle = Color(0xFFEDE8DF);

  // Status & Feedback Accents
  static const Color success = Color(0xFF10B981);
  static const Color successSoft = Color(0xFFECFDF5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSoft = Color(0xFFFFFBEB);
  static const Color error = Color(0xFFEF4444);
  static const Color errorSoft = Color(0xFFFEF2F2);
  static const Color info = Color(0xFF155B78);
  static const Color infoSoft = Color(0xFFE0F2FE);

  // Dark Theme Palette Variants
  static const Color darkBackground = Color(0xFF041824);
  static const Color darkSurface = Color(0xFF082538);
  static const Color darkSurfaceElevated = Color(0xFF0C3149);
  static const Color darkBorder = Color(0xFF1E3A4C);
  static const Color darkTextPrimary = Color(0xFFF0F4F8);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
}
