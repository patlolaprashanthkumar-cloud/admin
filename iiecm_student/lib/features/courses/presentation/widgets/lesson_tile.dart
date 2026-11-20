import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/models/course_lesson.dart';
import 'lesson_viewer_dialog.dart';

/// Clean, responsive tile for a curriculum lesson in the module syllabus list
///
/// Follows the IIECM Modern Academic design language with high visual differentiation
/// across media types (video, PDF, images, protocols, quizzes), clear metadata, and
/// intuitive tap interaction for launching the lesson viewer.
class LessonTile extends StatelessWidget {
  final CourseLesson lesson;
  final String moduleTitle;

  const LessonTile({
    super.key,
    required this.lesson,
    required this.moduleTitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final typeColor = _getTypeColor(lesson.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceElevated
            : AppColors.warmCreamLight,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => LessonViewerDialog.show(
            context,
            lesson: lesson,
            moduleTitle: moduleTitle,
          ),
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          splashColor: typeColor.withValues(alpha: 0.1),
          highlightColor: typeColor.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Leading Icon Badge with Media-Type Differentiation
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                    border: Border.all(
                      color: typeColor.withValues(alpha: 0.28),
                      width: 1.2,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      _getTypeIcon(lesson.type),
                      size: 20,
                      color: typeColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Lesson Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title
                      Text(
                        lesson.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Metadata Row: Type pill, duration, and resource tag
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 3,
                        children: [
                          // Type Label Chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              lesson.typeDisplayLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                                color: typeColor,
                              ),
                            ),
                          ),

                          // Duration Chip (if available)
                          if (lesson.durationMinutes > 0)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.schedule_rounded,
                                  size: 11,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '${lesson.durationMinutes} min',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),

                          // Stream / Resource Status Indicator
                          if (lesson.isVideo)
                            Text(
                              '• Video Stream',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textMuted,
                              ),
                            )
                          else if (lesson.isPdf)
                            Text(
                              '• Clinical PDF',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textMuted,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Trailing Action Button
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBackground : AppColors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      lesson.isVideo
                          ? Icons.play_arrow_rounded
                          : Icons.arrow_forward_rounded,
                      size: 15,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return Icons.play_circle_filled_rounded;
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'image':
        return Icons.image_rounded;
      case 'file':
      case 'document':
      case 'attachment':
        return Icons.insert_drive_file_rounded;
      case 'reading':
        return Icons.menu_book_rounded;
      case 'quiz':
        return Icons.quiz_rounded;
      case 'assignment':
        return Icons.assignment_rounded;
      default:
        return Icons.article_rounded;
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return AppColors.accentOrange;
      case 'pdf':
        return AppColors.error;
      case 'image':
        return AppColors.info;
      case 'file':
      case 'document':
      case 'attachment':
        return AppColors.primaryNavy;
      case 'reading':
        return AppColors.secondaryBlue;
      case 'quiz':
        return AppColors.warning;
      case 'assignment':
        return const Color(0xFF7C3AED);
      default:
        return AppColors.primaryNavy;
    }
  }
}
