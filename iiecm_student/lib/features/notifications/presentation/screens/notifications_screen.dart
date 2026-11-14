import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/models/student_notification.dart';
import '../providers/notifications_provider.dart';
import '../providers/notifications_state.dart';
import '../widgets/notification_card.dart';

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
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bulletins & Notifications'),
            Text(
              unreadCount > 0
                  ? '$unreadCount unread institutional alert${unreadCount > 1 ? 's' : ''}'
                  : 'All bulletins caught up',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          if (unreadCount > 0)
            TextButton.icon(
              icon: const Icon(Icons.done_all_rounded, size: 16),
              label: const Text('Mark All Read'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryForest,
                textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              ),
              onPressed: () => notifier.markAllAsRead(),
            ),
          const SizedBox(width: AppConstants.spacingSm),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Category Filter Chips
            _buildFilterBar(context, ref, state),

            const Divider(height: 1),

            // Content Area
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primaryForest,
                onRefresh: () async {
                  await notifier.loadNotifications(isRefresh: true);
                },
                child: state.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.primaryForest),
                      )
                    : state.hasError
                        ? _buildErrorView(context, ref, state.errorMessage)
                        : filteredList.isEmpty
                            ? _buildEmptyView(context, state)
                            : ListView.separated(
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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd,
        vertical: AppConstants.spacingSm,
      ),
      child: Row(
        children: [
          _buildFilterChip(
            label: 'All (${state.notifications.length})',
            isSelected: state.selectedCategory == NotificationCategory.all,
            onSelected: () => notifier.selectCategory(NotificationCategory.all),
          ),
          const SizedBox(width: AppConstants.spacingSm),
          _buildFilterChip(
            label: 'Unread (${state.unreadCount})',
            isSelected: state.selectedCategory == NotificationCategory.unread,
            onSelected: () => notifier.selectCategory(NotificationCategory.unread),
          ),
          const SizedBox(width: AppConstants.spacingSm),
          _buildFilterChip(
            label: 'Curriculum & Classes',
            isSelected: state.selectedCategory == NotificationCategory.academic,
            onSelected: () => notifier.selectCategory(NotificationCategory.academic),
          ),
          const SizedBox(width: AppConstants.spacingSm),
          _buildFilterChip(
            label: 'Fee & Receipts',
            isSelected: state.selectedCategory == NotificationCategory.payments,
            onSelected: () => notifier.selectCategory(NotificationCategory.payments),
          ),
          const SizedBox(width: AppConstants.spacingSm),
          _buildFilterChip(
            label: 'Institutional Alerts',
            isSelected: state.selectedCategory == NotificationCategory.system,
            onSelected: () => notifier.selectCategory(NotificationCategory.system),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      backgroundColor: Colors.transparent,
      selectedColor: AppColors.forestSoft,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? AppColors.primaryForest : null,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
        side: BorderSide(
          color: isSelected ? AppColors.primaryForest : Colors.grey.shade300,
        ),
      ),
      showCheckmark: false,
    );
  }

  Widget _buildErrorView(BuildContext context, WidgetRef ref, String? message) {
    final theme = Theme.of(context);
    final notifier = ref.read(notificationsNotifierProvider.notifier);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: AppCard(
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: AppColors.terracotta,
              ),
              const SizedBox(height: AppConstants.spacingMd),
              Text(
                'Unable to Load Bulletins',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppConstants.spacingSm),
              Text(
                message ?? 'Could not synchronize with the registry bulletin database.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: AppConstants.spacingMd),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryForest,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
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

    final isUnreadCategory = state.selectedCategory == NotificationCategory.unread;
    final title = isUnreadCategory ? 'All Bulletins Read' : 'No Bulletins Found';
    final subtitle = isUnreadCategory
        ? 'You have reviewed all official notifications and reminders.'
        : 'There are currently no institutional bulletins or announcements matching your filter.';

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      children: [
        const SizedBox(height: 60),
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceElevated : AppColors.forestSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isUnreadCategory
                  ? Icons.mark_email_read_outlined
                  : Icons.notifications_none_rounded,
              size: 48,
              color: AppColors.primaryForest,
            ),
          ),
        ),
        const SizedBox(height: AppConstants.spacingLg),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppConstants.spacingSm),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
