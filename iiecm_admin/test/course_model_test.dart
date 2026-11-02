import 'package:flutter_test/flutter_test.dart';
import 'package:iiecm_admin/features/courses/domain/models/course.dart';
import 'package:iiecm_admin/features/courses/domain/models/course_lesson.dart';
import 'package:iiecm_admin/features/courses/domain/models/course_module.dart';
import 'package:iiecm_admin/features/courses/domain/repositories/course_repository.dart';
import 'package:iiecm_admin/features/courses/presentation/providers/courses_provider.dart';

class MockCourseRepository implements CourseRepository {
  List<Course> store = [];

  MockCourseRepository([List<Course>? initial]) {
    store = initial ?? [];
  }

  @override
  Future<List<Course>> getCourses({String? categoryId, String? status, String? searchQuery}) async {
    var result = List<Course>.from(store);
    if (categoryId != null && categoryId != 'all') {
      result = result.where((c) => c.categoryId == categoryId).toList();
    }
    if (status != null && status != 'all') {
      result = result.where((c) => c.status == status).toList();
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result.where((c) =>
        c.title.toLowerCase().contains(q) ||
        c.description.toLowerCase().contains(q) ||
        c.categoryName.toLowerCase().contains(q)
      ).toList();
    }
    return result;
  }

  @override
  Future<Course?> getCourseById(String id) async {
    try {
      return store.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Course> createCourse({
    required String title,
    required String description,
    required String categoryId,
    required String categoryName,
    String? instructorId,
    int durationWeeks = 8,
    double fee = 0.0,
    String format = 'hybrid',
    String status = 'draft',
  }) async {
    final course = Course(
      id: 'crs-${store.length + 1}',
      title: title,
      description: description,
      categoryId: categoryId,
      categoryName: categoryName,
      instructorId: instructorId,
      instructorName: instructorId != null ? 'Instructor $instructorId' : null,
      durationWeeks: durationWeeks,
      fee: fee,
      format: format,
      status: status,
      createdAt: DateTime.now(),
      enrolledCount: 0,
    );
    store.add(course);
    return course;
  }

  @override
  Future<Course> updateCourse(
    String id, {
    String? title,
    String? description,
    String? categoryId,
    String? categoryName,
    String? instructorId,
    int? durationWeeks,
    double? fee,
    String? format,
    String? status,
  }) async {
    final idx = store.indexWhere((c) => c.id == id);
    final current = store[idx];
    final updated = Course(
      id: current.id,
      title: title ?? current.title,
      description: description ?? current.description,
      categoryId: categoryId ?? current.categoryId,
      categoryName: categoryName ?? current.categoryName,
      instructorId: instructorId ?? current.instructorId,
      instructorName: current.instructorName,
      durationWeeks: durationWeeks ?? current.durationWeeks,
      fee: fee ?? current.fee,
      format: format ?? current.format,
      status: status ?? current.status,
      createdAt: current.createdAt,
      enrolledCount: current.enrolledCount,
    );
    store[idx] = updated;
    return updated;
  }

  @override
  Future<void> deleteCourse(String id) async {
    store.removeWhere((c) => c.id == id);
  }

  @override
  Future<List<CourseModule>> getModules(String courseId) async => [];

  @override
  Future<CourseModule> createModule(CourseModule module) async => module;

  @override
  Future<CourseModule> updateModule(CourseModule module) async => module;

  @override
  Future<void> deleteModule(String moduleId) async {}

  @override
  Future<CourseLesson> createLesson(CourseLesson lesson) async => lesson;

  @override
  Future<CourseLesson> updateLesson(CourseLesson lesson) async => lesson;

  @override
  Future<void> deleteLesson(String lessonId) async {}
}

void main() {
  group('Course Domain Model Tests', () {
    test('Course.fromJson maps fields correctly', () {
      final json = {
        'id': 'crs-101',
        'title': 'Advanced Trauma Life Support',
        'description': 'Comprehensive resuscitation and surgical airway protocols.',
        'category_id': 'cat-trauma',
        'category_name': 'Trauma Care',
        'instructor_id': 'inst-001',
        'duration_weeks': 12,
        'fee': 24999.0,
        'format': 'hybrid',
        'status': 'published',
        'created_at': '2026-10-01T10:00:00Z',
      };

      final course = Course.fromJson(json, instructorName: 'Dr. Vikram Rao', enrolledCount: 42);

      expect(course.id, 'crs-101');
      expect(course.title, 'Advanced Trauma Life Support');
      expect(course.categoryId, 'cat-trauma');
      expect(course.categoryName, 'Trauma Care');
      expect(course.instructorId, 'inst-001');
      expect(course.instructorName, 'Dr. Vikram Rao');
      expect(course.durationWeeks, 12);
      expect(course.fee, 24999.0);
      expect(course.format, 'hybrid');
      expect(course.status, 'published');
      expect(course.enrolledCount, 42);
    });

    test('Course.toJson serializes correctly for mutation payloads', () {
      final course = Course(
        id: 'crs-temp',
        title: 'Emergency Ultrasound',
        description: 'Point-of-care ultrasound protocols in acute scenarios.',
        categoryId: 'cat-em',
        categoryName: 'Emergency Medicine',
        fee: 15000,
        createdAt: DateTime.now(),
      );

      final json = course.toJson();

      expect(json['title'], 'Emergency Ultrasound');
      expect(json['category_id'], 'cat-em');
      expect(json['category_name'], 'Emergency Medicine');
      expect(json['fee'], 15000.0);
      expect(json['status'], 'draft');
    });
  });

  group('CoursesNotifier State & Filtering Tests', () {
    late MockCourseRepository repo;
    late Course course1;
    late Course course2;
    late Course course3;

    setUp(() {
      course1 = Course(
        id: 'c1',
        title: 'Critical Airway Management',
        description: 'Difficult airway algorithms and RSI techniques.',
        categoryId: 'cat-em',
        categoryName: 'Emergency Medicine',
        status: 'published',
        createdAt: DateTime.now(),
      );

      course2 = Course(
        id: 'c2',
        title: 'Mass Casualty Incident Response',
        description: 'Hospital disaster preparedness and triaging protocols.',
        categoryId: 'cat-disaster',
        categoryName: 'Disaster Care',
        status: 'published',
        createdAt: DateTime.now(),
      );

      course3 = Course(
        id: 'c3',
        title: 'Pediatric Resuscitation Draft',
        description: 'PALS protocols and pediatric vascular access.',
        categoryId: 'cat-em',
        categoryName: 'Emergency Medicine',
        status: 'draft',
        createdAt: DateTime.now(),
      );

      repo = MockCourseRepository([course1, course2, course3]);
    });

    test('Initial load populates all courses', () async {
      final notifier = CoursesNotifier(repo);
      await notifier.loadCourses();

      expect(notifier.state.courses.length, 3);
      expect(notifier.state.filteredCourses.length, 3);
    });

    test('Category filtering filters courses accurately', () async {
      final notifier = CoursesNotifier(repo);
      await notifier.loadCourses();

      notifier.setSelectedCategory('cat-em');
      expect(notifier.state.filteredCourses.length, 2);
      expect(notifier.state.filteredCourses.every((c) => c.categoryId == 'cat-em'), isTrue);

      notifier.setSelectedCategory('cat-disaster');
      expect(notifier.state.filteredCourses.length, 1);
      expect(notifier.state.filteredCourses.first.id, 'c2');

      notifier.setSelectedCategory('all');
      expect(notifier.state.filteredCourses.length, 3);
    });

    test('Status filtering filters courses accurately', () async {
      final notifier = CoursesNotifier(repo);
      await notifier.loadCourses();

      notifier.setStatusFilter('published');
      expect(notifier.state.filteredCourses.length, 2);

      notifier.setStatusFilter('draft');
      expect(notifier.state.filteredCourses.length, 1);
      expect(notifier.state.filteredCourses.first.title, contains('Draft'));
    });

    test('Search query matches title, description, and category name', () async {
      final notifier = CoursesNotifier(repo);
      await notifier.loadCourses();

      notifier.setSearchQuery('Airway');
      expect(notifier.state.filteredCourses.length, 1);
      expect(notifier.state.filteredCourses.first.id, 'c1');

      notifier.setSearchQuery('Emergency');
      expect(notifier.state.filteredCourses.length, 2);

      notifier.setSearchQuery('non-existent');
      expect(notifier.state.filteredCourses, isEmpty);
    });

    test('Create, update, and delete course workflow', () async {
      final notifier = CoursesNotifier(repo);
      await notifier.loadCourses();

      final created = await notifier.createCourse(
        title: 'Toxicology Essentials',
        description: 'Antidotes and toxidrome recognition.',
        categoryId: 'cat-em',
        categoryName: 'Emergency Medicine',
        fee: 8000,
        status: 'published',
      );

      expect(created, isTrue);
      expect(notifier.state.courses.length, 4);

      final newCourseId = notifier.state.courses.last.id;
      final updated = await notifier.updateCourse(
        newCourseId,
        title: 'Toxicology & Poison Control',
      );
      expect(updated, isTrue);
      expect(notifier.state.courses.last.title, 'Toxicology & Poison Control');

      await notifier.deleteCourse(newCourseId);
      expect(notifier.state.courses.length, 3);
    });
  });
}
