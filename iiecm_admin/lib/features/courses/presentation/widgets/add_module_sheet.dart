import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/models/course_module.dart';
import '../providers/courses_provider.dart';

class AddModuleSheet extends ConsumerStatefulWidget {
  final String courseId;
  final CourseModule? existingModule;
  final int nextOrderIndex;

  const AddModuleSheet({
    super.key,
    required this.courseId,
    this.existingModule,
    this.nextOrderIndex = 1,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String courseId,
    CourseModule? existingModule,
    int nextOrderIndex = 1,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddModuleSheet(
        courseId: courseId,
        existingModule: existingModule,
        nextOrderIndex: nextOrderIndex,
      ),
    );
  }

  @override
  ConsumerState<AddModuleSheet> createState() => _AddModuleSheetState();
}

class _AddModuleSheetState extends ConsumerState<AddModuleSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _orderController;
  bool _isSubmitting = false;

  bool get isEditing => widget.existingModule != null;

  @override
  void initState() {
    super.initState();
    final m = widget.existingModule;
    _titleController = TextEditingController(text: m?.title ?? '');
    _descController = TextEditingController(text: m?.description ?? '');
    _orderController = TextEditingController(
      text: m != null ? m.orderIndex.toString() : widget.nextOrderIndex.toString(),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(courseRepositoryProvider);
      final order = int.tryParse(_orderController.text.trim()) ?? 1;

      final module = CourseModule(
        id: widget.existingModule?.id ?? '',
        courseId: widget.courseId,
        title: _titleController.text.trim(),
        description: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
        orderIndex: order,
        createdAt: widget.existingModule?.createdAt ?? DateTime.now(),
      );

      if (isEditing) {
        await repo.updateModule(module);
      } else {
        await repo.createModule(module);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Module updated' : 'Module added to curriculum'),
          backgroundColor: AppColors.primaryForest,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
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
    final effectiveHeight = (availableHeight - bottomInset) * 0.70;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: effectiveHeight.clamp(280.0, availableHeight),
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
                    child: const Icon(Icons.folder_outlined, color: AppColors.primaryForest, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEditing ? 'Edit Curriculum Module' : 'Add Curriculum Module',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
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

            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Module Title *',
                        hintText: 'e.g. Module 1: Hemodynamic Monitoring',
                        prefixIcon: Icon(Icons.title_rounded),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter title' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Module Summary (Optional)',
                        hintText: 'Overview of learning outcomes in this module...',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _orderController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Display Order *',
                        hintText: '1',
                        prefixIcon: Icon(Icons.format_list_numbered_rounded),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (int.tryParse(v) == null) return 'Must be a valid integer';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),

            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.surface,
                  border: Border(
                    top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.divider),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
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
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(isEditing ? 'Save Changes' : 'Create Module'),
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

