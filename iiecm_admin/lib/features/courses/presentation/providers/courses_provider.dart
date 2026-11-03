import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/supabase_course_repository.dart';
import '../../domain/models/course.dart';
import '../../domain/models/course_module.dart';
import '../../domain/repositories/course_repository.dart';

final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  return SupabaseCourseRepository();
});

class CoursesState {
  final List<Course> courses;
  final bool isLoading;
  final String? errorMessage;
  final String selectedCategoryId; // 'all' or category UUID
  final String statusFilter; // 'all', 'published', 'draft', 'archived'
  final String searchQuery;

  const CoursesState({
    this.courses = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedCategoryId = 'all',
    this.statusFilter = 'all',
    this.searchQuery = '',
  });

  List<Course> get filteredCourses {
    return courses.where((c) {
      final matchesCategory =
          selectedCategoryId == 'all' || c.categoryId == selectedCategoryId;
      final matchesStatus = statusFilter == 'all' || c.status == statusFilter;
      final matchesSearch =
          searchQuery.isEmpty ||
          c.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          c.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
          c.categoryName.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCategory && matchesStatus && matchesSearch;
    }).toList();
  }

  CoursesState copyWith({
    List<Course>? courses,
    bool? isLoading,
    String? errorMessage,
    String? selectedCategoryId,
    String? statusFilter,
    String? searchQuery,
  }) {
    return CoursesState(
      courses: courses ?? this.courses,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      statusFilter: statusFilter ?? this.statusFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class CoursesNotifier extends StateNotifier<CoursesState> {
  final CourseRepository _repository;

  CoursesNotifier(this._repository) : super(const CoursesState()) {
    loadCourses();
  }

  Future<void> loadCourses() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final items = await _repository.getCourses();
      state = state.copyWith(courses: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void setSelectedCategory(String categoryId) {
    state = state.copyWith(selectedCategoryId: categoryId);
  }

  void setStatusFilter(String status) {
    state = state.copyWith(statusFilter: status);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<bool> createCourse({
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
    try {
      final created = await _repository.createCourse(
        title: title,
        description: description,
        categoryId: categoryId,
        categoryName: categoryName,
        instructorId: instructorId,
        durationWeeks: durationWeeks,
        fee: fee,
        format: format,
        status: status,
      );
      state = state.copyWith(courses: [created, ...state.courses]);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateCourse(
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
    try {
      final updated = await _repository.updateCourse(
        id,
        title: title,
        description: description,
        categoryId: categoryId,
        categoryName: categoryName,
        instructorId: instructorId,
        durationWeeks: durationWeeks,
        fee: fee,
        format: format,
        status: status,
      );
      state = state.copyWith(
        courses: state.courses.map((c) => c.id == id ? updated : c).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<void> deleteCourse(String id) async {
    try {
      await _repository.deleteCourse(id);
      state = state.copyWith(
        courses: state.courses.where((c) => c.id != id).toList(),
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }
}

final coursesNotifierProvider =
    StateNotifierProvider<CoursesNotifier, CoursesState>((ref) {
      final repo = ref.watch(courseRepositoryProvider);
      return CoursesNotifier(repo);
    });

final courseDetailProvider = FutureProvider.family<Course?, String>((
  ref,
  id,
) async {
  final repo = ref.watch(courseRepositoryProvider);
  return repo.getCourseById(id);
});

final courseModulesProvider = FutureProvider.family<List<CourseModule>, String>(
  (ref, courseId) async {
    final repo = ref.watch(courseRepositoryProvider);
    return repo.getModules(courseId);
  },
);
