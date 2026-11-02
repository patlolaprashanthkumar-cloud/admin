import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../courses/presentation/providers/courses_provider.dart';
import '../../domain/models/faculty.dart';
import '../providers/faculty_provider.dart';

class AddEditFacultySheet extends ConsumerStatefulWidget {
  final Faculty? faculty;

  const AddEditFacultySheet({super.key, this.faculty});

  static Future<bool?> show(BuildContext context, {Faculty? faculty}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddEditFacultySheet(faculty: faculty),
    );
  }

  @override
  ConsumerState<AddEditFacultySheet> createState() => _AddEditFacultySheetState();
}

class _AddEditFacultySheetState extends ConsumerState<AddEditFacultySheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _qualificationsController;
  late TextEditingController _specializationController;
  late TextEditingController _experienceController;
  late TextEditingController _bioController;

  late String _status;
  final Set<String> _selectedCategoryIds = {};
  final Set<String> _selectedCourseIds = {};

  bool _isSubmitting = false;

  bool get isEditing => widget.faculty != null;

  @override
  void initState() {
    super.initState();
    final f = widget.faculty;
    _nameController = TextEditingController(text: f?.fullName ?? '');
    _emailController = TextEditingController(text: f?.email ?? '');
    _phoneController = TextEditingController(text: f?.phone ?? '');
    _qualificationsController = TextEditingController(text: f?.qualifications ?? '');
    _specializationController = TextEditingController(text: f?.specialization ?? '');
    _experienceController = TextEditingController(text: f != null ? f.experienceYears.toString() : '5');
    _bioController = TextEditingController(text: f?.bio ?? '');
    _status = f?.accountStatus ?? 'active';

    if (f != null) {
      _selectedCategoryIds.addAll(f.assignedCategories.map((c) => c.id));
      _selectedCourseIds.addAll(f.assignedCourseIds);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _qualificationsController.dispose();
    _specializationController.dispose();
    _experienceController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final notifier = ref.read(facultyNotifierProvider.notifier);
      final facultyData = Faculty(
        id: widget.faculty?.id ?? '',
        profileId: widget.faculty?.profileId,
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        qualifications: _qualificationsController.text.trim().isNotEmpty
            ? _qualificationsController.text.trim()
            : 'N/A',
        specialization: _specializationController.text.trim(),
        experienceYears: int.tryParse(_experienceController.text.trim()) ?? 0,
        accountStatus: _status,
        bio: _bioController.text.trim().isNotEmpty ? _bioController.text.trim() : null,
        createdAt: widget.faculty?.createdAt ?? DateTime.now(),
      );

      bool success;
      if (isEditing) {
        success = await notifier.updateFaculty(
          facultyData,
          categoryIds: _selectedCategoryIds.toList(),
          courseIds: _selectedCourseIds.toList(),
        );
      } else {
        success = await notifier.createFaculty(
          facultyData,
          categoryIds: _selectedCategoryIds.toList(),
          courseIds: _selectedCourseIds.toList(),
        );
      }

      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing ? 'Faculty updated successfully' : 'Faculty registered successfully',
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
    final effectiveHeight = (availableHeight - bottomInset) * 0.90;

    final categoriesState = ref.watch(categoryNotifierProvider);
    final coursesState = ref.watch(coursesNotifierProvider);

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
                      Icons.person_add_alt_1_rounded,
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
                          isEditing ? 'Edit Faculty Profile' : 'Register New Faculty',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          isEditing
                              ? 'Update credentials, category assignments, and courses'
                              : 'Create institutional instructor with multi-category teaching stream',
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

            // Scrollable Content
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  children: [
                    // Full Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        hintText: 'e.g. Dr. Ramesh Gupta',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Please enter full name' : null,
                    ),
                    const SizedBox(height: 16),

                    // Email & Phone
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email Address *',
                              hintText: 'faculty@iiecm.com',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              if (!v.contains('@') || !v.contains('.')) return 'Invalid email';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number *',
                              hintText: '+91 98765 43210',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Qualifications & Specialization
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _qualificationsController,
                            decoration: const InputDecoration(
                              labelText: 'Qualifications',
                              hintText: 'MD, DM, FRCP',
                              prefixIcon: Icon(Icons.school_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _specializationController,
                            decoration: const InputDecoration(
                              labelText: 'Specialization *',
                              hintText: 'Critical Care',
                              prefixIcon: Icon(Icons.medical_services_outlined),
                            ),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Experience & Status
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _experienceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Experience (Years)',
                              hintText: '8',
                              prefixIcon: Icon(Icons.timeline_rounded),
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
                          child: DropdownButtonFormField<String>(
                            initialValue: _status,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              prefixIcon: Icon(Icons.toggle_on_outlined),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'active', child: Text('Active')),
                              DropdownMenuItem(value: 'suspended', child: Text('Suspended')),
                              DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _status = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Bio
                    TextFormField(
                      controller: _bioController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Faculty Bio / Academic Summary',
                        hintText: 'Brief profile and clinical background...',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Multi-Category Teaching Streams
                    Text(
                      'Assigned Teaching Categories',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select curriculum streams this faculty member is certified to teach.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (categoriesState.categories.isEmpty)
                      const Text(
                        'No categories found in system.',
                        style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: categoriesState.categories.map((cat) {
                          final isSelected = _selectedCategoryIds.contains(cat.id);
                          return FilterChip(
                            label: Text(cat.name),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedCategoryIds.add(cat.id);
                                } else {
                                  _selectedCategoryIds.remove(cat.id);
                                }
                              });
                            },
                            selectedColor: AppColors.primaryForest.withValues(alpha: 0.15),
                            checkmarkColor: AppColors.primaryForest,
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.primaryForest
                                  : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                            ),
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 20),

                    // Assigned Courses
                    Text(
                      'Assign Courses (Instructor Allocation)',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select courses for which this faculty member is the primary instructor.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (coursesState.courses.isEmpty)
                      const Text(
                        'No courses found in catalog.',
                        style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.divider,
                          ),
                          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: coursesState.courses.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final course = coursesState.courses[index];
                            final isAssigned = _selectedCourseIds.contains(course.id);
                            return CheckboxListTile(
                              dense: true,
                              title: Text(
                                course.title,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                '${course.categoryName} • ${course.format.toUpperCase()}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                ),
                              ),
                              value: isAssigned,
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
                            : Text(isEditing ? 'Save Changes' : 'Register Faculty'),
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
