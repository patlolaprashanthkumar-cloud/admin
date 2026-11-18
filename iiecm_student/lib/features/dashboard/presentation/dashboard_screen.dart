import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../notifications/presentation/providers/notifications_provider.dart';
import '../../notifications/presentation/providers/notifications_state.dart';
import '../domain/models/student_dashboard_data.dart';
import 'providers/dashboard_provider.dart';
import 'widgets/live_class_detail_dialog.dart';

/// IIECM Learning Hub — Student Dashboard Screen matching the Right Phone Reference
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.accentOrange),
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
              backgroundColor: AppColors.accentOrange,
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

    final dashboardState = ref.watch(dashboardNotifierProvider);
    final data = dashboardState.data;
    final isLoading = dashboardState.isLoading && data == null;
    final hasError = dashboardState.hasError && data == null;

    final notifState = ref.watch(notificationsNotifierProvider);
    final unreadCount = notifState.unreadCount;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.backgroundWarmOffWhite,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.darkSurface
            : AppColors.backgroundWarmOffWhite,
        titleSpacing: 12,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.primaryNavy,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 19,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'IIECM',
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.primaryNavy,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'LEARNING HUB',
                        style: TextStyle(
                          color: AppColors.accentOrange,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'IIECM Student Portal',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Notification Bell with unread badge counter
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                tooltip: 'Notifications',
                icon: Icon(
                  Icons.notifications_outlined,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  size: 24,
                ),
                onPressed: () => context.push('/notifications'),
              ),
              if (unreadCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Center(
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // Student Profile Avatar
          InkWell(
            onTap: () => _showSignOutDialog(context, ref),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 34,
              height: 34,
              margin: const EdgeInsets.only(left: 4, right: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.deepNavy : const Color(0xFFFED7AA),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? AppColors.darkBorder
                      : const Color(0xFFFDBA74),
                  width: 1.2,
                ),
              ),
              child: Center(
                child: Text(
                  student?.firstName.isNotEmpty == true
                      ? student!.firstName[0].toUpperCase()
                      : 'S',
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.primaryNavy,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryNavy,
          backgroundColor: Colors.white,
          onRefresh: () async {
            await ref.read(dashboardNotifierProvider.notifier).refresh();
            await ref
                .read(notificationsNotifierProvider.notifier)
                .loadNotifications(isRefresh: true);
          },
          child: isLoading
              ? _buildLoadingState(theme, isDark)
              : hasError
              ? _buildErrorState(
                  context,
                  ref,
                  theme,
                  isDark,
                  dashboardState.errorMessage,
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  children: [
                    // 1. Welcome Greeting & Student Portrait Hero (Matching Right Phone)
                    _buildStudentHeroSection(context, theme, isDark, student),
                    const SizedBox(height: 16),

                    // 2. Continue Learning Spotlight Card (Matching Right Phone)
                    if (data != null && data.hasEnrollments) ...[
                      _buildPrimaryCourseCard(
                        context,
                        theme,
                        isDark,
                        data.primaryCourse!,
                      ),
                    ] else ...[
                      _buildEmptyCourseCard(context, theme, isDark),
                    ],
                    const SizedBox(height: 20),

                    // 3. My Courses Section (Matching Right Phone)
                    _buildMyCoursesSection(context, theme, isDark, data),
                    const SizedBox(height: 20),

                    // 4. Upcoming Class Section (Matching Right Phone)
                    _buildUpcomingClassSection(
                      context,
                      theme,
                      isDark,
                      data?.nextScheduledSession,
                    ),
                    const SizedBox(height: 20),

                    // 5. Announcements Section (Matching Right Phone)
                    _buildAnnouncementsSection(
                      context,
                      theme,
                      isDark,
                      notifState,
                    ),
                    const SizedBox(height: 20),

                    // 6. Quick Portals (Preserves quick_action_results & quick_action_payments test targets)
                    _buildQuickPortalsSection(context, theme, isDark),
                    const SizedBox(height: 18),

                    // 7. Academic Summary Metrics
                    if (data != null) ...[
                      _buildAcademicMetricsGrid(context, theme, isDark, data),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildStudentHeroSection(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    dynamic student,
  ) {
    final greetingName = student?.firstName.isNotEmpty == true
        ? student!.firstName
        : 'Student';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerLow : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Welcome back, $greetingName',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    letterSpacing: -0.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                const Text(
                  'Continue your learning journey',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'ID: ${student?.studentId ?? 'STU-ENROLLED'} • ${student?.email ?? 'Active Student'}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Student Avatar Presentation with Warm Peach Arch Backdrop
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(55),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: SizedBox(
              width: 105,
              height: 94,
              child: _buildStudentHeroVisual(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentHeroVisual(bool isDark) {
    return Image.asset(
      'assets/images/student.png',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A1C14) : const Color(0xFFFED7AA),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                bottom: -6,
                child: Container(
                  width: 68,
                  height: 54,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.deepNavy : AppColors.primaryNavy,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(34),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 14,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFDBA74),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.school_rounded,
                      size: 20,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.accentOrange,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    size: 13,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPrimaryCourseCard(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    EnrolledCourseItem course,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryNavy, Color(0xFF042031)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryNavy.withValues(alpha: isDark ? 0.4 : 0.22),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (course.courseId.isNotEmpty) {
              context.push('/courses/${course.courseId}');
            } else {
              context.go('/courses');
            }
          },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Circular White Play Button
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: AppColors.primaryNavy,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Continue Learning',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.75),
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            course.title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${course.categoryName} • ${course.format.toUpperCase()}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Forward Arrow Button
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: AppColors.primaryNavy,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Orange Progress Bar matching Right Phone
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: 0.65,
                    minHeight: 5,
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.accentOrange,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '65% Complete',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMyCoursesSection(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    StudentDashboardData? data,
  ) {
    final courses = data?.enrolledCourses ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Courses',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontSize: 17,
              ),
            ),
            TextButton(
              onPressed: () => context.go('/courses'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                foregroundColor: isDark
                    ? AppColors.accentOrange
                    : AppColors.primaryNavy,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View All',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  SizedBox(width: 3),
                  Icon(Icons.arrow_forward_rounded, size: 14),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (courses.isEmpty) ...[
          _buildEmptyCourseCard(context, theme, isDark),
        ] else ...[
          SizedBox(
            height: 168,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: courses.length >= 2 ? courses.length : 2,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                if (index < courses.length) {
                  final course = courses[index];
                  return _buildCourseCard(context, course, isDark, index);
                } else {
                  return _buildBrowseMoreCoursesCard(context, isDark);
                }
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCourseCard(
    BuildContext context,
    EnrolledCourseItem course,
    bool isDark,
    int index,
  ) {
    final cardGradients = [
      [const Color(0xFF0F172A), const Color(0xFF1E3A5F)],
      [const Color(0xFF162D4A), const Color(0xFF155B78)],
      [const Color(0xFF1A365D), const Color(0xFF2C5282)],
    ];
    final gradient = cardGradients[index % cardGradients.length];

    final icons = [
      Icons.smart_toy_outlined,
      Icons.insights_rounded,
      Icons.biotech_outlined,
      Icons.school_rounded,
    ];
    final icon = icons[index % icons.length];

    return Container(
      width: 185,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF082538) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (course.courseId.isNotEmpty) {
              context.push('/courses/${course.courseId}');
            } else {
              context.go('/courses');
            }
          },
          borderRadius: BorderRadius.circular(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner with learning icon
              Container(
                height: 76,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: Colors.white, size: 28),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          course.categoryName.isNotEmpty
                              ? course.categoryName
                                    .split(' ')
                                    .first
                                    .toUpperCase()
                              : 'CURRICULUM',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Course metadata & progress
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${course.durationWeeks} Lessons • 75% Complete',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: 0.75,
                        minHeight: 3.5,
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.accentOrange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrowseMoreCoursesCard(BuildContext context, bool isDark) {
    return Container(
      width: 185,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF082538) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go('/courses'),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryNavy.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.explore_outlined,
                    color: AppColors.primaryNavy,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Explore Curricula',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                const Text(
                  'Browse additional clinical tracks',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingClassSection(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    LiveClassItem? session,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming Class',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 8),
        if (session != null) ...[
          _buildUpcomingClassCard(context, theme, isDark, session),
        ] else ...[
          _buildEmptySessionCard(theme, isDark),
        ],
      ],
    );
  }

  Widget _buildUpcomingClassCard(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    LiveClassItem session,
  ) {
    final timeStr = DateFormat('h:mm a').format(session.scheduledAt);
    final isToday =
        DateTime.now().day == session.scheduledAt.day &&
        DateTime.now().month == session.scheduledAt.month;
    final displayDate = isToday
        ? 'Today, $timeStr'
        : DateFormat('d MMM, h:mm a').format(session.scheduledAt);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerLow : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => LiveClassDetailDialog.show(context, session: session),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.deepNavy
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.calendar_month_outlined,
                      color: AppColors.primaryNavy,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        displayDate,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${session.courseName} • ${session.instructorName}',
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () =>
                      LiveClassDetailDialog.show(context, session: session),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Join',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnnouncementsSection(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    NotificationsState notifState,
  ) {
    final latestNotification = notifState.notifications.firstOrNull;

    final title = latestNotification?.title ?? 'New Assessment Released';
    final message =
        latestNotification?.message ??
        'Take the final quiz for your enrolled clinical courses.';
    final timeStr = latestNotification != null
        ? _formatTimeAgo(latestNotification.createdAt)
        : '2h ago';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Announcements',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontSize: 17,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/notifications'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                foregroundColor: isDark
                    ? AppColors.accentOrange
                    : AppColors.primaryNavy,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View All',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  SizedBox(width: 3),
                  Icon(Icons.arrow_forward_rounded, size: 14),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark
                ? theme.colorScheme.surfaceContainerLow
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.025),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.push('/notifications'),
              borderRadius: BorderRadius.circular(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF4E8),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.campaign_rounded,
                        color: AppColors.accentOrange,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                  fontSize: 13.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              timeStr,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          message,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return 'Recent';
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('d MMM').format(dateTime);
  }

  Widget _buildQuickPortalsSection(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Portals',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 8),
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
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickActionCard(
                key: const Key('quick_action_results'),
                context: context,
                title: 'Results',
                icon: Icons.workspace_premium_rounded,
                onTap: () => context.push('/results'),
              ),
            ),
            const SizedBox(width: 10),
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
      ],
    );
  }

  Widget _buildAcademicMetricsGrid(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    StudentDashboardData data,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                context: context,
                title: 'My Courses',
                value: '${data.totalEnrolledCourses} Enrolled',
                subtitle: '${data.inProgressCourses} in Progress',
                icon: Icons.menu_book_rounded,
                color: AppColors.primaryNavy,
                onTap: () => context.go('/courses'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricTile(
                context: context,
                title: 'Assessments',
                value: '${data.upcomingAssessmentsCount} Due',
                subtitle: data.upcomingAssessmentsCount > 0
                    ? 'Upcoming Tests'
                    : 'All Clear',
                icon: Icons.assignment_turned_in_outlined,
                color: AppColors.accentOrange,
                onTap: () => context.go('/assessments'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                context: context,
                title: 'Results',
                value: data.averageGrade ?? 'No Results',
                subtitle: data.evaluatedResultsCount > 0
                    ? '${data.evaluatedResultsCount} Evaluated'
                    : 'Awaiting Tests',
                icon: Icons.workspace_premium_outlined,
                color: AppColors.success,
                onTap: () => context.push('/results'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricTile(
                context: context,
                title: 'Assignments',
                value: '${data.pendingAssignmentsCount} Due',
                subtitle: data.pendingAssignmentsCount > 0
                    ? 'Pending Tasks'
                    : 'All Submitted',
                icon: Icons.task_alt_rounded,
                color: AppColors.secondaryBlue,
                onTap: () => context.push('/assignments'),
              ),
            ),
          ],
        ),
      ],
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

    return Material(
      key: key,
      color: isDark ? theme.colorScheme.surfaceContainerLow : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.025),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 24,
                color: isDark ? Colors.white : AppColors.primaryNavy,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
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

    return Material(
      color: isDark ? theme.colorScheme.surfaceContainerLow : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.025),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
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
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 16, color: color),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
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
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
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
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
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

  Widget _buildEmptySessionCard(ThemeData theme, bool isDark) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceElevated
                  : AppColors.warmCream,
              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_busy_outlined,
                  color: AppColors.textMuted,
                  size: 24,
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
                  'No Live Sessions Scheduled',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'There are no live webinars or simulation classes scheduled at this time.',
                  style: theme.textTheme.bodySmall?.copyWith(
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
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryNavy,
                  ),
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
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
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
              const Icon(
                Icons.wifi_off_rounded,
                size: 40,
                color: AppColors.error,
              ),
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
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppConstants.spacingLg),
              AppButton(
                label: 'Retry Connection',
                icon: Icons.refresh_rounded,
                isFullWidth: false,
                onPressed: () => ref
                    .read(dashboardNotifierProvider.notifier)
                    .loadDashboard(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
