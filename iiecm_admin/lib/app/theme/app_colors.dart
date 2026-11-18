import 'package:flutter/material.dart';

/// Official IIECM LEARNING HUB Brand Design System Palette
class AppColors {
  // --- Core Brand Tokens (IIECM LEARNING HUB) ---
  /// Primary Navy: Institutional anchor color
  static const Color primaryNavy = Color(0xFF063B56);

  /// Deep Navy: Elevation, hero cards, dark surfaces
  static const Color deepNavy = Color(0xFF082F49);

  /// Secondary Blue: Secondary actions, subheadings, subtle headers
  static const Color secondaryBlue = Color(0xFF155B78);

  /// Accent Orange: High-visibility actions, badges, highlights
  static const Color accentOrange = Color(0xFFFF9B38);
  static const Color accentOrangeLight = Color(0xFFFFB266);
  static const Color accentOrangeSoft = Color(0xFFFFF4E8);

  /// Warm Off-White: Clean, warm institutional background wash
  static const Color backgroundWarmOffWhite = Color(0xFFFAF8F4);
  static const Color warmOffWhite = Color(0xFFFAF8F4);
  static const Color surfaceWarmWhite = Color(0xFFFCFBF9);
  static const Color cardWhite = Color(0xFFFFFFFF);

  // --- Typography & Dark Neutrals ---
  static const Color textPrimary = Color(0xFF102D46);
  static const Color textSecondary = Color(0xFF637487);
  static const Color textMuted = Color(0xFF8A9BA8);

  // --- Borders, Dividers & Outlines ---
  static const Color borderNeutral = Color(0xFFE2E8F0);
  static const Color borderSubtle = Color(0xFFEDE8DF);
  static const Color dividerColor = Color(0xFFE2E8F0);

  // --- Status & Feedback Colors ---
  static const Color success = Color(0xFF10B981);
  static const Color successSoft = Color(0xFFECFDF5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSoft = Color(0xFFFFFBEB);
  static const Color error = Color(0xFFEF4444);
  static const Color errorSoft = Color(0xFFFEF2F2);
  static const Color info = Color(0xFF155B78);
  static const Color infoSoft = Color(0xFFE0F2FE);

  // --- Backward-Compatibility Aliases ---
  // Maps previous green/terracotta aliases to the new Navy & Orange brand
  static const Color primaryForest = primaryNavy;
  static const Color forestDark = deepNavy;
  static const Color forestLight = secondaryBlue;
  static const Color forestSoft = Color(0xFFE6EFF5);

  static const Color warmCream = backgroundWarmOffWhite;
  static const Color warmCreamLight = Color(0xFFFAF7F0);

  static const Color accentTerracotta = accentOrange;
  static const Color terracottaDark = Color(0xFFE07E20);
  static const Color terracottaLight = accentOrangeLight;
  static const Color terracottaSoft = accentOrangeSoft;
  static const Color terracotta = accentOrange;

  static const Color secondaryTeal = secondaryBlue;
  static const Color accentCoral = accentOrange;
  static const Color accentAmber = warning;
  static const Color surface = lightSurface;
  static const Color divider = dividerColor;

  static const Color lightBackground = backgroundWarmOffWhite;
  static const Color lightSurface = Colors.white;
  static const Color lightSurfaceContainerLow = surfaceWarmWhite;
  static const Color lightTextPrimary = textPrimary;
  static const Color lightTextSecondary = textSecondary;
  static const Color lightBorder = borderNeutral;

  // Dark Scheme (Preserved for system theme compatibility)
  static const Color darkBackground = Color(0xFF041824);
  static const Color darkSurface = Color(0xFF082538);
  static const Color darkSurfaceContainerLow = Color(0xFF061D2C);
  static const Color darkSurfaceVariant = darkSurfaceContainerLow;
  static const Color darkTextPrimary = Color(0xFFF0F4F8);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkBorder = Color(0xFF1E3A4C);
}
