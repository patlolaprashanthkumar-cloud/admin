import '../models/student_notification.dart';

/// Contract for student-scoped notifications data operations
abstract class NotificationsRepository {
  /// Fetches notifications for the authenticated student (`user_id = auth.uid() OR user_id IS NULL`)
  Future<List<StudentNotification>> getStudentNotifications({
    required String userId,
  });

  /// Marks a specific personal notification as read in the database
  Future<void> markAsRead({
    required String notificationId,
    required String userId,
  });

  /// Marks all personal notifications for the student as read
  Future<void> markAllAsRead({
    required String userId,
  });
}

