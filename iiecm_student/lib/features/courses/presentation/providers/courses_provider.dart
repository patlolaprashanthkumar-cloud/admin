import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/models/student_profile.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/supabase_courses_repository.dart';
import '../../domain/models/course_module.dart';
import '../../domain/models/student_course.dart';
import '../../domain/repositories/courses_repository.dart';
import 'courses_state.dart';

/// Provider exposing the CoursesRepository contract
final coursesRepositoryProvider = Provider<CoursesRepository>((ref) {
  return SupabaseCoursesRepository();
});

/// StateNotifierProvider managing the enrolled courses list for the active student
final enrolledCoursesNotifierProvider =
    StateNotifierProvider<EnrolledCoursesNotifier, CoursesListState>((ref) {
  final repo = ref.watch(coursesRepositoryProvider);
  final authState = ref.watch(authNotifierProvider);
  return EnrolledCoursesNotifier(repo, authState.student);
});

class EnrolledCoursesNotifier extends StateNotifier<CoursesListState> {
  final CoursesRepository _repository;
  final StudentProfile? _student;

  EnrolledCoursesNotifier(this._repository, this._student)
      : super(const CoursesListState()) {
    if (_student != null) {
      loadCourses();
    }
  }

  /// Loads enrolled courses for the authenticated student from Supabase
  Future<void> loadCourses() async {
    if (_student == null) {
      state = state.copyWith(
        status: CoursesListStatus.error,
        errorMessage: 'No authenticated student session found.',
      );
      return;
    }

    state = state.copyWith(status: CoursesListStatus.loading);

    try {
      final courses =
          await _repository.getEnrolledCourses(_student.studentRecordId);
      state = state.copyWith(
        status: CoursesListStatus.loaded,
        courses: courses,
        errorMessage: null,
      );
    } catch (e, stack) {
      developer.log(
        'Failed to load enrolled courses for student ${_student.studentRecordId}: $e',
        name: 'EnrolledCoursesNotifier',
        error: e,
        stackTrace: stack,
      );
      state = state.copyWith(
        status: CoursesListStatus.error,
        errorMessage:
            'Unable to load your courses. Please check your network and retry.',
      );
    }
  }

  /// Sets the search filter query
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Selects or clears the active category filter
  void selectCategory(String? category) {
    if (category == null || category == 'All') {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(selectedCategory: category);
    }
  }

  /// Pull-to-refresh
  Future<void> refresh() async {
    await loadCourses();
  }
}

/// Family StateNotifierProvider managing the details and curriculum of a specific course
final courseDetailProvider = StateNotifierProvider.family<CourseDetailNotifier,
    CourseDetailState, String>((ref, courseId) {
  final repo = ref.watch(coursesRepositoryProvider);
  final authState = ref.watch(authNotifierProvider);
  final studentRecordId = authState.student?.studentRecordId ?? '';
  return CourseDetailNotifier(repo, courseId, studentRecordId);
});

class CourseDetailNotifier extends StateNotifier<CourseDetailState> {
  final CoursesRepository _repository;
  final String _courseId;
  final String _studentRecordId;

  CourseDetailNotifier(
    this._repository,
    this._courseId,
    this._studentRecordId,
  ) : super(const CourseDetailState()) {
    loadCourseDetails();
  }

  /// Fetches course metadata and curriculum modules with lessons
  Future<void> loadCourseDetails() async {
    if (_courseId.isEmpty) {
      state = state.copyWith(
        status: CourseDetailStatus.error,
        errorMessage: 'Invalid course reference identifier.',
      );
      return;
    }

    state = state.copyWith(status: CourseDetailStatus.loading);

    try {
      // 1. Fetch course details with enrollment status
      final StudentCourse? course =
          await _repository.getCourseDetails(_courseId, _studentRecordId);

      // 2. Fetch all modules and ordered lessons
      final List<CourseModule> modules =
          await _repository.getCourseModules(_courseId);

      state = state.copyWith(
        status: CourseDetailStatus.loaded,
        course: course,
        modules: modules,
        errorMessage: null,
      );
    } catch (e, stack) {
      developer.log(
        'Failed to load details for course $_courseId: $e',
        name: 'CourseDetailNotifier',
        error: e,
        stackTrace: stack,
      );
      state = state.copyWith(
        status: CourseDetailStatus.error,
        errorMessage:
            'Unable to load curriculum modules. Please check your connection and retry.',
      );
    }
  }

  /// Pull-to-refresh
  Future<void> refresh() async {
    await loadCourseDetails();
  }
}

