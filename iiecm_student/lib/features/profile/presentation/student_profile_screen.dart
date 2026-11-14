import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../auth/domain/models/student_profile.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import 'widgets/change_password_dialog.dart';
import 'widgets/edit_profile_dialog.dart';

class StudentProfileScreen extends ConsumerWidget {
  const StudentProfileScreen({super.key});

  void _showEditProfileDialog(BuildContext context, StudentProfile student) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => EditProfileDialog(student: student),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const ChangePasswordDialog(),
    );
  }

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.terracotta),
            SizedBox(width: 8),
            Text('Sign Out'),
          ],
        ),
        content: const Text(
          'Are you sure you want to sign out of the IIECM Student Portal?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.terracotta,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authNotifierProvider.notifier).logout();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.watch(authNotifierProvider);
    final student = authState.student;

    final registrationDateFormatted = student?.createdAt != null
        ? DateFormat('MMMM d, yyyy').format(student!.createdAt!)
        : 'Registered Institutional Scholar';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dossier & Profile'),
        actions: [
          if (student != null)
            IconButton(
              key: const Key('edit_profile_appbar_button'),
              tooltip: 'Edit Profile',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _showEditProfileDialog(context, student),
            ),
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _showSignOutDialog(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryForest,
          onRefresh: () async {
            await ref.read(authNotifierProvider.notifier).retryVerification();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppConstants.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              // Header Profile Card
              AppCard(
                padding: const EdgeInsets.all(AppConstants.spacingLg),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: isDark ? AppColors.forestDark : AppColors.forestSoft,
                          backgroundImage: (student?.avatarUrl != null &&
                                  student!.avatarUrl!.trim().isNotEmpty)
                              ? NetworkImage(student.avatarUrl!.trim())
                              : null,
                          child: (student?.avatarUrl == null ||
                                  student!.avatarUrl!.trim().isEmpty)
                              ? Text(
                                  (student?.fullName.isNotEmpty == true)
                                      ? student!.fullName.substring(0, 1).toUpperCase()
                                      : 'S',
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryForest,
                                  ),
                                )
                              : null,
                        ),
                        if (student != null)
                          GestureDetector(
                            onTap: () => _showEditProfileDialog(context, student),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primaryForest,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark ? AppColors.darkSurface : Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.edit,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.spacingMd),
                    Text(
                      student?.fullName ?? 'Student Name',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      student?.studentId ?? 'STU-ID-PENDING',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.terracotta,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingSm),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.forestSoft,
                            borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                            border: Border.all(color: AppColors.primaryForest.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified_rounded, size: 14, color: AppColors.primaryForest),
                              const SizedBox(width: 4),
                              Text(
                                'Status: ${(student?.accountStatus ?? "Active").toUpperCase()}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryForest,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.school_outlined, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                (student?.role ?? 'Student').toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.spacingMd),
                    if (student != null)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          key: const Key('edit_profile_header_button'),
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Edit Contact Information'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryForest,
                            side: const BorderSide(color: AppColors.primaryForest),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                            ),
                          ),
                          onPressed: () => _showEditProfileDialog(context, student),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.spacingMd),

              // Academic Information Card
              AppCard(
                padding: const EdgeInsets.all(AppConstants.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.school_outlined, color: AppColors.primaryForest, size: 20),
                        const SizedBox(width: AppConstants.spacingSm),
                        Text(
                          'Academic Credentials & Program',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      context,
                      'Institutional Student ID',
                      student?.studentId ?? '—',
                    ),
                    _buildInfoRow(
                      context,
                      'Current Qualification',
                      student?.qualification?.isNotEmpty == true
                          ? student!.qualification!
                          : (student?.educationLevel?.isNotEmpty == true
                              ? student!.educationLevel!
                              : 'Medical Scholar'),
                    ),
                    _buildInfoRow(
                      context,
                      'Specialization / Department',
                      student?.preferredCategory?.isNotEmpty == true
                          ? student!.preferredCategory!
                          : 'Emergency Medicine',
                    ),
                    _buildInfoRow(
                      context,
                      'Curriculum Plan',
                      student?.subscriptionPlan?.isNotEmpty == true
                          ? student!.subscriptionPlan!
                          : 'Standard Institutional Track',
                    ),
                    _buildInfoRow(
                      context,
                      'Enrollment Record',
                      registrationDateFormatted,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.spacingMd),

              // Contact Information Card
              AppCard(
                padding: const EdgeInsets.all(AppConstants.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.contact_mail_outlined, color: AppColors.primaryForest, size: 20),
                            const SizedBox(width: AppConstants.spacingSm),
                            Text(
                              'Contact Information',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        if (student != null)
                          InkWell(
                            onTap: () => _showEditProfileDialog(context, student),
                            borderRadius: BorderRadius.circular(4),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              child: Text(
                                'Edit',
                                style: TextStyle(
                                  color: AppColors.primaryForest,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      context,
                      'Registered Email (Institutional)',
                      student?.email ?? '—',
                    ),
                    _buildInfoRow(
                      context,
                      'Phone Number',
                      student?.phone?.isNotEmpty == true ? student!.phone! : 'Not registered',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.spacingMd),

              // Account & Security Card
              AppCard(
                padding: const EdgeInsets.all(AppConstants.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.security_outlined, color: AppColors.primaryForest, size: 20),
                        const SizedBox(width: AppConstants.spacingSm),
                        Text(
                          'Account & Security',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceElevated : AppColors.forestSoft,
                          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                        ),
                        child: const Icon(Icons.lock_reset_rounded, color: AppColors.primaryForest, size: 18),
                      ),
                      title: const Text(
                        'Change Password',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      subtitle: const Text(
                        'Update your portal login password securely',
                        style: TextStyle(fontSize: 11),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                      onTap: () => _showChangePasswordDialog(context),
                    ),
                    const Divider(height: 16),
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceElevated : AppColors.forestSoft,
                          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                        ),
                        child: const Icon(Icons.verified_user_outlined, color: AppColors.primaryForest, size: 18),
                      ),
                      title: const Text(
                        'Identity Provider',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      subtitle: const Text(
                        'Supabase Institutional Single Sign-On',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.spacingMd),

              // Institutional Records Quick Links
              AppCard(
                padding: const EdgeInsets.all(AppConstants.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.account_balance_outlined, color: AppColors.primaryForest, size: 20),
                        const SizedBox(width: AppConstants.spacingSm),
                        Text(
                          'Institutional Records',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceElevated : AppColors.forestSoft,
                          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                        ),
                        child: const Icon(Icons.workspace_premium_rounded, color: AppColors.primaryForest, size: 18),
                      ),
                      title: const Text('Academic Results & Transcripts', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      subtitle: const Text('View evaluated grades and performance records', style: TextStyle(fontSize: 11)),
                      trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                      onTap: () => context.push('/results'),
                    ),
                    const Divider(height: 16),
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceElevated : AppColors.forestSoft,
                          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                        ),
                        child: const Icon(Icons.receipt_long_rounded, color: AppColors.primaryForest, size: 18),
                      ),
                      title: const Text('Fee Status & Payment Receipts', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      subtitle: const Text('Review tuition invoices and digital receipt vouchers', style: TextStyle(fontSize: 11)),
                      trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                      onTap: () => context.push('/payments'),
                    ),
                    const Divider(height: 16),
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceElevated : AppColors.forestSoft,
                          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                        ),
                        child: const Icon(Icons.notifications_active_outlined, color: AppColors.primaryForest, size: 18),
                      ),
                      title: const Text('Institutional Bulletins & Alerts', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      subtitle: const Text('Academic notices, class schedules and alerts', style: TextStyle(fontSize: 11)),
                      trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                      onTap: () => context.push('/notifications'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.spacingLg),

              // Sign Out Button
              AppButton(
                label: 'Sign Out of Student Portal',
                icon: Icons.logout_rounded,
                variant: AppButtonVariant.outline,
                onPressed: () => _showSignOutDialog(context, ref),
              ),
              const SizedBox(height: AppConstants.spacingMd),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
