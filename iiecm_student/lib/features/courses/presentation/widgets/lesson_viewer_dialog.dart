import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../domain/models/course_lesson.dart';

/// Modal dialog providing interactive preview, playback info, and access to lesson learning resources
class LessonViewerDialog extends StatelessWidget {
  final CourseLesson lesson;
  final String moduleTitle;

  const LessonViewerDialog({
    super.key,
    required this.lesson,
    required this.moduleTitle,
  });

  static Future<void> show(
    BuildContext context, {
    required CourseLesson lesson,
    required String moduleTitle,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => LessonViewerDialog(
        lesson: lesson,
        moduleTitle: moduleTitle,
      ),
    );
  }

  void _copyContentUrl(BuildContext context) {
    if (lesson.contentUrl == null || lesson.contentUrl!.isEmpty) return;
    Clipboard.setData(ClipboardData(text: lesson.contentUrl!));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Resource link copied to clipboard'),
          ],
        ),
        backgroundColor: AppColors.primaryForest,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasUrl = lesson.contentUrl != null && lesson.contentUrl!.trim().isNotEmpty;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
      ),
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Bar: Module Tag & Close Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurfaceElevated : AppColors.forestSoft,
                            borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                          ),
                          child: Text(
                            moduleTitle.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: AppColors.primaryForest,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          lesson.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingSm),

              // Badges Row: Type & Duration
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _buildPill(
                    icon: _getTypeIcon(lesson.type),
                    label: lesson.typeDisplayLabel,
                    color: _getTypeColor(lesson.type),
                    isDark: isDark,
                  ),
                  if (lesson.durationMinutes > 0)
                    _buildPill(
                      icon: Icons.timer_outlined,
                      label: '${lesson.durationMinutes} min',
                      color: AppColors.textSecondary,
                      isDark: isDark,
                    ),
                  _buildPill(
                    icon: Icons.sort_rounded,
                    label: 'Lesson #${lesson.orderIndex}',
                    color: AppColors.textSecondary,
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingMd),

              const Divider(height: 1),
              const SizedBox(height: AppConstants.spacingMd),

              // Dynamic Media / Resource Content Section
              if (!hasUrl)
                _buildNoUrlCard(isDark, theme)
              else if (lesson.isVideo)
                _buildVideoResource(context, isDark, theme)
              else if (lesson.isImage)
                _buildImageResource(context, isDark, theme)
              else if (lesson.isPdf)
                _buildPdfResource(context, isDark, theme)
              else
                _buildGenericFileResource(context, isDark, theme),

              const SizedBox(height: AppConstants.spacingLg),

              // Actions Row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (hasUrl)
                    TextButton.icon(
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Copy URL'),
                      onPressed: () => _copyContentUrl(context),
                    ),
                  const SizedBox(width: AppConstants.spacingSm),
                  AppButton(
                    label: 'Close',
                    variant: AppButtonVariant.primary,
                    isFullWidth: false,
                    height: 38,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPill({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoUrlCard(bool isDark, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.warmCream,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Clinical In-Person or Upcoming Material',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'This lesson module is conducted via clinical ward rounds, OSCE demonstration, or the faculty will publish digital access closer to the session date.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoResource(BuildContext context, bool isDark, ThemeData theme) {
    final thumbUrl = lesson.videoThumbnailUrl;
    final isYouTube = lesson.youtubeVideoId != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (thumbUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    thumbUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: Colors.black87,
                      child: const Center(
                        child: Icon(Icons.video_library_rounded, size: 48, color: Colors.white54),
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isYouTube ? 'YouTube Lecture' : 'Video Stream',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingLg),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceElevated : AppColors.warmCream,
              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            ),
            child: const Column(
              children: [
                Icon(Icons.video_camera_front_rounded, size: 48, color: AppColors.terracotta),
                SizedBox(height: 8),
                Text(
                  'Video Lecture Stream Available',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppConstants.spacingSm),
        _buildUrlDisplay(context, isDark, theme),
      ],
    );
  }

  Widget _buildImageResource(BuildContext context, bool isDark, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          child: Image.network(
            lesson.contentUrl!,
            fit: BoxFit.contain,
            loadingBuilder: (ctx, child, progress) {
              if (progress == null) return child;
              return Container(
                height: 200,
                color: isDark ? AppColors.darkSurfaceElevated : AppColors.warmCream,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            },
            errorBuilder: (_, _, _) => Container(
              height: 180,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : AppColors.warmCream,
                borderRadius: BorderRadius.circular(AppConstants.radiusMd),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.broken_image_rounded, size: 40, color: AppColors.error),
                    SizedBox(height: 6),
                    Text('Unable to display image preview'),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppConstants.spacingSm),
        _buildUrlDisplay(context, isDark, theme),
      ],
    );
  }

  Widget _buildPdfResource(BuildContext context, bool isDark, ThemeData theme) {
    final fileName = lesson.fileName ?? 'Clinical_Document.pdf';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppConstants.spacingMd),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceElevated : AppColors.warmCream,
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorSoft,
                  borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                ),
                child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.error, size: 32),
              ),
              const SizedBox(width: AppConstants.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Portable Document Format • Clinical Case Study',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppConstants.spacingSm),
        _buildUrlDisplay(context, isDark, theme),
      ],
    );
  }

  Widget _buildGenericFileResource(BuildContext context, bool isDark, ThemeData theme) {
    final fileName = lesson.fileName ?? 'Study_Material';
    final ext = lesson.fileExtension?.toUpperCase() ?? 'FILE';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppConstants.spacingMd),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceElevated : AppColors.warmCream,
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.forestSoft,
                  borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                ),
                child: const Icon(Icons.attach_file_rounded, color: AppColors.primaryForest, size: 30),
              ),
              const SizedBox(width: AppConstants.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$ext Attachment • Academic Reference Document',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppConstants.spacingSm),
        _buildUrlDisplay(context, isDark, theme),
      ],
    );
  }

  Widget _buildUrlDisplay(BuildContext context, bool isDark, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.warmCreamLight,
        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.link_rounded, size: 16, color: AppColors.primaryForest),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              lesson.contentUrl ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ),
        ],
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

