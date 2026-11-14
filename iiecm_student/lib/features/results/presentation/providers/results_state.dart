import '../../domain/models/student_result.dart';

enum ResultsStatus { initial, loading, loaded, error }

enum ResultFilterType {
  all,
  assessments,
  assignments,
  passed,
  failed;

  String get label {
    switch (this) {
      case ResultFilterType.all:
        return 'All Results';
      case ResultFilterType.assessments:
        return 'Assessments';
      case ResultFilterType.assignments:
        return 'Assignments';
      case ResultFilterType.passed:
        return 'Passed';
      case ResultFilterType.failed:
        return 'Needs Revision';
    }
  }
}

class ResultsState {
  final ResultsStatus status;
  final List<StudentResult> results;
  final ResultFilterType filter;
  final String searchQuery;
  final String? errorMessage;

  const ResultsState({
    this.status = ResultsStatus.initial,
    this.results = const [],
    this.filter = ResultFilterType.all,
    this.searchQuery = '',
    this.errorMessage,
  });

  bool get isLoading => status == ResultsStatus.loading;
  bool get hasError => status == ResultsStatus.error;
  bool get isLoaded => status == ResultsStatus.loaded;

  /// Returns results filtered by selected filter tab and search query
  List<StudentResult> get filteredResults {
    var list = results;

    switch (filter) {
      case ResultFilterType.assessments:
        list = list.where((r) => r.isAssessment).toList();
        break;
      case ResultFilterType.assignments:
        list = list.where((r) => r.isAssignment).toList();
        break;
      case ResultFilterType.passed:
        list = list.where((r) => r.passed).toList();
        break;
      case ResultFilterType.failed:
        list = list.where((r) => !r.passed).toList();
        break;
      case ResultFilterType.all:
        break;
    }

    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      list = list.where((r) {
        return r.title.toLowerCase().contains(q) ||
            r.courseTitle.toLowerCase().contains(q) ||
            r.type.displayName.toLowerCase().contains(q);
      }).toList();
    }

    return list;
  }

  int get totalCount => results.length;
  int get passedCount => results.where((r) => r.passed).length;
  int get failedCount => results.where((r) => !r.passed).length;

  double get averagePercentage {
    if (results.isEmpty) return 0.0;
    final sum = results.fold<double>(0.0, (acc, r) => acc + r.percentage);
    return sum / results.length;
  }

  ResultsState copyWith({
    ResultsStatus? status,
    List<StudentResult>? results,
    ResultFilterType? filter,
    String? searchQuery,
    String? errorMessage,
  }) {
    return ResultsState(
      status: status ?? this.status,
      results: results ?? this.results,
      filter: filter ?? this.filter,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage,
    );
  }
}

