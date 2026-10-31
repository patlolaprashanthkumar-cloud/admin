import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iiecm_admin/core/widgets/stat_kpi_card.dart';
import 'package:iiecm_admin/features/dashboard/domain/models/dashboard_stats.dart';
import 'package:iiecm_admin/features/dashboard/presentation/widgets/payment_breakdown_chart.dart';

void main() {
  group('DashboardStats Model Tests', () {
    test('DashboardStats.empty produces clean zero-initialized telemetry', () {
      final stats = DashboardStats.empty();

      expect(stats.totalStudents, 0);
      expect(stats.activeStudents, 0);
      expect(stats.totalInstructors, 0);
      expect(stats.publishedCourses, 0);
      expect(stats.verifiedRevenue, 0.0);
      expect(stats.pendingPayments, 0);
      expect(stats.admissionsLeads, 0);
      expect(stats.monthlyMetrics, isEmpty);
      expect(stats.paymentBreakdown, isEmpty);
      expect(stats.recentStudents, isEmpty);
      expect(stats.recentEnrollments, isEmpty);
      expect(stats.upcomingLiveClasses, isEmpty);
    });

    test('Constructs DashboardStats correctly with populated telemetry', () {
      final stats = DashboardStats(
        totalStudents: 150,
        activeStudents: 142,
        totalInstructors: 12,
        publishedCourses: 8,
        verifiedRevenue: 450000.0,
        pendingPayments: 5,
        admissionsLeads: 18,
        totalEnquiries: 45,
        activeAssessments: 3,
        careerAppointmentsCount: 7,
        resourcesCount: 24,
        categoriesCount: 6,
        unreadNotifications: 2,
        monthlyMetrics: [
          const MonthlyMetricPoint(month: 'Oct', enrolments: 25, revenue: 85000.0),
        ],
        paymentBreakdown: {'verified': 85, 'pending': 5},
        recentStudents: [
          RecentStudentItem(
            id: 's-1',
            studentId: 'STU-001',
            fullName: 'Rahul Sharma',
            preferredCategory: 'Emergency Medicine',
            accountStatus: 'active',
            createdAt: DateTime.now(),
          ),
        ],
        recentEnrollments: [
          RecentEnrollmentItem(
            courseTitle: 'Critical Care Fellowship',
            studentName: 'Rahul Sharma',
            enrolledAt: DateTime.now(),
          ),
        ],
        upcomingLiveClasses: [
          UpcomingLiveClassItem(
            id: 'c-1',
            title: 'Cardiopulmonary Resuscitation',
            courseName: 'Emergency Medicine',
            instructorName: 'Dr. Nair',
            scheduledAt: DateTime.now(),
          ),
        ],
      );

      expect(stats.totalStudents, 150);
      expect(stats.activeStudents, 142);
      expect(stats.verifiedRevenue, 450000.0);
      expect(stats.recentStudents.first.fullName, 'Rahul Sharma');
      expect(stats.recentEnrollments.first.courseTitle, 'Critical Care Fellowship');
      expect(stats.upcomingLiveClasses.first.instructorName, 'Dr. Nair');
    });
  });

  group('Dashboard Widget Tests', () {
    testWidgets('StatKpiCard renders values and labels accurately', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatKpiCard(
              label: 'Total Students',
              value: '150',
              icon: Icons.people_rounded,
              accentColor: const Color(0xFF0F2744),
              trendLabel: '142 active',
              isTrendPositive: true,
            ),
          ),
        ),
      );

      expect(find.text('Total Students'), findsOneWidget);
      expect(find.text('150'), findsOneWidget);
      expect(find.text('142 active'), findsOneWidget);
    });

    testWidgets('PaymentBreakdownChart displays empty state when transactions count is 0', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PaymentBreakdownChart(breakdown: {}),
          ),
        ),
      );

      expect(find.text('No fee payment transactions found.'), findsOneWidget);
    });
  });
}

