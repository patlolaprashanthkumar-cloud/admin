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

/// Primary Student Profile & Scholar Dossier Screen
///
/// Designed in accordance with the IIECM Modern Academic design language:
/// Deep institutional navy, secondary teal, warm off-white background,
/// verified scholar badge, read-only academic credentials, contact information,
/// emergency safety protocol, institutional quick links, and account security.
///
/// Strict Data-Binding Integrity (Phase 4F.1A):
/// All student-specific information is bound directly to actual model properties
/// on [StudentProfile]. Where fields are unassigned or unavailable in the underlying
/// data entity, neutral placeholders ('Not provided', 'Not assigned', or '—') are displayed
/// without fabricating generic institutional assignments.
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          side: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
          ),
        ),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.terracotta.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: AppColors.terracotta,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Sign Out of Student Portal',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to sign out of the IIECM Student Portal? You will need to re-authenticate with your institutional credentials to access your academic dossier.',
          style: TextStyle(
            fontSize: 13,
            height: 1.45,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
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
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.terracotta,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusSm),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authNotifierProvider.notifier).logout();
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
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
        : 'Not recorded';

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.backgroundWarmOffWhite,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.darkSurface
            : AppColors.backgroundWarmOffWhite,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: Row(
          children: [
            // Institutional Brand Emblem
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceElevated
                    : AppColors.forestSoft,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryNavy.withValues(alpha: 0.2),
                  width: 1.2,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.account_box_rounded,
                  color: AppColors.primaryNavy,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Student Dossier & Profile',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Official Institutional Identity',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (student != null)
            IconButton(
              key: const Key('edit_profile_appbar_button'),
              tooltip: 'Edit Profile',
              icon: Icon(
                Icons.edit_outlined,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.primaryNavy,
              ),
              onPressed: () => _showEditProfileDialog(context, student),
            ),
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout_rounded, color: AppColors.terracotta),
            onPressed: () => _showSignOutDialog(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryNavy,
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
          onRefresh: () async {
            await ref.read(authNotifierProvider.notifier).retryVerification();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppConstants.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Scholar Identity Header Card
                _buildScholarHeaderCard(context, student, isDark, theme),
                const SizedBox(height: AppConstants.spacingMd),

                // 2. Academic Enrolment & Advisor (Strictly Read-Only)
                _buildAcademicCredentialsCard(
                  context,
                  student,
                  isDark,
                  theme,
                  registrationDateFormatted,
                ),
                const SizedBox(height: AppConstants.spacingMd),

                // 3. Contact & Communication Card
                _buildContactInformationCard(context, student, isDark, theme),
                const SizedBox(height: AppConstants.spacingMd),

                // 4. Emergency Safety Contact Card
                _buildEmergencyContactCard(context, student, isDark, theme),
                const SizedBox(height: AppConstants.spacingMd),

                // 5. Account & Security Card
                _buildAccountSecurityCard(context, isDark, theme),
                const SizedBox(height: AppConstants.spacingMd),

                // 6. Institutional Records Navigation Hub
                _buildInstitutionalRecordsCard(context, isDark, theme),
                const SizedBox(height: AppConstants.spacingLg),

                // 7. Sign Out Portal Action
                AppButton(
                  label: 'Sign Out of Student Portal',
                  icon: Icons.logout_rounded,
                  variant: AppButtonVariant.outline,
                  onPressed: () => _showSignOutDialog(context, ref),
                ),
                const SizedBox(height: AppConstants.spacingLg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. Scholar Identity Header
  // ===========================================================================
  Widget _buildScholarHeaderCard(
    BuildContext context,
    StudentProfile? student,
    bool isDark,
    ThemeData theme,
  ) {
    final studentIdText =
        (student?.studentId != null && student!.studentId.trim().isNotEmpty)
        ? student.studentId.trim()
        : '—';

    return AppCard(
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
      borderColor: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
      borderRadius: AppConstants.radiusLg,
      child: Column(
        children: [
          // Scholar Avatar with Concentric Institutional Border Rings
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                padding: const EdgeInsets.all(3.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryNavy.withValues(
                      alpha: isDark ? 0.4 : 0.25,
                    ),
                    width: 2.2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 42,
                  backgroundColor: isDark
                      ? AppColors.darkSurfaceElevated
                      : AppColors.forestSoft,
                  backgroundImage:
                      (student?.avatarUrl != null &&
                          student!.avatarUrl!.trim().isNotEmpty)
                      ? NetworkImage(student.avatarUrl!.trim())
                      : null,
                  child:
                      (student?.avatarUrl == null ||
                          student!.avatarUrl!.trim().isEmpty)
                      ? Text(
                          (student?.fullName.isNotEmpty == true)
                              ? student!.fullName.substring(0, 1).toUpperCase()
                              : 'S',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? AppColors.accentOrangeLight
                                : AppColors.primaryNavy,
                          ),
                        )
                      : null,
                ),
              ),
              if (student != null)
                GestureDetector(
                  onTap: () => _showEditProfileDialog(context, student),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryNavy,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppColors.darkSurface : AppColors.white,
                        width: 2.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Student Full Legal Name (Test Contract: Dr. Anita Roy)
          Text(
            (student?.fullName != null && student!.fullName.trim().isNotEmpty)
                ? student.fullName.trim()
                : 'Student',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),

          // Institutional Registration Badge (Displays real student ID or neutral placeholder)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
            decoration: BoxDecoration(
              color: AppColors.terracotta.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppConstants.radiusSm),
              border: Border.all(
                color: AppColors.terracotta.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Text(
              studentIdText,
              style: const TextStyle(
                color: AppColors.terracotta,
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                letterSpacing: 0.6,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Status & Institutional Role Badges
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              // Dynamic Account Status Badge
              _buildAccountStatusBadge(student, isDark),

              // Institutional Role Badge
              _buildRoleBadge(student, isDark),
            ],
          ),
          const SizedBox(height: 16),

          // Edit Contact Information Button (Test Contract: edit_profile_header_button)
          if (student != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const Key('edit_profile_header_button'),
                icon: const Icon(Icons.edit_outlined, size: 15),
                label: const Text('Edit Contact Information'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryNavy,
                  side: BorderSide(
                    color: AppColors.primaryNavy.withValues(alpha: 0.45),
                    width: 1.2,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                  ),
                ),
                onPressed: () => _showEditProfileDialog(context, student),
              ),
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Status Badge Builder (Truthful representation of account status)
  // ===========================================================================
  Widget _buildAccountStatusBadge(StudentProfile? student, bool isDark) {
    final rawStatus = student?.accountStatus.trim().toLowerCase();
    final hasStatus = rawStatus != null && rawStatus.isNotEmpty;

    Color badgeColor;
    Color badgeBg;
    IconData badgeIcon;
    String displayStatus;

    if (hasStatus) {
      displayStatus = rawStatus.toUpperCase();
      if (rawStatus == 'active') {
        badgeColor = AppColors.success;
        badgeBg = AppColors.success.withValues(alpha: 0.1);
        badgeIcon = Icons.verified_rounded;
      } else if (rawStatus == 'pending') {
        badgeColor = AppColors.warning;
        badgeBg = AppColors.warning.withValues(alpha: 0.12);
        badgeIcon = Icons.hourglass_empty_rounded;
      } else if (rawStatus == 'suspended') {
        badgeColor = AppColors.error;
        badgeBg = AppColors.error.withValues(alpha: 0.12);
        badgeIcon = Icons.block_rounded;
      } else {
        badgeColor = isDark
            ? AppColors.darkTextSecondary
            : AppColors.textSecondary;
        badgeBg = isDark ? AppColors.darkSurfaceElevated : AppColors.forestSoft;
        badgeIcon = Icons.info_outline_rounded;
      }
    } else {
      displayStatus = '—';
      badgeColor = isDark
          ? AppColors.darkTextSecondary
          : AppColors.textSecondary;
      badgeBg = isDark ? AppColors.darkSurfaceElevated : AppColors.forestSoft;
      badgeIcon = Icons.help_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
        border: Border.all(color: badgeColor.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 13, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            'STATUS: $displayStatus',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: badgeColor,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Role Badge Builder
  // ===========================================================================
  Widget _buildRoleBadge(StudentProfile? student, bool isDark) {
    final role = student?.role.trim();
    final displayRole = (role != null && role.isNotEmpty)
        ? role.toUpperCase()
        : 'STUDENT';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.forestSoft,
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
        border: Border.all(
          color: AppColors.primaryNavy.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.school_outlined,
            size: 13,
            color: AppColors.primaryNavy,
          ),
          const SizedBox(width: 4),
          Text(
            displayRole,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.primaryNavy,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. Academic Enrolment & Advisor (Strictly Read-Only)
  // ===========================================================================
  Widget _buildAcademicCredentialsCard(
    BuildContext context,
    StudentProfile? student,
    bool isDark,
    ThemeData theme,
    String registrationDateFormatted,
  ) {
    final studentId =
        (student?.studentId != null && student!.studentId.trim().isNotEmpty)
        ? student.studentId.trim()
        : '—';

    final qualification =
        (student?.qualification != null &&
            student!.qualification!.trim().isNotEmpty)
        ? student.qualification!.trim()
        : ((student?.educationLevel != null &&
                  student!.educationLevel!.trim().isNotEmpty)
              ? student.educationLevel!.trim()
              : 'Not provided');

    final department =
        (student?.preferredCategory != null &&
            student!.preferredCategory!.trim().isNotEmpty)
        ? student.preferredCategory!.trim()
        : 'Not provided';

    final curriculumPlan =
        (student?.subscriptionPlan != null &&
            student!.subscriptionPlan!.trim().isNotEmpty)
        ? student.subscriptionPlan!.trim()
        : 'Not enrolled';

    return AppCard(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
      borderColor: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
      borderRadius: AppConstants.radiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryNavy.withValues(
                          alpha: isDark ? 0.3 : 0.08,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: AppColors.primaryNavy,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Academic Credentials & Program',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
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
              const SizedBox(width: 8),
              // Read-only indicator chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceElevated
                      : AppColors.forestSoft,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppColors.primaryNavy.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 11,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'Read-only',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
          ),
          const SizedBox(height: 8),

          _buildInfoRow(
            context,
            'Institutional Student ID',
            studentId,
            icon: Icons.badge_outlined,
          ),
          _buildInfoRow(
            context,
            'Academic Batch & Cohort',
            'Not assigned',
            icon: Icons.calendar_today_outlined,
          ),
          _buildInfoRow(
            context,
            'Current Qualification',
            qualification,
            icon: Icons.workspace_premium_outlined,
          ),
          _buildInfoRow(
            context,
            'Specialization / Department',
            department,
            icon: Icons.local_hospital_outlined,
          ),
          _buildInfoRow(
            context,
            'Curriculum Plan & Track',
            curriculumPlan,
            icon: Icons.menu_book_outlined,
          ),
          _buildInfoRow(
            context,
            'Academic Advisor',
            'Not assigned',
            icon: Icons.person_outline_rounded,
          ),
          _buildInfoRow(
            context,
            'Enrollment Record',
            registrationDateFormatted,
            icon: Icons.history_edu_outlined,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. Contact & Communication Card
  // ===========================================================================
  Widget _buildContactInformationCard(
    BuildContext context,
    StudentProfile? student,
    bool isDark,
    ThemeData theme,
  ) {
    final email = (student?.email != null && student!.email.trim().isNotEmpty)
        ? student.email.trim()
        : '—';

    final phone = (student?.phone != null && student!.phone!.trim().isNotEmpty)
        ? student.phone!.trim()
        : 'Not provided';

    return AppCard(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
      borderColor: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
      borderRadius: AppConstants.radiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryNavy.withValues(
                          alpha: isDark ? 0.3 : 0.08,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.contact_mail_rounded,
                        color: AppColors.primaryNavy,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Contact Information',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
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
              const SizedBox(width: 8),
              if (student != null)
                InkWell(
                  onTap: () => _showEditProfileDialog(context, student),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryNavy.withValues(
                        alpha: isDark ? 0.2 : 0.08,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 12,
                          color: AppColors.primaryNavy,
                        ),
                        SizedBox(width: 3),
                        Text(
                          'Edit',
                          style: TextStyle(
                            color: AppColors.primaryNavy,
                            fontWeight: FontWeight.w700,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
          ),
          const SizedBox(height: 8),

          _buildInfoRow(
            context,
            'Registered Email (Institutional)',
            email,
            icon: Icons.alternate_email_rounded,
          ),
          _buildInfoRow(
            context,
            'Phone Number',
            phone,
            icon: Icons.phone_outlined,
          ),
          _buildInfoRow(
            context,
            'Alternate Phone',
            'Not provided',
            icon: Icons.phone_iphone_outlined,
          ),
          _buildInfoRow(
            context,
            'Permanent Address',
            'Not provided',
            icon: Icons.location_on_outlined,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. Emergency Safety Contact Card
  // ===========================================================================
  Widget _buildEmergencyContactCard(
    BuildContext context,
    StudentProfile? student,
    bool isDark,
    ThemeData theme,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
      borderColor: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
      borderRadius: AppConstants.radiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.terracotta.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.health_and_safety_rounded,
                        color: AppColors.terracotta,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Emergency Contact',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
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
              const SizedBox(width: 8),
              if (student != null)
                InkWell(
                  onTap: () => _showEditProfileDialog(context, student),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.terracotta.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 12,
                          color: AppColors.terracotta,
                        ),
                        SizedBox(width: 3),
                        Text(
                          'Update',
                          style: TextStyle(
                            color: AppColors.terracotta,
                            fontWeight: FontWeight.w700,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
          ),
          const SizedBox(height: 8),

          _buildInfoRow(
            context,
            'Emergency Contact Name',
            'Not provided',
            icon: Icons.person_pin_circle_outlined,
          ),
          _buildInfoRow(
            context,
            'Relationship to Scholar',
            'Not provided',
            icon: Icons.family_restroom_rounded,
          ),
          _buildInfoRow(
            context,
            'Emergency Phone',
            'Not provided',
            icon: Icons.emergency_outlined,
          ),
          const SizedBox(height: 8),

          // Institutional Safety Notice Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceElevated
                  : AppColors.forestSoft.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(AppConstants.radiusSm),
              border: Border.all(
                color: AppColors.primaryNavy.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: AppColors.primaryNavy,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Emergency contact details may be registered with the institutional registrar or updated during administrative registration.',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.35,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 5. Account & Security Card
  // ===========================================================================
  Widget _buildAccountSecurityCard(
    BuildContext context,
    bool isDark,
    ThemeData theme,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
      borderColor: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
      borderRadius: AppConstants.radiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryNavy.withValues(
                    alpha: isDark ? 0.3 : 0.08,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.security_rounded,
                  color: AppColors.primaryNavy,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Account & Security',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
          ),
          const SizedBox(height: 6),

          // Change Password Action
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceElevated
                    : AppColors.forestSoft,
                borderRadius: BorderRadius.circular(AppConstants.radiusSm),
              ),
              child: const Icon(
                Icons.lock_reset_rounded,
                color: AppColors.primaryNavy,
                size: 18,
              ),
            ),
            title: Text(
              'Change Password',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              'Update your portal login password securely',
              style: TextStyle(
                fontSize: 11.5,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
            onTap: () => _showChangePasswordDialog(context),
          ),
          Divider(
            height: 12,
            color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
          ),

          // Identity Provider Information
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceElevated
                    : AppColors.forestSoft,
                borderRadius: BorderRadius.circular(AppConstants.radiusSm),
              ),
              child: const Icon(
                Icons.verified_user_outlined,
                color: AppColors.primaryNavy,
                size: 18,
              ),
            ),
            title: Text(
              'Identity Provider',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              'Supabase Institutional Single Sign-On',
              style: TextStyle(
                fontSize: 11.5,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 6. Institutional Records Hub
  // ===========================================================================
  Widget _buildInstitutionalRecordsCard(
    BuildContext context,
    bool isDark,
    ThemeData theme,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
      borderColor: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
      borderRadius: AppConstants.radiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryNavy.withValues(
                    alpha: isDark ? 0.3 : 0.08,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.account_balance_outlined,
                  color: AppColors.primaryNavy,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Institutional Records',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
          ),
          const SizedBox(height: 6),

          // Academic Results & Transcripts
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceElevated
                    : AppColors.forestSoft,
                borderRadius: BorderRadius.circular(AppConstants.radiusSm),
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: AppColors.primaryNavy,
                size: 18,
              ),
            ),
            title: Text(
              'Academic Results & Transcripts',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              'View evaluated grades and performance records',
              style: TextStyle(
                fontSize: 11.5,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
            onTap: () => context.push('/results'),
          ),
          Divider(
            height: 12,
            color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
          ),

          // Fee Status & Payment Receipts
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceElevated
                    : AppColors.forestSoft,
                borderRadius: BorderRadius.circular(AppConstants.radiusSm),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: AppColors.primaryNavy,
                size: 18,
              ),
            ),
            title: Text(
              'Fee Status & Payment Receipts',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              'Review tuition invoices and digital receipt vouchers',
              style: TextStyle(
                fontSize: 11.5,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
            onTap: () => context.push('/payments'),
          ),
          Divider(
            height: 12,
            color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
          ),

          // Institutional Bulletins & Alerts
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceElevated
                    : AppColors.forestSoft,
                borderRadius: BorderRadius.circular(AppConstants.radiusSm),
              ),
              child: const Icon(
                Icons.notifications_active_outlined,
                color: AppColors.primaryNavy,
                size: 18,
              ),
            ),
            title: Text(
              'Institutional Bulletins & Alerts',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              'Academic notices, class schedules and alerts',
              style: TextStyle(
                fontSize: 11.5,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
            onTap: () => context.push('/notifications'),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Helper: Visual Info Row
  // ===========================================================================
  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 5,
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 14,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
