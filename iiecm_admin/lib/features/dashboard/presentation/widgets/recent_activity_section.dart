import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/models/dashboard_stats.dart';

class RecentActivitySection extends StatelessWidget {
  final DashboardStats stats;

  const RecentActivitySection({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Recent Student Registrations
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Registrations',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton.icon(
              onPressed: () => context.go('/students'),
              label: const Text('View All'),
              icon: const Icon(Icons.arrow_forward_rounded, size: 14),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AppCard(
          padding: EdgeInsets.zero,
          child: stats.recentStudents.isEmpty
              ? _buildEmptyState(
                  context,
                  icon: Icons.person_off_rounded,
                  message: 'No student registrations recorded yet.',
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: stats.recentStudents.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final student = stats.recentStudents[index];
                    final isActive = student.accountStatus == 'active';

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFF0F2744).withValues(alpha: 0.1),
                        child: Text(
                          student.fullName.isNotEmpty ? student.fullName[0].toUpperCase() : 'S',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F2744),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      title: Text(
                        student.fullName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${student.studentId} · ${student.preferredCategory}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF10B981).withValues(alpha: 0.12)
                              : const Color(0xFF94A3B8).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          student.accountStatus,
                          style: TextStyle(
                            color: isActive ? const Color(0xFF047857) : const Color(0xFF475569),
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 24),

        // 2. Recent Enrolments
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Enrolments',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton.icon(
              onPressed: () => context.go('/courses'),
              label: const Text('Curricula'),
              icon: const Icon(Icons.arrow_forward_rounded, size: 14),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AppCard(
          padding: EdgeInsets.zero,
          child: stats.recentEnrollments.isEmpty
              ? _buildEmptyState(
                  context,
                  icon: Icons.menu_book_rounded,
                  message: 'No course enrolments recorded yet.',
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: stats.recentEnrollments.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = stats.recentEnrollments[index];

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF028090).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                        ),
                        child: const Icon(Icons.auto_stories_rounded, size: 18, color: Color(0xFF028090)),
                      ),
                      title: Text(
                        item.courseTitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        item.studentName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                      trailing: Text(
                        AppDateFormatter.formatDate(item.enrolledAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, {required IconData icon, required String message}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 36, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
