import 'package:flutter_test/flutter_test.dart';
import 'package:iiecm_admin/features/courses/domain/models/course_lesson.dart';
import 'package:iiecm_admin/features/courses/domain/models/course_module.dart';

void main() {
  group('Course Video Lessons & Curriculum Models Tests', () {
    test(
      'Constructs CourseLesson and extracts YouTube thumbnail automatically',
      () {
        final json = {
          'id': 'les-1',
          'module_id': 'mod-1',
          'title': 'Mechanical Ventilation Waveforms',
          'duration_minutes': 45,
          'type': 'video',
          'order_index': 2,
          'content_url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
          'created_at': '2026-11-01T10:00:00Z',
        };

        final lesson = CourseLesson.fromJson(json);

        expect(lesson.id, equals('les-1'));
        expect(lesson.isVideo, isTrue);
        expect(lesson.durationMinutes, equals(45));
        expect(lesson.youtubeVideoId, equals('dQw4w9WgXcQ'));
        expect(
          lesson.videoThumbnailUrl,
          equals('https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg'),
        );
      },
    );

    test('CourseModule calculates total duration and video counts', () {
      final lesson1 = CourseLesson(
        id: 'l1',
        moduleId: 'm1',
        title: 'Video 1',
        durationMinutes: 30,
        type: 'video',
        createdAt: DateTime.now(),
      );

      final lesson2 = CourseLesson(
        id: 'l2',
        moduleId: 'm1',
        title: 'Reading 1',
        durationMinutes: 15,
        type: 'reading',
        createdAt: DateTime.now(),
      );

      final module = CourseModule(
        id: 'm1',
        courseId: 'c1',
        title: 'Module 1: Respiratory Care',
        orderIndex: 1,
        createdAt: DateTime.now(),
        lessons: [lesson1, lesson2],
      );

      expect(module.totalDurationMinutes, equals(45));
      expect(module.videoCount, equals(1));
    });
  });
}
