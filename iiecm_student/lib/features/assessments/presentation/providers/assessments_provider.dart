import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/models/student_profile.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/supabase_assessments_repository.dart';
import '../../domain/models/assessment_attempt_result.dart';
import '../../domain/repositories/assessments_repository.dart';
import 'assessments_state.dart';

/// Provider exposing the AssessmentsRepository contract
final assessmentsRepositoryProvider = Provider<AssessmentsRepository>((ref) {
  return SupabaseAssessmentsRepository();
});

/// StateNotifierProvider managing the assessments catalog for the active student
final studentAssessmentsNotifierProvider =
    StateNotifierProvider<StudentAssessmentsNotifier, AssessmentsListState>((ref) {
  final repo = ref.watch(assessmentsRepositoryProvider);
  final authState = ref.watch(authNotifierProvider);
  return StudentAssessmentsNotifier(repo, authState.student);
});

class StudentAssessmentsNotifier extends StateNotifier<AssessmentsListState> {
  final AssessmentsRepository _repository;
  final StudentProfile? _student;

  StudentAssessmentsNotifier(this._repository, this._student)
      : super(const AssessmentsListState()) {
    if (_student != null) {
      loadAssessments();
    }
  }

  /// Loads assessments allocated to student's enrolled courses
  Future<void> loadAssessments() async {
    if (_student == null) {
      state = state.copyWith(
        status: AssessmentsListStatus.error,
        errorMessage: 'No active student session found.',
      );
      return;
    }

    state = state.copyWith(status: AssessmentsListStatus.loading);

    try {
      final assessments =
          await _repository.getStudentAssessments(_student.studentRecordId);
      state = state.copyWith(
        status: AssessmentsListStatus.loaded,
        assessments: assessments,
        errorMessage: null,
      );
    } catch (e, stack) {
      developer.log(
        'Failed to load student assessments: $e',
        name: 'StudentAssessmentsNotifier',
        error: e,
        stackTrace: stack,
      );
      state = state.copyWith(
        status: AssessmentsListStatus.error,
        errorMessage:
            'Unable to load your examinations. Please check network and retry.',
      );
    }
  }

  void setFilter(AssessmentFilter filter) {
    state = state.copyWith(activeFilter: filter);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> refresh() async {
    await loadAssessments();
  }
}

/// Family StateNotifierProvider managing assessment details and instructions
final assessmentDetailProvider = StateNotifierProvider.family<
    AssessmentDetailNotifier, AssessmentDetailState, String>((ref, assessmentId) {
  final repo = ref.watch(assessmentsRepositoryProvider);
  final authState = ref.watch(authNotifierProvider);
  final studentRecordId = authState.student?.studentRecordId ?? '';
  return AssessmentDetailNotifier(repo, assessmentId, studentRecordId);
});

class AssessmentDetailNotifier extends StateNotifier<AssessmentDetailState> {
  final AssessmentsRepository _repository;
  final String _assessmentId;
  final String _studentRecordId;

  AssessmentDetailNotifier(
    this._repository,
    this._assessmentId,
    this._studentRecordId,
  ) : super(const AssessmentDetailState()) {
    loadDetails();
  }

  Future<void> loadDetails() async {
    if (_assessmentId.isEmpty) {
      state = state.copyWith(
        status: AssessmentDetailStatus.error,
        errorMessage: 'Invalid examination reference.',
      );
      return;
    }

    state = state.copyWith(status: AssessmentDetailStatus.loading);

    try {
      final assessment = await _repository.getAssessmentDetails(
        assessmentId: _assessmentId,
        studentRecordId: _studentRecordId,
      );

      final questions =
          await _repository.getAssessmentQuestions(_assessmentId);

      state = state.copyWith(
        status: AssessmentDetailStatus.loaded,
        assessment: assessment,
        questions: questions,
        errorMessage: null,
      );
    } catch (e, stack) {
      developer.log(
        'Error loading assessment $_assessmentId: $e',
        name: 'AssessmentDetailNotifier',
        error: e,
        stackTrace: stack,
      );
      state = state.copyWith(
        status: AssessmentDetailStatus.error,
        errorMessage: 'Unable to load examination details.',
      );
    }
  }

  Future<void> refresh() async {
    await loadDetails();
  }
}

/// Family StateNotifierProvider managing the live timed examination attempt session
final assessmentAttemptProvider = StateNotifierProvider.family<
    AssessmentAttemptNotifier, AssessmentAttemptState, String>((ref, assessmentId) {
  final repo = ref.watch(assessmentsRepositoryProvider);
  final authState = ref.watch(authNotifierProvider);
  final studentRecordId = authState.student?.studentRecordId ?? '';
  return AssessmentAttemptNotifier(repo, assessmentId, studentRecordId);
});

class AssessmentAttemptNotifier extends StateNotifier<AssessmentAttemptState> {
  final AssessmentsRepository _repository;
  final String _assessmentId;
  final String _studentRecordId;
  Timer? _timer;

  AssessmentAttemptNotifier(
    this._repository,
    this._assessmentId,
    this._studentRecordId,
  ) : super(const AssessmentAttemptState());

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Initializes the attempt session with duration and starts timer
  void startSession(int durationMinutes) {
    _timer?.cancel();
    final totalSeconds = durationMinutes > 0 ? durationMinutes * 60 : 3600;
    state = state.copyWith(remainingSeconds: totalSeconds);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds > 1) {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      } else {
        timer.cancel();
        state = state.copyWith(remainingSeconds: 0);
        // Time expired auto-submit
        submitAttempt();
      }
    });
  }

  /// Selects or changes answer for a question
  void selectAnswer(String questionId, String optionId) {
    final updated = Map<String, String>.from(state.selectedAnswers);
    updated[questionId] = optionId;
    state = state.copyWith(selectedAnswers: updated);
  }

  /// Navigates to a specific question index
  void goToQuestion(int index) {
    state = state.copyWith(currentQuestionIndex: index);
  }

  /// Submits the completed examination attempt
  Future<AssessmentAttemptResult?> submitAttempt() async {
    if (state.isSubmitting || state.isCompleted) return state.result;

    _timer?.cancel();
    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      final result = await _repository.submitAssessmentAttempt(
        assessmentId: _assessmentId,
        studentRecordId: _studentRecordId,
        selectedAnswers: state.selectedAnswers,
      );

      state = state.copyWith(
        isSubmitting: false,
        isCompleted: true,
        result: result,
      );
      return result;
    } catch (e, stack) {
      developer.log(
        'Error submitting assessment $_assessmentId attempt: $e',
        name: 'AssessmentAttemptNotifier',
        error: e,
        stackTrace: stack,
      );
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Network error submitting examination. Please retry.',
      );
      return null;
    }
  }
}

