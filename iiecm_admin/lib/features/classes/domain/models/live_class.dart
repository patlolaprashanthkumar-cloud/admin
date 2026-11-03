class LiveClass {
  final String id;
  final String title;
  final String courseId;
  final String courseName;
  final String instructorId;
  final String instructorName;
  final DateTime scheduledAt;
  final int durationMinutes;
  final String status; // 'upcoming', 'live', 'completed', 'cancelled'
  final String? meetingLink;
  final DateTime createdAt;

  const LiveClass({
    required this.id,
    required this.title,
    required this.courseId,
    required this.courseName,
    required this.instructorId,
    required this.instructorName,
    required this.scheduledAt,
    this.durationMinutes = 60,
    this.status = 'upcoming',
    this.meetingLink,
    required this.createdAt,
  });

  DateTime get endTime => scheduledAt.add(Duration(minutes: durationMinutes));

  bool get isUpcoming => status.toLowerCase() == 'upcoming';
  bool get isLive => status.toLowerCase() == 'live';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isCancelled => status.toLowerCase() == 'cancelled';

  /// Checks if this class time interval overlaps with another time interval
  bool overlapsWith(DateTime start, int duration) {
    if (isCancelled) return false;
    final otherEnd = start.add(Duration(minutes: duration));
    return scheduledAt.isBefore(otherEnd) && start.isBefore(endTime);
  }

  factory LiveClass.fromJson(Map<String, dynamic> json) {
    return LiveClass(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Live Session',
      courseId: json['course_id']?.toString() ?? '',
      courseName: json['course_name']?.toString() ?? 'Course',
      instructorId: json['instructor_id']?.toString() ?? '',
      instructorName: json['instructor_name']?.toString() ?? 'Instructor',
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.tryParse(json['scheduled_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      durationMinutes: json['duration_minutes'] is int
          ? json['duration_minutes'] as int
          : int.tryParse(json['duration_minutes']?.toString() ?? '60') ?? 60,
      status: json['status']?.toString() ?? 'upcoming',
      meetingLink: json['meeting_link']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson({bool includeId = false}) {
    final map = <String, dynamic>{
      'title': title,
      'course_id': courseId,
      'course_name': courseName,
      'instructor_id': instructorId,
      'instructor_name': instructorName,
      'scheduled_at': scheduledAt.toIso8601String(),
      'duration_minutes': durationMinutes,
      'status': status,
      'meeting_link': meetingLink,
    };
    if (includeId && id.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }

  LiveClass copyWith({
    String? id,
    String? title,
    String? courseId,
    String? courseName,
    String? instructorId,
    String? instructorName,
    DateTime? scheduledAt,
    int? durationMinutes,
    String? status,
    String? meetingLink,
    DateTime? createdAt,
  }) {
    return LiveClass(
      id: id ?? this.id,
      title: title ?? this.title,
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
      instructorId: instructorId ?? this.instructorId,
      instructorName: instructorName ?? this.instructorName,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      meetingLink: meetingLink ?? this.meetingLink,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
