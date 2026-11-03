import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/youtube_helper.dart';
import '../../domain/models/course_lesson.dart';
import '../providers/courses_provider.dart';

class AddLessonSheet extends ConsumerStatefulWidget {
  final String moduleId;
  final CourseLesson? existingLesson;
  final int nextOrderIndex;

  const AddLessonSheet({
    super.key,
    required this.moduleId,
    this.existingLesson,
    this.nextOrderIndex = 1,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String moduleId,
    CourseLesson? existingLesson,
    int nextOrderIndex = 1,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddLessonSheet(
        moduleId: moduleId,
        existingLesson: existingLesson,
        nextOrderIndex: nextOrderIndex,
      ),
    );
  }

  @override
  ConsumerState<AddLessonSheet> createState() => _AddLessonSheetState();
}

class _AddLessonSheetState extends ConsumerState<AddLessonSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _durationController;
  late TextEditingController _contentUrlController;
  late TextEditingController _orderController;

  late String _type;
  String? _previewThumbnailUrl;
  String? _previewVideoId;
  bool _isSubmitting = false;

  bool get isEditing => widget.existingLesson != null;

  @override
  void initState() {
    super.initState();
    final l = widget.existingLesson;
    _titleController = TextEditingController(text: l?.title ?? '');
    _durationController = TextEditingController(
      text: l != null ? l.durationMinutes.toString() : '30',
    );
    _contentUrlController = TextEditingController(text: l?.contentUrl ?? '');
    _orderController = TextEditingController(
      text: l != null
          ? l.orderIndex.toString()
          : widget.nextOrderIndex.toString(),
    );
    _type = l?.type ?? 'video';

    _contentUrlController.addListener(_updateVideoPreview);
    _updateVideoPreview();
  }

  @override
  void dispose() {
    _contentUrlController.removeListener(_updateVideoPreview);
    _titleController.dispose();
    _durationController.dispose();
    _contentUrlController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  void _updateVideoPreview() {
    if (_type == 'video') {
      final url = _contentUrlController.text.trim();
      if (YouTubeHelper.isValidYouTubeUrl(url)) {
        setState(() {
          _previewVideoId = YouTubeHelper.extractVideoId(url);
          _previewThumbnailUrl = YouTubeHelper.getThumbnailUrl(url);
        });
      } else {
        if (_previewThumbnailUrl != null) {
          setState(() {
            _previewThumbnailUrl = null;
            _previewVideoId = null;
          });
        }
      }
    } else {
      if (_previewThumbnailUrl != null) {
        setState(() {
          _previewThumbnailUrl = null;
          _previewVideoId = null;
        });
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(courseRepositoryProvider);
      final duration = int.tryParse(_durationController.text.trim()) ?? 0;
      final order = int.tryParse(_orderController.text.trim()) ?? 1;

      final lesson = CourseLesson(
        id: widget.existingLesson?.id ?? '',
        moduleId: widget.moduleId,
        title: _titleController.text.trim(),
        durationMinutes: duration,
        type: _type,
        orderIndex: order,
        contentUrl: _contentUrlController.text.trim().isNotEmpty
            ? _contentUrlController.text.trim()
            : null,
        createdAt: widget.existingLesson?.createdAt ?? DateTime.now(),
      );

      if (isEditing) {
        await repo.updateLesson(lesson);
      } else {
        await repo.createLesson(lesson);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing ? 'Lesson updated' : 'Lesson added to module',
          ),
          backgroundColor: AppColors.primaryForest,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final availableHeight = mediaQuery.size.height - mediaQuery.padding.top;
    final maxSheetHeight = availableHeight - bottomInset;
    final effectiveHeight = maxSheetHeight * 0.85;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: effectiveHeight.clamp(
          260.0,
          maxSheetHeight > 260.0 ? maxSheetHeight : availableHeight,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppConstants.radiusLarge),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Handle Bar
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryForest.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.play_lesson_rounded,
                      color: AppColors.primaryForest,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Edit Lesson' : 'Add Lesson to Module',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Configure video, auto-extracted thumbnail & content',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  children: [
                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Lesson Title *',
                        hintText: 'e.g. Interpretation of Central Venous Pressure Tracings',
                        prefixIcon: Icon(Icons.title_rounded),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter title'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Type & Duration
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _type,
                            decoration: const InputDecoration(
                              labelText: 'Lesson Type',
                              prefixIcon: Icon(Icons.category_outlined),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'video',
                                child: Text('Video Lecture'),
                              ),
                              DropdownMenuItem(
                                value: 'reading',
                                child: Text('Clinical Reading'),
                              ),
                              DropdownMenuItem(
                                value: 'quiz',
                                child: Text('Checkpoint Quiz'),
                              ),
                              DropdownMenuItem(
                                value: 'assignment',
                                child: Text('Practical Task'),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _type = val);
                                _updateVideoPreview();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _durationController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Duration (Mins) *',
                              prefixIcon: Icon(Icons.timer_outlined),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Required';
                              }
                              if (int.tryParse(v) == null) {
                                return 'Must be a number';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Display Order
                    TextFormField(
                      controller: _orderController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Display Order *',
                        prefixIcon: Icon(Icons.format_list_numbered_rounded),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (int.tryParse(v) == null) return 'Must be a number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Content URL / Video Link
                    TextFormField(
                      controller: _contentUrlController,
                      keyboardType: TextInputType.url,
                      decoration: InputDecoration(
                        labelText: _type == 'video'
                            ? 'YouTube Video URL *'
                            : 'Content URL / Resource Link',
                        hintText: _type == 'video'
                            ? 'https://www.youtube.com/watch?v=dQw4w9WgXcQ'
                            : 'https://...',
                        prefixIcon: Icon(
                          _type == 'video'
                              ? Icons.smart_display_rounded
                              : Icons.link_rounded,
                        ),
                      ),
                      validator: (v) {
                        if (_type == 'video' &&
                            (v == null || v.trim().isEmpty)) {
                          return 'Video lessons require a URL';
                        }
                        return null;
                      },
                    ),

                    // Real-Time YouTube Video Thumbnail Preview
                    if (_type == 'video') ...[
                      const SizedBox(height: 16),
                      if (_previewThumbnailUrl != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.forestSoft,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.primaryForest.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    size: 16,
                                    color: AppColors.primaryForest,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Detected YouTube Video (ID: $_previewVideoId)',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryForest,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: Image.network(
                                    _previewThumbnailUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      color: Colors.grey.shade300,
                                      child: const Center(
                                        child: Text(
                                          'Thumbnail unavailable',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurface
                                : AppColors.warmCream,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.divider,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Paste a YouTube URL (watch, youtu.be, embed, shorts) to automatically extract high-resolution thumbnails.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Sticky Bottom Actions
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.surface,
                  border: Border(
                    top: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.divider,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryForest,
                          foregroundColor: Colors.white,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(isEditing ? 'Save Changes' : 'Add Lesson'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
