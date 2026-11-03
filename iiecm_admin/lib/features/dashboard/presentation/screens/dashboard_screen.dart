import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../core/widgets/stat_kpi_card.dart';
import '../../../auth/domain/models/user_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../categories/presentation/widgets/category_form_sheet.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/monthly_trends_chart.dart';
import '../widgets/operational_hubs_section.dart';
import '../widgets/payment_breakdown_chart.dart';
import '../widgets/quick_actions_bar.dart';
import '../widgets/recent_activity_section.dart';

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
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.warmCream,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primaryForest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'IIECM',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Command Hub',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'Administration',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentTerracotta,
                      letterSpacing: 0.5,
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
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.primaryForest,
            ),
            onPressed: () => ref.invalidate(dashboardStatsProvider),
          ),
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(
              Icons.logout_rounded,
              color: AppColors.textSecondary,
            ),
            onPressed: () => _confirmLogout(context, ref),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryForest,
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
                  // 1. Executive Institutional Welcome Banner (Forest Green & Warm Accents)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [AppColors.darkSurface, const Color(0xFF161F1A)]
                            : [AppColors.forestDark, AppColors.primaryForest],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusLarge,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.forestDark.withValues(alpha: 0.25),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4.5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.shield_rounded,
                                    color: AppColors.warmCream,
                                    size: 13,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    admin?.role == UserRole.superAdmin
                                        ? 'SUPER ADMINISTRATOR'
                                        : 'VERIFIED ADMINISTRATOR',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 10.5,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3.5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accentTerracotta.withValues(
                                  alpha: 0.3,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.accentTerracotta.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              child: const Text(
                                'AY 2026-2027',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Welcome back, ${admin?.fullName ?? "Administrator"}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Institutional Command Hub · Oversight of academic curricula, faculty coordination, student assessments, and revenue reconciliation.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontSize: 12.5,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 2. Quick Actions Bar
                  const QuickActionsBar(),
                  const SizedBox(height: 20),

                  // 3. Core Dashboard Content (Loading / Error / Data)
                  dashboardAsync.when(
                    loading: () => _buildLoadingState(theme),
                    error: (err, stack) => _buildErrorState(context, ref, err),
                    data: (stats) =>
                        _buildDashboardData(context, ref, stats, theme),
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
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section: Core Institutional KPIs (6 Stat Cards)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Performance Telemetry',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.forestSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Live Metrics',
                style: TextStyle(
                  color: AppColors.primaryForest,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.25,
          children: [
            StatKpiCard(
              label: 'Total Students',
              value: '${stats.totalStudents}',
              icon: Icons.people_rounded,
              accentColor: AppColors.primaryForest,
              trendLabel: '${stats.activeStudents} active',
              isTrendPositive: true,
              onTap: () => context.go('/students'),
            ),
            StatKpiCard(
              label: 'Faculty Members',
              value: '${stats.totalInstructors}',
              icon: Icons.school_rounded,
              accentColor: AppColors.forestDark,
              onTap: () => context.go('/hubs'),
            ),
            StatKpiCard(
              label: 'Published Courses',
              value: '${stats.publishedCourses}',
              icon: Icons.menu_book_rounded,
              accentColor: AppColors.forestLight,
              onTap: () => context.go('/courses'),
            ),
            StatKpiCard(
              label: 'Verified Revenue',
              value: CurrencyFormatter.format(stats.verifiedRevenue),
              icon: Icons.currency_rupee_rounded,
              accentColor: AppColors.accentTerracotta,
              onTap: () => context.go('/payments'),
            ),
            StatKpiCard(
              label: 'Pending Fees',
              value: '${stats.pendingPayments}',
              icon: Icons.credit_card_rounded,
              accentColor: AppColors.warning,
              trendLabel: 'Review required',
              isTrendPositive: false,
              onTap: () => context.go('/payments'),
            ),
            StatKpiCard(
              label: 'Admissions Leads',
              value: '${stats.admissionsLeads}',
              icon: Icons.mark_chat_unread_rounded,
              accentColor: AppColors.accentTerracotta,
              trendLabel: 'Active pipeline',
              isTrendPositive: true,
              onTap: () => context.go('/hubs'),
            ),
          ],
        ),
        const SizedBox(height: 16),

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
                    color: AppColors.accentTerracotta.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.category_rounded,
                    color: AppColors.accentTerracotta,
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
        const SizedBox(height: 22),

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
        const SizedBox(height: 22),

        // Section: Operational Management Hubs
        OperationalHubsSection(stats: stats),
        const SizedBox(height: 22),

        // Section: Recent Activity & Live Classes
        RecentActivitySection(stats: stats),
      ],
    );
  }
}
