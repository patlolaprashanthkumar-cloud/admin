import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/models/student_profile.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/supabase_assignments_repository.dart';
import '../../domain/repositories/assignments_repository.dart';
import 'assignments_state.dart';

/// Provider exposing the AssignmentsRepository contract
final assignmentsRepositoryProvider = Provider<AssignmentsRepository>((ref) {
  return SupabaseAssignmentsRepository();
});

/// StateNotifierProvider managing the assignments list for the authenticated student
final studentAssignmentsNotifierProvider =
    StateNotifierProvider<StudentAssignmentsNotifier, AssignmentsListState>((ref) {
  final repo = ref.watch(assignmentsRepositoryProvider);
  final authState = ref.watch(authNotifierProvider);
  return StudentAssignmentsNotifier(repo, authState.student);
});

class StudentAssignmentsNotifier extends StateNotifier<AssignmentsListState> {
  final AssignmentsRepository _repository;
  final StudentProfile? _student;

  StudentAssignmentsNotifier(this._repository, this._student)
      : super(const AssignmentsListState()) {
    if (_student != null) {
      loadAssignments();
    }
  }

  /// Loads enrolled course assignments for the active student
  Future<void> loadAssignments() async {
    if (_student == null) {
      state = state.copyWith(
        status: AssignmentsListStatus.error,
        errorMessage: 'No active student session found.',
      );
      return;
    }

    state = state.copyWith(status: AssignmentsListStatus.loading);

    try {
      final assignments =
          await _repository.getStudentAssignments(_student.studentRecordId);
      state = state.copyWith(
        status: AssignmentsListStatus.loaded,
        assignments: assignments,
        errorMessage: null,
      );
    } catch (e, stack) {
      developer.log(
        'Failed to load student assignments: $e',
        name: 'StudentAssignmentsNotifier',
        error: e,
        stackTrace: stack,
      );
      state = state.copyWith(
        status: AssignmentsListStatus.error,
        errorMessage:
            'Unable to load your assignments. Please check connection and retry.',
      );
    }
  }

  /// Changes the active status filter
  void setFilter(AssignmentFilter filter) {
    state = state.copyWith(activeFilter: filter);
  }

  /// Sets the search filter query
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Pull-to-refresh
  Future<void> refresh() async {
    await loadAssignments();
  }
}

/// Family StateNotifierProvider managing details and submission for a specific assignment
final assignmentDetailProvider = StateNotifierProvider.family<
    AssignmentDetailNotifier, AssignmentDetailState, String>((ref, assignmentId) {
  final repo = ref.watch(assignmentsRepositoryProvider);
  final authState = ref.watch(authNotifierProvider);
  final studentRecordId = authState.student?.studentRecordId ?? '';
  return AssignmentDetailNotifier(repo, assignmentId, studentRecordId);
});

class AssignmentDetailNotifier extends StateNotifier<AssignmentDetailState> {
  final AssignmentsRepository _repository;
  final String _assignmentId;
  final String _studentRecordId;

  AssignmentDetailNotifier(
    this._repository,
    this._assignmentId,
    this._studentRecordId,
  ) : super(const AssignmentDetailState()) {
    loadAssignment();
  }

  /// Loads full assignment details and previous submission
  Future<void> loadAssignment() async {
    if (_assignmentId.isEmpty) {
      state = state.copyWith(
        status: AssignmentDetailStatus.error,
        errorMessage: 'Invalid assignment reference.',
      );
      return;
    }

    state = state.copyWith(status: AssignmentDetailStatus.loading);

    try {
      final assignment = await _repository.getAssignmentDetails(
        assignmentId: _assignmentId,
        studentRecordId: _studentRecordId,
      );

      state = state.copyWith(
        status: AssignmentDetailStatus.loaded,
        assignment: assignment,
        errorMessage: null,
      );
    } catch (e, stack) {
      developer.log(
        'Failed to load assignment details for $_assignmentId: $e',
        name: 'AssignmentDetailNotifier',
        error: e,
        stackTrace: stack,
      );
      state = state.copyWith(
        status: AssignmentDetailStatus.error,
        errorMessage:
            'Unable to load assignment details. Please check network and retry.',
      );
    }
  }

  /// Submits the student's deliverable
  Future<bool> submitDeliverable({
    required String submissionText,
    String? attachmentUrl,
  }) async {
    if (_studentRecordId.isEmpty || _assignmentId.isEmpty) return false;

    state = state.copyWith(isSubmitting: true, submissionError: null);

    try {
      final success = await _repository.submitAssignment(
        assignmentId: _assignmentId,
        studentRecordId: _studentRecordId,
        submissionText: submissionText,
        attachmentUrl: attachmentUrl,
      );

      if (success) {
        state = state.copyWith(
          isSubmitting: false,
          submissionSuccess: true,
        );
        // Reload assignment to reflect submission status
        await loadAssignment();
        return true;
      } else {
        state = state.copyWith(
          isSubmitting: false,
          submissionError: 'Submission could not be completed. Please retry.',
        );
        return false;
      }
    } catch (e, stack) {
      developer.log(
        'Error submitting assignment $_assignmentId: $e',
        name: 'AssignmentDetailNotifier',
        error: e,
        stackTrace: stack,
      );
      state = state.copyWith(
        isSubmitting: false,
        submissionError: 'Network error submitting deliverable. Please retry.',
      );
      return false;
    }
  }

  /// Pull-to-refresh
  Future<void> refresh() async {
    await loadAssignment();
  }
}

