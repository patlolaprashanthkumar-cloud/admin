import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../assignments/domain/models/assignment_submission.dart';
import '../../data/repositories/supabase_assessment_repository.dart';
import '../../domain/models/assessment.dart';
import '../../domain/models/question.dart';
import '../../domain/repositories/assessment_repository.dart';

class AssessmentState {
  final List<Assessment> assessments;
  final List<Assessment> filteredAssessments;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;
  final String selectedStatus;
  final String selectedType;

  const AssessmentState({
    this.assessments = const [],
    this.filteredAssessments = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
    this.selectedStatus = 'all',
    this.selectedType = 'all',
  });

  AssessmentState copyWith({
    List<Assessment>? assessments,
    List<Assessment>? filteredAssessments,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    String? selectedStatus,
    String? selectedType,
  }) {
    return AssessmentState(
      assessments: assessments ?? this.assessments,
      filteredAssessments: filteredAssessments ?? this.filteredAssessments,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      selectedType: selectedType ?? this.selectedType,
    );
  }
}

class AssessmentNotifier extends StateNotifier<AssessmentState> {
  final AssessmentRepository _repository;

  AssessmentNotifier(this._repository) : super(const AssessmentState()) {
    loadAssessments();
  }

  String? get errorMessage => state.errorMessage;

  Future<void> loadAssessments() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _repository.getAssessments();
      state = state.copyWith(
        assessments: list,
        filteredAssessments: _applyFilters(list),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load assessments: $e',
      );
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(
      searchQuery: query,
      filteredAssessments: _applyFilters(state.assessments, search: query),
    );
  }

  void setStatusFilter(String status) {
    state = state.copyWith(
      selectedStatus: status,
      filteredAssessments: _applyFilters(state.assessments, status: status),
    );
  }

  void setTypeFilter(String type) {
    state = state.copyWith(
      selectedType: type,
      filteredAssessments: _applyFilters(state.assessments, type: type),
    );
  }

  List<Assessment> _applyFilters(
    List<Assessment> list, {
    String? search,
    String? status,
    String? type,
  }) {
    final effectiveSearch = search ?? state.searchQuery;
    final effectiveStatus = status ?? state.selectedStatus;
    final effectiveType = type ?? state.selectedType;

    var result = list;

    if (effectiveStatus != 'all') {
      result = result
          .where((a) => a.status.toLowerCase() == effectiveStatus.toLowerCase())
          .toList();
    }

    if (effectiveType != 'all') {
      result = result
          .where((a) => a.type.toLowerCase() == effectiveType.toLowerCase())
          .toList();
    }

    if (effectiveSearch.trim().isNotEmpty) {
      final q = effectiveSearch.trim().toLowerCase();
      result = result.where((a) {
        return a.title.toLowerCase().contains(q) ||
            a.description.toLowerCase().contains(q);
      }).toList();
    }

    return result;
  }

  Future<bool> createAssessment(Assessment assessment) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final created = await _repository.createAssessment(assessment);
      final updatedList = [created, ...state.assessments];
      state = state.copyWith(
        assessments: updatedList,
        filteredAssessments: _applyFilters(updatedList),
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to create assessment: $e',
      );
      return false;
    }
  }

  Future<bool> updateAssessment(Assessment assessment) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updated = await _repository.updateAssessment(assessment);
      final updatedList = state.assessments
          .map((a) => a.id == updated.id ? updated : a)
          .toList();
      state = state.copyWith(
        assessments: updatedList,
        filteredAssessments: _applyFilters(updatedList),
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update assessment: $e',
      );
      return false;
    }
  }

  Future<bool> updateStatus(String id, String status) async {
    try {
      await _repository.updateAssessmentStatus(id, status);
      final updatedList = state.assessments.map((a) {
        return a.id == id ? a.copyWith(status: status) : a;
      }).toList();
      state = state.copyWith(
        assessments: updatedList,
        filteredAssessments: _applyFilters(updatedList),
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update status: $e');
      return false;
    }
  }

  Future<bool> deleteAssessment(String id) async {
    try {
      await _repository.deleteAssessment(id);
      final updatedList = state.assessments.where((a) => a.id != id).toList();
      state = state.copyWith(
        assessments: updatedList,
        filteredAssessments: _applyFilters(updatedList),
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete assessment: $e');
      return false;
    }
  }
}

final assessmentRepositoryProvider = Provider<AssessmentRepository>((ref) {
  return SupabaseAssessmentRepository();
});

final assessmentNotifierProvider =
    StateNotifierProvider<AssessmentNotifier, AssessmentState>((ref) {
      final repo = ref.watch(assessmentRepositoryProvider);
      return AssessmentNotifier(repo);
    });

final assessmentDetailProvider = FutureProvider.family<Assessment?, String>((
  ref,
  id,
) async {
  final repo = ref.watch(assessmentRepositoryProvider);
  return repo.getAssessmentById(id);
});

final assessmentQuestionsProvider =
    FutureProvider.family<List<Question>, String>((ref, id) async {
      final repo = ref.watch(assessmentRepositoryProvider);
      return repo.getAssessmentQuestions(id);
    });

final assessmentResultsProvider =
    FutureProvider.family<List<AssignmentSubmission>, String>((ref, id) async {
      final repo = ref.watch(assessmentRepositoryProvider);
      return repo.getAssessmentResults(id);
    });
