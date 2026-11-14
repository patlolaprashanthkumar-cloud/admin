import '../../domain/models/student_assignment.dart';

enum AssignmentsListStatus { initial, loading, loaded, error }
enum AssignmentFilter { all, pending, submitted, evaluated, overdue }

/// Immutable state for the student's assignments list
class AssignmentsListState {
  final AssignmentsListStatus status;
  final List<StudentAssignment> assignments;
  final AssignmentFilter activeFilter;
  final String searchQuery;
  final String? errorMessage;

  const AssignmentsListState({
    this.status = AssignmentsListStatus.initial,
    this.assignments = const [],
    this.activeFilter = AssignmentFilter.all,
    this.searchQuery = '',
    this.errorMessage,
  });

  bool get isLoading => status == AssignmentsListStatus.loading;
  bool get hasError => status == AssignmentsListStatus.error;
  bool get isLoaded => status == AssignmentsListStatus.loaded;

  int get pendingCount =>
      assignments.where((a) => !a.isSubmitted && !a.isOverdue).length;
  int get submittedCount =>
      assignments.where((a) => a.isSubmitted && !a.isGraded).length;
  int get evaluatedCount =>
      assignments.where((a) => a.isGraded).length;
  int get overdueCount =>
      assignments.where((a) => a.isOverdue).length;

  List<StudentAssignment> get filteredAssignments {
    return assignments.where((assignment) {
      // Status filter
      switch (activeFilter) {
        case AssignmentFilter.all:
          break;
        case AssignmentFilter.pending:
          if (assignment.isSubmitted || assignment.isOverdue) return false;
          break;
        case AssignmentFilter.submitted:
          if (!assignment.isSubmitted || assignment.isGraded) return false;
          break;
        case AssignmentFilter.evaluated:
          if (!assignment.isGraded) return false;
          break;
        case AssignmentFilter.overdue:
          if (!assignment.isOverdue) return false;
          break;
      }

      // Search filter
      if (searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        final matchesTitle = assignment.title.toLowerCase().contains(q);
        final matchesCourse = assignment.courseTitle.toLowerCase().contains(q);
        final matchesDesc = assignment.description.toLowerCase().contains(q);
        return matchesTitle || matchesCourse || matchesDesc;
      }

      return true;
    }).toList();
  }

  AssignmentsListState copyWith({
    AssignmentsListStatus? status,
    List<StudentAssignment>? assignments,
    AssignmentFilter? activeFilter,
    String? searchQuery,
    String? errorMessage,
  }) {
    return AssignmentsListState(
      status: status ?? this.status,
      assignments: assignments ?? this.assignments,
      activeFilter: activeFilter ?? this.activeFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

enum AssignmentDetailStatus { initial, loading, loaded, error }

/// Immutable state for a single assignment detail view and submission action
class AssignmentDetailState {
  final AssignmentDetailStatus status;
  final StudentAssignment? assignment;
  final bool isSubmitting;
  final String? submissionError;
  final bool submissionSuccess;
  final String? errorMessage;

  const AssignmentDetailState({
    this.status = AssignmentDetailStatus.initial,
    this.assignment,
    this.isSubmitting = false,
    this.submissionError,
    this.submissionSuccess = false,
    this.errorMessage,
  });

  bool get isLoading => status == AssignmentDetailStatus.loading;
  bool get hasError => status == AssignmentDetailStatus.error;
  bool get isLoaded => status == AssignmentDetailStatus.loaded;

  AssignmentDetailState copyWith({
    AssignmentDetailStatus? status,
    StudentAssignment? assignment,
    bool? isSubmitting,
    String? submissionError,
    bool? submissionSuccess,
    String? errorMessage,
  }) {
    return AssignmentDetailState(
      status: status ?? this.status,
      assignment: assignment ?? this.assignment,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submissionError: submissionError,
      submissionSuccess: submissionSuccess ?? this.submissionSuccess,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

