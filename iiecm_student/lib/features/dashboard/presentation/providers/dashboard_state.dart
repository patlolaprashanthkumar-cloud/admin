import '../../domain/models/student_dashboard_data.dart';

enum DashboardStatus { initial, loading, loaded, error }

class DashboardState {
  final DashboardStatus status;
  final StudentDashboardData? data;
  final String? errorMessage;

  const DashboardState({
    required this.status,
    this.data,
    this.errorMessage,
  });

  const DashboardState.initial()
      : status = DashboardStatus.initial,
        data = null,
        errorMessage = null;

  const DashboardState.loading({this.data})
      : status = DashboardStatus.loading,
        errorMessage = null;

  const DashboardState.loaded(StudentDashboardData dashboardData)
      : status = DashboardStatus.loaded,
        data = dashboardData,
        errorMessage = null;

  const DashboardState.error(String message, {this.data})
      : status = DashboardStatus.error,
        errorMessage = message;

  bool get isLoading => status == DashboardStatus.loading || status == DashboardStatus.initial;
  bool get isLoaded => status == DashboardStatus.loaded && data != null;
  bool get hasError => status == DashboardStatus.error;
}

