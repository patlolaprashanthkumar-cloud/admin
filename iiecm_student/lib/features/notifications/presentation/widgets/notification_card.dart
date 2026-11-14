import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/models/student_notification.dart';

class NotificationCard extends StatelessWidget {
  final StudentNotification notification;
  final bool isRead;
  final VoidCallback onMarkAsRead;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.isRead,
    required this.onMarkAsRead,
  });

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.course:
        return Icons.menu_book_rounded;
      case NotificationType.liveClass:
        return Icons.event_available_rounded;
      case NotificationType.payment:
        return Icons.receipt_long_rounded;
      case NotificationType.instructor:
        return Icons.person_outline_rounded;
      case NotificationType.student:
        return Icons.account_circle_outlined;
      case NotificationType.system:
        return Icons.campaign_outlined;
    }
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.course:
        return AppColors.primaryForest;
      case NotificationType.liveClass:
        return const Color(0xFF1565C0); // Blue
      case NotificationType.payment:
        return AppColors.terracotta;
      case NotificationType.instructor:
        return const Color(0xFF6A1B9A); // Purple
      case NotificationType.student:
        return AppColors.primaryForest;
      case NotificationType.system:
        return const Color(0xFFE65100); // Deep Orange
    }
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1 && now.day == dt.day) {
      return 'Today at ${DateFormat('h:mm a').format(dt)}';
    } else if (difference.inDays < 2 && now.day - dt.day == 1) {
      return 'Yesterday at ${DateFormat('h:mm a').format(dt)}';
    } else {
      return DateFormat('MMM d, yyyy • h:mm a').format(dt);
    }
  }

  void _handleAction(BuildContext context) {
    if (!isRead) {
      onMarkAsRead();
    }

    final actionUrl = notification.actionUrl?.trim();
    if (actionUrl != null && actionUrl.isNotEmpty) {
      if (actionUrl.startsWith('/')) {
        context.push(actionUrl);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final typeColor = _getTypeColor(notification.type);
    final formattedTime = _formatTimestamp(notification.createdAt);

    return AppCard(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      borderColor: !isRead
          ? AppColors.primaryForest.withValues(alpha: 0.4)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Category, Priority, and Read Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Type Icon Badge
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getTypeIcon(notification.type),
                  size: 16,
                  color: typeColor,
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),

              // Category Label and Priority Pill wrapped flexibly
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Text(
                      notification.type.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: typeColor,
                      ),
                    ),
                    if (notification.priority == NotificationPriority.high)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.terracottaSoft,
                          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                          border: Border.all(
                            color: AppColors.terracotta.withValues(alpha: 0.5),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.priority_high_rounded,
                              size: 10,
                              color: AppColors.terracotta,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              notification.priority.label.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.terracotta,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (notification.priority == NotificationPriority.medium)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.warningSoft,
                          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                          border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.5),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          notification.priority.label.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Unread Indicator Dot
              if (!isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryForest,
                    shape: BoxShape.circle,
                  ),
                ),

              // Timestamp
              Text(
                formattedTime,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppConstants.spacingSm),

          // Notification Title
          Text(
            notification.title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
            ),
          ),

          const SizedBox(height: 4),

          // Notification Message Body
          Text(
            notification.message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.textPrimary,
              fontSize: 13,
              height: 1.4,
            ),
          ),

          // Action URL button / Mark as read row
          if ((notification.actionUrl != null && notification.actionUrl!.isNotEmpty) || !isRead) ...[
            const SizedBox(height: AppConstants.spacingSm),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isRead)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.check_rounded, size: 14),
                    label: const Text(
                      'Mark Read',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    onPressed: onMarkAsRead,
                  ),
                if (notification.actionUrl != null &&
                    notification.actionUrl!.trim().isNotEmpty) ...[
                  const SizedBox(width: AppConstants.spacingSm),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryForest,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                    label: const Text(
                      'Open Link',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                    onPressed: () => _handleAction(context),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
