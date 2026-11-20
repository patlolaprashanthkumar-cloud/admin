import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/models/course_module.dart';
import '../providers/courses_provider.dart';

/// Modal bottom sheet for creating and updating course curriculum modules
///
/// Implements the IIECM Modern Academic design language with structured sections,
/// clear academic typography, polished inputs, and full keyboard responsiveness.
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
      text: m != null
          ? m.orderIndex.toString()
          : widget.nextOrderIndex.toString(),
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
        description: _descController.text.trim().isNotEmpty
            ? _descController.text.trim()
            : null,
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
          content: Text(
            isEditing ? 'Module updated' : 'Module added to curriculum',
          ),
          backgroundColor: AppColors.primaryNavy,
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

  InputDecoration _inputDecoration({
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    required bool isDark,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
      ),
      hintText: hintText,
      hintStyle: TextStyle(
        fontSize: 12.5,
        color: isDark ? AppColors.darkTextSecondary : AppColors.textMuted,
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: isDark ? AppColors.accentOrangeLight : AppColors.primaryNavy,
        size: 19,
      ),
      filled: true,
      fillColor: isDark
          ? AppColors.darkSurfaceContainerLow
          : AppColors.surfaceWarmWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.borderNeutral,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.borderNeutral,
        ),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        borderSide: BorderSide(color: AppColors.primaryNavy, width: 1.5),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        borderSide: BorderSide(color: AppColors.error, width: 1.2),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        borderSide: BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceContainerLow
                  : AppColors.forestSoft,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: AppColors.primaryNavy.withValues(alpha: 0.12),
              ),
            ),
            child: Icon(icon, size: 15, color: AppColors.primaryNavy),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final availableHeight = mediaQuery.size.height - mediaQuery.padding.top;
    final maxSheetHeight = availableHeight - bottomInset;
    final effectiveHeight = maxSheetHeight * 0.75;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: effectiveHeight.clamp(
          280.0,
          maxSheetHeight > 280.0 ? maxSheetHeight : availableHeight,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.cardWhite,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppConstants.radiusLarge),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
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
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Sheet Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceContainerLow
                          : AppColors.forestSoft,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryNavy.withValues(alpha: 0.15),
                        width: 1.2,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.create_new_folder_rounded,
                        color: AppColors.primaryNavy,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing
                              ? 'Edit Curriculum Module'
                              : 'Add Curriculum Module',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          isEditing
                              ? 'Modify syllabus unit and sequencing'
                              : 'Define syllabus module and sequencing order',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),

            Divider(
              height: 1,
              color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
            ),

            // Form Body
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  children: [
                    _buildSectionHeader(
                      icon: Icons.layers_outlined,
                      title: 'Module Specifications',
                      subtitle: 'Curriculum unit details and display sequence',
                      isDark: isDark,
                    ),

                    // Module Title
                    TextFormField(
                      controller: _titleController,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                      decoration: _inputDecoration(
                        labelText: 'Module Title *',
                        hintText: 'e.g. Module 1: Hemodynamic Monitoring & Resuscitation',
                        prefixIcon: Icons.title_rounded,
                        isDark: isDark,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter module title'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Display Order
                    TextFormField(
                      controller: _orderController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                      decoration: _inputDecoration(
                        labelText: 'Display Order *',
                        hintText: '1',
                        prefixIcon: Icons.format_list_numbered_rounded,
                        isDark: isDark,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Required';
                        }
                        if (int.tryParse(v) == null) {
                          return 'Must be a valid integer';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Module Summary
                    TextFormField(
                      controller: _descController,
                      maxLines: 3,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                      decoration: _inputDecoration(
                        labelText: 'Module Summary (Optional)',
                        hintText: 'Outline key clinical competencies or syllabus learning outcomes...',
                        prefixIcon: Icons.notes_rounded,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Sticky Bottom Actions
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.cardWhite,
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.borderSubtle,
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
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.borderNeutral,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryNavy,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                isEditing ? 'Save Changes' : 'Create Module',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
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
}
