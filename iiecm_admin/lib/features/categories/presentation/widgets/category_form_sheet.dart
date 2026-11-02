import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/models/course_category.dart';

class CategoryFormSheet extends StatefulWidget {
  final CourseCategory? initialCategory;
  final List<CourseCategory>? existingCategories;
  final Future<dynamic> Function({
    required String name,
    required String description,
    required String color,
    String? iconName,
    bool isActive,
  }) onSave;

  const CategoryFormSheet({
    super.key,
    this.initialCategory,
    this.existingCategories,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    CourseCategory? initialCategory,
    List<CourseCategory>? existingCategories,
    required Future<dynamic> Function({
      required String name,
      required String description,
      required String color,
      String? iconName,
      bool isActive,
    }) onSave,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CategoryFormSheet(
        initialCategory: initialCategory,
        existingCategories: existingCategories,
        onSave: onSave,
      ),
    );
  }

  @override
  State<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late String _selectedColor;
  late String _selectedIcon;
  late bool _isActive;
  bool _isSaving = false;
  String? _errorMessage;

  static const List<String> _colorPresets = [
    '#245B43', // Forest Green (Primary)
    '#C87552', // Terracotta (Accent)
    '#1A4331', // Dark Forest
    '#1E3A8A', // Deep Navy
    '#0F766E', // Institutional Teal
    '#D97706', // Saffron Amber
    '#991B1B', // Crimson
    '#4338CA', // Indigo
  ];

  static const List<(String name, IconData icon)> _iconPresets = [
    ('category', Icons.category_rounded),
    ('medical', Icons.medical_services_rounded),
    ('school', Icons.school_rounded),
    ('emergency', Icons.emergency_rounded),
    ('science', Icons.science_rounded),
    ('psychology', Icons.psychology_rounded),
    ('analytics', Icons.analytics_rounded),
    ('terminal', Icons.terminal_rounded),
    ('biotech', Icons.biotech_rounded),
    ('health', Icons.health_and_safety_rounded),
  ];

  @override
  void initState() {
    super.initState();
    final cat = widget.initialCategory;
    _nameController = TextEditingController(text: cat?.name ?? '');
    _descController = TextEditingController(text: cat?.description ?? '');
    _selectedColor = cat?.color ?? _colorPresets.first;
    _selectedIcon = cat?.iconName ?? _iconPresets.first.$1;
    _isActive = cat?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Color _parseHex(String hex) {
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return AppColors.primaryForest;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final trimmedName = _nameController.text.trim();
    final lowerName = trimmedName.toLowerCase();

    // Prevent duplicate names belonging to OTHER categories
    final isDuplicate = widget.existingCategories?.any((c) {
      if (widget.initialCategory != null && c.id == widget.initialCategory!.id) {
        return false; // Not a duplicate if it belongs to the current category being edited
      }
      return c.name.trim().toLowerCase() == lowerName;
    }) ?? false;

    if (isDuplicate) {
      setState(() {
        _errorMessage = 'A category named "$trimmedName" already exists. Please choose a unique name.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final result = await widget.onSave(
        name: trimmedName,
        description: _descController.text.trim(),
        color: _selectedColor,
        iconName: _selectedIcon,
        isActive: _isActive,
      );

      if (mounted) {
        setState(() => _isSaving = false);
        if (result == true || result == null) {
          Navigator.of(context).pop();
        } else if (result is String) {
          setState(() {
            _errorMessage = result;
          });
        } else {
          setState(() {
            _errorMessage = 'Failed to save category. Ensure name is unique.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEdit = widget.initialCategory != null;
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final screenHeight = mediaQuery.size.height;
    final safeTop = mediaQuery.padding.top;
    final effectiveHeight = (screenHeight - safeTop - bottomInset) * 0.90;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: effectiveHeight > 200 ? effectiveHeight : 200,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _parseHex(_selectedColor).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.category_rounded,
                        color: _parseHex(_selectedColor),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isEdit ? 'Edit Category' : 'Create Course Category',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Form Body
              Flexible(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.error),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: AppColors.error, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Name
                    Text(
                      'Category Name *',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Critical Care Medicine',
                        prefixIcon: Icon(Icons.label_outline_rounded),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Please enter category name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description
                    Text(
                      'Description *',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _descController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Curriculum scope, focus area, and clinical learning aims...',
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 40),
                          child: Icon(Icons.description_outlined),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Please enter category description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // Color Selection
                    Text(
                      'Institutional Brand Color',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _colorPresets.map((hex) {
                        final isSelected = _selectedColor.toLowerCase() == hex.toLowerCase();
                        final color = _parseHex(hex);
                        return GestureDetector(
                          onTap: () => setState(() => _selectedColor = hex),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.black87 : Colors.transparent,
                                width: 2.5,
                              ),
                              boxShadow: [
                                if (isSelected)
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                              ],
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 20)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // Icon Selection
                    Text(
                      'Curriculum Icon',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _iconPresets.map((item) {
                        final isSelected = _selectedIcon == item.$1;
                        final color = _parseHex(_selectedColor);
                        return ChoiceChip(
                          avatar: Icon(
                            item.$2,
                            size: 16,
                            color: isSelected ? Colors.white : color,
                          ),
                          label: Text(item.$1),
                          selected: isSelected,
                          selectedColor: color,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          onSelected: (_) => setState(() => _selectedIcon = item.$1),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // Active Toggle
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBackground : AppColors.warmCream.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.borderNeutral,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Active Status',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  _isActive
                                      ? 'Available for new courses and enrollments'
                                      : 'Deactivated from new student admissions',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: _isActive,
                            activeThumbColor: AppColors.primaryForest,
                            onChanged: (val) => setState(() => _isActive = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          // Sticky Bottom Action Bar
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              color: isDark ? AppColors.darkSurface : Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _isSaving ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryForest,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(isEdit ? 'Save Changes' : 'Create Category'),
                    ),
                  ),
                ],
              ),
            ),
          ),
            ],
          ),
        ),
      ),
    );
  }
}
