import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/supabase_client.dart';
import '../../../auth/domain/models/student_profile.dart';
import '../../domain/models/student_dashboard_data.dart';
import '../../domain/repositories/dashboard_repository.dart';

/// Concrete Supabase implementation of DashboardRepository for the student portal
class SupabaseDashboardRepository implements DashboardRepository {
  SupabaseClient get _client => AppSupabase.client;

  @override
  Future<StudentDashboardData> getDashboardData(StudentProfile student) async {
    if (!AppSupabase.isInitialized) {
      throw StateError('Supabase is not initialized.');
    }

    final studentRecordId = student.studentRecordId;
    if (studentRecordId.isEmpty) {
      developer.log('Student record ID is empty, returning blank dashboard', name: 'SupabaseDashboardRepository');
      return StudentDashboardData(
        student: student,
        enrolledCourses: const [],
        totalEnrolledCourses: 0,
        inProgressCourses: 0,
        pendingAssignmentsCount: 0,
        upcomingAssessmentsCount: 0,
        evaluatedResultsCount: 0,
        lastRefreshed: DateTime.now(),
      );
    }

    // 1. Fetch Student Course Enrollments
    final List<EnrolledCourseItem> enrolledCourses = [];
    final List<String> enrolledCourseIds = [];
    final Map<String, Map<String, dynamic>> enrollmentMetaMap = {};

    try {
      final List<dynamic> enrollmentRows = await _client
          .from('course_enrollments')
          .select('id, course_id, status, enrolled_at')
          .eq('student_id', studentRecordId)
          .timeout(const Duration(seconds: 10));

      for (final r in enrollmentRows) {
        final cid = r['course_id']?.toString() ?? '';
        if (cid.isNotEmpty) {
          enrolledCourseIds.add(cid);
          enrollmentMetaMap[cid] = Map<String, dynamic>.from(r as Map);
        }
      }
    } catch (e) {
      developer.log('Error fetching course_enrollments: $e', name: 'SupabaseDashboardRepository');
    }

    // 2. Fetch Course details for enrolled courses
    if (enrolledCourseIds.isNotEmpty) {
      try {
        final List<dynamic> courseRows = await _client
            .from('courses')
            .select('id, title, description, category_name, format, duration_weeks, instructor_id')
            .inFilter('id', enrolledCourseIds)
            .timeout(const Duration(seconds: 10));

        // Optional instructor lookup
        final Set<String> instructorIds = courseRows
            .map((c) => c['instructor_id']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toSet();
        final Map<String, String> instructorMap = {};

        if (instructorIds.isNotEmpty) {
          try {
            final List<dynamic> insRows = await _client
                .from('instructors')
                .select('id, full_name')
                .inFilter('id', instructorIds.toList())
                .timeout(const Duration(seconds: 8));

            for (final ins in insRows) {
              final id = ins['id']?.toString() ?? '';
              final name = ins['full_name']?.toString() ?? 'Faculty Member';
              if (id.isNotEmpty) instructorMap[id] = name;
            }
          } catch (_) {
            // Non-fatal
          }
        }

        for (final c in courseRows) {
          final cMap = Map<String, dynamic>.from(c as Map);
          final cid = cMap['id']?.toString() ?? '';
          final insId = cMap['instructor_id']?.toString() ?? '';
          enrolledCourses.add(
            EnrolledCourseItem.fromData(
              courseMap: cMap,
              enrollmentMap: enrollmentMetaMap[cid],
              instructorName: instructorMap[insId],
            ),
          );
        }
      } catch (e) {
        developer.log('Error fetching courses: $e', name: 'SupabaseDashboardRepository');
      }
    }

    final totalEnrolledCourses = enrolledCourses.length;
    final inProgressCourses = enrolledCourses
        .where((c) => c.enrollmentStatus.toLowerCase() == 'active')
        .length;

    // 3. Fetch Upcoming Live Classes for enrolled courses (or institutional sessions)
    LiveClassItem? nextScheduledSession;
    try {
      // Filter classes scheduled from 2 hours ago onwards
      final threshold = DateTime.now().subtract(const Duration(hours: 2)).toIso8601String();
      final List<dynamic> classRows = await _client
          .from('live_classes')
          .select('*')
          .gte('scheduled_at', threshold)
          .neq('status', 'cancelled')
          .order('scheduled_at', ascending: true)
          .limit(5)
          .timeout(const Duration(seconds: 10));

      if (classRows.isNotEmpty) {
        // Prioritize classes matching student's enrolled courses
        dynamic matchingClass;
        if (enrolledCourseIds.isNotEmpty) {
          for (final c in classRows) {
            final cid = c['course_id']?.toString();
            if (cid != null && enrolledCourseIds.contains(cid)) {
              matchingClass = c;
              break;
            }
          }
        }
        // If no course-specific match, check for institutional general sessions
        if (matchingClass == null) {
          for (final c in classRows) {
            final cid = c['course_id']?.toString();
            if (cid == null || cid.isEmpty) {
              matchingClass = c;
              break;
            }
          }
        }

        if (matchingClass != null) {
          nextScheduledSession = LiveClassItem.fromJson(
            Map<String, dynamic>.from(matchingClass as Map),
          );
        }
      }
    } catch (e) {
      developer.log('Error fetching live_classes: $e', name: 'SupabaseDashboardRepository');
    }

    // 4. Fetch Completed Submissions & Assessment Results for this student
    final Set<String> completedAssessmentIds = {};
    int evaluatedResultsCount = 0;
    double? averageScorePercentage;
    String? averageGrade;

    try {
      final List<dynamic> resultRows = await _client
          .from('assessment_results')
          .select('id, assessment_id, score, total_marks, percentage, passed')
          .eq('student_id', studentRecordId)
          .timeout(const Duration(seconds: 10));

      evaluatedResultsCount = resultRows.length;
      double totalPercentageSum = 0.0;
      int scoredCount = 0;

      for (final r in resultRows) {
        final aId = r['assessment_id']?.toString() ?? '';
        if (aId.isNotEmpty) {
          completedAssessmentIds.add(aId);
        }

        final pct = (r['percentage'] as num?)?.toDouble() ??
            (((r['score'] as num?)?.toDouble() ?? 0.0) /
                (((r['total_marks'] as num?)?.toDouble() ?? 100.0) > 0
                    ? ((r['total_marks'] as num?)?.toDouble() ?? 100.0)
                    : 100.0) *
                100.0);

        if (pct > 0) {
          totalPercentageSum += pct;
          scoredCount++;
        }
      }

      if (scoredCount > 0) {
        averageScorePercentage = totalPercentageSum / scoredCount;
        if (averageScorePercentage >= 90) {
          averageGrade = 'Grade: A+';
        } else if (averageScorePercentage >= 80) {
          averageGrade = 'Grade: A';
        } else if (averageScorePercentage >= 70) {
          averageGrade = 'Grade: B';
        } else if (averageScorePercentage >= 60) {
          averageGrade = 'Grade: C';
        } else {
          averageGrade = 'Grade: D';
        }
      } else if (evaluatedResultsCount > 0) {
        averageGrade = 'Evaluated';
      }
    } catch (e) {
      developer.log('Error fetching assessment_results: $e', name: 'SupabaseDashboardRepository');
    }

    // 5. Fetch Assessments & Assignments assigned to student's courses
    int pendingAssignmentsCount = 0;
    int upcomingAssessmentsCount = 0;

    try {
      final Set<String> assignedAssessmentIds = {};

      if (enrolledCourseIds.isNotEmpty) {
        try {
          final List<dynamic> links = await _client
              .from('assessment_course_assignments')
              .select('assessment_id')
              .inFilter('course_id', enrolledCourseIds)
              .timeout(const Duration(seconds: 8));

          for (final l in links) {
            final aId = l['assessment_id']?.toString() ?? '';
            if (aId.isNotEmpty) assignedAssessmentIds.add(aId);
          }
        } catch (_) {
          // Non-fatal if junction query fails
        }
      }

      if (assignedAssessmentIds.isNotEmpty) {
        final List<dynamic> assessRows = await _client
            .from('assessments')
            .select('id, type, status')
            .inFilter('id', assignedAssessmentIds.toList())
            .timeout(const Duration(seconds: 10));

        for (final a in assessRows) {
          final aId = a['id']?.toString() ?? '';
          final type = (a['type']?.toString() ?? '').toLowerCase();

          // If student already completed this assessment, skip
          if (completedAssessmentIds.contains(aId)) continue;

          if (type == 'assignment' || type == 'project') {
            pendingAssignmentsCount++;
          } else if (type == 'mcq' || type == 'quiz') {
            upcomingAssessmentsCount++;
          }
        }
      }
    } catch (e) {
      developer.log('Error calculating pending assessments/assignments: $e', name: 'SupabaseDashboardRepository');
    }

    return StudentDashboardData(
      student: student,
      enrolledCourses: enrolledCourses,
      totalEnrolledCourses: totalEnrolledCourses,
      inProgressCourses: inProgressCourses,
      pendingAssignmentsCount: pendingAssignmentsCount,
      upcomingAssessmentsCount: upcomingAssessmentsCount,
      evaluatedResultsCount: evaluatedResultsCount,
      averageGrade: averageGrade,
      averageScorePercentage: averageScorePercentage,
      nextScheduledSession: nextScheduledSession,
      lastRefreshed: DateTime.now(),
    );
  }
}
