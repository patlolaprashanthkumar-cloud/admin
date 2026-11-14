import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/models/student_profile.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/supabase_results_repository.dart';
import '../../domain/models/student_result.dart';
import '../../domain/repositories/results_repository.dart';
import 'results_state.dart';

/// Provider exposing the ResultsRepository abstraction
final resultsRepositoryProvider = Provider<ResultsRepository>((ref) {
  return SupabaseResultsRepository();
});

/// StateNotifierProvider managing student academic results
final studentResultsNotifierProvider =
    StateNotifierProvider<StudentResultsNotifier, ResultsState>((ref) {
  final repo = ref.watch(resultsRepositoryProvider);
  final authState = ref.watch(authNotifierProvider);
  return StudentResultsNotifier(repo, authState.student);
});

class StudentResultsNotifier extends StateNotifier<ResultsState> {
  final ResultsRepository _repository;
  final StudentProfile? _student;

  StudentResultsNotifier(this._repository, this._student)
      : super(const ResultsState()) {
    if (_student != null) {
      loadResults();
    }
  }

  /// Loads results scoped strictly to the authenticated student's record
  Future<void> loadResults() async {
    if (_student == null) {
      state = state.copyWith(
        status: ResultsStatus.error,
        errorMessage: 'No active authenticated student session found.',
      );
      return;
    }

    state = state.copyWith(status: ResultsStatus.loading);

    try {
      final results =
          await _repository.getStudentResults(_student.studentRecordId);
      state = state.copyWith(
        status: ResultsStatus.loaded,
        results: results,
        errorMessage: null,
      );
    } catch (e, stack) {
      developer.log(
        'Failed to load student results: $e',
        name: 'StudentResultsNotifier',
        error: e,
        stackTrace: stack,
      );
      state = state.copyWith(
        status: ResultsStatus.error,
        errorMessage:
            'Unable to retrieve academic results. Please check your network connection.',
      );
    }
  }

  Future<void> refresh() => loadResults();

  void setFilter(ResultFilterType filter) {
    state = state.copyWith(filter: filter);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }
}

/// Provider for retrieving specific result details by resultId
final studentResultDetailProvider =
    FutureProvider.family<StudentResult?, String>((ref, resultId) async {
  final repo = ref.watch(resultsRepositoryProvider);
  final authState = ref.watch(authNotifierProvider);
  final student = authState.student;

  if (student == null || resultId.isEmpty) return null;

  return repo.getResultDetails(
    resultId: resultId,
    studentRecordId: student.studentRecordId,
  );
});

