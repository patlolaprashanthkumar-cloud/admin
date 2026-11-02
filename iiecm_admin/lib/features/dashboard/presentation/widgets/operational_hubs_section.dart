import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/models/dashboard_stats.dart';

class OperationalHubsSection extends StatelessWidget {
  final DashboardStats stats;

  const OperationalHubsSection({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final hubs = [
      (
        title: 'Assessments & Exams',
        subtitle: '${stats.activeAssessments} Active evaluations',
        badge: '${stats.activeAssessments} Tests',
        icon: Icons.assignment_turned_in_rounded,
        color: AppColors.primaryForest,
        bgColor: AppColors.forestSoft,
        route: '/hubs',
      ),
      (
        title: 'Curriculum Taxonomies',
        subtitle: '${stats.categoriesCount} Subject streams configured',
        badge: '${stats.categoriesCount} Streams',
        icon: Icons.category_rounded,
        color: AppColors.accentTerracotta,
        bgColor: AppColors.terracottaSoft,
        route: '/hubs',
      ),
      (
        title: 'Career & Mentorship',
        subtitle: '${stats.careerAppointmentsCount} Active advisory sessions',
        badge: '${stats.careerAppointmentsCount} Sessions',
        icon: Icons.explore_rounded,
        color: AppColors.forestLight,
        bgColor: AppColors.forestSoft,
        route: '/hubs',
      ),
      (
        title: 'Digital Resource Library',
        subtitle: '${stats.resourcesCount} Syllabi, decks & assets',
        badge: '${stats.resourcesCount} Assets',
        icon: Icons.folder_special_rounded,
        color: AppColors.forestDark,
        bgColor: AppColors.forestSoft,
        route: '/hubs',
      ),
      (
        title: 'Admissions CRM',
        subtitle: '${stats.admissionsLeads} Prospective leads in pipeline',
        badge: '${stats.admissionsLeads} Leads',
        icon: Icons.forum_rounded,
        color: AppColors.terracottaDark,
        bgColor: AppColors.terracottaSoft,
        route: '/hubs',
      ),
      (
        title: 'Campus Broadcasts',
        subtitle: '${stats.unreadNotifications} Unread dispatches',
        badge: '${stats.unreadNotifications} Notices',
        icon: Icons.campaign_rounded,
        color: AppColors.warning,
        bgColor: const Color(0xFFFEF3C7),
        route: '/hubs',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryForest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.layers_rounded, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Text(
                  'Operational Hubs',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.forestSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '6 Suites',
                style: TextStyle(
                  color: AppColors.primaryForest,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.38,
          ),
          itemCount: hubs.length,
          itemBuilder: (context, index) {
            final h = hubs[index];
            return _buildHubTile(context, h);
          },
        ),
      ],
    );
  }

  Widget _buildHubTile(
    BuildContext context,
    ({String title, String subtitle, String badge, IconData icon, Color color, Color bgColor, String route}) hub,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark ? theme.colorScheme.surfaceContainerLow : Colors.white,
      borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
      child: InkWell(
        onTap: () => context.go(hub.route),
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.borderNeutral,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark ? hub.color.withValues(alpha: 0.2) : hub.bgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(hub.icon, size: 17, color: hub.color),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? hub.color.withValues(alpha: 0.15) : hub.bgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      hub.badge,
                      style: TextStyle(
                        color: hub.color,
                        fontWeight: FontWeight.w800,
                        fontSize: 9.5,
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hub.title,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hub.subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
