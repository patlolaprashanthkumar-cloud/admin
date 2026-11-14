import '../../domain/models/course_module.dart';
import '../../domain/models/student_course.dart';

enum CoursesListStatus { initial, loading, loaded, error }

/// Immutable state for the student's enrolled course catalog
class CoursesListState {
  final CoursesListStatus status;
  final List<StudentCourse> courses;
  final String searchQuery;
  final String? selectedCategory;
  final String? errorMessage;

  const CoursesListState({
    this.status = CoursesListStatus.initial,
    this.courses = const [],
    this.searchQuery = '',
    this.selectedCategory,
    this.errorMessage,
  });

  bool get isLoading => status == CoursesListStatus.loading;
  bool get hasError => status == CoursesListStatus.error;
  bool get isLoaded => status == CoursesListStatus.loaded;

  /// Returns distinct category names from all enrolled courses
  List<String> get availableCategories {
    final categories = courses
        .map((c) => c.categoryName)
        .where((cat) => cat.trim().isNotEmpty)
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }

  /// Returns courses filtered by the active search query and category filter
  List<StudentCourse> get filteredCourses {
    return courses.where((course) {
      // Category filter
      if (selectedCategory != null &&
          selectedCategory!.isNotEmpty &&
          selectedCategory != 'All') {
        if (course.categoryName.toLowerCase() !=
            selectedCategory!.toLowerCase()) {
          return false;
        }
      }

      // Search query filter (matches title, category, or instructor)
      if (searchQuery.trim().isNotEmpty) {
        final query = searchQuery.toLowerCase().trim();
        final matchesTitle = course.title.toLowerCase().contains(query);
        final matchesCategory =
            course.categoryName.toLowerCase().contains(query);
        final matchesInstructor =
            course.instructorName?.toLowerCase().contains(query) ?? false;
        return matchesTitle || matchesCategory || matchesInstructor;
      }

      return true;
    }).toList();
  }

  CoursesListState copyWith({
    CoursesListStatus? status,
    List<StudentCourse>? courses,
    String? searchQuery,
    String? selectedCategory,
    bool clearCategory = false,
    String? errorMessage,
  }) {
    return CoursesListState(
      status: status ?? this.status,
      courses: courses ?? this.courses,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory:
          clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

enum CourseDetailStatus { initial, loading, loaded, error }

/// Immutable state for a single course curriculum view (modules & lessons)
class CourseDetailState {
  final CourseDetailStatus status;
  final StudentCourse? course;
  final List<CourseModule> modules;
  final String? errorMessage;

  const CourseDetailState({
    this.status = CourseDetailStatus.initial,
    this.course,
    this.modules = const [],
    this.errorMessage,
  });

  bool get isLoading => status == CourseDetailStatus.loading;
  bool get hasError => status == CourseDetailStatus.error;
  bool get isLoaded => status == CourseDetailStatus.loaded;

  int get totalLessonsCount =>
      modules.fold<int>(0, (sum, m) => sum + m.lessons.length);

  int get totalDurationMinutes =>
      modules.fold<int>(0, (sum, m) => sum + m.totalDurationMinutes);

  int get videoCount =>
      modules.fold<int>(0, (sum, m) => sum + m.videoCount);

  int get pdfCount =>
      modules.fold<int>(0, (sum, m) => sum + m.pdfCount);

  int get fileCount =>
      modules.fold<int>(0, (sum, m) => sum + m.fileCount + m.imageCount);

  CourseDetailState copyWith({
    CourseDetailStatus? status,
    StudentCourse? course,
    List<CourseModule>? modules,
    String? errorMessage,
  }) {
    return CourseDetailState(
      status: status ?? this.status,
      course: course ?? this.course,
      modules: modules ?? this.modules,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

