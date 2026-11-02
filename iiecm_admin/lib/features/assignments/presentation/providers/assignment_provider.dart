import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/supabase_assignment_repository.dart';
import '../../domain/models/assignment.dart';
import '../../domain/models/assignment_submission.dart';
import '../../domain/repositories/assignment_repository.dart';

class AssignmentState {
  final List<Assignment> assignments;
  final List<Assignment> filteredAssignments;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;
  final String selectedStatus;
  final String selectedType;

  const AssignmentState({
    this.assignments = const [],
    this.filteredAssignments = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
    this.selectedStatus = 'all',
    this.selectedType = 'all',
  });

  AssignmentState copyWith({
    List<Assignment>? assignments,
    List<Assignment>? filteredAssignments,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    String? selectedStatus,
    String? selectedType,
  }) {
    return AssignmentState(
      assignments: assignments ?? this.assignments,
      filteredAssignments: filteredAssignments ?? this.filteredAssignments,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      selectedType: selectedType ?? this.selectedType,
    );
  }
}

class AssignmentNotifier extends StateNotifier<AssignmentState> {
  final AssignmentRepository _repository;

  AssignmentNotifier(this._repository) : super(const AssignmentState()) {
    loadAssignments();
  }

  String? get errorMessage => state.errorMessage;

  Future<void> loadAssignments() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _repository.getAssignments();
      state = state.copyWith(
        assignments: list,
        filteredAssignments: _applyFilters(list),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load assignments: $e',
      );
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(
      searchQuery: query,
      filteredAssignments: _applyFilters(state.assignments, search: query),
    );
  }

  void setStatusFilter(String status) {
    state = state.copyWith(
      selectedStatus: status,
      filteredAssignments: _applyFilters(state.assignments, status: status),
    );
  }

  void setTypeFilter(String type) {
    state = state.copyWith(
      selectedType: type,
      filteredAssignments: _applyFilters(state.assignments, type: type),
    );
  }

  List<Assignment> _applyFilters(
    List<Assignment> list, {
    String? search,
    String? status,
    String? type,
  }) {
    final effectiveSearch = search ?? state.searchQuery;
    final effectiveStatus = status ?? state.selectedStatus;
    final effectiveType = type ?? state.selectedType;

    var result = list;

    if (effectiveStatus != 'all') {
      result = result.where((a) => a.status.toLowerCase() == effectiveStatus.toLowerCase()).toList();
    }

    if (effectiveType != 'all') {
      result = result.where((a) => a.type.toLowerCase() == effectiveType.toLowerCase()).toList();
    }

    if (effectiveSearch.trim().isNotEmpty) {
      final q = effectiveSearch.trim().toLowerCase();
      result = result.where((a) {
        return a.title.toLowerCase().contains(q) ||
            a.description.toLowerCase().contains(q) ||
            a.assignedCourses.any((c) => c.title.toLowerCase().contains(q));
      }).toList();
    }

    return result;
  }

  Future<bool> createAssignment(
    Assignment assignment, {
    List<String> courseIds = const [],
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final created = await _repository.createAssignment(assignment, courseIds: courseIds);
      final updatedList = [created, ...state.assignments];
      state = state.copyWith(
        assignments: updatedList,
        filteredAssignments: _applyFilters(updatedList),
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to create assignment: $e',
      );
      return false;
    }
  }

  Future<bool> updateAssignment(
    Assignment assignment, {
    List<String>? courseIds,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updated = await _repository.updateAssignment(assignment, courseIds: courseIds);
      final updatedList = state.assignments.map((a) => a.id == updated.id ? updated : a).toList();
      state = state.copyWith(
        assignments: updatedList,
        filteredAssignments: _applyFilters(updatedList),
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update assignment: $e',
      );
      return false;
    }
  }

  Future<bool> updateStatus(String id, String status) async {
    try {
      await _repository.updateAssignmentStatus(id, status);
      final updatedList = state.assignments.map((a) {
        return a.id == id ? a.copyWith(status: status) : a;
      }).toList();
      state = state.copyWith(
        assignments: updatedList,
        filteredAssignments: _applyFilters(updatedList),
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update status: $e');
      return false;
    }
  }

  Future<bool> deleteAssignment(String id) async {
    try {
      await _repository.deleteAssignment(id);
      final updatedList = state.assignments.where((a) => a.id != id).toList();
      state = state.copyWith(
        assignments: updatedList,
        filteredAssignments: _applyFilters(updatedList),
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete assignment: $e');
      return false;
    }
  }
}

final assignmentRepositoryProvider = Provider<AssignmentRepository>((ref) {
  return SupabaseAssignmentRepository();
});

final assignmentNotifierProvider = StateNotifierProvider<AssignmentNotifier, AssignmentState>((ref) {
  final repo = ref.watch(assignmentRepositoryProvider);
  return AssignmentNotifier(repo);
});

final assignmentDetailProvider = FutureProvider.family<Assignment?, String>((ref, id) async {
  final repo = ref.watch(assignmentRepositoryProvider);
  return repo.getAssignmentById(id);
});

final assignmentSubmissionsProvider = FutureProvider.family<List<AssignmentSubmission>, String>((ref, id) async {
  final repo = ref.watch(assignmentRepositoryProvider);
  return repo.getSubmissions(id);
});

