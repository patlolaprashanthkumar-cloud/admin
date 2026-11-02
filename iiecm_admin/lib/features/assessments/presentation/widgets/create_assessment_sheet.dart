import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/date_formatter.dart';
import '../domain/models/assessment.dart';
import '../providers/assessment_provider.dart';

class CreateAssessmentSheet extends ConsumerStatefulWidget {
  final Assessment? existingAssessment;

  const CreateAssessmentSheet({super.key, this.existingAssessment});

  static Future<bool?> show(BuildContext context, {Assessment? existingAssessment}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CreateAssessmentSheet(existingAssessment: existingAssessment),
    );
  }

  @override
  ConsumerState<CreateAssessmentSheet> createState() => _CreateAssessmentSheetState();
}

class _CreateAssessmentSheetState extends ConsumerState<CreateAssessmentSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _totalMarksController;
  late TextEditingController _passingMarksController;
  late TextEditingController _durationController;

  late String _type;
  late String _status;
  DateTime _scheduledDate = DateTime.now().add(const Duration(days: 3));
  TimeOfDay _scheduledTime = const TimeOfDay(hour: 10, minute: 0);

  bool _isSubmitting = false;

  bool get isEditing => widget.existingAssessment != null;

  @override
  void initState() {
    super.initState();
    final a = widget.existingAssessment;
    _titleController = TextEditingController(text: a?.title ?? '');
    _descController = TextEditingController(text: a?.description ?? '');
    _totalMarksController = TextEditingController(text: a != null ? a.totalMarks.toString() : '100');
    _passingMarksController = TextEditingController(text: a != null ? a.passingMarks.toString() : '40');
    _durationController = TextEditingController(text: a != null ? a.durationMinutes.toString() : '60');
    _type = a?.type ?? 'mcq';
    _status = a?.status ?? 'active';

    if (a?.scheduledAt != null) {
      _scheduledDate = a!.scheduledAt!;
      _scheduledTime = TimeOfDay(hour: a.scheduledAt!.hour, minute: a.scheduledAt!.minute);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _totalMarksController.dispose();
    _passingMarksController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  DateTime get _combinedDateTime {
    return DateTime(
      _scheduledDate.year,
      _scheduledDate.month,
      _scheduledDate.day,
      _scheduledTime.hour,
      _scheduledTime.minute,
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final total = int.tryParse(_totalMarksController.text.trim()) ?? 100;
    final passing = int.tryParse(_passingMarksController.text.trim()) ?? 40;
    final duration = int.tryParse(_durationController.text.trim()) ?? 60;

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
      final notifier = ref.read(assessmentNotifierProvider.notifier);
      final assessmentData = Assessment(
        id: widget.existingAssessment?.id ?? '',
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        type: _type,
        totalMarks: total,
        passingMarks: passing,
        durationMinutes: duration,
        status: _status,
        scheduledAt: _combinedDateTime,
        createdAt: widget.existingAssessment?.createdAt ?? DateTime.now(),
      );

      bool success;
      if (isEditing) {
        success = await notifier.updateAssessment(assessmentData);
      } else {
        success = await notifier.createAssessment(assessmentData);
      }

      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing ? 'Assessment updated successfully' : 'Assessment created successfully',
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
    final effectiveHeight = (availableHeight - bottomInset) * 0.85;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: effectiveHeight.clamp(320.0, availableHeight),
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
                      Icons.quiz_outlined,
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
                          isEditing ? 'Edit Assessment / Exam' : 'Create New Assessment',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          isEditing
                              ? 'Modify exam duration, passing score, or exam schedule'
                              : 'Set evaluation criteria, timer, and question structure',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  children: [
                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Assessment Title *',
                        hintText: 'e.g. Critical Care Mid-Term Certification Exam',
                        prefixIcon: Icon(Icons.title_rounded),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter title' : null,
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description / Instructions',
                        hintText: 'Exam guidelines, negative marking rules, syllabus covered...',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Type & Status
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _type,
                            decoration: const InputDecoration(
                              labelText: 'Type',
                              prefixIcon: Icon(Icons.category_outlined),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'mcq', child: Text('MCQ Exam')),
                              DropdownMenuItem(value: 'quiz', child: Text('Modular Quiz')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _type = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _status,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              prefixIcon: Icon(Icons.toggle_on_outlined),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'active', child: Text('Active')),
                              DropdownMenuItem(value: 'scheduled', child: Text('Scheduled')),
                              DropdownMenuItem(value: 'draft', child: Text('Draft')),
                              DropdownMenuItem(value: 'completed', child: Text('Completed')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _status = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Total Marks, Passing Marks, Duration
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
                              if (v == null || v.trim().isEmpty) return 'Required';
                              if (int.tryParse(v) == null) return 'Must be a number';
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
                              labelText: 'Pass Marks *',
                              prefixIcon: Icon(Icons.check_circle_outline),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              if (int.tryParse(v) == null) return 'Must be a number';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _durationController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Time (Mins) *',
                              prefixIcon: Icon(Icons.timer_outlined),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              if (int.tryParse(v) == null) return 'Must be a number';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Exam Date & Time
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _scheduledDate,
                                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) setState(() => _scheduledDate = picked);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Exam Date',
                                prefixIcon: Icon(Icons.calendar_today_rounded),
                              ),
                              child: Text(
                                DateFormatter.formatDate(_scheduledDate),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
                                initialTime: _scheduledTime,
                              );
                              if (picked != null) setState(() => _scheduledTime = picked);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Start Time',
                                prefixIcon: Icon(Icons.access_time_rounded),
                              ),
                              child: Text(
                                _scheduledTime.format(context),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                      ],
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
                            : Text(isEditing ? 'Save Changes' : 'Create Assessment'),
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

