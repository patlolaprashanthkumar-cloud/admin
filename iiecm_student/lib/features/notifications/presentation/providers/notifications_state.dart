import '../../domain/models/student_notification.dart';

enum NotificationsStatus {
  initial,
  loading,
  loaded,
  error,
}

class NotificationsState {
  final NotificationsStatus status;
  final List<StudentNotification> notifications;
  final NotificationCategory selectedCategory;
  final Set<String> localReadIds;
  final String? errorMessage;

  const NotificationsState({
    this.status = NotificationsStatus.initial,
    this.notifications = const [],
    this.selectedCategory = NotificationCategory.all,
    this.localReadIds = const {},
    this.errorMessage,
  });

  bool get isLoading => status == NotificationsStatus.loading;
  bool get hasError => status == NotificationsStatus.error;
  bool get isLoaded => status == NotificationsStatus.loaded;

  /// Determines whether a notification is read (either on Supabase or locally marked read)
  bool isNotificationRead(StudentNotification notification) {
    if (notification.read) return true;
    return localReadIds.contains(notification.id);
  }

  /// Total count of unread notifications for badge display
  int get unreadCount {
    return notifications.where((n) => !isNotificationRead(n)).length;
  }

  /// List of notifications filtered by the selected category tab
  List<StudentNotification> get filteredNotifications {
    switch (selectedCategory) {
      case NotificationCategory.unread:
        return notifications.where((n) => !isNotificationRead(n)).toList();
      case NotificationCategory.academic:
        return notifications
            .where((n) =>
                n.type == NotificationType.course ||
                n.type == NotificationType.liveClass ||
                n.type == NotificationType.instructor)
            .toList();
      case NotificationCategory.payments:
        return notifications
            .where((n) => n.type == NotificationType.payment)
            .toList();
      case NotificationCategory.system:
        return notifications
            .where((n) =>
                n.type == NotificationType.system ||
                n.type == NotificationType.student)
            .toList();
      case NotificationCategory.all:
        return notifications;
    }
  }

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<StudentNotification>? notifications,
    NotificationCategory? selectedCategory,
    Set<String>? localReadIds,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      localReadIds: localReadIds ?? this.localReadIds,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
