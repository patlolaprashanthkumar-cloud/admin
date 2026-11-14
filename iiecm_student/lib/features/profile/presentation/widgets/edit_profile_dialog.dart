import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../auth/domain/models/student_profile.dart';
import '../providers/profile_provider.dart';

class EditProfileDialog extends ConsumerStatefulWidget {
  final StudentProfile student;

  const EditProfileDialog({
    super.key,
    required this.student,
  });

  @override
  ConsumerState<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _qualificationController;
  late final TextEditingController _educationLevelController;
  late final TextEditingController _categoryController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.student.fullName);
    _phoneController = TextEditingController(text: widget.student.phone ?? '');
    _qualificationController =
        TextEditingController(text: widget.student.qualification ?? '');
    _educationLevelController =
        TextEditingController(text: widget.student.educationLevel ?? '');
    _categoryController =
        TextEditingController(text: widget.student.preferredCategory ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _qualificationController.dispose();
    _educationLevelController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success =
        await ref.read(profileNotifierProvider.notifier).updateProfile(
              fullName: _nameController.text.trim(),
              phone: _phoneController.text.trim(),
              qualification: _qualificationController.text.trim(),
              educationLevel: _educationLevelController.text.trim(),
              preferredCategory: _categoryController.text.trim(),
            );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile information updated successfully.'),
          backgroundColor: AppColors.primaryForest,
        ),
      );
    } else {
      final error = ref.read(profileNotifierProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Failed to update profile.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profileState = ref.watch(profileNotifierProvider);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dialog Header
              Row(
                children: [
                  const Icon(Icons.edit_note_rounded,
                      color: AppColors.primaryForest),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Edit Contact & Profile',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),

              // Form fields
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      // Non-editable Institutional ID Callout
                      _buildLockedField(
                        label: 'Institutional Student ID (Registry Locked)',
                        value: widget.student.studentId,
                        icon: Icons.badge_outlined,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),

                      // Non-editable Email Callout
                      _buildLockedField(
                        label: 'Institutional Registered Email (Locked)',
                        value: widget.student.email,
                        icon: Icons.email_outlined,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),

                      // Full Legal Name
                      _buildTextField(
                        controller: _nameController,
                        label: 'Full Legal Name',
                        icon: Icons.person_outline_rounded,
                        isDark: isDark,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter your full legal name.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Phone Number
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Contact Phone Number',
                        icon: Icons.phone_outlined,
                        isDark: isDark,
                        keyboardType: TextInputType.phone,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter a valid contact phone number.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Qualification
                      _buildTextField(
                        controller: _qualificationController,
                        label: 'Medical / Academic Qualification',
                        icon: Icons.school_outlined,
                        isDark: isDark,
                        hint: 'e.g., MBBS, MD Emergency Medicine, B.Sc Nursing',
                      ),
                      const SizedBox(height: 12),

                      // Education Level
                      _buildTextField(
                        controller: _educationLevelController,
                        label: 'Education Level',
                        icon: Icons.workspace_premium_outlined,
                        isDark: isDark,
                        hint: 'e.g., Postgraduate, Undergraduate, Fellow',
                      ),
                      const SizedBox(height: 12),

                      // Department / Preferred Category
                      _buildTextField(
                        controller: _categoryController,
                        label: 'Department / Clinical Focus',
                        icon: Icons.local_hospital_outlined,
                        isDark: isDark,
                        hint: 'e.g., Emergency Medicine, Critical Care',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: profileState.isUpdating
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  AppButton(
                    label: 'Save Changes',
                    icon: Icons.check_rounded,
                    isLoading: profileState.isUpdating,
                    isFullWidth: false,
                    height: 38,
                    onPressed: profileState.isUpdating ? null : _submit,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLockedField({
    required String label,
    required String value,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.warmCream,
        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.lock_outline_rounded,
              size: 14, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18),
        filled: true,
        fillColor: isDark ? AppColors.darkSurface : AppColors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
          borderSide: const BorderSide(
            color: AppColors.primaryForest,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
