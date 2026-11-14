import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../domain/models/student_dashboard_data.dart';
import 'providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

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
    final todayFormatted = DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());

    final authState = ref.watch(authNotifierProvider);
    final student = authState.student;

    final dashboardState = ref.watch(dashboardNotifierProvider);
    final data = dashboardState.data;
    final isLoading = dashboardState.isLoading && data == null;
    final hasError = dashboardState.hasError && data == null;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'IIECM Student Portal',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            Text(
              todayFormatted,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _showSignOutDialog(context, ref),
          ),
          const SizedBox(width: AppConstants.spacingSm),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryForest,
          onRefresh: () async {
            await ref.read(dashboardNotifierProvider.notifier).refresh();
          },
          child: isLoading
              ? _buildLoadingState(theme, isDark)
              : hasError
                  ? _buildErrorState(context, ref, theme, isDark, dashboardState.errorMessage)
                  : ListView(
                      padding: const EdgeInsets.all(AppConstants.spacingMd),
                      children: [
                        // 1. Authoritative Student Hero Welcome Card
                        AppCard(
                          backgroundColor: isDark ? AppColors.forestDark : AppColors.primaryForest,
                          borderColor: isDark ? AppColors.forestLight : AppColors.forestDark,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: AppColors.forestSoft,
                                    child: const Icon(
                                      Icons.school_rounded,
                                      color: AppColors.primaryForest,
                                      size: 26,
                                    ),
                                  ),
                                  const SizedBox(width: AppConstants.spacingMd),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Welcome back, ${student?.firstName ?? 'Student'}',
                                          style: theme.textTheme.titleLarge?.copyWith(
                                            color: AppColors.white,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'ID: ${student?.studentId ?? 'STU-ENROLLED'} • ${student?.email ?? 'Active Student'}',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: AppColors.forestSoft,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppConstants.spacingMd),
                              const Divider(color: Color(0x33FFFFFF)),
                              const SizedBox(height: AppConstants.spacingSm),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.verified_rounded,
                                    color: AppColors.warmCream,
                                    size: 16,
                                  ),
                                  const SizedBox(width: AppConstants.spacingSm),
                                  Expanded(
                                    child: Text(
                                      'Status: ${(student?.accountStatus ?? 'Active').toUpperCase()} • Plan: ${student?.subscriptionPlan ?? 'Enrolled Candidate'}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppConstants.spacingMd),

                        // 2. Real Academic Summary Metrics Grid
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricTile(
                                context: context,
                                title: 'My Courses',
                                value: '${data?.totalEnrolledCourses ?? 0} Enrolled',
                                subtitle: '${data?.inProgressCourses ?? 0} in Progress',
                                icon: Icons.menu_book_rounded,
                                color: AppColors.primaryForest,
                                onTap: () => context.go('/courses'),
                              ),
                            ),
                            const SizedBox(width: AppConstants.spacingSm),
                            Expanded(
                              child: _buildMetricTile(
                                context: context,
                                title: 'Assessments',
                                value: '${data?.upcomingAssessmentsCount ?? 0} Due',
                                subtitle: (data?.upcomingAssessmentsCount ?? 0) > 0 ? 'Upcoming Tests' : 'All Clear',
                                icon: Icons.assignment_turned_in_outlined,
                                color: AppColors.terracotta,
                                onTap: () => context.go('/assessments'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppConstants.spacingSm),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricTile(
                                context: context,
                                title: 'Results',
                                value: data?.averageGrade ?? 'No Results',
                                subtitle: (data?.evaluatedResultsCount ?? 0) > 0
                                    ? '${data!.evaluatedResultsCount} Evaluated'
                                    : 'Awaiting Tests',
                                icon: Icons.workspace_premium_outlined,
                                color: const Color(0xFF2E7D32),
                                onTap: () => context.push('/results'),
                              ),
                            ),
                            const SizedBox(width: AppConstants.spacingSm),
                            Expanded(
                              child: _buildMetricTile(
                                context: context,
                                title: 'Assignments',
                                value: '${data?.pendingAssignmentsCount ?? 0} Due',
                                subtitle: (data?.pendingAssignmentsCount ?? 0) > 0 ? 'Pending Tasks' : 'All Submitted',
                                icon: Icons.task_alt_rounded,
                                color: const Color(0xFF0288D1),
                                onTap: () => context.push('/assignments'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppConstants.spacingLg),

                        // 3. Continue Learning Spotlight
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Continue Learning',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.go('/courses'),
                              child: const Text('View All'),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppConstants.spacingSm),
                        if (data != null && data.hasEnrollments) ...[
                          _buildPrimaryCourseCard(context, theme, isDark, data.primaryCourse!),
                        ] else ...[
                          _buildEmptyCourseCard(context, theme, isDark),
                        ],
                        const SizedBox(height: AppConstants.spacingLg),

                        // 4. Real Next Scheduled Live Session
                        Text(
                          'Next Scheduled Session',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppConstants.spacingSm),
                        if (data?.nextScheduledSession != null) ...[
                          _buildLiveClassCard(context, theme, isDark, data!.nextScheduledSession!),
                        ] else ...[
                          _buildEmptySessionCard(theme, isDark),
                        ],
                        const SizedBox(height: AppConstants.spacingLg),

                        // 5. Quick Portals
                        Text(
                          'Quick Portals',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppConstants.spacingSm),
                        Row(
                          children: [
                            Expanded(
                              child: _buildQuickActionCard(
                                context: context,
                                title: 'Assignments',
                                icon: Icons.task_alt_rounded,
                                onTap: () => context.push('/assignments'),
                              ),
                            ),
                            const SizedBox(width: AppConstants.spacingSm),
                            Expanded(
                              child: _buildQuickActionCard(
                                key: const Key('quick_action_results'),
                                context: context,
                                title: 'Results',
                                icon: Icons.workspace_premium_rounded,
                                onTap: () => context.push('/results'),
                              ),
                            ),
                            const SizedBox(width: AppConstants.spacingSm),
                            Expanded(
                              child: _buildQuickActionCard(
                                key: const Key('quick_action_payments'),
                                context: context,
                                title: 'Fee Status',
                                icon: Icons.receipt_long_rounded,
                                onTap: () => context.push('/payments'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppConstants.spacingLg),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildPrimaryCourseCard(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    EnrolledCourseItem course,
  ) {
    return AppCard(
      onTap: () => context.go('/courses'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.forestSoft,
                    borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                  ),
                  child: Text(
                    course.categoryName,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryForest,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: course.enrollmentStatus.toLowerCase() == 'active'
                      ? AppColors.forestSoft
                      : AppColors.terracottaSoft,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                ),
                child: Text(
                  'Status: ${course.enrollmentStatus.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: course.enrollmentStatus.toLowerCase() == 'active'
                        ? AppColors.primaryForest
                        : AppColors.terracotta,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            course.title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppConstants.spacingXs),
          Text(
            '${course.format.toUpperCase()} • ${course.durationWeeks} Weeks${course.instructorName != null ? " • Mentor: ${course.instructorName}" : ""}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton(
                label: 'Open Curriculum',
                icon: Icons.menu_book_rounded,
                isFullWidth: false,
                height: 38,
                onPressed: () {
                  if (course.courseId.isNotEmpty) {
                    context.push('/courses/${course.courseId}');
                  } else {
                    context.go('/courses');
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCourseCard(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      child: Column(
        children: [
          Icon(
            Icons.school_outlined,
            size: 36,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            'No Course Enrollments Assigned',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'You are not currently enrolled in any academic curriculum. Please contact the IIECM Academic Registrar to assign your courses.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppConstants.spacingMd),
          AppButton(
            label: 'Explore Courses',
            icon: Icons.explore_outlined,
            isFullWidth: false,
            height: 36,
            variant: AppButtonVariant.outline,
            onPressed: () => context.go('/courses'),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveClassCard(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    LiveClassItem session,
  ) {
    final weekday = DateFormat('EEE').format(session.scheduledAt).toUpperCase();
    final dayNum = DateFormat('d').format(session.scheduledAt);
    final timeStr = DateFormat('h:mm a').format(session.scheduledAt);

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: session.isLive ? const Color(0xFFFFEBEE) : AppColors.terracottaSoft,
              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  session.isLive ? 'LIVE' : weekday,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: session.isLive ? AppColors.error : AppColors.terracotta,
                  ),
                ),
                Text(
                  dayNum,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: session.isLive ? AppColors.error : AppColors.terracotta,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppConstants.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$timeStr IST • ${session.courseName}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
                Text(
                  'Faculty: ${session.instructorName}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }

  Widget _buildEmptySessionCard(ThemeData theme, bool isDark) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceElevated : AppColors.warmCream,
              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy_outlined, color: AppColors.textMuted, size: 24),
              ],
            ),
          ),
          const SizedBox(width: AppConstants.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No Live Sessions Scheduled',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'There are no live webinars or simulation classes scheduled at this time.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      children: [
        AppCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingMd,
            vertical: AppConstants.spacingLg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryForest),
                ),
              ),
              const SizedBox(height: AppConstants.spacingMd),
              Text(
                'Loading Academic Dashboard',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Synchronizing curriculum, schedules, and clinical assessments...',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    bool isDark,
    String? error,
  ) {
    return ListView(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      children: [
        AppCard(
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          child: Column(
            children: [
              const Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.error),
              const SizedBox(height: AppConstants.spacingMd),
              Text(
                'Unable to Load Student Dashboard',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: AppConstants.spacingSm),
              Text(
                error ?? 'A network or connectivity issue occurred while retrieving your academic data.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppConstants.spacingLg),
              AppButton(
                label: 'Retry Connection',
                icon: Icons.refresh_rounded,
                isFullWidth: false,
                onPressed: () => ref.read(dashboardNotifierProvider.notifier).loadDashboard(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required BuildContext context,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppConstants.spacingSm + 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    Key? key,
    required BuildContext context,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppCard(
      key: key,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingSm,
        vertical: AppConstants.spacingMd,
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: AppColors.primaryForest),
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
