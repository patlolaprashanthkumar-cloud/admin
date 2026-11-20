import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/models/student_course.dart';

/// Modern Academic card representing an enrolled course in the My Courses screen
///
/// Features institutional branding, category-based taxonomy badges,
/// visual media banner with fallback, academic metadata, and direct curriculum access.
class CourseCard extends StatelessWidget {
  final StudentCourse course;
  final VoidCallback onTap;

  const CourseCard({super.key, required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isActive = course.isActive;
    final hasThumbnail =
        course.thumbnailUrl != null && course.thumbnailUrl!.trim().isNotEmpty;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      borderRadius: AppConstants.radiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Optional Course Thumbnail / Graphic Header
          if (hasThumbnail) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
              child: AspectRatio(
                aspectRatio: 16 / 7.5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      course.thumbnailUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _buildDefaultThumbnail(isDark),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${course.durationWeeks} WEEKS',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spacingSm + 4),
          ],

          // Header Row: Category Badge, Format Pill & Enrollment Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Category Taxonomy Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceElevated
                            : AppColors.forestSoft,
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusSm,
                        ),
                        border: Border.all(
                          color: AppColors.primaryNavy.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Text(
                        course.categoryName.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                    ),

                    // Delivery Format Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkBackground
                            : AppColors.warmCreamLight,
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusSm,
                        ),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        course.format.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.accentOrangeLight
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Enrollment Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.successSoft : AppColors.infoSoft,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                  border: Border.all(
                    color: isActive
                        ? AppColors.success.withValues(alpha: 0.28)
                        : AppColors.info.withValues(alpha: 0.28),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isActive
                          ? Icons.check_circle_rounded
                          : Icons.verified_rounded,
                      size: 11,
                      color: isActive ? AppColors.success : AppColors.info,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      course.enrollmentStatus.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: isActive ? AppColors.success : AppColors.info,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingSm + 2),

          // Course Title (Preserves test expectation: 'Advanced Emergency Protocols')
          Text(
            course.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              height: 1.3,
            ),
          ),

          if (course.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              course.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],

          const SizedBox(height: AppConstants.spacingMd),

          // Metadata Chips Row: Duration, Instructor/Faculty
          Wrap(
            spacing: 14,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 13,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${course.durationWeeks} Weeks Curriculum',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (course.instructorName != null &&
                  course.instructorName!.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceElevated
                            : AppColors.forestSoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        size: 13,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      course.instructorName!,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          const SizedBox(height: AppConstants.spacingMd),
          Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
          ),
          const SizedBox(height: AppConstants.spacingMd - 2),

          // Action Row: Curriculum Ready Pill & Action Button (Responsive Wrap prevents RenderFlex overflow on narrow/test widths)
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              runAlignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppConstants.spacingSm,
              runSpacing: AppConstants.spacingSm + 2,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Curriculum Enrolled',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                // Preserves exact text contract: 'View Curriculum & Lessons'
                AppButton(
                  label: 'View Curriculum & Lessons',
                  icon: Icons.menu_book_rounded,
                  isFullWidth: false,
                  height: 38,
                  onPressed: onTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultThumbnail(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.forestSoft,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
      ),
      child: Center(
        child: Icon(
          Icons.school_outlined,
          size: 32,
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.primaryNavy.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}
