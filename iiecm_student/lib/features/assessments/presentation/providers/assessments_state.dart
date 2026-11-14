import '../../domain/models/assessment_attempt_result.dart';
import '../../domain/models/assessment_question.dart';
import '../../domain/models/student_assessment.dart';

enum AssessmentsListStatus { initial, loading, loaded, error }
enum AssessmentFilter { all, available, scheduled, completed }

/// Immutable state for the student's examinations and assessments list
class AssessmentsListState {
  final AssessmentsListStatus status;
  final List<StudentAssessment> assessments;
  final AssessmentFilter activeFilter;
  final String searchQuery;
  final String? errorMessage;

  const AssessmentsListState({
    this.status = AssessmentsListStatus.initial,
    this.assessments = const [],
    this.activeFilter = AssessmentFilter.all,
    this.searchQuery = '',
    this.errorMessage,
  });

  bool get isLoading => status == AssessmentsListStatus.loading;
  bool get hasError => status == AssessmentsListStatus.error;
  bool get isLoaded => status == AssessmentsListStatus.loaded;

  int get availableCount => assessments.where((a) => a.isAvailable).length;
  int get scheduledCount => assessments.where((a) => a.isUpcoming).length;
  int get completedCount => assessments.where((a) => a.isCompleted).length;

  List<StudentAssessment> get filteredAssessments {
    return assessments.where((assessment) {
      // Filter tab
      switch (activeFilter) {
        case AssessmentFilter.all:
          break;
        case AssessmentFilter.available:
          if (!assessment.isAvailable) return false;
          break;
        case AssessmentFilter.scheduled:
          if (!assessment.isUpcoming) return false;
          break;
        case AssessmentFilter.completed:
          if (!assessment.isCompleted) return false;
          break;
      }

      // Search query
      if (searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        final matchesTitle = assessment.title.toLowerCase().contains(q);
        final matchesCourse = assessment.courseTitle.toLowerCase().contains(q);
        final matchesDesc = assessment.description.toLowerCase().contains(q);
        return matchesTitle || matchesCourse || matchesDesc;
      }

      return true;
    }).toList();
  }

  AssessmentsListState copyWith({
    AssessmentsListStatus? status,
    List<StudentAssessment>? assessments,
    AssessmentFilter? activeFilter,
    String? searchQuery,
    String? errorMessage,
  }) {
    return AssessmentsListState(
      status: status ?? this.status,
      assessments: assessments ?? this.assessments,
      activeFilter: activeFilter ?? this.activeFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

enum AssessmentDetailStatus { initial, loading, loaded, error }

/// Immutable state for an assessment instruction overview
class AssessmentDetailState {
  final AssessmentDetailStatus status;
  final StudentAssessment? assessment;
  final List<StudentQuestion> questions;
  final String? errorMessage;

  const AssessmentDetailState({
    this.status = AssessmentDetailStatus.initial,
    this.assessment,
    this.questions = const [],
    this.errorMessage,
  });

  bool get isLoading => status == AssessmentDetailStatus.loading;
  bool get hasError => status == AssessmentDetailStatus.error;
  bool get isLoaded => status == AssessmentDetailStatus.loaded;

  AssessmentDetailState copyWith({
    AssessmentDetailStatus? status,
    StudentAssessment? assessment,
    List<StudentQuestion>? questions,
    String? errorMessage,
  }) {
    return AssessmentDetailState(
      status: status ?? this.status,
      assessment: assessment ?? this.assessment,
      questions: questions ?? this.questions,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Immutable state for an active timed assessment attempt session
class AssessmentAttemptState {
  final int currentQuestionIndex;
  final Map<String, String> selectedAnswers; // questionId -> optionId
  final int remainingSeconds;
  final bool isSubmitting;
  final bool isCompleted;
  final AssessmentAttemptResult? result;
  final String? errorMessage;

  const AssessmentAttemptState({
    this.currentQuestionIndex = 0,
    this.selectedAnswers = const {},
    this.remainingSeconds = 3600,
    this.isSubmitting = false,
    this.isCompleted = false,
    this.result,
    this.errorMessage,
  });

  int get answeredCount => selectedAnswers.length;

  AssessmentAttemptState copyWith({
    int? currentQuestionIndex,
    Map<String, String>? selectedAnswers,
    int? remainingSeconds,
    bool? isSubmitting,
    bool? isCompleted,
    AssessmentAttemptResult? result,
    String? errorMessage,
  }) {
    return AssessmentAttemptState(
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isCompleted: isCompleted ?? this.isCompleted,
      result: result ?? this.result,
      errorMessage: errorMessage,
    );
  }
}

