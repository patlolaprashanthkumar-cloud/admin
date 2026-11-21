import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../categories/domain/models/course_category.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../courses/domain/models/course.dart';
import '../../../courses/presentation/providers/courses_provider.dart';
import '../providers/students_provider.dart';

/// AddStudentWizard
///
/// 6-step guided admissions workflow for enrolling new student candidates:
/// 1. Personal & Contact Information
/// 2. Multi-Category Academic Streams
/// 3. Curriculum Course Enrollments
/// 4. Faculty Advisor Assignment
/// 5. Class Format & Timetable Schedule
/// 6. Review & Final Confirmation
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
  final _qualificationController = TextEditingController();

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
      return AppColors.primaryNavy;
    }
  }

  String _formatLearningFormatLabel(String format) {
    switch (format.trim().toLowerCase()) {
      case 'hybrid':
        return 'Online + Offline Classes';
      case 'live':
        return 'Live Online Classes';
      case 'recorded':
        return 'Recorded Classes';
      case 'live_recorded':
        return 'Live + Recorded Classes';
      default:
        return format;
    }
  }

  bool _validateCurrentStep() {
    if (_currentStep == 0) {
      return _formKeyStep1.currentState?.validate() ?? false;
    } else if (_currentStep == 1) {
      if (_selectedCategoryIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one curriculum category'),
          ),
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

    final allCourses = ref.read(coursesNotifierProvider).courses;
    // Guard: Only enroll courses belonging to actively selected categories
    final validCourseIds = _selectedCourseIds.where((cid) {
      final match = allCourses.where((c) => c.id == cid).firstOrNull;
      return match != null && _selectedCategoryIds.contains(match.categoryId);
    }).toList();

    final result = await notifier.registerStudent(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      educationLevel: _educationLevel,
      qualification: _qualificationController.text.trim(),
      categoryIds: _selectedCategoryIds.toList(),
      courseIds: validCourseIds,
      city: _cityController.text.trim().isNotEmpty
          ? _cityController.text.trim()
          : null,
      subscriptionPlan: 'basic',
      learningFormat: _learningFormat,
      preferredSlot: _preferredSlot,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (result != null) {
        String feedbackMessage;
        Color snackColor = AppColors.primaryNavy;

        if (result.hasAssignmentWarning) {
          snackColor = AppColors.warning;
          feedbackMessage =
              'Account created for ${result.student.fullName}, but assignment warning: ${result.assignmentWarning}';
        } else if (result.isExistingUser) {
          snackColor = AppColors.info;
          feedbackMessage =
              'Existing account recognized for ${result.student.fullName}. Profile re-linked and password activation link dispatched!';
        } else if (result.invitationSent) {
          snackColor = AppColors.success;
          feedbackMessage =
              'Student ${result.student.fullName} provisioned! Setup invitation sent to ${result.student.email}.';
        } else {
          snackColor = AppColors.warning;
          feedbackMessage =
              'Student ${result.student.fullName} provisioned, but invitation email dispatch could not be confirmed.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: snackColor,
            duration: const Duration(seconds: 4),
            content: Text(feedbackMessage),
          ),
        );
        context.pop();
      } else {
        final serverErr = ref.read(studentsNotifierProvider).errorMessage;
        setState(() {
          _submissionError = serverErr ?? 'Failed to register student. Please verify the information and retry.';
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
    final activeCategories = categoriesState.categories
        .where((c) => c.isActive)
        .toList();

    // Courses belonging to the selected categories
    final availableCourses = coursesState.courses.where((c) {
      return _selectedCategoryIds.contains(c.categoryId);
    }).toList();

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.backgroundWarmOffWhite,
      appBar: AppBar(
        title: const Text('Add Student Admission'),
        backgroundColor: isDark
            ? AppColors.darkSurface
            : AppColors.backgroundWarmOffWhite,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Stepper Indicator Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: isDark ? AppColors.darkSurface : AppColors.cardWhite,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppConstants.maxContentWidth,
                  ),
                  child: Row(
                    children: List.generate(6, (index) {
                      final isPassed = index < _currentStep;
                      final isCurrent = index == _currentStep;
                      final color = isPassed || isCurrent
                          ? AppColors.primaryNavy
                          : (isDark
                                ? Colors.white.withValues(alpha: 0.15)
                                : Colors.grey.withValues(alpha: 0.25));

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
                constraints: const BoxConstraints(
                  maxWidth: AppConstants.maxContentWidth,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.primaryNavy.withValues(alpha: 0.3)
                              : AppColors.forestSoft,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.primaryNavy.withValues(
                              alpha: 0.15,
                            ),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          'Step ${_currentStep + 1} of 6',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.accentOrangeLight
                                : AppColors.primaryNavy,
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
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
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
                  constraints: const BoxConstraints(
                    maxWidth: AppConstants.maxContentWidth,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.errorSoft,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.4),
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
                              _submissionError!,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (_submissionError!.contains(
                                'session has expired',
                              ) ||
                              _submissionError!.contains('sign in again')) ...[
                            const SizedBox(width: 8),
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.error,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                              ),
                              onPressed: () {
                                ref
                                    .read(authNotifierProvider.notifier)
                                    .logout();
                                context.go(AppRoutes.login);
                              },
                              child: const Text(
                                'Sign In',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Step Content Area (Vertically scrollable across all steps)
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppConstants.maxContentWidth,
                  ),
                  child: ScrollConfiguration(
                    behavior: const _NoScrollbarBehavior(),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      child: _buildStepContent(
                        activeCategories: activeCategories,
                        availableCourses: availableCourses,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Sticky Bottom Navigation Controls
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.cardWhite,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.borderNeutral,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppConstants.maxContentWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Row(
                        children: [
                          if (_currentStep > 0)
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isSubmitting
                                    ? null
                                    : () => setState(() => _currentStep--),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  side: BorderSide(
                                    color: isDark
                                        ? AppColors.darkBorder
                                        : AppColors.borderNeutral,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text('Previous'),
                              ),
                            )
                          else
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isSubmitting
                                    ? null
                                    : () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
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
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primaryNavy,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _currentStep == 5
                                          ? 'Confirm & Register Student'
                                          : 'Continue',
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    InputDecoration inputDecor({
      required String hintText,
      required IconData icon,
    }) {
      return InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: isDark ? AppColors.darkTextSecondary : AppColors.textMuted,
          fontSize: 13,
        ),
        prefixIcon: Icon(
          icon,
          color: isDark ? AppColors.accentOrangeLight : AppColors.primaryNavy,
          size: 20,
        ),
        filled: true,
        fillColor: isDark ? AppColors.darkSurface : AppColors.cardWhite,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
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
          borderSide: const BorderSide(
            color: AppColors.primaryNavy,
            width: 1.6,
          ),
        ),
      );
    }

    return Form(
      key: _formKeyStep1,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Name
            const Text(
              'Full Name *',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: inputDecor(
                hintText: 'e.g. Dr. Aarav Patel',
                icon: Icons.person_outline_rounded,
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Please enter student name'
                  : null,
            ),
            const SizedBox(height: 14),

            // 2. Email
            const Text(
              'Institutional Email *',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: inputDecor(
                hintText: 'student@example.com',
                icon: Icons.email_outlined,
              ),
              validator: (v) => v == null || !v.contains('@')
                  ? 'Enter a valid email address'
                  : null,
            ),
            const SizedBox(height: 14),

            // 3. Phone
            const Text(
              'Phone Number *',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: inputDecor(
                hintText: '+91 98765 43210',
                icon: Icons.phone_outlined,
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter phone number' : null,
            ),
            const SizedBox(height: 14),

            // 4. City
            const Text('City', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _cityController,
              textInputAction: TextInputAction.next,
              decoration: inputDecor(
                hintText: 'e.g. Mumbai',
                icon: Icons.location_city_outlined,
              ),
            ),
            const SizedBox(height: 14),

            // Education Level Dropdown
            const Text(
              'Education Level *',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _educationLevel,
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark ? AppColors.darkSurface : AppColors.cardWhite,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.borderNeutral,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.borderNeutral,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: AppColors.primaryNavy,
                    width: 1.6,
                  ),
                ),
              ),
              items:
                  [
                    "High School",
                    "Diploma",
                    "Bachelor's",
                    "Master's",
                    "Doctorate",
                  ].map((e) {
                    return DropdownMenuItem(value: e, child: Text(e));
                  }).toList(),
              onChanged: (val) =>
                  setState(() => _educationLevel = val ?? "Bachelor's"),
            ),
            const SizedBox(height: 14),

            // 5. Specialization or Stream
            const Text(
              'Specialization or Stream *',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _qualificationController,
              textInputAction: TextInputAction.done,
              decoration: inputDecor(
                hintText: 'e.g. Emergency Medicine, Critical Care, Cardiology',
                icon: Icons.school_outlined,
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Enter specialization or stream'
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2Categories(List<CourseCategory> categories) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.primaryNavy.withValues(alpha: 0.2)
                : AppColors.forestSoft,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primaryNavy.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: isDark
                    ? AppColors.accentOrangeLight
                    : AppColors.primaryNavy,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Multi-Category Support Active: Select one or more curriculum streams for this student. Courses and faculty in following steps will adapt dynamically.',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.primaryNavy,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
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
                child: Text(
                  'No active course categories found. Please configure categories first.',
                ),
              ),
            ),
          )
        else
          ...categories.map((cat) {
            final isSelected = _selectedCategoryIds.contains(cat.id);
            final catColor = _parseHex(cat.color);

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? catColor.withValues(alpha: isDark ? 0.16 : 0.08)
                      : (isDark ? AppColors.darkSurface : AppColors.cardWhite),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? catColor
                        : (isDark
                              ? AppColors.darkBorder
                              : AppColors.borderNeutral),
                    width: isSelected ? 1.8 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.2 : 0.03,
                      ),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedCategoryIds.remove(cat.id);
                          final catCourses = ref
                              .read(coursesNotifierProvider)
                              .courses
                              .where((c) => c.categoryId == cat.id)
                              .map((c) => c.id)
                              .toSet();
                          _selectedCourseIds.removeWhere(catCourses.contains);
                        } else {
                          _selectedCategoryIds.add(cat.id);
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
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
                                  final catCourses = ref
                                      .read(coursesNotifierProvider)
                                      .courses
                                      .where((c) => c.categoryId == cat.id)
                                      .map((c) => c.id)
                                      .toSet();
                                  _selectedCourseIds
                                      .removeWhere(catCourses.contains);
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
                            child: Icon(
                              Icons.category_rounded,
                              color: catColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cat.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  cat.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildStep3Courses(List<Course> courses) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_selectedCategoryIds.isEmpty) {
      return const AppCard(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Please select at least one category in Step 2.'),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Available Courses in Selected Streams (${courses.length})',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (courses.isEmpty)
          const AppCard(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No courses found for the selected category stream(s). You may proceed and enroll courses later.',
                ),
              ),
            ),
          )
        else
          ...courses.map((course) {
            final isEnrolled = _selectedCourseIds.contains(course.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: isEnrolled
                      ? (isDark
                            ? AppColors.primaryNavy.withValues(alpha: 0.2)
                            : AppColors.forestSoft)
                      : (isDark ? AppColors.darkSurface : AppColors.cardWhite),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isEnrolled
                        ? AppColors.primaryNavy
                        : (isDark
                              ? AppColors.darkBorder
                              : AppColors.borderNeutral),
                    width: isEnrolled ? 1.8 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.2 : 0.03,
                      ),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: CheckboxListTile(
                    value: isEnrolled,
                    activeColor: AppColors.primaryNavy,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedCourseIds.add(course.id);
                        } else {
                          _selectedCourseIds.remove(course.id);
                        }
                      });
                    },
                    title: Text(
                      course.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      '${course.categoryName} · ${course.durationWeeks} weeks · ${CurrencyFormatter.format(course.fee)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildStep4Instructors() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _instructorsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: AppColors.primaryNavy),
            ),
          );
        }
        final instructors = snapshot.data ?? [];

        return RadioGroup<String>(
          groupValue: _selectedInstructorId,
          onChanged: (val) {
            setState(() {
              _selectedInstructorId = val;
              if (val != null) {
                for (final ins in instructors) {
                  if (ins['id']?.toString() == val) {
                    _selectedInstructorName = ins['full_name']?.toString();
                    break;
                  }
                }
              } else {
                _selectedInstructorName = null;
              }
            });
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Assign Primary Faculty Advisor',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  if (_selectedInstructorId != null)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.accentOrange,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedInstructorId = null;
                          _selectedInstructorName = null;
                        });
                      },
                      icon: const Icon(Icons.close_rounded, size: 14),
                      label: const Text(
                        'Clear Selection',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              ...instructors.map((ins) {
                final id = ins['id']?.toString() ?? '';
                final isSelected = _selectedInstructorId == id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      setState(() {
                        _selectedInstructorId = id;
                        _selectedInstructorName = ins['full_name']?.toString();
                      });
                    },
                    onDoubleTap: () {
                      if (isSelected) {
                        setState(() {
                          _selectedInstructorId = null;
                          _selectedInstructorName = null;
                        });
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark
                                  ? AppColors.accentOrange.withValues(alpha: 0.15)
                                  : AppColors.accentOrangeSoft)
                            : (isDark
                                  ? AppColors.darkSurface
                                  : AppColors.cardWhite),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.accentOrange
                              : (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.borderNeutral),
                          width: isSelected ? 1.6 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.2 : 0.03,
                            ),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Radio<String>(
                            value: id,
                            activeColor: AppColors.accentOrange,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ins['full_name']?.toString() ?? 'Faculty',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                if (ins['specialization'] != null &&
                                    ins['specialization'].toString().isNotEmpty)
                                  Text(
                                    ins['specialization'].toString(),
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
                          if (isSelected)
                            IconButton(
                              tooltip: 'Remove selection (or double-click card)',
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: AppColors.accentOrange,
                              ),
                              onPressed: () {
                                setState(() {
                                  _selectedInstructorId = null;
                                  _selectedInstructorName = null;
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStep5Timetable() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.cardWhite;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.borderNeutral,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Class Format & Schedule',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _learningFormat,
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark ? AppColors.darkSurface : AppColors.cardWhite,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.borderNeutral,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.borderNeutral,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: AppColors.primaryNavy,
                    width: 1.6,
                  ),
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'hybrid',
                  child: Text('Online + Offline Classes'),
                ),
                DropdownMenuItem(
                  value: 'live',
                  child: Text('Live Online Classes'),
                ),
                DropdownMenuItem(
                  value: 'recorded',
                  child: Text('Recorded Classes'),
                ),
                DropdownMenuItem(
                  value: 'live_recorded',
                  child: Text('Live + Recorded Classes'),
                ),
              ],
              onChanged: (val) =>
                  setState(() => _learningFormat = val ?? 'hybrid'),
            ),
            const SizedBox(height: 16),

            const Text(
              'Preferred Timetable Slot',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _preferredSlot,
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark ? AppColors.darkSurface : AppColors.cardWhite,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.borderNeutral,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.borderNeutral,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: AppColors.primaryNavy,
                    width: 1.6,
                  ),
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Morning Clinical Batch (08:00 - 10:00 IST)',
                  child: Text('Morning Batch (08:00 - 10:00 IST)'),
                ),
                DropdownMenuItem(
                  value: 'Evening Executive Batch (18:00 - 20:00 IST)',
                  child: Text('Evening Batch (18:00 - 20:00 IST)'),
                ),
                DropdownMenuItem(
                  value: 'Weekend Intensive (Saturday & Sunday)',
                  child: Text('Weekend Intensive (Sat & Sun)'),
                ),
              ],
              onChanged: (val) =>
                  setState(() => _preferredSlot = val ?? _preferredSlot),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep6Review(
    List<CourseCategory> categories,
    List<Course> courses,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedCats = categories
        .where((c) => _selectedCategoryIds.contains(c.id))
        .toList();
    final selectedCrs = courses
        .where((c) => _selectedCourseIds.contains(c.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Student Candidate',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _nameController.text,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              Text(
                '${_emailController.text} · ${_phoneController.text}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Specialization / Stream: ${_qualificationController.text} · $_educationLevel',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Divider(
                height: 1,
                color: isDark ? AppColors.darkBorder : AppColors.borderNeutral,
              ),
              const SizedBox(height: 10),

              Text(
                'Multi-Category Academic Streams (${selectedCats.length})',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: selectedCats.map((c) {
                  final catColor = _parseHex(c.color);
                  return Chip(
                    backgroundColor: catColor.withValues(
                      alpha: isDark ? 0.2 : 0.12,
                    ),
                    label: Text(
                      c.name,
                      style: TextStyle(
                        color: catColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Divider(
                height: 1,
                color: isDark ? AppColors.darkBorder : AppColors.borderNeutral,
              ),
              const SizedBox(height: 10),

              Text(
                'Assigned Courses (${selectedCrs.length})',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              if (selectedCrs.isEmpty)
                Text(
                  'No courses assigned during admission',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                    fontSize: 12,
                  ),
                )
              else
                ...selectedCrs.map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 14,
                          color: AppColors.primaryNavy,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${c.title} (${c.categoryName})',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Divider(
                height: 1,
                color: isDark ? AppColors.darkBorder : AppColors.borderNeutral,
              ),
              const SizedBox(height: 10),

              if (_selectedInstructorName != null) ...[
                Text(
                  'Faculty Advisor: $_selectedInstructorName',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Divider(
                  height: 1,
                  color: isDark
                      ? AppColors.darkBorder
                      : AppColors.borderNeutral,
                ),
                const SizedBox(height: 10),
              ],
              Text(
                'Class Format & Schedule',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Format: ${_formatLearningFormatLabel(_learningFormat)} · $_preferredSlot',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Custom scroll behavior that suppresses scrollbar painting across all desktop and mobile platforms
class _NoScrollbarBehavior extends MaterialScrollBehavior {
  const _NoScrollbarBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
