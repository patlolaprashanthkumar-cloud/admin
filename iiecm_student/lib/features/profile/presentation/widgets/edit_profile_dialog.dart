import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../auth/domain/models/student_profile.dart';
import '../providers/profile_provider.dart';

/// Institutional Profile Editing Dialog
///
/// Redesigned in accordance with the IIECM Modern Academic design language:
/// Institutional navy headers, subtle borders, warm ivory input fields in light mode,
/// clear validation states, registry-locked field presentation, and keyboard-safe scrolling.
class EditProfileDialog extends ConsumerStatefulWidget {
  final StudentProfile student;

  const EditProfileDialog({super.key, required this.student});

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
    _qualificationController = TextEditingController(
      text: widget.student.qualification ?? '',
    );
    _educationLevelController = TextEditingController(
      text: widget.student.educationLevel ?? '',
    );
    _categoryController = TextEditingController(
      text: widget.student.preferredCategory ?? '',
    );
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

    final success = await ref
        .read(profileNotifierProvider.notifier)
        .updateProfile(
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
          backgroundColor: AppColors.primaryNavy,
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
    final mediaQuery = MediaQuery.of(context);
    final availableHeight = mediaQuery.size.height;

    return Dialog(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
        ),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: availableHeight * 0.88,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Institutional Dialog Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceElevated
                          : AppColors.forestSoft,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryNavy.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Icon(
                      Icons.edit_note_rounded,
                      color: AppColors.primaryNavy,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Edit Contact & Profile',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Institutional Scholar Records File',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Divider(
                height: 1,
                color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
              ),
              const SizedBox(height: 12),

              // 2. Scrollable Form Fields with Keyboard Safety
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
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
                        icon: Icons.alternate_email_rounded,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 14),

                      // Section Header: Personal Contact Information
                      Row(
                        children: [
                          Icon(
                            Icons.contact_mail_outlined,
                            size: 15,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.primaryNavy,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Personal Contact Details',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

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
                      const SizedBox(height: 16),

                      // Section Header: Academic Background
                      Row(
                        children: [
                          Icon(
                            Icons.school_outlined,
                            size: 15,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.primaryNavy,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Academic Profile & Background',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Qualification
                      _buildTextField(
                        controller: _qualificationController,
                        label: 'Medical / Academic Qualification',
                        icon: Icons.workspace_premium_outlined,
                        isDark: isDark,
                        hint: 'e.g., MBBS, MD Emergency Medicine, B.Sc Nursing',
                      ),
                      const SizedBox(height: 12),

                      // Education Level
                      _buildTextField(
                        controller: _educationLevelController,
                        label: 'Education Level',
                        icon: Icons.school_outlined,
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
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),
              Divider(
                height: 1,
                color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
              ),
              const SizedBox(height: 10),

              // 3. Institutional Dialog Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: profileState.isUpdating
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.warmCream,
        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isNotEmpty ? value : '—',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primaryNavy.withValues(
                alpha: isDark ? 0.25 : 0.08,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 11,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.primaryNavy,
                ),
                const SizedBox(width: 3),
                Text(
                  'Locked',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.primaryNavy,
                  ),
                ),
              ],
            ),
          ),
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
      style: TextStyle(
        fontSize: 13,
        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: 12.5,
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        ),
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 11.5,
          color: isDark
              ? AppColors.darkTextSecondary.withValues(alpha: 0.6)
              : AppColors.textMuted,
        ),
        prefixIcon: Icon(
          icon,
          size: 18,
          color: isDark ? AppColors.darkTextSecondary : AppColors.primaryNavy,
        ),
        filled: true,
        fillColor: isDark
            ? AppColors.darkSurfaceElevated
            : AppColors.warmCreamLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
          borderSide: const BorderSide(
            color: AppColors.primaryNavy,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
          borderSide: const BorderSide(color: AppColors.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
    );
  }
}
