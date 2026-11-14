import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../domain/models/course_lesson.dart';
import '../../domain/models/course_module.dart';
import '../providers/courses_provider.dart';
import '../widgets/add_lesson_sheet.dart';
import '../widgets/add_module_sheet.dart';

class CourseCurriculumScreen extends ConsumerStatefulWidget {
  final String courseId;

  const CourseCurriculumScreen({super.key, required this.courseId});

  @override
  ConsumerState<CourseCurriculumScreen> createState() =>
      _CourseCurriculumScreenState();
}

class _CourseCurriculumScreenState
    extends ConsumerState<CourseCurriculumScreen> {
  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return AppColors.primaryForest;
      case 'pdf':
        return const Color(0xFFDC2626);
      case 'image':
        return const Color(0xFF7C3AED);
      case 'file':
      case 'document':
      case 'attachment':
        return const Color(0xFF2563EB);
      case 'reading':
        return const Color(0xFFD97706);
      case 'quiz':
        return const Color(0xFF0D9488);
      case 'assignment':
        return AppColors.accentTerracotta;
      default:
        return AppColors.primaryForest;
    }
  }

  IconData _getTypeIcon(CourseLesson lesson) {
    if (lesson.isVideo) return Icons.play_circle_fill_rounded;
    if (lesson.isPdf) return Icons.picture_as_pdf_rounded;
    if (lesson.isImage) return Icons.image_rounded;
    if (lesson.isFile) return Icons.insert_drive_file_rounded;
    if (lesson.isReading) return Icons.menu_book_rounded;
    if (lesson.isQuiz) return Icons.quiz_outlined;
    if (lesson.isAssignment) return Icons.assignment_outlined;
    return Icons.attachment_rounded;
  }

  void _showImagePreviewDialog(CourseLesson lesson) {
    if (lesson.contentUrl == null || lesson.contentUrl!.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkSurface
                : AppColors.surface,
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.image_rounded,
                      color: Color(0xFF7C3AED),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        lesson.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Image Viewer with Zoom & Pan
              Flexible(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(AppConstants.radiusMedium),
                  ),
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.8,
                    maxScale: 4.0,
                    child: Image.network(
                      lesson.contentUrl!,
                      fit: BoxFit.contain,
                      loadingBuilder: (c, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                      errorBuilder: (_, _, _) => const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'Failed to load image preview. Check network or image URL.',
                            style: TextStyle(fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Action Toolbar
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        lesson.fileName ?? lesson.contentUrl!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: lesson.contentUrl!),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Image link copied to clipboard'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 14),
                      label: const Text(
                        'Copy Link',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContentDetailsDialog(CourseLesson lesson) {
    final typeColor = _getTypeColor(lesson.type);
    final hasUrl =
        lesson.contentUrl != null && lesson.contentUrl!.trim().isNotEmpty;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppConstants.radiusLarge),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getTypeIcon(lesson),
                      color: typeColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lesson.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: typeColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                lesson.typeDisplayLabel.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: typeColor,
                                ),
                              ),
                            ),
                            if (lesson.durationMinutes > 0) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.timer_outlined,
                                size: 12,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${lesson.durationMinutes} mins',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              if (hasUrl) ...[
                const Text(
                  'Content / Storage Link',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkBackground
                        : AppColors.warmCream,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.divider,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.link_rounded,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          lesson.contentUrl!,
                          style: const TextStyle(fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        tooltip: 'Copy link',
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: lesson.contentUrl!),
                          );
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Content link copied to clipboard'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const Text(
                  'No direct URL or file attached to this curriculum item.',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Close'),
                    ),
                  ),
                  if (hasUrl) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: typeColor,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: lesson.contentUrl!),
                          );
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Link copied to clipboard'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('Copy URL'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteModule(CourseModule module) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Module?'),
        content: Text(
          'Are you sure you want to delete "${module.title}" and all its content items?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final repo = ref.read(courseRepositoryProvider);
              await repo.deleteModule(module.id);
              ref.invalidate(courseModulesProvider(widget.courseId));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteLesson(CourseLesson lesson) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item?'),
        content: Text('Are you sure you want to delete "${lesson.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final repo = ref.read(courseRepositoryProvider);
              await repo.deleteLesson(lesson.id);
              ref.invalidate(courseModulesProvider(widget.courseId));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonLeading(CourseLesson lesson, bool isDark) {
    final typeColor = _getTypeColor(lesson.type);

    // 1. YouTube Video Thumbnail
    if (lesson.isVideo && lesson.videoThumbnailUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 80,
          height: 48,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                lesson.videoThumbnailUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: typeColor.withValues(alpha: 0.1),
                  child: Icon(Icons.play_circle_outline, color: typeColor),
                ),
              ),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 2. Clinical Image Thumbnail
    if (lesson.isImage &&
        lesson.contentUrl != null &&
        lesson.contentUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 80,
          height: 48,
          child: Image.network(
            lesson.contentUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              color: typeColor.withValues(alpha: 0.12),
              child: Icon(
                Icons.broken_image_rounded,
                color: typeColor,
                size: 22,
              ),
            ),
          ),
        ),
      );
    }

    // 3. PDF Document Card
    if (lesson.isPdf) {
      return Container(
        width: 50,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFDC2626).withValues(alpha: 0.3),
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.picture_as_pdf_rounded,
              color: Color(0xFFDC2626),
              size: 20,
            ),
            SizedBox(height: 2),
            Text(
              'PDF',
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
                color: Color(0xFFDC2626),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    }

    // 4. File Attachment Card
    if (lesson.isFile) {
      final ext = lesson.fileExtension?.toUpperCase() ?? 'FILE';
      return Container(
        width: 50,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF2563EB).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF2563EB).withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.insert_drive_file_rounded,
              color: Color(0xFF2563EB),
              size: 19,
            ),
            const SizedBox(height: 2),
            Text(
              ext.length > 4 ? ext.substring(0, 4) : ext,
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2563EB),
              ),
            ),
          ],
        ),
      );
    }

    // 5. Default Type Icon Card
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: typeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(_getTypeIcon(lesson), color: typeColor, size: 22),
    );
  }

  Widget _buildSmallCountPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final courseAsync = ref.watch(courseDetailProvider(widget.courseId));
    final modulesAsync = ref.watch(courseModulesProvider(widget.courseId));

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      appBar: AppBar(
        title: const Text('Course Curriculum & Content'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () =>
                ref.invalidate(courseModulesProvider(widget.courseId)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryForest,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.create_new_folder_rounded),
        label: const Text('Add Module'),
        onPressed: () {
          modulesAsync.whenData((modules) {
            AddModuleSheet.show(
              context,
              courseId: widget.courseId,
              nextOrderIndex: modules.length + 1,
            ).then((added) {
              if (added == true) {
                ref.invalidate(courseModulesProvider(widget.courseId));
              }
            });
          });
        },
      ),
      body: SafeArea(
        child: ResponsiveLayout(
          child: RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(courseModulesProvider(widget.courseId)),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: [
                // Course Header Card
                courseAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (course) {
                    if (course == null) return const SizedBox.shrink();
                    return AppCard(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.forestSoft,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  course.categoryName,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryForest,
                                  ),
                                ),
                              ),
                              Text(
                                '${course.durationWeeks} Weeks • ${course.format.toUpperCase()}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            course.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          if (course.instructorName != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.person_outline_rounded,
                                  size: 14,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Instructor: ${course.instructorName}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),

                // Modules Accordion List
                modulesAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(
                        color: AppColors.primaryForest,
                      ),
                    ),
                  ),
                  error: (err, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Error loading curriculum: $err'),
                    ),
                  ),
                  data: (modules) {
                    if (modules.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(32),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            Icon(
                              Icons.folder_open_rounded,
                              size: 56,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Curriculum is empty',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Tap "Add Module" to begin creating modules and attaching videos, PDFs, images, and learning materials.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: modules.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final mod = modules[index];

                        return AppCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Module Header
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryForest.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'MODULE ${mod.orderIndex}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primaryForest,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      mod.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: const Icon(
                                      Icons.more_vert_rounded,
                                      size: 18,
                                    ),
                                    onSelected: (val) {
                                      if (val == 'edit') {
                                        AddModuleSheet.show(
                                          context,
                                          courseId: widget.courseId,
                                          existingModule: mod,
                                        ).then(
                                          (_) => ref.invalidate(
                                            courseModulesProvider(
                                              widget.courseId,
                                            ),
                                          ),
                                        );
                                      } else if (val == 'delete') {
                                        _confirmDeleteModule(mod);
                                      } else if (val == 'add_lesson') {
                                        AddLessonSheet.show(
                                          context,
                                          moduleId: mod.id,
                                          nextOrderIndex:
                                              mod.lessons.length + 1,
                                        ).then(
                                          (_) => ref.invalidate(
                                            courseModulesProvider(
                                              widget.courseId,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    itemBuilder: (ctx) => [
                                      const PopupMenuItem(
                                        value: 'add_lesson',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.add_circle_outline_rounded,
                                              size: 18,
                                              color: AppColors.primaryForest,
                                            ),
                                            SizedBox(width: 8),
                                            Text('Add Curriculum Item'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit_outlined, size: 18),
                                            SizedBox(width: 8),
                                            Text('Edit Module'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.delete_outline_rounded,
                                              size: 18,
                                              color: AppColors.error,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Delete Module',
                                              style: TextStyle(
                                                color: AppColors.error,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              if (mod.description != null &&
                                  mod.description!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  mod.description!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],

                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Text(
                                          '${mod.lessons.length} Items • ${mod.totalDurationMinutes} Mins',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        if (mod.videoCount > 0)
                                          _buildSmallCountPill(
                                            '${mod.videoCount} Videos',
                                            AppColors.primaryForest,
                                          ),
                                        if (mod.pdfCount > 0)
                                          _buildSmallCountPill(
                                            '${mod.pdfCount} PDFs',
                                            const Color(0xFFDC2626),
                                          ),
                                        if (mod.imageCount > 0)
                                          _buildSmallCountPill(
                                            '${mod.imageCount} Images',
                                            const Color(0xFF7C3AED),
                                          ),
                                        if (mod.fileCount > 0)
                                          _buildSmallCountPill(
                                            '${mod.fileCount} Files',
                                            const Color(0xFF2563EB),
                                          ),
                                      ],
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () {
                                      AddLessonSheet.show(
                                        context,
                                        moduleId: mod.id,
                                        nextOrderIndex: mod.lessons.length + 1,
                                      ).then(
                                        (_) => ref.invalidate(
                                          courseModulesProvider(
                                            widget.courseId,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.add_rounded,
                                      size: 14,
                                    ),
                                    label: const Text(
                                      'Add Item',
                                      style: TextStyle(fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),
                              const Divider(height: 1),
                              const SizedBox(height: 10),

                              // Lessons / Activities List
                              if (mod.lessons.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'No items in this module yet.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                        color: isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: mod.lessons.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, lIdx) {
                                    final lesson = mod.lessons[lIdx];
                                    final typeColor = _getTypeColor(
                                      lesson.type,
                                    );

                                    return InkWell(
                                      borderRadius: BorderRadius.circular(
                                        AppConstants.radiusMedium,
                                      ),
                                      onTap: () {
                                        if (lesson.isImage) {
                                          _showImagePreviewDialog(lesson);
                                        } else {
                                          _showContentDetailsDialog(lesson);
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? AppColors.darkSurface
                                              : AppColors.warmCream,
                                          borderRadius: BorderRadius.circular(
                                            AppConstants.radiusMedium,
                                          ),
                                          border: Border.all(
                                            color: isDark
                                                ? AppColors.darkBorder
                                                : AppColors.divider,
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Dynamic Thumbnail or Graphic
                                            _buildLessonLeading(lesson, isDark),

                                            const SizedBox(width: 10),

                                            // Title & Metadata
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    lesson.title,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Wrap(
                                                    spacing: 6,
                                                    runSpacing: 4,
                                                    crossAxisAlignment:
                                                        WrapCrossAlignment
                                                            .center,
                                                    children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 2,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: typeColor
                                                              .withValues(
                                                                alpha: 0.12,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                4,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          lesson
                                                              .typeDisplayLabel
                                                              .toUpperCase(),
                                                          style: TextStyle(
                                                            fontSize: 9,
                                                            fontWeight:
                                                                FontWeight.w800,
                                                            color: typeColor,
                                                          ),
                                                        ),
                                                      ),
                                                      if (lesson
                                                              .durationMinutes >
                                                          0) ...[
                                                        Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            const Icon(
                                                              Icons
                                                                  .timer_outlined,
                                                              size: 11,
                                                              color: AppColors
                                                                  .textSecondary,
                                                            ),
                                                            const SizedBox(
                                                              width: 2,
                                                            ),
                                                            Text(
                                                              '${lesson.durationMinutes}m',
                                                              style: const TextStyle(
                                                                fontSize: 10.5,
                                                                color: AppColors
                                                                    .textSecondary,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                      if (lesson.contentUrl !=
                                                              null &&
                                                          lesson
                                                              .contentUrl!
                                                              .isNotEmpty) ...[
                                                        Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Icon(
                                                              lesson.isImage
                                                                  ? Icons
                                                                        .zoom_in_rounded
                                                                  : Icons
                                                                        .link_rounded,
                                                              size: 11,
                                                              color: typeColor,
                                                            ),
                                                            const SizedBox(
                                                              width: 2,
                                                            ),
                                                            Text(
                                                              lesson.isImage
                                                                  ? 'Preview'
                                                                  : (lesson.fileName ??
                                                                        'Link'),
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: TextStyle(
                                                                fontSize: 10.5,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color:
                                                                    typeColor,
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

                                            PopupMenuButton<String>(
                                              icon: const Icon(
                                                Icons.more_vert_rounded,
                                                size: 16,
                                              ),
                                              onSelected: (val) {
                                                if (val == 'view') {
                                                  if (lesson.isImage) {
                                                    _showImagePreviewDialog(
                                                      lesson,
                                                    );
                                                  } else {
                                                    _showContentDetailsDialog(
                                                      lesson,
                                                    );
                                                  }
                                                } else if (val == 'copy_link') {
                                                  if (lesson.contentUrl !=
                                                      null) {
                                                    Clipboard.setData(
                                                      ClipboardData(
                                                        text:
                                                            lesson.contentUrl!,
                                                      ),
                                                    );
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Link copied to clipboard',
                                                        ),
                                                        duration: Duration(
                                                          seconds: 1,
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                } else if (val == 'edit') {
                                                  AddLessonSheet.show(
                                                    context,
                                                    moduleId: mod.id,
                                                    existingLesson: lesson,
                                                  ).then(
                                                    (_) => ref.invalidate(
                                                      courseModulesProvider(
                                                        widget.courseId,
                                                      ),
                                                    ),
                                                  );
                                                } else if (val == 'delete') {
                                                  _confirmDeleteLesson(lesson);
                                                }
                                              },
                                              itemBuilder: (ctx) => [
                                                if (lesson.contentUrl != null &&
                                                    lesson
                                                        .contentUrl!
                                                        .isNotEmpty) ...[
                                                  PopupMenuItem(
                                                    value: 'view',
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          lesson.isImage
                                                              ? Icons
                                                                    .zoom_in_rounded
                                                              : Icons
                                                                    .visibility_outlined,
                                                          size: 16,
                                                          color: typeColor,
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Text(
                                                          lesson.isImage
                                                              ? 'View Full Image'
                                                              : 'View Content',
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const PopupMenuItem(
                                                    value: 'copy_link',
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.copy_rounded,
                                                          size: 16,
                                                        ),
                                                        SizedBox(width: 8),
                                                        Text('Copy Link'),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                                const PopupMenuItem(
                                                  value: 'edit',
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.edit_outlined,
                                                        size: 16,
                                                      ),
                                                      SizedBox(width: 8),
                                                      Text('Edit Item'),
                                                    ],
                                                  ),
                                                ),
                                                const PopupMenuItem(
                                                  value: 'delete',
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .delete_outline_rounded,
                                                        size: 16,
                                                        color: AppColors.error,
                                                      ),
                                                      SizedBox(width: 8),
                                                      Text(
                                                        'Delete Item',
                                                        style: TextStyle(
                                                          color:
                                                              AppColors.error,
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
                                    );
                                  },
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
