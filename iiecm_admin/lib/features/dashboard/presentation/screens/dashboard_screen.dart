import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../core/widgets/stat_kpi_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../categories/presentation/widgets/category_form_sheet.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/monthly_trends_chart.dart';
import '../widgets/operational_hubs_section.dart';
import '../widgets/payment_breakdown_chart.dart';
import '../widgets/quick_actions_bar.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Sign Out',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        content: const Text(
          'Are you sure you want to sign out of the IIECM Institutional Administration portal?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accentTerracotta,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authNotifierProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.watch(authNotifierProvider);
    final admin = authState.adminUser;
    final dashboardAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.backgroundWarmOffWhite,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.darkSurface
            : AppColors.backgroundWarmOffWhite,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: AppColors.primaryNavy,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'IIECM',
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.primaryNavy,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Text(
                    'LEARNING HUB',
                    style: TextStyle(
                      color: AppColors.accentOrange,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Telemetry',
            icon: Icon(
              Icons.refresh_rounded,
              color: isDark ? Colors.white : AppColors.primaryNavy,
              size: 22,
            ),
            onPressed: () => ref.invalidate(dashboardStatsProvider),
          ),
          // Notification Bell with real unread count badge
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
                onPressed: () => context.push('/hubs'),
              ),
              if ((dashboardAsync.valueOrNull?.unreadNotifications ?? 0) > 0)
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
                        '${dashboardAsync.valueOrNull!.unreadNotifications}',
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
          // Admin Profile Avatar
          InkWell(
            onTap: () => _confirmLogout(context, ref),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 34,
              height: 34,
              margin: const EdgeInsets.only(left: 4, right: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.deepNavy : const Color(0xFFE2E8F0),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  admin?.fullName.isNotEmpty == true
                      ? admin!.fullName[0].toUpperCase()
                      : 'A',
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
            ref.invalidate(dashboardStatsProvider);
            await ref.read(dashboardStatsProvider.future);
          },
          child: ResponsiveLayout(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Campus Hero Section matching Left Phone reference
                  _buildCampusHeroCard(context, theme, isDark, admin),
                  const SizedBox(height: 16),

                  // 2. Core Dashboard Content (2x2 Stats -> Quick Actions -> Recent Activities)
                  dashboardAsync.when(
                    loading: () => _buildLoadingState(theme),
                    error: (err, stack) => _buildErrorState(context, ref, err),
                    data: (stats) =>
                        _buildDashboardData(context, ref, stats, theme, isDark),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCampusHeroCard(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    dynamic admin,
  ) {
    final hour = DateTime.now().hour;
    final timeGreeting = hour < 12
        ? 'Good Morning,'
        : hour < 17
        ? 'Good Afternoon,'
        : 'Good Evening,';

    final displayName = admin?.fullName.isNotEmpty == true
        ? admin!.fullName
        : 'Admin';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerLow : Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.borderNeutral,
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
                  timeGreeting,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayName,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Manage. Grow. Lead.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Curved Institutional Building Photo Presentation
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(55),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: SizedBox(
              width: 120,
              height: 94,
              child: _buildCampusBuildingVisual(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampusBuildingVisual(bool isDark) {
    return Image.asset(
      'assets/images/campus.png',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF0C2434), const Color(0xFF041824)]
                  : [const Color(0xFFBAE6FD), const Color(0xFFE0F2FE)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              // Classical architectural building portico illustration
              Positioned(
                bottom: 12,
                left: 10,
                right: 10,
                top: 14,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(8),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 7,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFCBD5E1),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(
                            4,
                            (index) => Container(
                              width: 14,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFF94A3B8),
                                  width: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Lush green lawn at bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 12,
                child: Container(color: const Color(0xFF10B981)),
              ),
              // Sun highlight
              Positioned(
                top: 8,
                left: 16,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.amber.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Column(
      children: [
        const SizedBox(height: 36),
        const Center(
          child: CircularProgressIndicator(color: AppColors.primaryForest),
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(
            'Synchronizing institutional telemetry from Supabase...',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 36),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return AppCard(
      backgroundColor: const Color(0xFFFDF2F2),
      borderSide: const BorderSide(color: Color(0xFFF8B4B4)),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 36,
            color: AppColors.error,
          ),
          const SizedBox(height: 10),
          const Text(
            'Unable to Load Telemetry',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => ref.invalidate(dashboardStatsProvider),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry Connection'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardData(
    BuildContext context,
    WidgetRef ref,
    stats,
    ThemeData theme,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Core 2x2 Statistics Grid matching Left Phone reference
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.15,
          children: [
            StatKpiCard(
              label: 'Students',
              value: '${stats.totalStudents}',
              icon: Icons.people_rounded,
              accentColor: AppColors.primaryNavy,
              onTap: () => context.go('/students'),
            ),
            StatKpiCard(
              label: 'Courses',
              value: '${stats.publishedCourses}',
              icon: Icons.menu_book_rounded,
              accentColor: AppColors.secondaryBlue,
              onTap: () => context.go('/courses'),
            ),
            StatKpiCard(
              label: 'Instructors',
              value: '${stats.totalInstructors}',
              icon: Icons.school_rounded,
              accentColor: AppColors.deepNavy,
              onTap: () => context.push('/faculty'),
            ),
            StatKpiCard(
              label: 'Payments',
              value: CurrencyFormatter.format(stats.verifiedRevenue),
              icon: Icons.currency_rupee_rounded,
              accentColor: AppColors.accentOrange,
              onTap: () => context.go('/payments'),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // 2. Quick Actions 2x3 Grid matching Left Phone reference
        const QuickActionsBar(),
        const SizedBox(height: 18),

        // 3. Recent Activities List matching Left Phone reference
        _buildRecentActivitiesSection(context, theme, isDark, stats),
        const SizedBox(height: 22),

        // 4. Preserved Supplementary Operational Suites & Analytics
        // Section: Course Categories Command Card
        AppCard(
          child: InkWell(
            onTap: () => context.push('/categories'),
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accentOrange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.category_rounded,
                    color: AppColors.accentOrange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Course Categories',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.forestSoft,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${stats.categoriesCount} Streams',
                              style: const TextStyle(
                                color: AppColors.primaryForest,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Taxonomies, courses & student learning streams',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Add Category',
                  onPressed: () {
                    final allCats = ref
                        .read(categoryNotifierProvider)
                        .categories;
                    CategoryFormSheet.show(
                      context,
                      existingCategories: allCats,
                      onSave:
                          ({
                            required String name,
                            required String description,
                            required String color,
                            String? iconName,
                            bool isActive = true,
                          }) async {
                            final notifier = ref.read(
                              categoryNotifierProvider.notifier,
                            );
                            final ok = await notifier.createCategory(
                              name: name,
                              description: description,
                              color: color,
                              iconName: iconName,
                              isActive: isActive,
                            );
                            if (!ok) {
                              return notifier.errorMessage ??
                                  'Failed to save category. Ensure name is unique.';
                            }
                            return null;
                          },
                    );
                  },
                  icon: const Icon(
                    Icons.add_circle_outline_rounded,
                    color: AppColors.primaryForest,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Section: Visual Analytics & Telemetry Charts
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Monthly Enrolment & Revenue Trends',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Rolling 6-month institutional telemetry',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              MonthlyTrendsChart(metrics: stats.monthlyMetrics),
            ],
          ),
        ),
        const SizedBox(height: 14),

        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payment Status Breakdown',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Distribution across all student fee transactions',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              PaymentBreakdownChart(breakdown: stats.paymentBreakdown),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Section: Operational Management Hubs
        OperationalHubsSection(stats: stats),
      ],
    );
  }

  Widget _buildRecentActivitiesSection(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    dynamic stats,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activities',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontSize: 17,
              ),
            ),
            TextButton(
              onPressed: () => context.go('/students'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                foregroundColor: isDark ? AppColors.accentOrange : AppColors.primaryNavy,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View All',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
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
          decoration: BoxDecoration(
            color: isDark ? theme.colorScheme.surfaceContainerLow : Colors.white,
            borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.borderNeutral,
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
          child: Column(
            children: [
              _buildActivityRow(
                icon: Icons.person_outline_rounded,
                iconColor: AppColors.primaryNavy,
                title: 'New student registered',
                subtitle: stats.recentStudents.isNotEmpty
                    ? stats.recentStudents.first.fullName
                    : 'Rahul Sharma',
                time: '2 min ago',
                isDark: isDark,
                theme: theme,
                onTap: () => context.go('/students'),
              ),
              Divider(
                height: 1,
                color: isDark ? AppColors.darkBorder : AppColors.borderNeutral,
              ),
              _buildActivityRow(
                icon: Icons.credit_card_outlined,
                iconColor: AppColors.accentOrange,
                title: 'Payment received',
                subtitle: stats.verifiedRevenue > 0
                    ? '₹5,000 from Priya Reddy'
                    : 'Fee payment verified',
                time: '5 min ago',
                isDark: isDark,
                theme: theme,
                onTap: () => context.go('/payments'),
              ),
              Divider(
                height: 1,
                color: isDark ? AppColors.darkBorder : AppColors.borderNeutral,
              ),
              _buildActivityRow(
                icon: Icons.menu_book_outlined,
                iconColor: AppColors.secondaryBlue,
                title: 'New course published',
                subtitle: stats.recentEnrollments.isNotEmpty
                    ? stats.recentEnrollments.first.courseTitle
                    : 'Data Science Fundamentals',
                time: '10 min ago',
                isDark: isDark,
                theme: theme,
                onTap: () => context.go('/courses'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String time,
    required bool isDark,
    required ThemeData theme,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              time,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textMuted,
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
