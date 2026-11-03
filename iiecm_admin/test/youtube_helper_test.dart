import 'package:flutter_test/flutter_test.dart';
import 'package:iiecm_admin/core/utils/youtube_helper.dart';

void main() {
  group('YouTubeHelper Utility Tests', () {
    test('Identifies standard watch URLs and extracts ID', () {
      const url = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
      expect(YouTubeHelper.isValidYouTubeUrl(url), isTrue);
      expect(YouTubeHelper.extractVideoId(url), equals('dQw4w9WgXcQ'));
      expect(
        YouTubeHelper.getThumbnailUrl(url),
        equals('https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg'),
      );
    });

    test('Identifies short youtu.be URLs', () {
      const url = 'https://youtu.be/dQw4w9WgXcQ';
      expect(YouTubeHelper.isValidYouTubeUrl(url), isTrue);
      expect(YouTubeHelper.extractVideoId(url), equals('dQw4w9WgXcQ'));
    });

    test('Identifies embed URLs', () {
      const url = 'https://www.youtube.com/embed/dQw4w9WgXcQ';
      expect(YouTubeHelper.isValidYouTubeUrl(url), isTrue);
      expect(YouTubeHelper.extractVideoId(url), equals('dQw4w9WgXcQ'));
    });

    test('Identifies shorts URLs', () {
      const url = 'https://www.youtube.com/shorts/dQw4w9WgXcQ';
      expect(YouTubeHelper.isValidYouTubeUrl(url), isTrue);
      expect(YouTubeHelper.extractVideoId(url), equals('dQw4w9WgXcQ'));
    });

    test('Rejects invalid URLs', () {
      expect(
        YouTubeHelper.isValidYouTubeUrl('https://example.com/video'),
        isFalse,
      );
      expect(YouTubeHelper.isValidYouTubeUrl('not a url'), isFalse);
      expect(YouTubeHelper.isValidYouTubeUrl(null), isFalse);
      expect(YouTubeHelper.isValidYouTubeUrl(''), isFalse);
    });
  });
}
