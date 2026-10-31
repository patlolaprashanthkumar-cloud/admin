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
        title: const Text('Log Out'),
        content: const Text(
          'Are you sure you want to log out of the IIECM Admin portal?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Log Out'),
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
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'IIECM',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                'Command Hub',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Telemetry',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(dashboardStatsProvider),
          ),
          IconButton(
            tooltip: 'Log Out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _confirmLogout(context, ref),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardStatsProvider);
            await ref.read(dashboardStatsProvider.future);
          },
          child: ResponsiveLayout(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Executive Institutional Welcome Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF132A46), const Color(0xFF0F1E33)]
                            : [const Color(0xFF0F2744), const Color(0xFF163E66)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
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
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    admin?.role == UserRole.superAdmin
                                        ? 'SUPER ADMINISTRATOR'
                                        : 'VERIFIED ADMINISTRATOR',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'AY 2026-2027',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Welcome, ${admin?.fullName ?? "Administrator"}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Institutional Command Hub · Oversight of academic curricula, faculty coordination, student assessments, and revenue reconciliation.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. Quick Actions Bar
                  const QuickActionsBar(),
                  const SizedBox(height: 20),

                  // 3. Core Dashboard Content (Loading / Error / Data)
                  dashboardAsync.when(
                    loading: () => _buildLoadingState(theme),
                    error: (err, stack) => _buildErrorState(context, ref, err),
                    data: (stats) => _buildDashboardData(context, stats, theme),
                  ),
                  const SizedBox(height: 32),
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
        const SizedBox(height: 40),
        const Center(
          child: CircularProgressIndicator(),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'Synchronizing institutional telemetry from Supabase...',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    final theme = Theme.of(context);
    return AppCard(
      backgroundColor: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, size: 40, color: theme.colorScheme.error),
          const SizedBox(height: 10),
          Text(
            'Unable to Load Institutional Telemetry',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => ref.refresh(dashboardStatsProvider),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry Connection'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardData(BuildContext context, stats, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section: Core Institutional KPIs (6 Stat Cards)
        Text(
          'Institutional Performance Telemetry',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.25,
          children: [
            StatKpiCard(
              label: 'Total Students',
              value: '${stats.totalStudents}',
              icon: Icons.people_rounded,
              accentColor: AppColors.primaryNavy,
              trendLabel: '${stats.activeStudents} active',
              isTrendPositive: true,
              onTap: () => context.go('/students'),
            ),
            StatKpiCard(
              label: 'Faculty Members',
              value: '${stats.totalInstructors}',
              icon: Icons.school_rounded,
              accentColor: const Color(0xFF064B3E),
              onTap: () => context.go('/hubs'),
            ),
            StatKpiCard(
              label: 'Published Courses',
              value: '${stats.publishedCourses}',
              icon: Icons.menu_book_rounded,
              accentColor: AppColors.secondaryTeal,
              onTap: () => context.go('/courses'),
            ),
            StatKpiCard(
              label: 'Verified Revenue',
              value: CurrencyFormatter.format(stats.verifiedRevenue),
              icon: Icons.currency_rupee_rounded,
              accentColor: const Color(0xFF10B981),
              onTap: () => context.go('/payments'),
            ),
            StatKpiCard(
              label: 'Pending Fees',
              value: '${stats.pendingPayments}',
              icon: Icons.credit_card_rounded,
              accentColor: AppColors.accentAmber,
              trendLabel: 'Review required',
              isTrendPositive: false,
              onTap: () => context.go('/payments'),
            ),
            StatKpiCard(
              label: 'Admissions Leads',
              value: '${stats.admissionsLeads}',
              icon: Icons.mark_chat_unread_rounded,
              accentColor: const Color(0xFFFF8E53),
              trendLabel: 'Active pipeline',
              isTrendPositive: true,
              onTap: () => context.go('/hubs'),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Section: Visual Analytics & Telemetry Charts
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Monthly Enrolment & Revenue Trends',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Rolling 6-month institutional telemetry',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              MonthlyTrendsChart(metrics: stats.monthlyMetrics),
            ],
          ),
        ),
        const SizedBox(height: 16),

        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payment Status Breakdown',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Distribution across all student fee transactions',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              PaymentBreakdownChart(breakdown: stats.paymentBreakdown),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Section: Operational Management Hubs
        OperationalHubsSection(stats: stats),
        const SizedBox(height: 24),

        // Section: Recent Registrations & Enrolments
        RecentActivitySection(stats: stats),
      ],
    );
  }
}
