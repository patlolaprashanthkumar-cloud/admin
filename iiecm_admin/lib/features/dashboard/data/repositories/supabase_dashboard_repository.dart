import 'dart:developer' as developer;
import 'package:intl/intl.dart';
import '../../../../core/network/supabase_client.dart';
import '../../domain/models/dashboard_stats.dart';
import '../../domain/repositories/dashboard_repository.dart';

class SupabaseDashboardRepository implements DashboardRepository {
  @override
  Future<DashboardStats> getDashboardStats() async {
    final client = AppSupabase.client;

    // 1. Fetch Students
    List<dynamic> studentsData = [];
    try {
      studentsData = await client
          .from('students')
          .select('id, student_id, full_name, preferred_category, account_status, created_at')
          .order('created_at', ascending: false);
    } catch (e) {
      developer.log('Error fetching students for dashboard: $e', name: 'SupabaseDashboardRepository');
    }

    final totalStudents = studentsData.length;
    final activeStudents = studentsData.where((s) => s['account_status'] == 'active').length;

    // Student ID to Name map for recent enrollment resolution
    final Map<String, String> studentNameMap = {};
    for (final s in studentsData) {
      studentNameMap[s['id'].toString()] = s['full_name']?.toString() ?? 'Student';
    }

    final recentStudents = studentsData.take(5).map((s) {
      return RecentStudentItem(
        id: s['id']?.toString() ?? '',
        studentId: s['student_id']?.toString() ?? 'N/A',
        fullName: s['full_name']?.toString() ?? 'Unknown Student',
        preferredCategory: s['preferred_category']?.toString() ?? 'General',
        accountStatus: s['account_status']?.toString() ?? 'active',
        createdAt: s['created_at'] != null ? DateTime.tryParse(s['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
      );
    }).toList();

    // 2. Fetch Instructors Count
    int totalInstructors = 0;
    try {
      final instructorsRes = await client.from('instructors').select('id');
      totalInstructors = instructorsRes.length;
    } catch (e) {
      developer.log('Error fetching instructors count: $e', name: 'SupabaseDashboardRepository');
    }

    // 3. Fetch Courses
    List<dynamic> coursesData = [];
    final Map<String, String> courseTitleMap = {};
    try {
      coursesData = await client.from('courses').select('id, title, status, created_at');
      for (final c in coursesData) {
        courseTitleMap[c['id'].toString()] = c['title']?.toString() ?? 'Course';
      }
    } catch (e) {
      developer.log('Error fetching courses: $e', name: 'SupabaseDashboardRepository');
    }
    final publishedCourses = coursesData.where((c) => c['status'] == 'published').length;

    // 4. Fetch Payments
    List<dynamic> paymentsData = [];
    try {
      paymentsData = await client
          .from('payments')
          .select('id, amount, status, payment_date')
          .order('payment_date', ascending: false);
    } catch (e) {
      developer.log('Error fetching payments: $e', name: 'SupabaseDashboardRepository');
    }

    double verifiedRevenue = 0.0;
    int pendingPayments = 0;
    final Map<String, int> paymentBreakdown = {
      'verified': 0,
      'pending': 0,
      'rejected': 0,
      'failed': 0,
      'refunded': 0,
    };

    for (final p in paymentsData) {
      final status = (p['status']?.toString().toLowerCase() ?? 'pending');
      final amount = (p['amount'] is num) ? (p['amount'] as num).toDouble() : double.tryParse(p['amount']?.toString() ?? '0') ?? 0.0;

      paymentBreakdown[status] = (paymentBreakdown[status] ?? 0) + 1;
      if (status == 'verified') {
        verifiedRevenue += amount;
      } else if (status == 'pending') {
        pendingPayments += 1;
      }
    }

    // 5. Fetch Enquiries / Leads
    List<dynamic> enquiriesData = [];
    try {
      enquiriesData = await client.from('enquiries').select('id, status');
    } catch (e) {
      developer.log('Error fetching enquiries: $e', name: 'SupabaseDashboardRepository');
    }
    final totalEnquiries = enquiriesData.length;
    final admissionsLeads = enquiriesData.where((e) {
      final status = e['status']?.toString().toLowerCase();
      return status == 'new' || status == 'follow_up';
    }).length;

    // 6. Fetch Recent Enrollments
    List<RecentEnrollmentItem> recentEnrollments = [];
    try {
      final enrollmentsData = await client
          .from('course_enrollments')
          .select('course_id, student_id, enrolled_at')
          .order('enrolled_at', ascending: false)
          .limit(5);

      recentEnrollments = enrollmentsData.map((e) {
        final courseId = e['course_id']?.toString() ?? '';
        final studentId = e['student_id']?.toString() ?? '';
        return RecentEnrollmentItem(
          courseTitle: courseTitleMap[courseId] ?? 'Specialized Curricula',
          studentName: studentNameMap[studentId] ?? 'Registered Student',
          enrolledAt: e['enrolled_at'] != null ? DateTime.tryParse(e['enrolled_at'].toString()) ?? DateTime.now() : DateTime.now(),
        );
      }).toList();
    } catch (e) {
      developer.log('Error fetching course enrollments: $e', name: 'SupabaseDashboardRepository');
    }

    // 7. Fetch Upcoming Live Classes
    List<UpcomingLiveClassItem> upcomingLiveClasses = [];
    try {
      final classesData = await client
          .from('live_classes')
          .select('id, title, course_name, instructor_name, scheduled_at, status')
          .order('scheduled_at', ascending: true)
          .limit(4);

      upcomingLiveClasses = classesData.map((c) {
        return UpcomingLiveClassItem(
          id: c['id']?.toString() ?? '',
          title: c['title']?.toString() ?? 'Clinical Lecture',
          courseName: c['course_name']?.toString() ?? 'Emergency Medicine',
          instructorName: c['instructor_name']?.toString() ?? 'Faculty Consultant',
          scheduledAt: c['scheduled_at'] != null ? DateTime.tryParse(c['scheduled_at'].toString()) ?? DateTime.now() : DateTime.now(),
        );
      }).toList();
    } catch (e) {
      developer.log('Error fetching live classes: $e', name: 'SupabaseDashboardRepository');
    }

    // 8. Supplementary Management Hubs telemetry
    int activeAssessments = 0;
    try {
      final assessmentsRes = await client.from('assessments').select('id, status');
      activeAssessments = assessmentsRes.where((a) {
        final st = a['status']?.toString().toLowerCase();
        return st == 'active' || st == 'scheduled';
      }).length;
    } catch (_) {}

    int careerAppointmentsCount = 0;
    try {
      final careerRes = await client.from('career_appointments').select('id');
      careerAppointmentsCount = careerRes.length;
    } catch (_) {}

    int resourcesCount = 0;
    try {
      final res = await client.from('resources').select('id');
      resourcesCount = res.length;
    } catch (_) {}

    int categoriesCount = 0;
    try {
      final catRes = await client.from('course_categories').select('id');
      categoriesCount = catRes.length;
    } catch (_) {}

    int unreadNotifications = 0;
    try {
      final notifRes = await client.from('notifications').select('id, read');
      unreadNotifications = notifRes.where((n) => n['read'] == false).length;
    } catch (_) {}

    // 9. Calculate Monthly Rolling Metrics (Past 6 months)
    final now = DateTime.now();
    final List<MonthlyMetricPoint> monthlyMetrics = [];
    final monthFormat = DateFormat('MMM');

    for (int i = 5; i >= 0; i--) {
      final targetDate = DateTime(now.year, now.month - i, 1);
      final monthLabel = monthFormat.format(targetDate);
      final monthYear = targetDate.year;
      final monthNumber = targetDate.month;

      // Count enrolments in this month
      int monthEnrolments = 0;
      for (final s in studentsData) {
        if (s['created_at'] != null) {
          final dt = DateTime.tryParse(s['created_at'].toString());
          if (dt != null && dt.year == monthYear && dt.month == monthNumber) {
            monthEnrolments++;
          }
        }
      }

      // Sum verified revenue in this month
      double monthRevenue = 0.0;
      for (final p in paymentsData) {
        final status = p['status']?.toString().toLowerCase();
        if (status == 'verified' && p['payment_date'] != null) {
          final dt = DateTime.tryParse(p['payment_date'].toString());
          if (dt != null && dt.year == monthYear && dt.month == monthNumber) {
            final amt = (p['amount'] is num) ? (p['amount'] as num).toDouble() : double.tryParse(p['amount']?.toString() ?? '0') ?? 0.0;
            monthRevenue += amt;
          }
        }
      }

      monthlyMetrics.add(
        MonthlyMetricPoint(
          month: monthLabel,
          enrolments: monthEnrolments,
          revenue: monthRevenue,
        ),
      );
    }

    return DashboardStats(
      totalStudents: totalStudents,
      activeStudents: activeStudents,
      totalInstructors: totalInstructors,
      publishedCourses: publishedCourses,
      verifiedRevenue: verifiedRevenue,
      pendingPayments: pendingPayments,
      admissionsLeads: admissionsLeads,
      totalEnquiries: totalEnquiries,
      activeAssessments: activeAssessments,
      careerAppointmentsCount: careerAppointmentsCount,
      resourcesCount: resourcesCount,
      categoriesCount: categoriesCount,
      unreadNotifications: unreadNotifications,
      monthlyMetrics: monthlyMetrics,
      paymentBreakdown: paymentBreakdown,
      recentStudents: recentStudents,
      recentEnrollments: recentEnrollments,
      upcomingLiveClasses: upcomingLiveClasses,
    );
  }
}

