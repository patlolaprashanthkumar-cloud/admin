import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
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
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton.icon(
              onPressed: () => context.go('/students'),
              label: const Text('View All'),
              icon: const Icon(Icons.arrow_forward_rounded, size: 14),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: AppColors.primaryForest,
              ),
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
                        backgroundColor: AppColors.forestSoft,
                        child: Text(
                          student.fullName.isNotEmpty ? student.fullName[0].toUpperCase() : 'S',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryForest,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      title: Text(
                        student.fullName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${student.studentId} · ${student.preferredCategory}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.forestSoft
                              : const Color(0xFFF1F1ED),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isActive
                                ? AppColors.primaryForest.withValues(alpha: 0.2)
                                : AppColors.borderNeutral,
                          ),
                        ),
                        child: Text(
                          student.accountStatus,
                          style: TextStyle(
                            color: isActive ? AppColors.primaryForest : AppColors.textSecondary,
                            fontWeight: FontWeight.w800,
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
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton.icon(
              onPressed: () => context.go('/courses'),
              label: const Text('Curricula'),
              icon: const Icon(Icons.arrow_forward_rounded, size: 14),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: AppColors.primaryForest,
              ),
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
                          color: AppColors.terracottaSoft,
                          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                        ),
                        child: const Icon(Icons.auto_stories_rounded, size: 18, color: AppColors.accentTerracotta),
                      ),
                      title: Text(
                        item.courseTitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        item.studentName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      trailing: Text(
                        AppDateFormatter.formatDate(item.enrolledAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
        ),

        // 3. Upcoming Clinical Lectures & Live Classes
        if (stats.upcomingLiveClasses.isNotEmpty) ...[
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Upcoming Clinical Classes',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton.icon(
                onPressed: () => context.go('/hubs'),
                label: const Text('Schedule'),
                icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: AppColors.primaryForest,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AppCard(
            padding: EdgeInsets.zero,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: stats.upcomingLiveClasses.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final lecture = stats.upcomingLiveClasses[index];

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.forestSoft,
                      borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                    ),
                    child: const Icon(Icons.video_camera_front_rounded, size: 18, color: AppColors.primaryForest),
                  ),
                  title: Text(
                    lecture.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${lecture.courseName} · ${lecture.instructorName}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warmCream,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderNeutral),
                    ),
                    child: Text(
                      AppDateFormatter.formatDate(lecture.scheduledAt),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, {required IconData icon, required String message}) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 36, color: AppColors.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
