import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/supabase_class_repository.dart';
import '../../domain/models/live_class.dart';
import '../../domain/repositories/class_repository.dart';

enum ClassViewMode { list, daily, weekly, monthly }

class ClassState {
  final List<LiveClass> classList;
  final List<LiveClass> filteredClasses;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;
  final String selectedStatus;
  final String selectedInstructorId;
  final String selectedCourseId;
  final ClassViewMode viewMode;
  final DateTime selectedDate;

  const ClassState({
    this.classList = const [],
    this.filteredClasses = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
    this.selectedStatus = 'all',
    this.selectedInstructorId = 'all',
    this.selectedCourseId = 'all',
    this.viewMode = ClassViewMode.list,
    required this.selectedDate,
  });

  ClassState copyWith({
    List<LiveClass>? classList,
    List<LiveClass>? filteredClasses,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    String? selectedStatus,
    String? selectedInstructorId,
    String? selectedCourseId,
    ClassViewMode? viewMode,
    DateTime? selectedDate,
  }) {
    return ClassState(
      classList: classList ?? this.classList,
      filteredClasses: filteredClasses ?? this.filteredClasses,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      selectedInstructorId: selectedInstructorId ?? this.selectedInstructorId,
      selectedCourseId: selectedCourseId ?? this.selectedCourseId,
      viewMode: viewMode ?? this.viewMode,
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }
}

class ClassNotifier extends StateNotifier<ClassState> {
  final ClassRepository _repository;

  ClassNotifier(this._repository)
    : super(ClassState(selectedDate: DateTime.now())) {
    loadClasses();
  }

  String? get errorMessage => state.errorMessage;

  Future<void> loadClasses() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _repository.getClasses();
      state = state.copyWith(
        classList: list,
        filteredClasses: _applyFilters(list),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load classes: $e',
      );
    }
  }

  void setViewMode(ClassViewMode mode) {
    state = state.copyWith(
      viewMode: mode,
      filteredClasses: _applyFilters(state.classList, mode: mode),
    );
  }

  void setSelectedDate(DateTime date) {
    state = state.copyWith(
      selectedDate: date,
      filteredClasses: _applyFilters(state.classList, date: date),
    );
  }

  void setSearchQuery(String query) {
    state = state.copyWith(
      searchQuery: query,
      filteredClasses: _applyFilters(state.classList, search: query),
    );
  }

  void setStatusFilter(String status) {
    state = state.copyWith(
      selectedStatus: status,
      filteredClasses: _applyFilters(state.classList, status: status),
    );
  }

  void setInstructorFilter(String instructorId) {
    state = state.copyWith(
      selectedInstructorId: instructorId,
      filteredClasses: _applyFilters(
        state.classList,
        instructorId: instructorId,
      ),
    );
  }

  void setCourseFilter(String courseId) {
    state = state.copyWith(
      selectedCourseId: courseId,
      filteredClasses: _applyFilters(state.classList, courseId: courseId),
    );
  }

  List<LiveClass> _applyFilters(
    List<LiveClass> list, {
    String? search,
    String? status,
    String? instructorId,
    String? courseId,
    ClassViewMode? mode,
    DateTime? date,
  }) {
    final effectiveSearch = search ?? state.searchQuery;
    final effectiveStatus = status ?? state.selectedStatus;
    final effectiveInstructor = instructorId ?? state.selectedInstructorId;
    final effectiveCourse = courseId ?? state.selectedCourseId;
    final effectiveMode = mode ?? state.viewMode;
    final effectiveDate = date ?? state.selectedDate;

    var result = list;

    // Filter by view mode date window
    if (effectiveMode == ClassViewMode.daily) {
      result = result.where((c) {
        return c.scheduledAt.year == effectiveDate.year &&
            c.scheduledAt.month == effectiveDate.month &&
            c.scheduledAt.day == effectiveDate.day;
      }).toList();
    } else if (effectiveMode == ClassViewMode.weekly) {
      final startOfWeek = effectiveDate.subtract(
        Duration(days: effectiveDate.weekday - 1),
      );
      final endOfWeek = startOfWeek.add(const Duration(days: 7));
      result = result.where((c) {
        return c.scheduledAt.isAfter(
              startOfWeek.subtract(const Duration(seconds: 1)),
            ) &&
            c.scheduledAt.isBefore(endOfWeek);
      }).toList();
    } else if (effectiveMode == ClassViewMode.monthly) {
      result = result.where((c) {
        return c.scheduledAt.year == effectiveDate.year &&
            c.scheduledAt.month == effectiveDate.month;
      }).toList();
    }

    // Filter by status
    if (effectiveStatus != 'all') {
      result = result
          .where((c) => c.status.toLowerCase() == effectiveStatus.toLowerCase())
          .toList();
    }

    // Filter by instructor
    if (effectiveInstructor != 'all') {
      result = result
          .where((c) => c.instructorId == effectiveInstructor)
          .toList();
    }

    // Filter by course
    if (effectiveCourse != 'all') {
      result = result.where((c) => c.courseId == effectiveCourse).toList();
    }

    // Filter by search query
    if (effectiveSearch.trim().isNotEmpty) {
      final q = effectiveSearch.trim().toLowerCase();
      result = result.where((c) {
        return c.title.toLowerCase().contains(q) ||
            c.courseName.toLowerCase().contains(q) ||
            c.instructorName.toLowerCase().contains(q);
      }).toList();
    }

    return result;
  }

  Future<bool> createClass(
    LiveClass liveClass, {
    bool notifyStudents = true,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final created = await _repository.createClass(
        liveClass,
        notifyStudents: notifyStudents,
      );
      final updatedList = [...state.classList, created]
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      state = state.copyWith(
        classList: updatedList,
        filteredClasses: _applyFilters(updatedList),
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to create class: $e',
      );
      return false;
    }
  }

  Future<bool> rescheduleClass(
    String id,
    DateTime newDate,
    int duration,
  ) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updated = await _repository.rescheduleClass(id, newDate, duration);
      final updatedList =
          state.classList.map((c) => c.id == id ? updated : c).toList()
            ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      state = state.copyWith(
        classList: updatedList,
        filteredClasses: _applyFilters(updatedList),
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to reschedule class: $e',
      );
      return false;
    }
  }

  Future<bool> updateStatus(String id, String status) async {
    try {
      await _repository.updateClassStatus(id, status);
      final updatedList = state.classList.map((c) {
        return c.id == id ? c.copyWith(status: status) : c;
      }).toList();
      state = state.copyWith(
        classList: updatedList,
        filteredClasses: _applyFilters(updatedList),
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update status: $e');
      return false;
    }
  }

  Future<bool> deleteClass(String id) async {
    try {
      await _repository.deleteClass(id);
      final updatedList = state.classList.where((c) => c.id != id).toList();
      state = state.copyWith(
        classList: updatedList,
        filteredClasses: _applyFilters(updatedList),
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete class: $e');
      return false;
    }
  }
}

final classRepositoryProvider = Provider<ClassRepository>((ref) {
  return SupabaseClassRepository();
});

final classNotifierProvider = StateNotifierProvider<ClassNotifier, ClassState>((
  ref,
) {
  final repo = ref.watch(classRepositoryProvider);
  return ClassNotifier(repo);
});
