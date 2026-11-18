import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../categories/domain/models/course_category.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../domain/models/course.dart';

/// Modal bottom sheet for creating and updating curricula courses
///
/// Organized into distinct institutional sections (Basic Information,
/// Academic Metadata, and Tuition & Delivery Format) matching the
/// IIECM LEARNING HUB Modern Academic design system.
class CourseFormSheet extends ConsumerStatefulWidget {
  final Course? initialCourse;
  final Future<dynamic> Function({
    required String title,
    required String description,
    required String categoryId,
    required String categoryName,
    String? instructorId,
    int durationWeeks,
    double fee,
    String format,
    String status,
  })
  onSave;

  const CourseFormSheet({super.key, this.initialCourse, required this.onSave});

  static Future<void> show(
    BuildContext context, {
    Course? initialCourse,
    required Future<dynamic> Function({
      required String title,
      required String description,
      required String categoryId,
      required String categoryName,
      String? instructorId,
      int durationWeeks,
      double fee,
      String format,
      String status,
    })
    onSave,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          CourseFormSheet(initialCourse: initialCourse, onSave: onSave),
    );
  }

  @override
  ConsumerState<CourseFormSheet> createState() => _CourseFormSheetState();
}

class _CourseFormSheetState extends ConsumerState<CourseFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _durationController;
  late TextEditingController _feeController;

  String? _selectedCategoryId;
  String? _selectedCategoryName;
  String? _selectedInstructorId;
  String _selectedFormat = 'hybrid';
  String _selectedStatus = 'draft';

  List<CourseCategory> _categories = [];
  List<Map<String, dynamic>> _instructors = [];
  bool _isLoadingLookups = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final c = widget.initialCourse;
    _titleController = TextEditingController(text: c?.title ?? '');
    _descController = TextEditingController(text: c?.description ?? '');
    _durationController = TextEditingController(
      text: '${c?.durationWeeks ?? 8}',
    );
    _feeController = TextEditingController(text: '${c?.fee.toInt() ?? 4999}');
    _selectedCategoryId = c?.categoryId;
    _selectedCategoryName = c?.categoryName;
    _selectedInstructorId = c?.instructorId;
    _selectedFormat = c?.format ?? 'hybrid';
    _selectedStatus = c?.status ?? 'draft';

    _loadLookups();
  }

  Future<void> _loadLookups() async {
    try {
      final catRepo = ref.read(categoryRepositoryProvider);
      // If editing an existing course, include inactive categories so the current selection is valid
      final cats = await catRepo.getCategories(
        onlyActive: widget.initialCourse == null,
      );

      // Load instructors from Supabase safely
      List<Map<String, dynamic>> insList = [];
      try {
        final client = AppSupabase.client;
        final insRows = await client
            .from('instructors')
            .select('id, full_name, specialization')
            .eq('account_status', 'active');
        insList = List<Map<String, dynamic>>.from(insRows);
      } catch (_) {}

      if (mounted) {
        setState(() {
          _categories = cats;
          _instructors = insList;
          _isLoadingLookups = false;

          // If no category selected yet, default to first category
          if (_selectedCategoryId == null && _categories.isNotEmpty) {
            _selectedCategoryId = _categories.first.id;
            _selectedCategoryName = _categories.first.name;
          } else if (_selectedCategoryId != null &&
              !_categories.any((c) => c.id == _selectedCategoryId)) {
            // If the selected category is not in list, keep name or fall back to first
            if (_categories.isNotEmpty) {
              _selectedCategoryId = _categories.first.id;
              _selectedCategoryName = _categories.first.name;
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingLookups = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _durationController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      setState(() => _errorMessage = 'Please select a course category');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final result = await widget.onSave(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        categoryId: _selectedCategoryId!,
        categoryName: _selectedCategoryName ?? 'General',
        instructorId: _selectedInstructorId,
        durationWeeks: int.tryParse(_durationController.text) ?? 8,
        fee: double.tryParse(_feeController.text) ?? 0.0,
        format: _selectedFormat,
        status: _selectedStatus,
      );

      if (mounted) {
        setState(() => _isSaving = false);
        if (result == true || result == null) {
          Navigator.of(context).pop();
        } else if (result is String) {
          setState(() => _errorMessage = result);
        } else {
          setState(
            () => _errorMessage = 'Failed to save course. Check requirements.',
          );
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

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    required bool isDark,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        fontSize: 13,
        color: isDark ? AppColors.darkTextSecondary : AppColors.textMuted,
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: isDark ? AppColors.accentOrangeLight : AppColors.primaryNavy,
        size: 18,
      ),
      filled: true,
      fillColor: isDark ? AppColors.darkBackground : AppColors.surfaceWarmWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primaryNavy, width: 1.5),
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
      padding: const EdgeInsets.only(bottom: 12),
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
          const SizedBox(width: 8),
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
    final isEdit = widget.initialCourse != null;
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final screenHeight = mediaQuery.size.height;
    final safeTop = mediaQuery.padding.top;
    final effectiveHeight = (screenHeight - safeTop - bottomInset) * 0.90;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: effectiveHeight > 240 ? effectiveHeight : 240,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.cardWhite,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
              blurRadius: 18,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkBorder
                        : Colors.grey.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // Header Row
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 16, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceContainerLow
                            : AppColors.forestSoft,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.primaryNavy.withValues(alpha: 0.12),
                        ),
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: AppColors.primaryNavy,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEdit
                                ? 'Edit Curriculum Course'
                                : 'Create New Course',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            isEdit
                                ? 'Update specifications and publishing parameters'
                                : 'Define academic program and cohort settings',
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
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: isDark ? AppColors.darkBorder : AppColors.borderNeutral,
              ),

              // Form Content Area
              _isLoadingLookups
                  ? const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryNavy,
                        ),
                      ),
                    )
                  : Flexible(
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Error Alert Banner
                              if (_errorMessage != null)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withValues(
                                      alpha: 0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.error.withValues(
                                        alpha: 0.35,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline_rounded,
                                        color: AppColors.error,
                                        size: 18,
                                      ),
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

                              // SECTION 1: Basic Information
                              _buildSectionHeader(
                                icon: Icons.info_outline_rounded,
                                title: 'Basic Information',
                                subtitle: 'Course title and curriculum syllabus summary',
                                isDark: isDark,
                              ),
                              Text(
                                'Course Title *',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _titleController,
                                decoration: _inputDecoration(
                                  hintText:
                                      'e.g. Advanced Emergency Resuscitation',
                                  prefixIcon: Icons.school_outlined,
                                  isDark: isDark,
                                ),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Enter course title'
                                    : null,
                              ),
                              const SizedBox(height: 14),

                              Text(
                                'Course Description *',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _descController,
                                maxLines: 3,
                                decoration: _inputDecoration(
                                  hintText: 'Syllabus breakdown and clinical training aims...',
                                  prefixIcon: Icons.description_outlined,
                                  isDark: isDark,
                                ),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Enter course description'
                                    : null,
                              ),
                              const SizedBox(height: 20),

                              // SECTION 2: Academic Metadata
                              _buildSectionHeader(
                                icon: Icons.account_balance_outlined,
                                title: 'Academic Metadata',
                                subtitle: 'Discipline category stream and supervising faculty lead',
                                isDark: isDark,
                              ),
                              Text(
                                'Course Category *',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                initialValue: _selectedCategoryId,
                                decoration: _inputDecoration(
                                  hintText: 'Select active category stream',
                                  prefixIcon: Icons.category_outlined,
                                  isDark: isDark,
                                ),
                                dropdownColor: isDark
                                    ? AppColors.darkSurface
                                    : AppColors.cardWhite,
                                items: _categories.map((cat) {
                                  return DropdownMenuItem<String>(
                                    value: cat.id,
                                    child: Text(
                                      cat.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (id) {
                                  final match = _categories.firstWhere(
                                    (c) => c.id == id,
                                  );
                                  setState(() {
                                    _selectedCategoryId = id;
                                    _selectedCategoryName = match.name;
                                  });
                                },
                                validator: (v) => v == null
                                    ? 'Please select a category'
                                    : null,
                              ),
                              const SizedBox(height: 14),

                              Text(
                                'Assigned Faculty Lead (Optional)',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String?>(
                                isExpanded: true,
                                initialValue: _selectedInstructorId,
                                decoration: _inputDecoration(
                                  hintText: 'Unassigned',
                                  prefixIcon: Icons.person_pin_outlined,
                                  isDark: isDark,
                                ),
                                dropdownColor: isDark
                                    ? AppColors.darkSurface
                                    : AppColors.cardWhite,
                                items: [
                                  const DropdownMenuItem<String?>(
                                    value: null,
                                    child: Text('No Instructor Assigned'),
                                  ),
                                  ..._instructors.map((ins) {
                                    return DropdownMenuItem<String?>(
                                      value: ins['id']?.toString(),
                                      child: Text(
                                        '${ins['full_name']} (${ins['specialization']})',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }),
                                ],
                                onChanged: (id) =>
                                    setState(() => _selectedInstructorId = id),
                              ),
                              const SizedBox(height: 20),

                              // SECTION 3: Tuition & Delivery Format
                              _buildSectionHeader(
                                icon: Icons.monetization_on_outlined,
                                title: 'Tuition & Delivery Format',
                                subtitle: 'Training timeline, tuition fee, and publication state',
                                isDark: isDark,
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Duration (Weeks)',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12.5,
                                                color: isDark
                                                    ? Colors.white
                                                    : AppColors.textPrimary,
                                              ),
                                        ),
                                        const SizedBox(height: 6),
                                        TextFormField(
                                          controller: _durationController,
                                          keyboardType: TextInputType.number,
                                          decoration: _inputDecoration(
                                            hintText: '8',
                                            prefixIcon: Icons.schedule_rounded,
                                            isDark: isDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Tuition Fee (₹)',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12.5,
                                                color: isDark
                                                    ? Colors.white
                                                    : AppColors.textPrimary,
                                              ),
                                        ),
                                        const SizedBox(height: 6),
                                        TextFormField(
                                          controller: _feeController,
                                          keyboardType: TextInputType.number,
                                          decoration: _inputDecoration(
                                            hintText: '4999',
                                            prefixIcon:
                                                Icons.currency_rupee_rounded,
                                            isDark: isDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Format',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12.5,
                                                color: isDark
                                                    ? Colors.white
                                                    : AppColors.textPrimary,
                                              ),
                                        ),
                                        const SizedBox(height: 6),
                                        DropdownButtonFormField<String>(
                                          isExpanded: true,
                                          initialValue: _selectedFormat,
                                          dropdownColor: isDark
                                              ? AppColors.darkSurface
                                              : AppColors.cardWhite,
                                          decoration: _inputDecoration(
                                            hintText: 'Select format',
                                            prefixIcon: Icons
                                                .video_camera_front_outlined,
                                            isDark: isDark,
                                          ),
                                          items: const [
                                            DropdownMenuItem(
                                              value: 'hybrid',
                                              child: Text('Hybrid'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'live',
                                              child: Text('Live Virtual'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'recorded',
                                              child: Text('Self-Paced'),
                                            ),
                                          ],
                                          onChanged: (val) => setState(
                                            () => _selectedFormat =
                                                val ?? 'hybrid',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Publication Status',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12.5,
                                                color: isDark
                                                    ? Colors.white
                                                    : AppColors.textPrimary,
                                              ),
                                        ),
                                        const SizedBox(height: 6),
                                        DropdownButtonFormField<String>(
                                          isExpanded: true,
                                          initialValue: _selectedStatus,
                                          dropdownColor: isDark
                                              ? AppColors.darkSurface
                                              : AppColors.cardWhite,
                                          decoration: _inputDecoration(
                                            hintText: 'Status',
                                            prefixIcon:
                                                Icons.visibility_outlined,
                                            isDark: isDark,
                                          ),
                                          items: const [
                                            DropdownMenuItem(
                                              value: 'draft',
                                              child: Text('Draft'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'published',
                                              child: Text('Published'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'archived',
                                              child: Text('Archived'),
                                            ),
                                          ],
                                          onChanged: (val) => setState(
                                            () => _selectedStatus =
                                                val ?? 'draft',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),
                    ),

              Divider(
                height: 1,
                color: isDark ? AppColors.darkBorder : AppColors.borderNeutral,
              ),

              // Sticky Bottom Action Bar
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  color: isDark ? AppColors.darkSurface : AppColors.cardWhite,
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving
                              ? null
                              : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            side: BorderSide(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.borderNeutral,
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: _isSaving ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryNavy,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
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
                              : Text(
                                  isEdit ? 'Save Changes' : 'Create Course',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
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
      ),
    );
  }
}
