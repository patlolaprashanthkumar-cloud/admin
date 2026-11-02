import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../categories/domain/models/course_category.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../courses/domain/models/course.dart';
import '../../../courses/presentation/providers/courses_provider.dart';
import '../providers/students_provider.dart';

class AddStudentWizard extends ConsumerStatefulWidget {
  const AddStudentWizard({super.key});

  @override
  ConsumerState<AddStudentWizard> createState() => _AddStudentWizardState();
}

class _AddStudentWizardState extends ConsumerState<AddStudentWizard> {
  int _currentStep = 0;

  // Step 1: Personal Details
  final _formKeyStep1 = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  String _educationLevel = "Bachelor's";
  final _qualificationController = TextEditingController(text: 'Emergency Medicine');

  // Step 2: Multi-Category Selection
  final Set<String> _selectedCategoryIds = {};

  // Step 3: Course Selection
  final Set<String> _selectedCourseIds = {};

  // Step 4: Faculty Lead
  String? _selectedInstructorId;
  String? _selectedInstructorName;

  // Step 5: Timetable & Format
  String _learningFormat = 'hybrid';
  String _preferredSlot = 'Morning Clinical Batch (08:00 - 10:00 IST)';

  // Submission state
  bool _isSubmitting = false;
  String? _submissionError;

  late Future<List<Map<String, dynamic>>> _instructorsFuture;

  @override
  void initState() {
    super.initState();
    _instructorsFuture = _loadInstructors();
  }

  Future<List<Map<String, dynamic>>> _loadInstructors() async {
    try {
      final rows = await AppSupabase.client
          .from('instructors')
          .select('*')
          .eq('account_status', 'active');
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return [];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _qualificationController.dispose();
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

  bool _validateCurrentStep() {
    if (_currentStep == 0) {
      return _formKeyStep1.currentState?.validate() ?? false;
    } else if (_currentStep == 1) {
      if (_selectedCategoryIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one curriculum category')),
        );
        return false;
      }
      return true;
    }
    return true;
  }

  Future<void> _submitRegistration() async {
    setState(() {
      _isSubmitting = true;
      _submissionError = null;
    });

    final notifier = ref.read(studentsNotifierProvider.notifier);

    final newStudent = await notifier.registerStudent(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      educationLevel: _educationLevel,
      qualification: _qualificationController.text.trim(),
      categoryIds: _selectedCategoryIds.toList(),
      courseIds: _selectedCourseIds.toList(),
      city: _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : null,
      subscriptionPlan: 'basic',
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (newStudent != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primaryForest,
            content: Text('Student ${newStudent.fullName} registered successfully!'),
          ),
        );
        context.pop();
      } else {
        setState(() {
          _submissionError = 'Failed to register student. Ensure email is unique.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final categoriesState = ref.watch(categoryNotifierProvider);
    final coursesState = ref.watch(coursesNotifierProvider);

    // Active categories
    final activeCategories = categoriesState.categories.where((c) => c.isActive).toList();

    // Courses belonging to the selected categories
    final availableCourses = coursesState.courses.where((c) {
      return _selectedCategoryIds.contains(c.categoryId);
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      appBar: AppBar(
        title: const Text('Add Student Admission'),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.warmCream,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Stepper Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: isDark ? AppColors.darkSurface : Colors.white,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
                  child: Row(
                    children: List.generate(6, (index) {
                      final isPassed = index < _currentStep;
                      final isCurrent = index == _currentStep;
                      final color = isPassed || isCurrent ? AppColors.primaryForest : Colors.grey.withValues(alpha: 0.3);

                      return Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            if (index < 5) const SizedBox(width: 4),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),

            // Step Title & Instructions Banner
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.forestSoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Step ${_currentStep + 1} of 6',
                          style: const TextStyle(
                            color: AppColors.primaryForest,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _getStepTitle(_currentStep),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (_submissionError != null)
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.error),
                      ),
                      child: Text(_submissionError!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                    ),
                  ),
                ),
              ),

            // Step Content Area (Vertically scrollable across all steps)
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    child: _buildStepContent(
                      activeCategories: activeCategories,
                      availableCourses: availableCourses,
                    ),
                  ),
                ),
              ),
            ),

            // Sticky Bottom Navigation Controls
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.borderNeutral)),
              ),
              child: SafeArea(
                top: false,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Row(
                        children: [
                          if (_currentStep > 0)
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isSubmitting ? null : () => setState(() => _currentStep--),
                                child: const Text('Previous'),
                              ),
                            )
                          else
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: FilledButton(
                              onPressed: _isSubmitting
                                  ? null
                                  : () {
                                      if (!_validateCurrentStep()) return;
                                      if (_currentStep < 5) {
                                        setState(() => _currentStep++);
                                      } else {
                                        _submitRegistration();
                                      }
                                    },
                              style: FilledButton.styleFrom(backgroundColor: AppColors.primaryForest),
                              child: _isSubmitting
                                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : Text(_currentStep == 5 ? 'Confirm & Register Student' : 'Continue'),
                            ),
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
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Personal & Contact Information';
      case 1:
        return 'Multi-Category Academic Streams';
      case 2:
        return 'Curriculum Course Enrollments';
      case 3:
        return 'Faculty Advisor Assignment';
      case 4:
        return 'Timetable & Learning Format';
      case 5:
        return 'Review & Confirm Admission';
      default:
        return '';
    }
  }

  Widget _buildStepContent({
    required List<CourseCategory> activeCategories,
    required List<Course> availableCourses,
  }) {
    switch (_currentStep) {
      case 0:
        return _buildStep1Personal();
      case 1:
        return _buildStep2Categories(activeCategories);
      case 2:
        return _buildStep3Courses(availableCourses);
      case 3:
        return _buildStep4Instructors();
      case 4:
        return _buildStep5Timetable();
      case 5:
        return _buildStep6Review(activeCategories, availableCourses);
      default:
        return const SizedBox();
    }
  }

  Widget _buildStep1Personal() {
    return Form(
      key: _formKeyStep1,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name
            const Text('Full Name *', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(hintText: 'e.g. Dr. Aarav Patel', prefixIcon: Icon(Icons.person_outline_rounded)),
              validator: (v) => v == null || v.trim().isEmpty ? 'Please enter student name' : null,
            ),
            const SizedBox(height: 14),

            // Email
            const Text('Institutional Email *', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(hintText: 'student@example.com', prefixIcon: Icon(Icons.email_outlined)),
              validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email address' : null,
            ),
            const SizedBox(height: 14),

            // Phone
            const Text('Phone Number *', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(hintText: '+91 98765 43210', prefixIcon: Icon(Icons.phone_outlined)),
              validator: (v) => v == null || v.trim().isEmpty ? 'Enter phone number' : null,
            ),
            const SizedBox(height: 14),

            // City
            const Text('City', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _cityController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(hintText: 'e.g. Mumbai', prefixIcon: Icon(Icons.location_city_outlined)),
            ),
            const SizedBox(height: 14),

            // Education Level
            const Text('Education Level *', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _educationLevel,
              items: ["High School", "Diploma", "Bachelor's", "Master's", "Doctorate"].map((e) {
                return DropdownMenuItem(value: e, child: Text(e));
              }).toList(),
              onChanged: (val) => setState(() => _educationLevel = val ?? "Bachelor's"),
            ),
            const SizedBox(height: 14),

            // Specialization or Stream
            const Text('Specialization or Stream *', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _qualificationController,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                hintText: 'e.g. Emergency Medicine, Critical Care, Cardiology',
                prefixIcon: Icon(Icons.school_outlined),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Enter specialization or stream' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2Categories(List<CourseCategory> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          backgroundColor: AppColors.forestSoft,
          borderSide: BorderSide(color: AppColors.primaryForest.withValues(alpha: 0.3)),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.primaryForest, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Multi-Category Support Active: Select one or more curriculum streams for this student. Courses and faculty in following steps will adapt dynamically.',
                  style: const TextStyle(color: AppColors.primaryForest, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (categories.isEmpty)
          const AppCard(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No active course categories found. Please configure categories first.'),
              ),
            ),
          )
        else
          ...categories.map((cat) {
            final isSelected = _selectedCategoryIds.contains(cat.id);
            final catColor = _parseHex(cat.color);

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                backgroundColor: isSelected ? catColor.withValues(alpha: 0.08) : null,
                borderSide: BorderSide(
                  color: isSelected ? catColor : AppColors.borderNeutral,
                  width: isSelected ? 1.8 : 1.0,
                ),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedCategoryIds.remove(cat.id);
                      } else {
                        _selectedCategoryIds.add(cat.id);
                      }
                    });
                  },
                  child: Row(
                    children: [
                      Checkbox(
                        value: isSelected,
                        activeColor: catColor,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedCategoryIds.add(cat.id);
                            } else {
                              _selectedCategoryIds.remove(cat.id);
                            }
                          });
                        },
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: catColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.category_rounded, color: catColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                            const SizedBox(height: 2),
                            Text(cat.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildStep3Courses(List<Course> courses) {
    if (_selectedCategoryIds.isEmpty) {
      return const AppCard(child: Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Please select at least one category in Step 2.'))));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Courses in Selected Streams (${courses.length})',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        ),
        const SizedBox(height: 10),
        if (courses.isEmpty)
          const AppCard(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No courses found for the selected category stream(s). You may proceed and enroll courses later.'),
              ),
            ),
          )
        else
          ...courses.map((course) {
            final isEnrolled = _selectedCourseIds.contains(course.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                backgroundColor: isEnrolled ? AppColors.forestSoft : null,
                borderSide: BorderSide(
                  color: isEnrolled ? AppColors.primaryForest : AppColors.borderNeutral,
                  width: isEnrolled ? 1.8 : 1.0,
                ),
                child: CheckboxListTile(
                  value: isEnrolled,
                  activeColor: AppColors.primaryForest,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedCourseIds.add(course.id);
                      } else {
                        _selectedCourseIds.remove(course.id);
                      }
                    });
                  },
                  title: Text(course.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  subtitle: Text('${course.categoryName} · ${course.durationWeeks} weeks · ${CurrencyFormatter.format(course.fee)}', style: const TextStyle(fontSize: 11)),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildStep4Instructors() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _instructorsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
        }
        final instructors = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Assign Primary Faculty Advisor', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            const SizedBox(height: 10),
            ...instructors.map((ins) {
              final id = ins['id']?.toString() ?? '';
              final isSelected = _selectedInstructorId == id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  backgroundColor: isSelected ? AppColors.terracottaSoft : null,
                  borderSide: BorderSide(color: isSelected ? AppColors.accentTerracotta : AppColors.borderNeutral),
                  // ignore: deprecated_member_use
                  child: RadioListTile<String>(
                    value: id,
                    // ignore: deprecated_member_use
                    groupValue: _selectedInstructorId,
                    activeColor: AppColors.accentTerracotta,
                    contentPadding: EdgeInsets.zero,
                    // ignore: deprecated_member_use
                    onChanged: (val) {
                      setState(() {
                        _selectedInstructorId = val;
                        _selectedInstructorName = ins['full_name']?.toString();
                      });
                    },
                    title: Text(ins['full_name']?.toString() ?? 'Faculty', style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(ins['specialization']?.toString() ?? '', style: const TextStyle(fontSize: 11)),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildStep5Timetable() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Delivery & Cohort Format', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _learningFormat,
            items: const [
              DropdownMenuItem(value: 'hybrid', child: Text('Hybrid (Virtual Lecture + Clinical Onsite)')),
              DropdownMenuItem(value: 'live', child: Text('Live Virtual Synchronous')),
              DropdownMenuItem(value: 'recorded', child: Text('Asynchronous / Recorded LMS Modules')),
            ],
            onChanged: (val) => setState(() => _learningFormat = val ?? 'hybrid'),
          ),
          const SizedBox(height: 16),

          const Text('Preferred Timetable Slot', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _preferredSlot,
            items: const [
              DropdownMenuItem(value: 'Morning Clinical Batch (08:00 - 10:00 IST)', child: Text('Morning Batch (08:00 - 10:00 IST)')),
              DropdownMenuItem(value: 'Evening Executive Batch (18:00 - 20:00 IST)', child: Text('Evening Batch (18:00 - 20:00 IST)')),
              DropdownMenuItem(value: 'Weekend Intensive (Saturday & Sunday)', child: Text('Weekend Intensive (Sat & Sun)')),
            ],
            onChanged: (val) => setState(() => _preferredSlot = val ?? _preferredSlot),
          ),
        ],
      ),
    );
  }

  Widget _buildStep6Review(List<CourseCategory> categories, List<Course> courses) {
    final selectedCats = categories.where((c) => _selectedCategoryIds.contains(c.id)).toList();
    final selectedCrs = courses.where((c) => _selectedCourseIds.contains(c.id)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Student Candidate', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(_nameController.text, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              Text('${_emailController.text} · ${_phoneController.text}', style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 3),
              Text('Specialization / Stream: ${_qualificationController.text} · $_educationLevel',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),

              Text('Multi-Category Academic Streams (${selectedCats.length})', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: selectedCats.map((c) {
                  return Chip(
                    backgroundColor: _parseHex(c.color).withValues(alpha: 0.15),
                    label: Text(c.name, style: TextStyle(color: _parseHex(c.color), fontWeight: FontWeight.w700, fontSize: 11)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),

              Text('Assigned Courses (${selectedCrs.length})', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 6),
              if (selectedCrs.isEmpty)
                const Text('No courses assigned during admission', style: TextStyle(color: AppColors.textSecondary, fontSize: 12))
              else
                ...selectedCrs.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, size: 14, color: AppColors.primaryForest),
                      const SizedBox(width: 6),
                      Expanded(child: Text('${c.title} (${c.categoryName})', style: const TextStyle(fontSize: 12))),
                    ],
                  ),
                )),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),

              if (_selectedInstructorName != null)
                Text('Faculty Advisor: $_selectedInstructorName', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              Text('Format: $_learningFormat · $_preferredSlot', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}
