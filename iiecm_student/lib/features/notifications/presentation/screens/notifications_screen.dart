import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/models/student_notification.dart';
import '../providers/notifications_provider.dart';
import '../providers/notifications_state.dart';
import '../widgets/notification_card.dart';

/// Institutional Bulletins & Notifications Screen
///
/// Designed in accordance with the IIECM Modern Academic design language:
/// Deep institutional navy, secondary teal, warm off-white surfaces,
/// refined filter chips strip, live unread counter, responsive empty/error states,
/// and structured institutional bulletin cards.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(notificationsNotifierProvider);
    final notifier = ref.read(notificationsNotifierProvider.notifier);

    final unreadCount = state.unreadCount;
    final filteredList = state.filteredNotifications;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.backgroundWarmOffWhite,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.darkSurface
            : AppColors.backgroundWarmOffWhite,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: Row(
          children: [
            // Institutional Brand Emblem
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceElevated
                    : AppColors.forestSoft,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryNavy.withValues(alpha: 0.2),
                  width: 1.2,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.campaign_rounded,
                  color: AppColors.primaryNavy,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Bulletins & Notifications',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            letterSpacing: -0.2,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.terracotta.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.terracotta.withValues(
                                alpha: 0.35,
                              ),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(
                              color: AppColors.terracotta,
                              fontWeight: FontWeight.w800,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    unreadCount > 0
                        ? '$unreadCount unread institutional alert${unreadCount > 1 ? 's' : ''}'
                        : 'All official notices up to date',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
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
        actions: [
          if (unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                icon: const Icon(Icons.done_all_rounded, size: 15),
                label: const Text('Mark All Read'),
                style: TextButton.styleFrom(
                  foregroundColor: isDark
                      ? AppColors.accentOrangeLight
                      : AppColors.primaryNavy,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                onPressed: () => notifier.markAllAsRead(),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Category Filter Chips
            _buildFilterBar(context, ref, state),

            Divider(
              height: 1,
              color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
            ),

            // Content Area
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primaryNavy,
                backgroundColor: isDark
                    ? AppColors.darkSurface
                    : AppColors.white,
                onRefresh: () async {
                  await notifier.loadNotifications(isRefresh: true);
                },
                child: state.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryNavy,
                        ),
                      )
                    : state.hasError
                    ? _buildErrorView(context, ref, state.errorMessage)
                    : filteredList.isEmpty
                    ? _buildEmptyView(context, state)
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(AppConstants.spacingMd),
                        itemCount: filteredList.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppConstants.spacingSm),
                        itemBuilder: (context, index) {
                          final item = filteredList[index];
                          final isRead = state.isNotificationRead(item);
                          return NotificationCard(
                            key: Key('notification_${item.id}'),
                            notification: item,
                            isRead: isRead,
                            onMarkAsRead: () => notifier.markAsRead(item),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(
    BuildContext context,
    WidgetRef ref,
    NotificationsState state,
  ) {
    final notifier = ref.read(notificationsNotifierProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate category counts
    final allCount = state.notifications.length;
    final unreadCount = state.unreadCount;
    final academicCount = state.notifications
        .where(
          (n) =>
              n.type == NotificationType.course ||
              n.type == NotificationType.liveClass ||
              n.type == NotificationType.instructor,
        )
        .length;
    final financialCount = state.notifications
        .where((n) => n.type == NotificationType.payment)
        .length;
    final systemCount = state.notifications
        .where(
          (n) =>
              n.type == NotificationType.system ||
              n.type == NotificationType.student,
        )
        .length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd,
        vertical: 10,
      ),
      child: Row(
        children: [
          _buildFilterChip(
            label: 'All ($allCount)',
            isSelected: state.selectedCategory == NotificationCategory.all,
            onSelected: () => notifier.selectCategory(NotificationCategory.all),
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Unread ($unreadCount)',
            isSelected: state.selectedCategory == NotificationCategory.unread,
            onSelected: () =>
                notifier.selectCategory(NotificationCategory.unread),
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Curriculum & Classes',
            count: academicCount,
            isSelected: state.selectedCategory == NotificationCategory.academic,
            onSelected: () =>
                notifier.selectCategory(NotificationCategory.academic),
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Fee & Receipts',
            count: financialCount,
            isSelected: state.selectedCategory == NotificationCategory.payments,
            onSelected: () =>
                notifier.selectCategory(NotificationCategory.payments),
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Institutional Alerts',
            count: systemCount,
            isSelected: state.selectedCategory == NotificationCategory.system,
            onSelected: () =>
                notifier.selectCategory(NotificationCategory.system),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    int? count,
    required bool isSelected,
    required VoidCallback onSelected,
    required bool isDark,
    bool isWarningBadge = false,
  }) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : (isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary),
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.22)
                    : (isWarningBadge
                          ? AppColors.terracotta.withValues(alpha: 0.12)
                          : (isDark
                                ? AppColors.darkSurfaceElevated
                                : AppColors.forestSoft)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: isSelected
                      ? Colors.white
                      : (isWarningBadge
                            ? AppColors.terracotta
                            : (isDark
                                  ? AppColors.accentOrangeLight
                                  : AppColors.primaryNavy)),
                ),
              ),
            ),
          ],
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
      selectedColor: isDark
          ? AppColors.darkSurfaceElevated
          : AppColors.primaryNavy,
      checkmarkColor: Colors.white,
      showCheckmark: false,
      elevation: 0,
      pressElevation: 0,
      side: BorderSide(
        color: isSelected
            ? (isDark ? AppColors.accentOrangeLight : AppColors.primaryNavy)
            : (isDark ? AppColors.darkBorder : AppColors.borderSubtle),
        width: isSelected ? 1.2 : 1.0,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, WidgetRef ref, String? message) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final notifier = ref.read(notificationsNotifierProvider.notifier);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: AppCard(
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
          borderColor: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
          borderRadius: AppConstants.radiusLg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.terracotta.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 36,
                  color: AppColors.terracotta,
                ),
              ),
              const SizedBox(height: AppConstants.spacingMd),
              Text(
                'Unable to Load Bulletins',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppConstants.spacingSm),
              Text(
                message ?? 'Could not synchronize with the registry bulletin database.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppConstants.spacingMd),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text(
                  'Try Again',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                onPressed: () => notifier.loadNotifications(isRefresh: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyView(BuildContext context, NotificationsState state) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isUnreadCategory =
        state.selectedCategory == NotificationCategory.unread;
    final title = isUnreadCategory
        ? 'All Bulletins Read'
        : 'No Bulletins Found';
    final subtitle = isUnreadCategory
        ? 'You have reviewed all official notifications and reminders.'
        : 'There are currently no institutional bulletins or announcements matching your filter.';

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      children: [
        const SizedBox(height: 50),
        Center(
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceElevated
                  : AppColors.forestSoft,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primaryNavy.withValues(alpha: 0.15),
                width: 1.5,
              ),
            ),
            child: Icon(
              isUnreadCategory
                  ? Icons.mark_email_read_outlined
                  : Icons.notifications_none_rounded,
              size: 46,
              color: AppColors.primaryNavy,
            ),
          ),
        ),
        const SizedBox(height: AppConstants.spacingLg),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppConstants.spacingSm),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
