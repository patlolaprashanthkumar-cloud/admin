import 'package:flutter_test/flutter_test.dart';
import 'package:iiecm_student/core/utils/youtube_helper.dart';
import 'package:iiecm_student/features/courses/domain/models/course_lesson.dart';
import 'package:iiecm_student/features/courses/domain/models/course_module.dart';
import 'package:iiecm_student/features/courses/domain/models/student_course.dart';
import 'package:iiecm_student/features/courses/presentation/providers/courses_state.dart';

void main() {
  group('YouTubeHelper Unit Tests', () {
    test('extracts video ID from standard watch URL', () {
      const url = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
      expect(YouTubeHelper.isValidYouTubeUrl(url), isTrue);
      expect(YouTubeHelper.extractVideoId(url), 'dQw4w9WgXcQ');
      expect(
        YouTubeHelper.getThumbnailUrl(url),
        'https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
      );
    });

    test('extracts video ID from youtu.be short URL', () {
      const url = 'https://youtu.be/dQw4w9WgXcQ';
      expect(YouTubeHelper.isValidYouTubeUrl(url), isTrue);
      expect(YouTubeHelper.extractVideoId(url), 'dQw4w9WgXcQ');
    });

    test('extracts video ID from youtube embed URL', () {
      const url = 'https://www.youtube.com/embed/dQw4w9WgXcQ';
      expect(YouTubeHelper.isValidYouTubeUrl(url), isTrue);
      expect(YouTubeHelper.extractVideoId(url), 'dQw4w9WgXcQ');
    });

    test('handles non-YouTube URLs gracefully', () {
      const url = 'https://example.com/video.mp4';
      expect(YouTubeHelper.isValidYouTubeUrl(url), isFalse);
      expect(YouTubeHelper.extractVideoId(url), isNull);
      expect(YouTubeHelper.getThumbnailUrl(url), isNull);
    });

    test('handles null and empty input safely', () {
      expect(YouTubeHelper.isValidYouTubeUrl(null), isFalse);
      expect(YouTubeHelper.isValidYouTubeUrl(''), isFalse);
      expect(YouTubeHelper.extractVideoId(null), isNull);
      expect(YouTubeHelper.extractVideoId(''), isNull);
    });
  });

  group('CourseLesson Model Tests', () {
    test('correctly parses video lesson with YouTube URL', () {
      final json = {
        'id': 'les-1',
        'module_id': 'mod-1',
        'title': 'Emergency Airway Management Lecture',
        'duration_minutes': 45,
        'type': 'video',
        'order_index': 1,
        'content_url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        'created_at': '2026-01-15T10:00:00Z',
      };

      final lesson = CourseLesson.fromJson(json);

      expect(lesson.id, 'les-1');
      expect(lesson.moduleId, 'mod-1');
      expect(lesson.title, 'Emergency Airway Management Lecture');
      expect(lesson.durationMinutes, 45);
      expect(lesson.isVideo, isTrue);
      expect(lesson.isPdf, isFalse);
      expect(lesson.typeDisplayLabel, 'Video Lecture');
      expect(lesson.youtubeVideoId, 'dQw4w9WgXcQ');
      expect(
        lesson.videoThumbnailUrl,
        'https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
      );
    });

    test('correctly parses PDF document lesson with extension and filename', () {
      final json = {
        'id': 'les-2',
        'module_id': 'mod-1',
        'title': 'Trauma Resuscitation Clinical Protocol',
        'duration_minutes': 20,
        'type': 'pdf',
        'order_index': 2,
        'content_url': 'https://storage.supabase.co/protocols/trauma_resuscitation_guidelines.pdf',
        'created_at': '2026-01-15T10:00:00Z',
      };

      final lesson = CourseLesson.fromJson(json);

      expect(lesson.isPdf, isTrue);
      expect(lesson.isVideo, isFalse);
      expect(lesson.fileExtension, 'pdf');
      expect(lesson.fileName, 'trauma_resuscitation_guidelines.pdf');
      expect(lesson.typeDisplayLabel, 'PDF Document');
    });

    test('correctly parses clinical image lesson', () {
      final json = {
        'id': 'les-3',
        'module_id': 'mod-1',
        'title': 'CT Thorax Tension Pneumothorax Case',
        'duration_minutes': 10,
        'type': 'image',
        'order_index': 3,
        'content_url': 'https://storage.supabase.co/radiology/ct_thorax_case.png',
        'created_at': '2026-01-15T10:00:00Z',
      };

      final lesson = CourseLesson.fromJson(json);

      expect(lesson.isImage, isTrue);
      expect(lesson.fileExtension, 'png');
      expect(lesson.fileName, 'ct_thorax_case.png');
      expect(lesson.typeDisplayLabel, 'Clinical Image');
    });
  });

  group('CourseModule Model Tests', () {
    test('calculates duration and lesson type counters accurately', () {
      final lessons = [
        CourseLesson(
          id: 'l1',
          moduleId: 'm1',
          title: 'Airway Anatomy',
          durationMinutes: 30,
          type: 'video',
          createdAt: DateTime.now(),
        ),
        CourseLesson(
          id: 'l2',
          moduleId: 'm1',
          title: 'Intubation Checklist',
          durationMinutes: 15,
          type: 'pdf',
          createdAt: DateTime.now(),
        ),
        CourseLesson(
          id: 'l3',
          moduleId: 'm1',
          title: 'Bronchoscopy Image',
          durationMinutes: 10,
          type: 'image',
          createdAt: DateTime.now(),
        ),
      ];

      final module = CourseModule(
        id: 'm1',
        courseId: 'c1',
        title: 'Module 1: Advanced Airway',
        orderIndex: 1,
        createdAt: DateTime.now(),
        lessons: lessons,
      );

      expect(module.totalDurationMinutes, 55);
      expect(module.videoCount, 1);
      expect(module.pdfCount, 1);
      expect(module.imageCount, 1);
      expect(module.lessons.length, 3);
    });
  });

  group('StudentCourse Model Tests', () {
    test('parses course and enrollment metadata correctly', () {
      final courseJson = {
        'id': 'c-101',
        'title': 'Fellowship in Emergency Medicine',
        'description': 'Advanced 12-month postgraduate fellowship',
        'category_name': 'Emergency Medicine',
        'format': 'hybrid',
        'duration_weeks': 52,
        'learning_objectives': ['Airway mastery', 'Trauma resuscitation'],
        'prerequisites': ['MBBS degree', 'Internship completion'],
        'created_at': '2026-01-01T00:00:00Z',
      };

      final enrollmentJson = {
        'id': 'enr-1',
        'status': 'active',
        'enrolled_at': '2026-02-01T10:00:00Z',
      };

      final course = StudentCourse.fromData(
        courseJson: courseJson,
        enrollmentJson: enrollmentJson,
        instructorName: 'Dr. Ramesh Kumar',
      );

      expect(course.id, 'c-101');
      expect(course.title, 'Fellowship in Emergency Medicine');
      expect(course.instructorName, 'Dr. Ramesh Kumar');
      expect(course.isActive, isTrue);
      expect(course.isCompleted, isFalse);
      expect(course.enrollmentStatus, 'active');
      expect(course.learningObjectives.length, 2);
      expect(course.prerequisites.length, 2);
    });
  });

  group('CoursesListState Filtering Tests', () {
    final courses = [
      StudentCourse(
        id: '1',
        title: 'Pediatric Emergency Medicine',
        description: 'Pediatric resuscitation and triage',
        categoryName: 'Pediatrics',
        instructorName: 'Dr. Sunita Patel',
        createdAt: DateTime.now(),
      ),
      StudentCourse(
        id: '2',
        title: 'Adult Critical Care & Trauma',
        description: 'Advanced trauma life support',
        categoryName: 'Trauma & Critical Care',
        instructorName: 'Dr. Ramesh Kumar',
        createdAt: DateTime.now(),
      ),
    ];

    test('filters courses by category', () {
      final state = CoursesListState(
        courses: courses,
        selectedCategory: 'Pediatrics',
      );

      expect(state.filteredCourses.length, 1);
      expect(state.filteredCourses.first.id, '1');
    });

    test('filters courses by search query', () {
      final state = CoursesListState(
        courses: courses,
        searchQuery: 'trauma',
      );

      expect(state.filteredCourses.length, 1);
      expect(state.filteredCourses.first.id, '2');
    });

    test('returns all courses when category is null or All and query is empty', () {
      final state = CoursesListState(courses: courses);
      expect(state.filteredCourses.length, 2);
    });
  });
}

