import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/models/course_lesson.dart';
import 'lesson_viewer_dialog.dart';

/// Clean, responsive tile for a curriculum lesson in the module syllabus list
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

    return InkWell(
      onTap: () => LessonViewerDialog.show(
        context,
        lesson: lesson,
        moduleTitle: moduleTitle,
      ),
      borderRadius: BorderRadius.circular(AppConstants.radiusMd),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceElevated : AppColors.warmCreamLight,
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Leading Icon Badge
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                border: Border.all(color: typeColor.withValues(alpha: 0.24)),
              ),
              child: Icon(
                _getTypeIcon(lesson.type),
                size: 20,
                color: typeColor,
              ),
            ),
            const SizedBox(width: 12),

            // Lesson Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Text(
                        lesson.typeDisplayLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: typeColor,
                        ),
                      ),
                      if (lesson.durationMinutes > 0) ...[
                        Text(
                          '•',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textMuted,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 11,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textMuted,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${lesson.durationMinutes} min',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Trailing View Button / Icon
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBackground : AppColors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                ),
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ],
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
        return AppColors.terracotta;
      case 'pdf':
        return AppColors.error;
      case 'image':
        return AppColors.info;
      case 'file':
      case 'document':
      case 'attachment':
        return AppColors.primaryForest;
      case 'reading':
        return AppColors.forestLight;
      case 'quiz':
        return AppColors.warning;
      case 'assignment':
        return const Color(0xFF673AB7);
      default:
        return AppColors.primaryForest;
    }
  }
}

