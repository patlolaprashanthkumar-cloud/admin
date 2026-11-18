import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/models/student.dart';

/// Modern Academic Student Card
///
/// Presents student institutional credentials, active status badge,
/// academic stream tags, and enrolled course counts in alignment with the
/// IIECM LEARNING HUB design system.
class StudentCard extends StatelessWidget {
  final Student student;
  final Color Function(String hex)? parseHex;
  final VoidCallback onTap;

  const StudentCard({
    super.key,
    required this.student,
    this.parseHex,
    required this.onTap,
  });

  Color _resolveColor(String hex) {
    if (parseHex != null) {
      return parseHex!(hex);
    }
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return AppColors.primaryNavy;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isActive = student.accountStatus.toLowerCase() == 'active';

    final cardBg = isDark ? AppColors.darkSurface : AppColors.cardWhite;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.borderNeutral;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.primaryNavy.withValues(alpha: 0.08),
          highlightColor: AppColors.primaryNavy.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Avatar, Student Info, Status Badge, Chevron
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar with Institutional Navy Wash
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.primaryNavy.withValues(alpha: 0.3)
                            : AppColors.forestSoft,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryNavy.withValues(alpha: 0.15),
                          width: 1.2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          student.fullName.isNotEmpty
                              ? student.fullName.substring(0, 1).toUpperCase()
                              : 'S',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.accentOrangeLight
                                : AppColors.primaryNavy,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Name, Credentials, and Contact Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  student.fullName,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.textPrimary,
                                    letterSpacing: -0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Account Status Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? (isDark
                                            ? AppColors.success.withValues(
                                                alpha: 0.2,
                                              )
                                            : AppColors.successSoft)
                                      : (isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.08,
                                              )
                                            : Colors.grey.withValues(
                                                alpha: 0.12,
                                              )),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isActive
                                        ? AppColors.success.withValues(
                                            alpha: 0.35,
                                          )
                                        : AppColors.borderNeutral,
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  student.accountStatus.toUpperCase(),
                                  style: TextStyle(
                                    color: isActive
                                        ? (isDark
                                              ? const Color(0xFF34D399)
                                              : AppColors.success)
                                        : (isDark
                                              ? AppColors.darkTextSecondary
                                              : AppColors.textSecondary),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),

                          // Student ID & Academic Qualification
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : AppColors.backgroundWarmOffWhite,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: isDark
                                        ? AppColors.darkBorder
                                        : AppColors.borderSubtle,
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  student.studentId,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.primaryNavy,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${student.qualification} · ${student.educationLevel}',
                                  style: TextStyle(
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.textSecondary,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),

                          // Contact Row: Email & Phone
                          Text(
                            '${student.email} · ${student.phone}',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.darkTextSecondary.withValues(
                                      alpha: 0.8,
                                    )
                                  : AppColors.textMuted,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Chevron indicator
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textMuted,
                        size: 22,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Divider(
                  height: 1,
                  thickness: 0.8,
                  color: isDark
                      ? AppColors.darkBorder
                      : AppColors.borderNeutral,
                ),
                const SizedBox(height: 10),

                // Bottom Row: Multi-Category Academic Badges & Course Count
                Row(
                  children: [
                    Icon(
                      Icons.school_rounded,
                      size: 15,
                      color: isDark
                          ? AppColors.accentOrangeLight
                          : AppColors.primaryNavy,
                    ),
                    const SizedBox(width: 6),

                    // Categories Wrap
                    Expanded(
                      child: student.assignedCategories.isEmpty
                          ? Text(
                              'Category: ${student.preferredCategory}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : Wrap(
                              spacing: 5,
                              runSpacing: 4,
                              children: student.assignedCategories.map((c) {
                                final col = _resolveColor(c.color);
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: col.withValues(
                                      alpha: isDark ? 0.18 : 0.10,
                                    ),
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                      color: col.withValues(alpha: 0.28),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    c.name,
                                    style: TextStyle(
                                      color: col,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                    ),
                    const SizedBox(width: 8),

                    // Enrolled Courses Counter Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.accentOrange.withValues(alpha: 0.15)
                            : AppColors.accentOrangeSoft,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.accentOrange.withValues(alpha: 0.3),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_stories_rounded,
                            size: 12,
                            color: isDark
                                ? AppColors.accentOrangeLight
                                : AppColors.accentOrange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${student.enrolledCourseIds.length} Courses',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.accentOrangeLight
                                  : AppColors.accentOrange,
                              fontWeight: FontWeight.w800,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
