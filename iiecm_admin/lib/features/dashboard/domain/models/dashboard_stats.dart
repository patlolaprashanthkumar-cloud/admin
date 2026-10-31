/// Domain models representing executive institutional statistics and telemetry
class MonthlyMetricPoint {
  final String month;
  final int enrolments;
  final double revenue;

  const MonthlyMetricPoint({
    required this.month,
    required this.enrolments,
    required this.revenue,
  });
}

class RecentStudentItem {
  final String id;
  final String studentId;
  final String fullName;
  final String preferredCategory;
  final String accountStatus;
  final DateTime createdAt;

  const RecentStudentItem({
    required this.id,
    required this.studentId,
    required this.fullName,
    required this.preferredCategory,
    required this.accountStatus,
    required this.createdAt,
  });
}

class RecentEnrollmentItem {
  final String courseTitle;
  final String studentName;
  final DateTime enrolledAt;

  const RecentEnrollmentItem({
    required this.courseTitle,
    required this.studentName,
    required this.enrolledAt,
  });
}

class UpcomingLiveClassItem {
  final String id;
  final String title;
  final String courseName;
  final String instructorName;
  final DateTime scheduledAt;

  const UpcomingLiveClassItem({
    required this.id,
    required this.title,
    required this.courseName,
    required this.instructorName,
    required this.scheduledAt,
  });
}

class DashboardStats {
  final int totalStudents;
  final int activeStudents;
  final int totalInstructors;
  final int publishedCourses;
  final double verifiedRevenue;
  final int pendingPayments;
  final int admissionsLeads;
  final int totalEnquiries;
  final int activeAssessments;
  final int careerAppointmentsCount;
  final int resourcesCount;
  final int categoriesCount;
  final int unreadNotifications;
  final List<MonthlyMetricPoint> monthlyMetrics;
  final Map<String, int> paymentBreakdown;
  final List<RecentStudentItem> recentStudents;
  final List<RecentEnrollmentItem> recentEnrollments;
  final List<UpcomingLiveClassItem> upcomingLiveClasses;

  const DashboardStats({
    required this.totalStudents,
    required this.activeStudents,
    required this.totalInstructors,
    required this.publishedCourses,
    required this.verifiedRevenue,
    required this.pendingPayments,
    required this.admissionsLeads,
    required this.totalEnquiries,
    required this.activeAssessments,
    required this.careerAppointmentsCount,
    required this.resourcesCount,
    required this.categoriesCount,
    required this.unreadNotifications,
    required this.monthlyMetrics,
    required this.paymentBreakdown,
    required this.recentStudents,
    required this.recentEnrollments,
    required this.upcomingLiveClasses,
  });

  factory DashboardStats.empty() {
    return const DashboardStats(
      totalStudents: 0,
      activeStudents: 0,
      totalInstructors: 0,
      publishedCourses: 0,
      verifiedRevenue: 0.0,
      pendingPayments: 0,
      admissionsLeads: 0,
      totalEnquiries: 0,
      activeAssessments: 0,
      careerAppointmentsCount: 0,
      resourcesCount: 0,
      categoriesCount: 0,
      unreadNotifications: 0,
      monthlyMetrics: [],
      paymentBreakdown: {},
      recentStudents: [],
      recentEnrollments: [],
      upcomingLiveClasses: [],
    );
  }
}

