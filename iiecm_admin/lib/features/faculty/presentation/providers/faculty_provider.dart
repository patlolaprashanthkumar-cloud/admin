import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/supabase_faculty_repository.dart';
import '../../domain/models/faculty.dart';
import '../../domain/repositories/faculty_repository.dart';

class FacultyState {
  final List<Faculty> facultyList;
  final List<Faculty> filteredFaculty;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;
  final String selectedCategoryId;
  final String selectedStatus;

  const FacultyState({
    this.facultyList = const [],
    this.filteredFaculty = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
    this.selectedCategoryId = 'all',
    this.selectedStatus = 'all',
  });

  FacultyState copyWith({
    List<Faculty>? facultyList,
    List<Faculty>? filteredFaculty,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    String? selectedCategoryId,
    String? selectedStatus,
  }) {
    return FacultyState(
      facultyList: facultyList ?? this.facultyList,
      filteredFaculty: filteredFaculty ?? this.filteredFaculty,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      selectedStatus: selectedStatus ?? this.selectedStatus,
    );
  }
}

class FacultyNotifier extends StateNotifier<FacultyState> {
  final FacultyRepository _repository;

  FacultyNotifier(this._repository) : super(const FacultyState()) {
    loadFaculty();
  }

  String? get errorMessage => state.errorMessage;

  Future<void> loadFaculty() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _repository.getFaculty();
      state = state.copyWith(
        facultyList: list,
        filteredFaculty: _applyFilters(
          list,
          state.searchQuery,
          state.selectedCategoryId,
          state.selectedStatus,
        ),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load faculty: $e',
      );
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(
      searchQuery: query,
      filteredFaculty: _applyFilters(
        state.facultyList,
        query,
        state.selectedCategoryId,
        state.selectedStatus,
      ),
    );
  }

  void setCategoryFilter(String categoryId) {
    state = state.copyWith(
      selectedCategoryId: categoryId,
      filteredFaculty: _applyFilters(
        state.facultyList,
        state.searchQuery,
        categoryId,
        state.selectedStatus,
      ),
    );
  }

  void setStatusFilter(String status) {
    state = state.copyWith(
      selectedStatus: status,
      filteredFaculty: _applyFilters(
        state.facultyList,
        state.searchQuery,
        state.selectedCategoryId,
        status,
      ),
    );
  }

  List<Faculty> _applyFilters(
    List<Faculty> list,
    String search,
    String categoryId,
    String status,
  ) {
    var result = list;

    if (status != 'all') {
      result = result
          .where((f) => f.accountStatus.toLowerCase() == status.toLowerCase())
          .toList();
    }

    if (categoryId != 'all') {
      result = result.where((f) {
        return f.assignedCategories.any((c) => c.id == categoryId);
      }).toList();
    }

    if (search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      result = result.where((f) {
        return f.fullName.toLowerCase().contains(q) ||
            f.email.toLowerCase().contains(q) ||
            f.specialization.toLowerCase().contains(q) ||
            f.qualifications.toLowerCase().contains(q);
      }).toList();
    }

    return result;
  }

  Future<bool> createFaculty(
    Faculty faculty, {
    List<String> categoryIds = const [],
    List<String> courseIds = const [],
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final created = await _repository.createFaculty(
        faculty,
        categoryIds: categoryIds,
        courseIds: courseIds,
      );
      final updatedList = [created, ...state.facultyList];
      state = state.copyWith(
        facultyList: updatedList,
        filteredFaculty: _applyFilters(
          updatedList,
          state.searchQuery,
          state.selectedCategoryId,
          state.selectedStatus,
        ),
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to create faculty: $e',
      );
      return false;
    }
  }

  Future<bool> updateFaculty(
    Faculty faculty, {
    List<String>? categoryIds,
    List<String>? courseIds,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updated = await _repository.updateFaculty(
        faculty,
        categoryIds: categoryIds,
        courseIds: courseIds,
      );
      final updatedList = state.facultyList
          .map((f) => f.id == updated.id ? updated : f)
          .toList();
      state = state.copyWith(
        facultyList: updatedList,
        filteredFaculty: _applyFilters(
          updatedList,
          state.searchQuery,
          state.selectedCategoryId,
          state.selectedStatus,
        ),
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update faculty: $e',
      );
      return false;
    }
  }

  Future<bool> updateStatus(String id, String status) async {
    try {
      await _repository.updateFacultyStatus(id, status);
      final updatedList = state.facultyList.map((f) {
        return f.id == id ? f.copyWith(accountStatus: status) : f;
      }).toList();
      state = state.copyWith(
        facultyList: updatedList,
        filteredFaculty: _applyFilters(
          updatedList,
          state.searchQuery,
          state.selectedCategoryId,
          state.selectedStatus,
        ),
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update status: $e');
      return false;
    }
  }

  Future<bool> deleteFaculty(String id) async {
    try {
      await _repository.deleteFaculty(id);
      final updatedList = state.facultyList.where((f) => f.id != id).toList();
      state = state.copyWith(
        facultyList: updatedList,
        filteredFaculty: _applyFilters(
          updatedList,
          state.searchQuery,
          state.selectedCategoryId,
          state.selectedStatus,
        ),
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete faculty: $e');
      return false;
    }
  }
}

final facultyRepositoryProvider = Provider<FacultyRepository>((ref) {
  return SupabaseFacultyRepository();
});

final facultyNotifierProvider =
    StateNotifierProvider<FacultyNotifier, FacultyState>((ref) {
      final repo = ref.watch(facultyRepositoryProvider);
      return FacultyNotifier(repo);
    });

final facultyDetailProvider = FutureProvider.family<Faculty?, String>((
  ref,
  id,
) async {
  final repo = ref.watch(facultyRepositoryProvider);
  return repo.getFacultyById(id);
});
