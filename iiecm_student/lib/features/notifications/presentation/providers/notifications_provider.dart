import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/supabase_notifications_repository.dart';
import '../../domain/models/student_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import 'notifications_state.dart';

/// Provider exposing the NotificationsRepository contract
final notificationsRepositoryProvider =
    Provider<NotificationsRepository>((ref) {
  return SupabaseNotificationsRepository();
});

/// StateNotifierProvider managing student notifications, unread counts, and category filters
final notificationsNotifierProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  final repository = ref.watch(notificationsRepositoryProvider);
  final authState = ref.watch(authNotifierProvider);
  return NotificationsNotifier(repository, authState.student?.userId);
});

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final NotificationsRepository _repository;
  final String? _userId;

  NotificationsNotifier(this._repository, this._userId)
      : super(const NotificationsState()) {
    if (_userId != null && _userId.isNotEmpty) {
      loadNotifications();
    }
  }

  /// Fetches real notifications scoped to authenticated student session
  Future<void> loadNotifications({bool isRefresh = false}) async {
    if (_userId == null || _userId.isEmpty) {
      state = state.copyWith(
        status: NotificationsStatus.loaded,
        notifications: [],
      );
      return;
    }

    if (!isRefresh && state.status == NotificationsStatus.initial) {
      state = state.copyWith(status: NotificationsStatus.loading);
    }

    try {
      final notifications =
          await _repository.getStudentNotifications(userId: _userId);

      state = state.copyWith(
        status: NotificationsStatus.loaded,
        notifications: notifications,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        status: NotificationsStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Sets active category tab filter
  void selectCategory(NotificationCategory category) {
    state = state.copyWith(selectedCategory: category);
  }

  /// Marks a specific notification as read in database (if personal) and locally in state
  Future<void> markAsRead(StudentNotification notification) async {
    final updatedReadIds = Set<String>.from(state.localReadIds)..add(notification.id);
    state = state.copyWith(localReadIds: updatedReadIds);

    if (_userId != null && !notification.isBroadcast) {
      await _repository.markAsRead(
        notificationId: notification.id,
        userId: _userId,
      );
    }
  }

  /// Marks all current notifications as read
  Future<void> markAllAsRead() async {
    final allIds = state.notifications.map((n) => n.id).toSet();
    state = state.copyWith(
      localReadIds: {...state.localReadIds, ...allIds},
    );

    if (_userId != null && _userId.isNotEmpty) {
      await _repository.markAllAsRead(userId: _userId);
    }
  }
}
