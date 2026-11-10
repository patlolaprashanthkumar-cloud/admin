import '../../../../core/utils/youtube_helper.dart';

class CourseLesson {
  final String id;
  final String moduleId;
  final String title;
  final int durationMinutes;
  final String type; // 'video', 'pdf', 'image', 'file', 'reading', 'quiz', 'assignment'
  final int orderIndex;
  final String? contentUrl;
  final DateTime createdAt;

  const CourseLesson({
    required this.id,
    required this.moduleId,
    required this.title,
    this.durationMinutes = 0,
    this.type = 'video',
    this.orderIndex = 1,
    this.contentUrl,
    required this.createdAt,
  });

  bool get isVideo => type.toLowerCase() == 'video';
  bool get isPdf => type.toLowerCase() == 'pdf';
  bool get isImage => type.toLowerCase() == 'image';
  bool get isFile =>
      type.toLowerCase() == 'file' ||
      type.toLowerCase() == 'document' ||
      type.toLowerCase() == 'attachment';
  bool get isReading => type.toLowerCase() == 'reading';
  bool get isQuiz => type.toLowerCase() == 'quiz';
  bool get isAssignment => type.toLowerCase() == 'assignment';

  /// Extracts file extension from contentUrl if available (e.g. 'pdf', 'png', 'mp4', 'docx', 'zip')
  String? get fileExtension {
    if (contentUrl == null || contentUrl!.trim().isEmpty) return null;
    try {
      final uri = Uri.parse(contentUrl!.trim());
      final path = uri.path;
      final lastDot = path.lastIndexOf('.');
      if (lastDot != -1 && lastDot < path.length - 1) {
        final ext = path.substring(lastDot + 1).toLowerCase();
        if (ext.length <= 5 && RegExp(r'^[a-z0-9]+$').hasMatch(ext)) {
          return ext;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Extracts filename from contentUrl if available
  String? get fileName {
    if (contentUrl == null || contentUrl!.trim().isEmpty) return null;
    try {
      final uri = Uri.parse(contentUrl!.trim());
      final segments = uri.pathSegments;
      if (segments.isNotEmpty && segments.last.isNotEmpty) {
        return Uri.decodeComponent(segments.last);
      }
    } catch (_) {}
    return null;
  }

  /// Formatted type display label for UI
  String get typeDisplayLabel {
    switch (type.toLowerCase()) {
      case 'video':
        return 'Video Lecture';
      case 'pdf':
        return 'PDF Document';
      case 'image':
        return 'Clinical Image';
      case 'file':
      case 'document':
      case 'attachment':
        return fileExtension != null
            ? '${fileExtension!.toUpperCase()} File'
            : 'File Attachment';
      case 'reading':
        return 'Clinical Reading';
      case 'quiz':
        return 'Checkpoint Quiz';
      case 'assignment':
        return 'Practical Task';
      default:
        return type.toUpperCase();
    }
  }

  /// If this is a video and contains a YouTube URL, extracts the YouTube thumbnail URL
  String? get videoThumbnailUrl {
    if (isVideo && contentUrl != null) {
      return YouTubeHelper.getThumbnailUrl(contentUrl);
    }
    return null;
  }

  /// Extracts the YouTube video ID if available
  String? get youtubeVideoId {
    if (isVideo && contentUrl != null) {
      return YouTubeHelper.extractVideoId(contentUrl);
    }
    return null;
  }

  factory CourseLesson.fromJson(Map<String, dynamic> json) {
    return CourseLesson(
      id: json['id']?.toString() ?? '',
      moduleId: json['module_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Lesson',
      durationMinutes: json['duration_minutes'] is int
          ? json['duration_minutes'] as int
          : int.tryParse(json['duration_minutes']?.toString() ?? '0') ?? 0,
      type: json['type']?.toString() ?? 'video',
      orderIndex: json['order_index'] is int
          ? json['order_index'] as int
          : int.tryParse(json['order_index']?.toString() ?? '1') ?? 1,
      contentUrl: json['content_url']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson({bool includeId = false}) {
    final map = <String, dynamic>{
      'module_id': moduleId,
      'title': title,
      'duration_minutes': durationMinutes,
      'type': type,
      'order_index': orderIndex,
      'content_url': contentUrl,
    };
    if (includeId && id.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }

  CourseLesson copyWith({
    String? id,
    String? moduleId,
    String? title,
    int? durationMinutes,
    String? type,
    int? orderIndex,
    String? contentUrl,
    DateTime? createdAt,
  }) {
    return CourseLesson(
      id: id ?? this.id,
      moduleId: moduleId ?? this.moduleId,
      title: title ?? this.title,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      type: type ?? this.type,
      orderIndex: orderIndex ?? this.orderIndex,
      contentUrl: contentUrl ?? this.contentUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
