class YouTubeHelper {
  /// Regex to extract 11-character YouTube video ID from various URL formats:
  /// - https://www.youtube.com/watch?v=VIDEO_ID
  /// - https://youtu.be/VIDEO_ID
  /// - https://www.youtube.com/embed/VIDEO_ID
  /// - https://www.youtube.com/shorts/VIDEO_ID
  /// - https://music.youtube.com/watch?v=VIDEO_ID
  static final RegExp _youtubeRegex = RegExp(
    r'(?:https?:\/\/)?(?:www\.|m\.|music\.)?(?:youtube\.com\/(?:watch\?v=|embed\/|v\/|shorts\/)|youtu\.be\/)([a-zA-Z0-9_-]{11})',
    caseSensitive: false,
  );

  /// Checks if a string is a valid YouTube video URL
  static bool isValidYouTubeUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    return _youtubeRegex.hasMatch(url.trim());
  }

  /// Extracts the 11-character video ID from a YouTube URL
  static String? extractVideoId(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final match = _youtubeRegex.firstMatch(url.trim());
    return match?.group(1);
  }

  /// Returns the High Quality (480x360) thumbnail URL for a given video ID or URL
  static String? getThumbnailUrl(String? urlOrId, {bool highQuality = true}) {
    if (urlOrId == null || urlOrId.trim().isEmpty) return null;
    final trimmed = urlOrId.trim();

    String videoId;
    if (trimmed.length == 11 &&
        RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(trimmed)) {
      videoId = trimmed;
    } else {
      final extracted = extractVideoId(trimmed);
      if (extracted == null) return null;
      videoId = extracted;
    }

    final quality = highQuality ? 'hqdefault.jpg' : 'default.jpg';
    return 'https://img.youtube.com/vi/$videoId/$quality';
  }

  /// Returns the Max Resolution (1280x720) thumbnail URL if available
  static String? getMaxResThumbnailUrl(String? urlOrId) {
    final videoId =
        extractVideoId(urlOrId) ??
        (urlOrId != null && urlOrId.length == 11 ? urlOrId : null);
    if (videoId == null) return null;
    return 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
  }
}
