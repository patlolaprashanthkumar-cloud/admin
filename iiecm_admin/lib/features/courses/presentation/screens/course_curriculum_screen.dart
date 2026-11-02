import 'package:flutter/material.dart';
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
  ConsumerState<CourseCurriculumScreen> createState() => _CourseCurriculumScreenState();
}

class _CourseCurriculumScreenState extends ConsumerState<CourseCurriculumScreen> {
  void _confirmDeleteModule(CourseModule module) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Module?'),
        content: Text('Are you sure you want to delete "${module.title}" and all its lessons?'),
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
        title: const Text('Delete Lesson?'),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final courseAsync = ref.watch(courseDetailProvider(widget.courseId));
    final modulesAsync = ref.watch(courseModulesProvider(widget.courseId));

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      appBar: AppBar(
        title: const Text('Course Video Curriculum'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(courseModulesProvider(widget.courseId)),
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
              if (added == true) ref.invalidate(courseModulesProvider(widget.courseId));
            });
          });
        },
      ),
      body: SafeArea(
        child: ResponsiveLayout(
          child: RefreshIndicator(
            onRefresh: () async => ref.invalidate(courseModulesProvider(widget.courseId)),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                              const Spacer(),
                              Text(
                                '${course.durationWeeks} Weeks • ${course.format.toUpperCase()}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            course.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                          ),
                          if (course.instructorName != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.person_outline_rounded, size: 14, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  'Instructor: ${course.instructorName}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
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
                      child: CircularProgressIndicator(color: AppColors.primaryForest),
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
                              Icons.video_library_outlined,
                              size: 56,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Curriculum is empty',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Tap "Add Module" to begin creating modules and attaching video lectures.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryForest.withValues(alpha: 0.12),
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
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert_rounded, size: 18),
                                    onSelected: (val) {
                                      if (val == 'edit') {
                                        AddModuleSheet.show(
                                          context,
                                          courseId: widget.courseId,
                                          existingModule: mod,
                                        ).then((_) => ref.invalidate(courseModulesProvider(widget.courseId)));
                                      } else if (val == 'delete') {
                                        _confirmDeleteModule(mod);
                                      } else if (val == 'add_lesson') {
                                        AddLessonSheet.show(
                                          context,
                                          moduleId: mod.id,
                                          nextOrderIndex: mod.lessons.length + 1,
                                        ).then((_) => ref.invalidate(courseModulesProvider(widget.courseId)));
                                      }
                                    },
                                    itemBuilder: (ctx) => [
                                      const PopupMenuItem(
                                        value: 'add_lesson',
                                        child: Row(
                                          children: [
                                            Icon(Icons.video_call_outlined, size: 18),
                                            SizedBox(width: 8),
                                            Text('Add Lesson'),
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
                                            Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                                            SizedBox(width: 8),
                                            Text('Delete Module', style: TextStyle(color: AppColors.error)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              if (mod.description != null && mod.description!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  mod.description!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                  ),
                                ),
                              ],

                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Text(
                                    '${mod.lessons.length} Lessons • ${mod.totalDurationMinutes} Mins Total',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                                  ),
                                  const Spacer(),
                                  TextButton.icon(
                                    onPressed: () {
                                      AddLessonSheet.show(
                                        context,
                                        moduleId: mod.id,
                                        nextOrderIndex: mod.lessons.length + 1,
                                      ).then((_) => ref.invalidate(courseModulesProvider(widget.courseId)));
                                    },
                                    icon: const Icon(Icons.add_rounded, size: 14),
                                    label: const Text('Add Lesson', style: TextStyle(fontSize: 11)),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),
                              const Divider(height: 1),
                              const SizedBox(height: 10),

                              // Lessons List
                              if (mod.lessons.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Center(
                                    child: Text(
                                      'No lessons in this module yet.',
                                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                                    ),
                                  ),
                                )
                              else
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: mod.lessons.length,
                                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                                  itemBuilder: (context, lIdx) {
                                    final lesson = mod.lessons[lIdx];
                                    final thumbUrl = lesson.videoThumbnailUrl;

                                    return Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isDark ? AppColors.darkSurface : AppColors.warmCream,
                                        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.divider),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Thumbnail or Icon
                                          if (thumbUrl != null)
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(6),
                                              child: SizedBox(
                                                width: 80,
                                                height: 48,
                                                child: Image.network(
                                                  thumbUrl,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, _, _) => Container(
                                                    color: AppColors.primaryForest.withValues(alpha: 0.1),
                                                    child: const Icon(Icons.play_circle_outline, color: AppColors.primaryForest),
                                                  ),
                                                ),
                                              ),
                                            )
                                          else
                                            Container(
                                              width: 48,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryForest.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                lesson.isVideo
                                                    ? Icons.play_arrow_rounded
                                                    : (lesson.isReading
                                                        ? Icons.article_outlined
                                                        : Icons.help_outline_rounded),
                                                color: AppColors.primaryForest,
                                              ),
                                            ),

                                          const SizedBox(width: 10),

                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  lesson.title,
                                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                                ),
                                                const SizedBox(height: 3),
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.forestSoft,
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        lesson.type.toUpperCase(),
                                                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.primaryForest),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    const Icon(Icons.timer_outlined, size: 12, color: AppColors.textSecondary),
                                                    const SizedBox(width: 2),
                                                    Text(
                                                      '${lesson.durationMinutes}m',
                                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),

                                          PopupMenuButton<String>(
                                            icon: const Icon(Icons.more_vert_rounded, size: 16),
                                            onSelected: (val) {
                                              if (val == 'edit') {
                                                AddLessonSheet.show(
                                                  context,
                                                  moduleId: mod.id,
                                                  existingLesson: lesson,
                                                ).then((_) => ref.invalidate(courseModulesProvider(widget.courseId)));
                                              } else if (val == 'delete') {
                                                _confirmDeleteLesson(lesson);
                                              }
                                            },
                                            itemBuilder: (ctx) => [
                                              const PopupMenuItem(
                                                value: 'edit',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.edit_outlined, size: 16),
                                                    SizedBox(width: 8),
                                                    Text('Edit Lesson'),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
                                                    SizedBox(width: 8),
                                                    Text('Delete Lesson', style: TextStyle(color: AppColors.error)),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
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

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
