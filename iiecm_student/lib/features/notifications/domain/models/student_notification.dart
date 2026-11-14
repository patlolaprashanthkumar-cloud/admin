enum NotificationCategory {
  all,
  unread,
  academic,
  payments,
  system,
}

enum NotificationPriority {
  low,
  medium,
  high;

  static NotificationPriority fromString(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'high':
        return NotificationPriority.high;
      case 'medium':
        return NotificationPriority.medium;
      case 'low':
      default:
        return NotificationPriority.low;
    }
  }

  String get label {
    switch (this) {
      case NotificationPriority.high:
        return 'Urgent';
      case NotificationPriority.medium:
        return 'Important';
      case NotificationPriority.low:
        return 'General';
    }
  }
}

enum NotificationType {
  student,
  instructor,
  course,
  payment,
  liveClass,
  system;

  static NotificationType fromString(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'course':
        return NotificationType.course;
      case 'payment':
        return NotificationType.payment;
      case 'class':
        return NotificationType.liveClass;
      case 'instructor':
        return NotificationType.instructor;
      case 'student':
        return NotificationType.student;
      case 'system':
      default:
        return NotificationType.system;
    }
  }

  String get label {
    switch (this) {
      case NotificationType.course:
        return 'Course Bulletin';
      case NotificationType.payment:
        return 'Fee & Receipts';
      case NotificationType.liveClass:
        return 'Class Schedule';
      case NotificationType.instructor:
        return 'Faculty Notice';
      case NotificationType.student:
        return 'Personal Notice';
      case NotificationType.system:
        return 'Institutional Alert';
    }
  }
}

/// Domain entity representing a real record in `public.notifications`
class StudentNotification {
  final String id;
  final String? userId; // NULL indicates system-wide broadcast
  final String title;
  final String message;
  final NotificationType type;
  final NotificationPriority priority;
  final bool read;
  final String? actionUrl;
  final DateTime createdAt;

  const StudentNotification({
    required this.id,
    this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.priority,
    required this.read,
    this.actionUrl,
    required this.createdAt,
  });

  bool get isBroadcast => userId == null || userId!.isEmpty;

  StudentNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    NotificationType? type,
    NotificationPriority? priority,
    bool? read,
    String? actionUrl,
    DateTime? createdAt,
  }) {
    return StudentNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      read: read ?? this.read,
      actionUrl: actionUrl ?? this.actionUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory StudentNotification.fromMap(Map<String, dynamic> map) {
    DateTime parseDateTime(dynamic value) {
      if (value is DateTime) return value;
      if (value != null) {
        final parsed = DateTime.tryParse(value.toString());
        if (parsed != null) return parsed;
      }
      return DateTime.now();
    }

    return StudentNotification(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString(),
      title: map['title']?.toString() ?? 'Notification',
      message: map['message']?.toString() ?? '',
      type: NotificationType.fromString(map['type']?.toString()),
      priority: NotificationPriority.fromString(map['priority']?.toString()),
      read: map['read'] == true,
      actionUrl: map['action_url']?.toString(),
      createdAt: parseDateTime(map['created_at']),
    );
  }
}

