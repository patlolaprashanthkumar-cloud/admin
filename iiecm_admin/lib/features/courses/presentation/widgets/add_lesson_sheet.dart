import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  late String
  _type; // 'video', 'pdf', 'image', 'file', 'reading', 'quiz', 'assignment'
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
      text: l != null ? l.durationMinutes.toString() : '15',
    );
    _contentUrlController = TextEditingController(text: l?.contentUrl ?? '');
    _orderController = TextEditingController(
      text: l != null
          ? l.orderIndex.toString()
          : widget.nextOrderIndex.toString(),
    );
    _type = l?.type ?? 'video';

    _contentUrlController.addListener(_onUrlChanged);
    _updatePreview();
  }

  @override
  void dispose() {
    _contentUrlController.removeListener(_onUrlChanged);
    _titleController.dispose();
    _durationController.dispose();
    _contentUrlController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  void _onUrlChanged() {
    final url = _contentUrlController.text.trim();
    if (url.isNotEmpty) {
      _autoDetectType(url);
    }
    _updatePreview();
  }

  void _autoDetectType(String url) {
    final lower = url.toLowerCase();

    // YouTube URLs -> Video
    if (YouTubeHelper.isValidYouTubeUrl(url)) {
      if (_type != 'video') {
        setState(() => _type = 'video');
      }
      return;
    }

    // Direct Video Extensions -> Video
    if (lower.endsWith('.mp4') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.m3u8')) {
      if (_type != 'video') {
        setState(() => _type = 'video');
      }
      return;
    }

    // PDF Documents -> PDF
    if (lower.endsWith('.pdf')) {
      if (_type != 'pdf') {
        setState(() => _type = 'pdf');
      }
      return;
    }

    // Image Extensions -> Image
    if (lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.svg')) {
      if (_type != 'image') {
        setState(() => _type = 'image');
      }
      return;
    }

    // Common Files/Archives/Office Documents -> File
    if (lower.endsWith('.zip') ||
        lower.endsWith('.rar') ||
        lower.endsWith('.doc') ||
        lower.endsWith('.docx') ||
        lower.endsWith('.ppt') ||
        lower.endsWith('.pptx') ||
        lower.endsWith('.xls') ||
        lower.endsWith('.xlsx') ||
        lower.endsWith('.csv') ||
        lower.endsWith('.tar') ||
        lower.endsWith('.gz')) {
      if (_type != 'file') {
        setState(() => _type = 'file');
      }
      return;
    }
  }

  void _updatePreview() {
    final url = _contentUrlController.text.trim();

    if (_type == 'video') {
      if (YouTubeHelper.isValidYouTubeUrl(url)) {
        setState(() {
          _previewVideoId = YouTubeHelper.extractVideoId(url);
          _previewThumbnailUrl = YouTubeHelper.getThumbnailUrl(url);
        });
      } else {
        if (_previewThumbnailUrl != null || _previewVideoId != null) {
          setState(() {
            _previewThumbnailUrl = null;
            _previewVideoId = null;
          });
        }
      }
    } else {
      if (_previewThumbnailUrl != null || _previewVideoId != null) {
        setState(() {
          _previewThumbnailUrl = null;
          _previewVideoId = null;
        });
      }
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text != null && text.isNotEmpty) {
      _contentUrlController.text = text;
      _onUrlChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pasted link from clipboard'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }

  String? _extractFileName(String url) {
    if (url.trim().isEmpty) return null;
    try {
      final uri = Uri.parse(url.trim());
      final segments = uri.pathSegments;
      if (segments.isNotEmpty && segments.last.isNotEmpty) {
        return Uri.decodeComponent(segments.last);
      }
    } catch (_) {}
    return null;
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
            isEditing
                ? '${lesson.typeDisplayLabel} updated'
                : '${lesson.typeDisplayLabel} added to module',
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

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return Icons.play_circle_fill_rounded;
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'image':
        return Icons.image_rounded;
      case 'file':
        return Icons.insert_drive_file_rounded;
      case 'reading':
        return Icons.menu_book_rounded;
      case 'quiz':
        return Icons.quiz_outlined;
      case 'assignment':
        return Icons.assignment_outlined;
      default:
        return Icons.attachment_rounded;
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return AppColors.primaryForest;
      case 'pdf':
        return const Color(0xFFDC2626);
      case 'image':
        return const Color(0xFF7C3AED);
      case 'file':
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final availableHeight = mediaQuery.size.height - mediaQuery.padding.top;
    final maxSheetHeight = availableHeight - bottomInset;
    final effectiveHeight = maxSheetHeight * 0.90;

    final typeColor = _getTypeColor(_type);
    final contentUrl = _contentUrlController.text.trim();
    final fileName = _extractFileName(contentUrl);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: effectiveHeight.clamp(
          320.0,
          maxSheetHeight > 320.0 ? maxSheetHeight : availableHeight,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppConstants.radiusLarge),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 24,
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
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getTypeIcon(_type),
                      color: typeColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing
                              ? 'Edit Curriculum Item'
                              : 'Add Curriculum Item to Module',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Accepts videos, PDFs, images & every learning file',
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

            // Form Content
            Expanded(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context)
                    .copyWith(scrollbars: false),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    children: [
                      // Quick Type Selector Chips
                      Text(
                        'Content Type',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildTypeChip(
                              'video',
                              'Video',
                              Icons.videocam_rounded,
                            ),
                            const SizedBox(width: 8),
                            _buildTypeChip(
                              'pdf',
                              'PDF Doc',
                              Icons.picture_as_pdf_rounded,
                            ),
                            const SizedBox(width: 8),
                            _buildTypeChip(
                              'image',
                              'Image',
                              Icons.image_rounded,
                            ),
                            const SizedBox(width: 8),
                            _buildTypeChip(
                              'file',
                              'File',
                              Icons.attach_file_rounded,
                            ),
                            const SizedBox(width: 8),
                            _buildTypeChip(
                              'reading',
                              'Reading',
                              Icons.menu_book_rounded,
                            ),
                            const SizedBox(width: 8),
                            _buildTypeChip('quiz', 'Quiz', Icons.quiz_outlined),
                            const SizedBox(width: 8),
                            _buildTypeChip(
                              'assignment',
                              'Task',
                              Icons.assignment_outlined,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Title
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Item Title *',
                          hintText: _getTitleHintForType(_type),
                          prefixIcon: const Icon(Icons.title_rounded),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter title'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Detailed Type Dropdown & Duration
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<String>(
                              initialValue: _type,
                              decoration: const InputDecoration(
                                labelText: 'Activity Type',
                                prefixIcon: Icon(Icons.category_outlined),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'video',
                                  child: Text('Video Lecture / Stream'),
                                ),
                                DropdownMenuItem(
                                  value: 'pdf',
                                  child: Text('PDF Document / Slides'),
                                ),
                                DropdownMenuItem(
                                  value: 'image',
                                  child: Text('Clinical Image / Diagram'),
                                ),
                                DropdownMenuItem(
                                  value: 'file',
                                  child: Text('File Attachment (Any Type)'),
                                ),
                                DropdownMenuItem(
                                  value: 'reading',
                                  child: Text('Clinical Reading / Notes'),
                                ),
                                DropdownMenuItem(
                                  value: 'quiz',
                                  child: Text('Checkpoint Quiz'),
                                ),
                                DropdownMenuItem(
                                  value: 'assignment',
                                  child: Text('Practical Assignment'),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _type = val);
                                  _updatePreview();
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _durationController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Duration (Mins)',
                                hintText: 'e.g. 15',
                                prefixIcon: Icon(Icons.timer_outlined),
                              ),
                              validator: (v) {
                                if (v != null && v.trim().isNotEmpty) {
                                  if (int.tryParse(v.trim()) == null) {
                                    return 'Must be integer';
                                  }
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
                          if (v == null || v.trim().isEmpty) {
                            return 'Required';
                          }
                          if (int.tryParse(v) == null) {
                            return 'Must be a number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Content URL / File Link
                      TextFormField(
                        controller: _contentUrlController,
                        keyboardType: TextInputType.url,
                        decoration: InputDecoration(
                          labelText: _getUrlLabelForType(_type),
                          hintText: _getUrlHintForType(_type),
                          prefixIcon: Icon(_getTypeIcon(_type)),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.content_paste_rounded),
                            tooltip: 'Paste link from clipboard',
                            onPressed: _pasteFromClipboard,
                          ),
                        ),
                        validator: (v) {
                          if ([
                            'video',
                            'pdf',
                            'image',
                            'file',
                          ].contains(_type)) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Please enter a URL or file link';
                            }
                            final uri = Uri.tryParse(v.trim());
                            if (uri == null || !uri.hasScheme) {
                              return 'Please enter a valid link (e.g. https://...)';
                            }
                          }
                          return null;
                        },
                      ),

                      // REAL-TIME PREVIEWS FOR ALL SUPPORTED FILE TYPES
                      const SizedBox(height: 14),

                      // 1. YouTube Video Preview
                      if (_type == 'video' && _previewThumbnailUrl != null) ...[
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
                      ]
                      // 2. Direct Video File Preview (MP4, WebM, etc.)
                      else if (_type == 'video' &&
                          contentUrl.isNotEmpty &&
                          _previewThumbnailUrl == null) ...[
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
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryForest,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Direct Video Stream / File Link',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryForest,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      fileName ?? contentUrl,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]
                      // 3. PDF Document Preview
                      else if (_type == 'pdf' && contentUrl.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626)
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFDC2626)
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDC2626),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.picture_as_pdf_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'PDF Document Attached',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFDC2626),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      fileName ?? contentUrl,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]
                      // 4. Clinical Image Preview
                      else if (_type == 'image' && contentUrl.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED)
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFF7C3AED)
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.image_rounded,
                                    size: 16,
                                    color: Color(0xFF7C3AED),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Image Preview (${fileName ?? 'Direct Image'})',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF7C3AED),
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
                                    contentUrl,
                                    fit: BoxFit.contain,
                                    loadingBuilder: (ctx, child, progress) {
                                      if (progress == null) return child;
                                      return Container(
                                        color: Colors.grey.shade200,
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder: (_, _, _) => Container(
                                      color: Colors.grey.shade200,
                                      padding: const EdgeInsets.all(12),
                                      child: const Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.broken_image_rounded,
                                              color: Colors.grey,
                                              size: 28,
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'Image preview will display once link is reachable',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]
                      // 5. Generic File Preview
                      else if (_type == 'file' && contentUrl.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB)
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFF2563EB)
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2563EB),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.attach_file_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'File Attachment Linked',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF2563EB),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      fileName ?? contentUrl,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]
                      // Informational Guide Banner
                      else ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _getInfoTextForType(_type),
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),
                    ],
                  ),
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
                          backgroundColor: typeColor,
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
                            : Text(
                                isEditing ? 'Save Changes' : 'Add to Module',
                              ),
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

  Widget _buildTypeChip(String typeKey, String label, IconData icon) {
    final isSelected = _type == typeKey;
    final color = _getTypeColor(typeKey);

    return InkWell(
      onTap: () {
        setState(() => _type = typeKey);
        _updatePreview();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: isSelected ? Colors.white : color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTitleHintForType(String type) {
    switch (type) {
      case 'video':
        return 'e.g. Ultrasound-Guided Vascular Access & Interpretation';
      case 'pdf':
        return 'e.g. Advanced Cardiac Life Support (ACLS) Reference Protocol';
      case 'image':
        return 'e.g. 12-Lead ECG STEMI Criteria & Localization Diagram';
      case 'file':
        return 'e.g. Ventilator Management Worksheet & Dataset';
      case 'reading':
        return 'e.g. Trauma Resuscitation Protocol - 2026 Guidelines';
      case 'quiz':
        return 'e.g. Rapid Sequence Intubation Checkpoint Assessment';
      case 'assignment':
        return 'e.g. Cricothyroidotomy Simulation Case Report';
      default:
        return 'e.g. Clinical Curriculum Material';
    }
  }

  String _getUrlLabelForType(String type) {
    switch (type) {
      case 'video':
        return 'Video URL (YouTube or Direct Video Stream) *';
      case 'pdf':
        return 'PDF Document URL / Supabase Link *';
      case 'image':
        return 'Image URL (PNG, JPG, WebP, SVG) *';
      case 'file':
        return 'File URL / Download Link (ZIP, DOC, Any) *';
      case 'reading':
        return 'Reading URL / Clinical Article Link';
      case 'quiz':
        return 'Quiz URL / Assessment Link';
      case 'assignment':
        return 'Assignment URL / Resource Link';
      default:
        return 'Content URL / Resource Link *';
    }
  }

  String _getUrlHintForType(String type) {
    switch (type) {
      case 'video':
        return 'https://www.youtube.com/watch?... or https://domain.com/video.mp4';
      case 'pdf':
        return 'https://domain.com/handbook.pdf or storage link';
      case 'image':
        return 'https://domain.com/diagram.png or clinical image URL';
      case 'file':
        return 'https://domain.com/attachment.zip or document link';
      default:
        return 'https://...';
    }
  }

  String _getInfoTextForType(String type) {
    switch (type) {
      case 'video':
        return 'Paste a YouTube video link (watch, youtu.be, shorts) or direct MP4 stream URL. Thumbnails are automatically retrieved.';
      case 'pdf':
        return 'Paste any public PDF URL or Supabase storage document link. Trainees can view or download the PDF.';
      case 'image':
        return 'Paste any image URL (PNG, JPG, WebP, SVG). Real-time image previews and zoom are supported.';
      case 'file':
        return 'Paste any downloadable file attachment URL (ZIP, DOCX, PPTX, XLSX, etc.).';
      case 'reading':
        return 'Enter a link to a clinical guide, journal article, or reading reference.';
      case 'quiz':
        return 'Enter an assessment or interactive quiz URL.';
      case 'assignment':
        return 'Enter a practical clinical assignment or case submission resource URL.';
      default:
        return 'Paste any valid content URL.';
    }
  }
}
