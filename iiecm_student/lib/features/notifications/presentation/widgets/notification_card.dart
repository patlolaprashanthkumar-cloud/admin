import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/models/student_notification.dart';

/// Institutional Notification / Bulletin Card
///
/// Designed in accordance with the IIECM Modern Academic design language:
/// Category-specific badges, priority indicators, refined unread highlight,
/// readable timestamping, expandable message wrapping, and contextual actions.
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
        return Icons.school_rounded;
      case NotificationType.student:
        return Icons.account_circle_outlined;
      case NotificationType.system:
        return Icons.campaign_rounded;
    }
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.course:
        return AppColors.primaryNavy;
      case NotificationType.liveClass:
        return AppColors.secondaryBlue;
      case NotificationType.payment:
        return AppColors.terracotta;
      case NotificationType.instructor:
        return const Color(0xFF6B21A8); // Institutional Violet
      case NotificationType.student:
        return AppColors.primaryNavy;
      case NotificationType.system:
        return AppColors.accentOrange;
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
      backgroundColor: isRead
          ? (isDark ? AppColors.darkSurface : AppColors.warmCreamLight)
          : (isDark ? AppColors.darkSurfaceElevated : AppColors.white),
      borderColor: isRead
          ? (isDark ? AppColors.darkBorder : AppColors.borderSubtle)
          : (isDark
                ? AppColors.primaryNavy.withValues(alpha: 0.6)
                : AppColors.primaryNavy.withValues(alpha: 0.35)),
      borderRadius: AppConstants.radiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Category Badge, Priority Chip, Unread Dot & Timestamp
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Category Icon Badge
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: isDark ? 0.22 : 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: typeColor.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Icon(
                  _getTypeIcon(notification.type),
                  size: 15,
                  color: typeColor,
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),

              // Category Label & Priority Pill
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.terracotta.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusSm,
                          ),
                          border: Border.all(
                            color: AppColors.terracotta.withValues(alpha: 0.45),
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
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.terracotta,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (notification.priority ==
                        NotificationPriority.medium)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusSm,
                          ),
                          border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.45),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          notification.priority.label.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Unread Indicator Pill or Dot
              if (!isRead)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryNavy.withValues(
                      alpha: isDark ? 0.35 : 0.08,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primaryNavy.withValues(alpha: 0.3),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryNavy,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'NEW',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.accentOrangeLight
                              : AppColors.primaryNavy,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),

              // Formatted Timestamp with Clock Icon
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 11,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    formattedTime,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 2. Notification Title
          Text(
            notification.title,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 4),

          // 3. Notification Message Body (Accessible Text Wrapping)
          Text(
            notification.message,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : (isRead ? AppColors.textSecondary : AppColors.textPrimary),
            ),
          ),

          // 4. Action URL button / Mark Read Action Strip
          if ((notification.actionUrl != null &&
                  notification.actionUrl!.isNotEmpty) ||
              !isRead) ...[
            const SizedBox(height: 8),
            Divider(
              height: 14,
              color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isRead)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.check_rounded, size: 14),
                    label: const Text(
                      'Mark Read',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: onMarkAsRead,
                  ),
                if (notification.actionUrl != null &&
                    notification.actionUrl!.trim().isNotEmpty) ...[
                  const SizedBox(width: AppConstants.spacingSm),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryNavy,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusSm,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 13),
                    label: const Text(
                      'Open Link',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
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
