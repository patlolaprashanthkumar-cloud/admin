import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final todayFormatted = DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());

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
            icon: const Badge(
              label: Text('2'),
              child: Icon(Icons.notifications_outlined),
            ),
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            tooltip: 'Student Profile',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.go('/profile'),
          ),
          const SizedBox(width: AppConstants.spacingSm),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryForest,
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView(
            padding: const EdgeInsets.all(AppConstants.spacingMd),
            children: [
              // 1. Student Hero Welcome Card
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
                                'Welcome back, Student',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'ID: STU-2026-DEMO • Academic Year 2026',
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
                            'Active Enrollment Status: Verified & In Good Standing',
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

              // 2. Academic Summary Metrics Grid
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      context: context,
                      title: 'My Courses',
                      value: '3 Enrolled',
                      subtitle: '2 in Progress',
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
                      value: '2 Due',
                      subtitle: 'Upcoming Tests',
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
                      value: 'Grade: A',
                      subtitle: '3 Evaluated',
                      icon: Icons.workspace_premium_outlined,
                      color: const Color(0xFF2E7D32),
                      onTap: () => context.push('/results'),
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingSm),
                  Expanded(
                    child: _buildMetricTile(
                      context: context,
                      title: 'Attendance',
                      value: '94%',
                      subtitle: 'Clinical Batches',
                      icon: Icons.event_available_outlined,
                      color: const Color(0xFF0288D1),
                      onTap: () => context.go('/profile'),
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
              AppCard(
                onTap: () => context.go('/courses'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.forestSoft,
                            borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                          ),
                          child: const Text(
                            'Emergency Medicine',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryForest,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          '65% Complete',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryForest,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.spacingSm),
                    Text(
                      'Emergency Airway & Mechanical Ventilation Protocols',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingXs),
                    Text(
                      'Next: Video Lecture 4.2 - High-Flow Nasal Cannula in Hypoxemic Failure',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingMd),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                      child: const LinearProgressIndicator(
                        value: 0.65,
                        backgroundColor: AppColors.borderSubtle,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryForest),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingMd),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AppButton(
                          label: 'Resume Lesson',
                          icon: Icons.play_circle_outline_rounded,
                          isFullWidth: false,
                          height: 38,
                          onPressed: () => context.go('/courses'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.spacingLg),

              // 4. Upcoming Clinical Session / Workshop
              Text(
                'Next Scheduled Session',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppConstants.spacingSm),
              AppCard(
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.terracottaSoft,
                        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'WED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.terracotta,
                            ),
                          ),
                          Text(
                            '12',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.terracotta,
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
                            'Interactive Case Simulation',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '10:00 AM - 12:00 PM IST • Simulation Lab Hub',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.spacingLg),

              // 5. Quick Links Grid
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
                      context: context,
                      title: 'Certificates',
                      icon: Icons.card_membership_rounded,
                      onTap: () => context.push('/results'),
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingSm),
                  Expanded(
                    child: _buildQuickActionCard(
                      context: context,
                      title: 'Fee Status',
                      icon: Icons.payment_rounded,
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
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
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
    required BuildContext context,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppCard(
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

