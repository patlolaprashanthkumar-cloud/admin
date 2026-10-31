import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
        title: 'Assessments & Examinations',
        subtitle: '${stats.activeAssessments} Active / Scheduled evaluations',
        badge: '${stats.activeAssessments} Tests',
        icon: Icons.assignment_turned_in_rounded,
        color: const Color(0xFF064B3E),
        route: '/hubs',
      ),
      (
        title: 'Curriculum Taxonomies',
        subtitle: '${stats.categoriesCount} Subject streams configured',
        badge: '${stats.categoriesCount} Categories',
        icon: Icons.category_rounded,
        color: const Color(0xFFF59E0B),
        route: '/hubs',
      ),
      (
        title: 'Career Guidance & Pathways',
        subtitle: '${stats.careerAppointmentsCount} Active advisory mentorships',
        badge: '${stats.careerAppointmentsCount} Sessions',
        icon: Icons.explore_rounded,
        color: const Color(0xFFFF8E53),
        route: '/hubs',
      ),
      (
        title: 'Digital Resource Library',
        subtitle: '${stats.resourcesCount} Syllabi, slide decks & clinical files',
        badge: '${stats.resourcesCount} Assets',
        icon: Icons.folder_special_rounded,
        color: const Color(0xFF0F2744),
        route: '/hubs',
      ),
      (
        title: 'Admissions CRM & Inquiries',
        subtitle: '${stats.admissionsLeads} Prospective leads in pipeline',
        badge: '${stats.admissionsLeads} Active Leads',
        icon: Icons.forum_rounded,
        color: const Color(0xFF028090),
        route: '/hubs',
      ),
      (
        title: 'Campus Broadcasts & Alerts',
        subtitle: '${stats.unreadNotifications} Unread administrative dispatches',
        badge: '${stats.unreadNotifications} Unread',
        icon: Icons.campaign_rounded,
        color: const Color(0xFFE63946),
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
                    color: const Color(0xFF064B3E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.layers_rounded, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Text(
                  'Operational Hubs',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF064B3E).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '6 Suites',
                style: TextStyle(
                  color: Color(0xFF064B3E),
                  fontWeight: FontWeight.w700,
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
            childAspectRatio: 1.35,
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
    ({String title, String subtitle, String badge, IconData icon, Color color, String route}) hub,
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
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: 1,
            ),
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
                      color: hub.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(hub.icon, size: 18, color: hub.color),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: hub.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      hub.badge,
                      style: TextStyle(
                        color: hub.color,
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
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
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hub.subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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

