import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../categories/domain/models/course_category.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../domain/models/course.dart';

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
  }) onSave;

  const CourseFormSheet({
    super.key,
    this.initialCourse,
    required this.onSave,
  });

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
    }) onSave,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CourseFormSheet(
        initialCourse: initialCourse,
        onSave: onSave,
      ),
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
    _durationController = TextEditingController(text: '${c?.durationWeeks ?? 8}');
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
      final cats = await catRepo.getCategories(onlyActive: widget.initialCourse == null);

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
          setState(() => _errorMessage = 'Failed to save course. Check requirements.');
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.forestSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.menu_book_rounded, color: AppColors.primaryForest, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isEdit ? 'Edit Curriculum Course' : 'Create New Course',
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

              // Content
              _isLoadingLookups
                  ? const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.primaryForest),
                      ),
                    )
                  : Flexible(
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
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: AppColors.error, fontSize: 12),
                              ),
                            ),

                          // Title
                          Text('Course Title *', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              hintText: 'e.g. Advanced Emergency Resuscitation',
                              prefixIcon: Icon(Icons.school_outlined),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Enter course title' : null,
                          ),
                          const SizedBox(height: 16),

                          // Description
                          Text('Course Description *', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _descController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              hintText: 'Syllabus breakdown and clinical training aims...',
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Enter course description' : null,
                          ),
                          const SizedBox(height: 16),

                          // Category Picker (Loaded dynamically from Supabase)
                          Text('Course Category *', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: _selectedCategoryId,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.category_outlined),
                              hintText: 'Select active category stream',
                            ),
                            items: _categories.map((cat) {
                              return DropdownMenuItem<String>(
                                value: cat.id,
                                child: Text(cat.name, overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (id) {
                              final match = _categories.firstWhere((c) => c.id == id);
                              setState(() {
                                _selectedCategoryId = id;
                                _selectedCategoryName = match.name;
                              });
                            },
                            validator: (v) => v == null ? 'Please select a category' : null,
                          ),
                          const SizedBox(height: 16),

                          // Lead Instructor (Loaded dynamically from Supabase)
                          Text('Assigned Faculty Lead (Optional)', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String?>(
                            isExpanded: true,
                            initialValue: _selectedInstructorId,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.person_pin_outlined),
                              hintText: 'Unassigned',
                            ),
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
                            onChanged: (id) => setState(() => _selectedInstructorId = id),
                          ),
                          const SizedBox(height: 16),

                          // Duration & Fee in Row
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Duration (Weeks)', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _durationController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(prefixIcon: Icon(Icons.schedule_rounded)),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Tuition Fee (₹)', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _feeController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(prefixIcon: Icon(Icons.currency_rupee_rounded)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Format & Status in Row
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Format', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 6),
                                    DropdownButtonFormField<String>(
                                      isExpanded: true,
                                      initialValue: _selectedFormat,
                                      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
                                      items: const [
                                        DropdownMenuItem(value: 'hybrid', child: Text('Hybrid')),
                                        DropdownMenuItem(value: 'live', child: Text('Live Virtual')),
                                        DropdownMenuItem(value: 'recorded', child: Text('Self-Paced')),
                                      ],
                                      onChanged: (val) => setState(() => _selectedFormat = val ?? 'hybrid'),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Publication Status', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 6),
                                    DropdownButtonFormField<String>(
                                      isExpanded: true,
                                      initialValue: _selectedStatus,
                                      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
                                      items: const [
                                        DropdownMenuItem(value: 'draft', child: Text('Draft')),
                                        DropdownMenuItem(value: 'published', child: Text('Published')),
                                        DropdownMenuItem(value: 'archived', child: Text('Archived')),
                                      ],
                                      onChanged: (val) => setState(() => _selectedStatus = val ?? 'draft'),
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
                          style: FilledButton.styleFrom(backgroundColor: AppColors.primaryForest),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(isEdit ? 'Save Changes' : 'Create Course'),
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
