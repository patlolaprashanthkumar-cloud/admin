import '../../../auth/domain/models/student_profile.dart';
import '../models/student_dashboard_data.dart';

/// Contract for student dashboard data retrieval scoped to the authenticated student
abstract class DashboardRepository {
  /// Fetches real consolidated dashboard metrics and schedules for the student
  Future<StudentDashboardData> getDashboardData(StudentProfile student);
}

