import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../courses/presentation/providers/courses_provider.dart';
import '../../../faculty/presentation/providers/faculty_provider.dart';
import '../../domain/models/live_class.dart';
import '../providers/class_provider.dart';

class CreateClassSheet extends ConsumerStatefulWidget {
  final LiveClass? existingClass;

  const CreateClassSheet({super.key, this.existingClass});

  static Future<bool?> show(BuildContext context, {LiveClass? existingClass}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CreateClassSheet(existingClass: existingClass),
    );
  }

  @override
  ConsumerState<CreateClassSheet> createState() => _CreateClassSheetState();
}

class _CreateClassSheetState extends ConsumerState<CreateClassSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _meetingLinkController;
  late TextEditingController _durationController;

  String? _selectedCategoryId;
  String? _selectedCourseId;
  String? _selectedCourseName;
  String? _selectedInstructorId;
  String? _selectedInstructorName;

  DateTime _scheduledDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _scheduledTime = const TimeOfDay(hour: 18, minute: 0);

  int _enrolledStudentCount = 0;
  bool _isLoadingEnrolled = false;
  bool _isCheckingConflict = false;
  List<LiveClass> _conflicts = [];
  bool _conflictIgnored = false;
  bool _notifyStudents = true;
  bool _isSubmitting = false;

  bool get isEditing => widget.existingClass != null;

  @override
  void initState() {
    super.initState();
    final c = widget.existingClass;
    _titleController = TextEditingController(text: c?.title ?? '');
    _meetingLinkController = TextEditingController(text: c?.meetingLink ?? '');
    _durationController = TextEditingController(text: c != null ? c.durationMinutes.toString() : '60');

    if (c != null) {
      _selectedCourseId = c.courseId;
      _selectedCourseName = c.courseName;
      _selectedInstructorId = c.instructorId;
      _selectedInstructorName = c.instructorName;
      _scheduledDate = c.scheduledAt;
      _scheduledTime = TimeOfDay(hour: c.scheduledAt.hour, minute: c.scheduledAt.minute);
      _fetchEnrolledCount(c.courseId);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _meetingLinkController.dispose();
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

  Future<void> _fetchEnrolledCount(String courseId) async {
    setState(() => _isLoadingEnrolled = true);
    try {
      final rows = await AppSupabase.client
          .from('course_enrollments')
          .select('id')
          .eq('course_id', courseId)
          .eq('status', 'active');

      if (mounted) {
        setState(() {
          _enrolledStudentCount = rows.length;
          _isLoadingEnrolled = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingEnrolled = false);
    }
  }

  Future<void> _checkConflict() async {
    if (_selectedInstructorId == null || _selectedInstructorId!.isEmpty) return;

    setState(() => _isCheckingConflict = true);
    try {
      final repo = ref.read(classRepositoryProvider);
      final duration = int.tryParse(_durationController.text.trim()) ?? 60;
      final found = await repo.checkInstructorConflicts(
        instructorId: _selectedInstructorId!,
        scheduledAt: _combinedDateTime,
        durationMinutes: duration,
        excludeClassId: widget.existingClass?.id,
      );

      if (mounted) {
        setState(() {
          _conflicts = found;
          _isCheckingConflict = false;
          _conflictIgnored = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isCheckingConflict = false);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCourseId == null || _selectedCourseId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a course'), backgroundColor: AppColors.error),
      );
      return;
    }
    if (_selectedInstructorId == null || _selectedInstructorId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an instructor'), backgroundColor: AppColors.error),
      );
      return;
    }

    // If conflict detected and not acknowledged
    if (_conflicts.isNotEmpty && !_conflictIgnored) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('Schedule Conflict Detected'),
            ],
          ),
          content: Text(
            'Instructor $_selectedInstructorName already has another class scheduled during this time slot:\n\n'
            '• "${_conflicts.first.title}" on ${DateFormatter.formatDateTime(_conflicts.first.scheduledAt)}\n\n'
            'Do you still want to proceed and double-book this time?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Change Time'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Proceed Anyway', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (proceed != true) return;
      _conflictIgnored = true;
    }

    setState(() => _isSubmitting = true);

    try {
      final notifier = ref.read(classNotifierProvider.notifier);
      final duration = int.tryParse(_durationController.text.trim()) ?? 60;

      final liveClass = LiveClass(
        id: widget.existingClass?.id ?? '',
        title: _titleController.text.trim(),
        courseId: _selectedCourseId!,
        courseName: _selectedCourseName ?? 'Course',
        instructorId: _selectedInstructorId!,
        instructorName: _selectedInstructorName ?? 'Instructor',
        scheduledAt: _combinedDateTime,
        durationMinutes: duration,
        status: widget.existingClass?.status ?? 'upcoming',
        meetingLink: _meetingLinkController.text.trim().isNotEmpty
            ? _meetingLinkController.text.trim()
            : null,
        createdAt: widget.existingClass?.createdAt ?? DateTime.now(),
      );

      bool success;
      if (isEditing) {
        success = await notifier.rescheduleClass(
          liveClass.id,
          liveClass.scheduledAt,
          liveClass.durationMinutes,
        );
      } else {
        success = await notifier.createClass(liveClass, notifyStudents: _notifyStudents);
      }

      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing ? 'Class updated successfully' : 'Live class scheduled successfully',
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
    final effectiveHeight = (availableHeight - bottomInset) * 0.90;

    final categoriesState = ref.watch(categoryNotifierProvider);
    final coursesState = ref.watch(coursesNotifierProvider);
    final facultyState = ref.watch(facultyNotifierProvider);

    // Filter courses by selected category if selected
    final availableCourses = _selectedCategoryId == null || _selectedCategoryId == 'all'
        ? coursesState.courses
        : coursesState.courses.where((c) => c.categoryId == _selectedCategoryId).toList();

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

            // Sheet Header
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
                      Icons.video_camera_front_rounded,
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
                          isEditing ? 'Reschedule Live Class' : 'Schedule New Live Class',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          isEditing
                              ? 'Adjust date, time slot, duration, or meeting link'
                              : 'Admin-controlled cascading class scheduling & timetable allocation',
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

            // Scrollable Form
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  children: [
                    // Conflict Warning Banner
                    if (_conflicts.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade700),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.warning_rounded, color: Colors.amber.shade800, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Faculty Timetable Conflict Detected!',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      color: Colors.amber.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$_selectedInstructorName already has "${_conflicts.first.title}" booked at ${DateFormatter.formatDateTime(_conflicts.first.scheduledAt)}.',
                                    style: TextStyle(fontSize: 11, color: Colors.amber.shade900),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Step 1: Filter Category (Cascading)
                    DropdownButtonFormField<String>(
                      value: _selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Filter by Academic Category (Optional)',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Categories')),
                        ...categoriesState.categories.map((cat) {
                          return DropdownMenuItem(value: cat.id, child: Text(cat.name));
                        }),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedCategoryId = val;
                          _selectedCourseId = null;
                          _selectedCourseName = null;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // Step 2: Course Selection
                    DropdownButtonFormField<String>(
                      value: _selectedCourseId,
                      decoration: const InputDecoration(
                        labelText: 'Course *',
                        prefixIcon: Icon(Icons.menu_book_outlined),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Please select course' : null,
                      items: availableCourses.map((c) {
                        return DropdownMenuItem(
                          value: c.id,
                          child: Text(
                            c.title,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val == null) return;
                        final course = coursesState.courses.firstWhere((c) => c.id == val);
                        setState(() {
                          _selectedCourseId = val;
                          _selectedCourseName = course.title;

                          // Auto-select instructor if assigned
                          if (course.instructorId != null && course.instructorId!.isNotEmpty) {
                            _selectedInstructorId = course.instructorId;
                            _selectedInstructorName = course.instructorName;
                          }
                        });
                        _fetchEnrolledCount(val);
                        _checkConflict();
                      },
                    ),

                    // Enrolled Students Metric Badge
                    if (_selectedCourseId != null) ...[
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.group_outlined, size: 14, color: AppColors.primaryForest),
                            const SizedBox(width: 6),
                            Text(
                              _isLoadingEnrolled
                                  ? 'Loading enrolled students...'
                                  : '$_enrolledStudentCount active enrolled students will receive access',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryForest,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Step 3: Instructor Selection
                    DropdownButtonFormField<String>(
                      value: _selectedInstructorId,
                      decoration: const InputDecoration(
                        labelText: 'Assigned Instructor *',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Please select instructor' : null,
                      items: facultyState.facultyList.map((f) {
                        return DropdownMenuItem(
                          value: f.id,
                          child: Text(
                            '${f.fullName} (${f.specialization})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val == null) return;
                        final fac = facultyState.facultyList.firstWhere((f) => f.id == val);
                        setState(() {
                          _selectedInstructorId = val;
                          _selectedInstructorName = fac.fullName;
                        });
                        _checkConflict();
                      },
                    ),

                    const SizedBox(height: 16),

                    // Step 4: Class Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Session Title *',
                        hintText: 'e.g. Masterclass: Advanced Resuscitation Protocols',
                        prefixIcon: Icon(Icons.title_rounded),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter session title' : null,
                    ),

                    const SizedBox(height: 16),

                    // Step 5: Date & Time Pickers
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
                              if (picked != null) {
                                setState(() => _scheduledDate = picked);
                                _checkConflict();
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Date *',
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
                              if (picked != null) {
                                setState(() => _scheduledTime = picked);
                                _checkConflict();
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Time *',
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

                    const SizedBox(height: 16),

                    // Duration (minutes)
                    TextFormField(
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Duration (Minutes) *',
                        hintText: '60',
                        prefixIcon: Icon(Icons.timer_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (int.tryParse(v) == null) return 'Must be a valid integer';
                        return null;
                      },
                      onChanged: (_) => _checkConflict(),
                    ),

                    const SizedBox(height: 16),

                    // Meeting Link
                    TextFormField(
                      controller: _meetingLinkController,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'Meeting Link (Zoom / Google Meet)',
                        hintText: 'https://meet.google.com/abc-defg-hij',
                        prefixIcon: Icon(Icons.link_rounded),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Notification Toggle
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Send Notification to Students',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Automatically broadcast in-app notification to all enrolled candidates',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      value: _notifyStudents,
                      activeColor: AppColors.primaryForest,
                      onChanged: (val) => setState(() => _notifyStudents = val),
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
                            : Text(isEditing ? 'Save Changes' : 'Schedule Class'),
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

