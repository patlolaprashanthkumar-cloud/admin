import '../../../../core/utils/youtube_helper.dart';

/// Represents an individual clinical lesson, video lecture, or document in a course module
class CourseLesson {
  final String id;
  final String moduleId;
  final String title;
  final int durationMinutes;
  final String type; // 'video', 'pdf', 'image', 'file', 'document', 'reading', 'quiz', 'assignment'
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

  /// Extracts file extension from contentUrl if available (e.g. 'pdf', 'png', 'docx', 'zip')
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

  /// Extracts clean filename from contentUrl if available
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

  /// Formatted type display label for UI badges
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
        return fileExtension != null ? '${fileExtension!.toUpperCase()} File' : 'Document Attachment';
      case 'reading':
        return 'Clinical Protocol';
      case 'quiz':
        return 'Checkpoint Quiz';
      case 'assignment':
        return 'Practical Case Task';
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
    DateTime parseDate(dynamic val) {
      if (val is DateTime) return val;
      return DateTime.tryParse(val?.toString() ?? '') ?? DateTime.now();
    }

    return CourseLesson(
      id: json['id']?.toString() ?? '',
      moduleId: json['module_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Lesson',
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 0,
      type: json['type']?.toString() ?? 'video',
      orderIndex: (json['order_index'] as num?)?.toInt() ?? 1,
      contentUrl: json['content_url']?.toString(),
      createdAt: parseDate(json['created_at']),
    );
  }
}

