import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../courses/presentation/providers/courses_provider.dart';
import '../../domain/models/assignment.dart';
import '../providers/assignment_provider.dart';

class CreateAssignmentSheet extends ConsumerStatefulWidget {
  final Assignment? existingAssignment;

  const CreateAssignmentSheet({super.key, this.existingAssignment});

  static Future<bool?> show(
    BuildContext context, {
    Assignment? existingAssignment,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          CreateAssignmentSheet(existingAssignment: existingAssignment),
    );
  }

  @override
  ConsumerState<CreateAssignmentSheet> createState() =>
      _CreateAssignmentSheetState();
}

class _CreateAssignmentSheetState extends ConsumerState<CreateAssignmentSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _totalMarksController;
  late TextEditingController _passingMarksController;

  late String _type;
  late String _status;
  DateTime _deadline = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _deadlineTime = const TimeOfDay(hour: 23, minute: 59);

  final Set<String> _selectedCourseIds = {};
  bool _isSubmitting = false;

  bool get isEditing => widget.existingAssignment != null;

  @override
  void initState() {
    super.initState();
    final a = widget.existingAssignment;
    _titleController = TextEditingController(text: a?.title ?? '');
    _descriptionController = TextEditingController(text: a?.description ?? '');
    _totalMarksController = TextEditingController(
      text: a != null ? a.totalMarks.toString() : '100',
    );
    _passingMarksController = TextEditingController(
      text: a != null ? a.passingMarks.toString() : '40',
    );
    _type = a?.type ?? 'assignment';
    _status = a?.status ?? 'active';

    if (a != null) {
      if (a.deadline != null) {
        _deadline = a.deadline!;
        _deadlineTime = TimeOfDay(
          hour: a.deadline!.hour,
          minute: a.deadline!.minute,
        );
      }
      _selectedCourseIds.addAll(a.assignedCourses.map((c) => c.id));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _totalMarksController.dispose();
    _passingMarksController.dispose();
    super.dispose();
  }

  DateTime get _combinedDeadline {
    return DateTime(
      _deadline.year,
      _deadline.month,
      _deadline.day,
      _deadlineTime.hour,
      _deadlineTime.minute,
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCourseIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select at least one course for this assignment.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final total = int.tryParse(_totalMarksController.text.trim()) ?? 100;
    final passing = int.tryParse(_passingMarksController.text.trim()) ?? 40;
    if (passing > total) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passing marks cannot exceed total marks.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final notifier = ref.read(assignmentNotifierProvider.notifier);
      final assignmentData = Assignment(
        id: widget.existingAssignment?.id ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _type,
        totalMarks: total,
        passingMarks: passing,
        status: _status,
        deadline: _combinedDeadline,
        createdAt: widget.existingAssignment?.createdAt ?? DateTime.now(),
      );

      bool success;
      if (isEditing) {
        success = await notifier.updateAssignment(
          assignmentData,
          courseIds: _selectedCourseIds.toList(),
        );
      } else {
        success = await notifier.createAssignment(
          assignmentData,
          courseIds: _selectedCourseIds.toList(),
        );
      }

      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Assignment updated successfully'
                  : 'Assignment published successfully',
            ),
            backgroundColor: AppColors.primaryForest,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(notifier.errorMessage ?? 'Operation failed'),
            backgroundColor: AppColors.error,
          ),
        );
      }
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
    final effectiveHeight = maxSheetHeight * 0.90;

    final coursesState = ref.watch(coursesNotifierProvider);

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
                      Icons.assignment_outlined,
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
                          isEditing
                              ? 'Edit Assignment / Project'
                              : 'Create New Assignment',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          isEditing
                              ? 'Modify instructions, deadline, or course allocations'
                              : 'Set evaluation criteria, submission deadlines & target courses',
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
                        labelText: 'Assignment Title *',
                        hintText: 'e.g. Case Study: Acute Coronary Syndrome Protocols',
                        prefixIcon: Icon(Icons.title_rounded),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter title'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Instructions / Prompt *',
                        hintText: 'Detailed requirements, case background, and submission deliverables...',
                        alignLabelWithHint: true,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter instructions'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Type & Status
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _type,
                            decoration: const InputDecoration(
                              labelText: 'Type',
                              prefixIcon: Icon(Icons.category_outlined),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'assignment',
                                child: Text('Assignment'),
                              ),
                              DropdownMenuItem(
                                value: 'project',
                                child: Text('Clinical Project'),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _type = val);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _status,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              prefixIcon: Icon(Icons.toggle_on_outlined),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'active',
                                child: Text('Active'),
                              ),
                              DropdownMenuItem(
                                value: 'scheduled',
                                child: Text('Scheduled'),
                              ),
                              DropdownMenuItem(
                                value: 'draft',
                                child: Text('Draft'),
                              ),
                              DropdownMenuItem(
                                value: 'completed',
                                child: Text('Completed'),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _status = val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Total Marks & Passing Marks
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _totalMarksController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Total Marks *',
                              prefixIcon: Icon(Icons.grade_outlined),
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _passingMarksController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Passing Marks *',
                              prefixIcon: Icon(
                                Icons.check_circle_outline_rounded,
                              ),
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

                    // Submission Deadline Pickers
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _deadline,
                                firstDate: DateTime.now().subtract(
                                  const Duration(days: 30),
                                ),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );
                              if (picked != null) {
                                setState(() => _deadline = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Due Date *',
                                prefixIcon: Icon(Icons.calendar_today_rounded),
                              ),
                              child: Text(
                                DateFormatter.formatDate(_deadline),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: _deadlineTime,
                              );
                              if (picked != null) {
                                setState(() => _deadlineTime = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Due Time *',
                                prefixIcon: Icon(Icons.access_time_rounded),
                              ),
                              child: Text(
                                _deadlineTime.format(context),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Allocate to Courses
                    Text(
                      'Target Courses (Cohort Allocation)',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select courses where enrolled candidates will receive this assignment.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (coursesState.courses.isEmpty)
                      const Text(
                        'No courses available.',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.divider,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusMedium,
                          ),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: coursesState.courses.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final course = coursesState.courses[index];
                            final isAllocated = _selectedCourseIds.contains(
                              course.id,
                            );
                            return CheckboxListTile(
                              dense: true,
                              title: Text(
                                course.title,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '${course.categoryName} • ${course.enrolledCount} enrolled candidates',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textSecondary,
                                ),
                              ),
                              value: isAllocated,
                              activeColor: AppColors.primaryForest,
                              onChanged: (checked) {
                                setState(() {
                                  if (checked == true) {
                                    _selectedCourseIds.add(course.id);
                                  } else {
                                    _selectedCourseIds.remove(course.id);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),

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
                            : Text(
                                isEditing
                                    ? 'Save Changes'
                                    : 'Publish Assignment',
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
