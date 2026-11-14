import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iiecm_student/app/app.dart';
import 'package:iiecm_student/features/assessments/domain/models/assessment_attempt_result.dart';
import 'package:iiecm_student/features/assessments/domain/models/assessment_question.dart';
import 'package:iiecm_student/features/assessments/domain/models/student_assessment.dart';
import 'package:iiecm_student/features/assessments/domain/repositories/assessments_repository.dart';
import 'package:iiecm_student/features/assessments/presentation/providers/assessments_provider.dart';
import 'package:iiecm_student/features/assessments/presentation/screens/assessments_screen.dart';
import 'package:iiecm_student/features/assignments/domain/models/student_assignment.dart';
import 'package:iiecm_student/features/assignments/domain/repositories/assignments_repository.dart';
import 'package:iiecm_student/features/assignments/presentation/providers/assignments_provider.dart';
import 'package:iiecm_student/features/auth/domain/models/student_profile.dart';
import 'package:iiecm_student/features/auth/presentation/login_screen.dart';
import 'package:iiecm_student/features/auth/presentation/providers/auth_provider.dart';
import 'package:iiecm_student/features/auth/presentation/providers/auth_state.dart';
import 'package:iiecm_student/features/courses/domain/models/course_lesson.dart';
import 'package:iiecm_student/features/courses/domain/models/course_module.dart';
import 'package:iiecm_student/features/courses/domain/models/student_course.dart';
import 'package:iiecm_student/features/courses/domain/repositories/courses_repository.dart';
import 'package:iiecm_student/features/courses/presentation/providers/courses_provider.dart';
import 'package:iiecm_student/features/courses/presentation/screens/my_courses_screen.dart';
import 'package:iiecm_student/features/dashboard/domain/models/student_dashboard_data.dart';
import 'package:iiecm_student/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:iiecm_student/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:iiecm_student/features/payments/domain/models/student_payment.dart';
import 'package:iiecm_student/features/payments/domain/repositories/payments_repository.dart';
import 'package:iiecm_student/features/payments/presentation/providers/payments_provider.dart';
import 'package:iiecm_student/features/results/domain/models/student_result.dart';
import 'package:iiecm_student/features/results/domain/repositories/results_repository.dart';
import 'package:iiecm_student/features/results/presentation/providers/results_provider.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeDashboardRepository implements DashboardRepository {
  @override
  Future<StudentDashboardData> getDashboardData(StudentProfile student) async {
    return StudentDashboardData(
      student: student,
      enrolledCourses: const [
        EnrolledCourseItem(
          courseId: 'c1',
          title: 'Advanced Emergency Protocols',
          categoryName: 'Emergency Medicine',
          enrollmentStatus: 'active',
          format: 'hybrid',
          durationWeeks: 12,
        ),
      ],
      totalEnrolledCourses: 1,
      inProgressCourses: 1,
      pendingAssignmentsCount: 0,
      upcomingAssessmentsCount: 1,
      evaluatedResultsCount: 1,
      averageGrade: 'Grade: A',
      lastRefreshed: DateTime.now(),
    );
  }
}

class FakeCoursesRepository implements CoursesRepository {
  @override
  Future<List<StudentCourse>> getEnrolledCourses(String studentRecordId) async {
    return [
      StudentCourse(
        id: 'c1',
        title: 'Advanced Emergency Protocols',
        description: 'Comprehensive clinical emergency training curriculum',
        categoryName: 'Emergency Medicine',
        format: 'hybrid',
        durationWeeks: 12,
        enrollmentStatus: 'active',
        instructorName: 'Dr. Ramesh Kumar',
        createdAt: DateTime.now(),
      ),
    ];
  }

  @override
  Future<StudentCourse?> getCourseDetails(String courseId, String studentRecordId) async {
    return StudentCourse(
      id: courseId,
      title: 'Advanced Emergency Protocols',
      description: 'Comprehensive clinical emergency training curriculum',
      categoryName: 'Emergency Medicine',
      format: 'hybrid',
      durationWeeks: 12,
      enrollmentStatus: 'active',
      instructorName: 'Dr. Ramesh Kumar',
      learningObjectives: const ['Airway management', 'Trauma life support'],
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<List<CourseModule>> getCourseModules(String courseId) async {
    return [
      CourseModule(
        id: 'm1',
        courseId: courseId,
        title: 'Module 1: Resuscitation Protocols',
        orderIndex: 1,
        createdAt: DateTime.now(),
        lessons: [
          CourseLesson(
            id: 'l1',
            moduleId: 'm1',
            title: 'Initial Trauma Assessment',
            durationMinutes: 30,
            type: 'video',
            contentUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
            createdAt: DateTime.now(),
          ),
        ],
      ),
    ];
  }
}

class FakeAssessmentsRepository implements AssessmentsRepository {
  @override
  Future<List<StudentAssessment>> getStudentAssessments(String studentRecordId) async {
    return [
      StudentAssessment(
        id: 'exam-1',
        title: 'Emergency Medicine MCQ Checkpoint',
        description: 'Comprehensive multiple choice clinical assessment',
        courseTitle: 'Advanced Emergency Protocols',
        status: 'active',
        scheduledAt: DateTime.now().subtract(const Duration(hours: 1)),
        questionCount: 10,
        createdAt: DateTime.now(),
      ),
    ];
  }

  @override
  Future<StudentAssessment?> getAssessmentDetails({
    required String assessmentId,
    required String studentRecordId,
  }) async {
    return StudentAssessment(
      id: assessmentId,
      title: 'Emergency Medicine MCQ Checkpoint',
      courseTitle: 'Advanced Emergency Protocols',
      status: 'active',
      scheduledAt: DateTime.now().subtract(const Duration(hours: 1)),
      questionCount: 10,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<List<StudentQuestion>> getAssessmentQuestions(String assessmentId) async {
    return [
      const StudentQuestion(
        id: 'q1',
        questionText: 'First-line medication in anaphylaxis?',
        options: [
          StudentQuestionOption(id: 'opt1', text: 'Epinephrine IM'),
          StudentQuestionOption(id: 'opt2', text: 'Oral Antihistamine'),
        ],
        marks: 2,
        orderIndex: 1,
        correctOptionId: 'opt1',
      ),
    ];
  }

  @override
  Future<AssessmentAttemptResult?> submitAssessmentAttempt({
    required String assessmentId,
    required String studentRecordId,
    required Map<String, String> selectedAnswers,
  }) async {
    return AssessmentAttemptResult(
      assessmentId: assessmentId,
      studentId: studentRecordId,
      score: 2.0,
      totalMarks: 2.0,
      percentage: 100.0,
      passed: true,
      completedAt: DateTime.now(),
    );
  }
}

class FakeAssignmentsRepository implements AssignmentsRepository {
  @override
  Future<List<StudentAssignment>> getStudentAssignments(String studentRecordId) async {
    return [
      StudentAssignment(
        id: 'ass-1',
        title: 'Trauma Resuscitation Case Write-up',
        courseTitle: 'Advanced Emergency Protocols',
        createdAt: DateTime.now(),
      ),
    ];
  }

  @override
  Future<StudentAssignment?> getAssignmentDetails({
    required String assignmentId,
    required String studentRecordId,
  }) async {
    return StudentAssignment(
      id: assignmentId,
      title: 'Trauma Resuscitation Case Write-up',
      courseTitle: 'Advanced Emergency Protocols',
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<bool> submitAssignment({
    required String assignmentId,
    required String studentRecordId,
    required String submissionText,
    String? attachmentUrl,
  }) async {
    return true;
  }
}

class FakeResultsRepository implements ResultsRepository {
  @override
  Future<List<StudentResult>> getStudentResults(String studentRecordId) async {
    return [
      StudentResult(
        id: 'r1',
        assessmentId: 'a1',
        title: 'Trauma Evaluation Checkpoint',
        type: ResultType.mcq,
        courseTitle: 'Advanced Emergency Protocols',
        score: 85,
        totalMarks: 100,
        percentage: 85,
        passed: true,
        completedAt: DateTime.now(),
      ),
    ];
  }

  @override
  Future<StudentResult?> getResultDetails({
    required String resultId,
    required String studentRecordId,
  }) async {
    return StudentResult(
      id: resultId,
      assessmentId: 'a1',
      title: 'Trauma Evaluation Checkpoint',
      type: ResultType.mcq,
      courseTitle: 'Advanced Emergency Protocols',
      score: 85,
      totalMarks: 100,
      percentage: 85,
      passed: true,
      completedAt: DateTime.now(),
    );
  }
}

class FakePaymentsRepository implements PaymentsRepository {
  @override
  Future<List<StudentPayment>> getStudentPayments(String studentRecordId) async {
    return [
      StudentPayment(
        id: 'p1',
        transactionRef: 'TXN-101',
        studentId: studentRecordId,
        studentName: 'Dr. Anita Roy',
        amount: 25000,
        paymentMethod: 'razorpay',
        status: 'verified',
        courseName: 'Advanced Emergency Protocols',
        paymentDate: DateTime.now(),
      ),
    ];
  }

  @override
  Future<StudentPayment?> getPaymentDetails({
    required String paymentId,
    required String studentRecordId,
  }) async {
    return StudentPayment(
      id: paymentId,
      transactionRef: 'TXN-101',
      studentId: studentRecordId,
      studentName: 'Dr. Anita Roy',
      amount: 25000,
      paymentMethod: 'razorpay',
      status: 'verified',
      courseName: 'Advanced Emergency Protocols',
      paymentDate: DateTime.now(),
    );
  }
}

void main() {
  testWidgets('Unauthenticated user is redirected to LoginScreen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(
            (ref) => MockAuthNotifier(const AuthState.unauthenticated()),
          ),
        ],
        child: const IIECMStudentApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Login screen elements render
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Sign In to Student Portal'), findsOneWidget);
    expect(find.text('Registered Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });

  testWidgets('Authenticated student accesses Dashboard and Navigation Shell', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    const testStudent = StudentProfile(
      userId: 'test-user-id',
      studentRecordId: 'test-student-rec',
      studentId: 'IIECM-2026-STU-001',
      fullName: 'Dr. Anita Roy',
      email: 'anita.roy@iiecm.org',
      role: 'student',
      accountStatus: 'active',
      qualification: 'MBBS',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(
            (ref) => MockAuthNotifier(const AuthState.authenticated(testStudent)),
          ),
          dashboardRepositoryProvider.overrideWithValue(FakeDashboardRepository()),
          coursesRepositoryProvider.overrideWithValue(FakeCoursesRepository()),
          assessmentsRepositoryProvider.overrideWithValue(FakeAssessmentsRepository()),
          assignmentsRepositoryProvider.overrideWithValue(FakeAssignmentsRepository()),
          resultsRepositoryProvider.overrideWithValue(FakeResultsRepository()),
          paymentsRepositoryProvider.overrideWithValue(FakePaymentsRepository()),
        ],
        child: const IIECMStudentApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Dashboard screen renders with student information
    expect(find.text('IIECM Student Portal'), findsOneWidget);
    expect(find.text('Welcome back, Dr.'), findsOneWidget);
    expect(find.textContaining('IIECM-2026-STU-001'), findsOneWidget);

    // Locate NavigationBar
    final navBarFinder = find.byType(NavigationBar);
    expect(navBarFinder, findsOneWidget);

    // Verify destinations
    expect(find.descendant(of: navBarFinder, matching: find.text('Home')), findsOneWidget);
    expect(find.descendant(of: navBarFinder, matching: find.text('My Courses')), findsOneWidget);
    expect(find.descendant(of: navBarFinder, matching: find.text('Assessments')), findsOneWidget);
    expect(find.descendant(of: navBarFinder, matching: find.text('Profile')), findsOneWidget);

    // Tap My Courses branch
    await tester.tap(find.descendant(of: navBarFinder, matching: find.text('My Courses')));
    await tester.pumpAndSettle();

    expect(find.byType(MyCoursesScreen), findsOneWidget);
    expect(find.text('My Enrolled Courses'), findsOneWidget);
    expect(find.text('Advanced Emergency Protocols'), findsOneWidget);

    // Tap Assessments branch
    await tester.tap(find.descendant(of: navBarFinder, matching: find.text('Assessments')));
    await tester.pumpAndSettle();

    expect(find.byType(AssessmentsScreen), findsOneWidget);
    expect(find.text('Examinations & Checkpoints'), findsOneWidget);
    expect(find.text('Emergency Medicine MCQ Checkpoint'), findsOneWidget);

    // Tap Profile branch
    await tester.tap(find.descendant(of: navBarFinder, matching: find.text('Profile')));
    await tester.pumpAndSettle();

    expect(find.text('Student Dossier & Profile'), findsOneWidget);
    expect(find.text('Dr. Anita Roy'), findsOneWidget);
    expect(find.text('Sign Out of Student Portal'), findsOneWidget);
  });

  testWidgets('Authenticated student can access Results and Payments portals', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    const testStudent = StudentProfile(
      userId: 'test-user-id',
      studentRecordId: 'test-student-rec',
      studentId: 'IIECM-2026-STU-001',
      fullName: 'Dr. Anita Roy',
      email: 'anita.roy@iiecm.org',
      role: 'student',
      accountStatus: 'active',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(
            (ref) => MockAuthNotifier(const AuthState.authenticated(testStudent)),
          ),
          dashboardRepositoryProvider.overrideWithValue(FakeDashboardRepository()),
          coursesRepositoryProvider.overrideWithValue(FakeCoursesRepository()),
          assessmentsRepositoryProvider.overrideWithValue(FakeAssessmentsRepository()),
          assignmentsRepositoryProvider.overrideWithValue(FakeAssignmentsRepository()),
          resultsRepositoryProvider.overrideWithValue(FakeResultsRepository()),
          paymentsRepositoryProvider.overrideWithValue(FakePaymentsRepository()),
        ],
        child: const IIECMStudentApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Quick Portals has Results and Fee Status
    final resultsQuickActionFinder = find.byKey(const Key('quick_action_results'));
    expect(resultsQuickActionFinder, findsOneWidget);
    expect(find.descendant(of: resultsQuickActionFinder, matching: find.text('Results')), findsOneWidget);
    expect(find.text('Fee Status'), findsOneWidget);

    // Tap Results quick action
    await tester.tap(resultsQuickActionFinder);
    await tester.pumpAndSettle();

    // Verify Academic Results screen
    expect(find.text('Academic Results'), findsOneWidget);
    expect(find.text('Academic Performance Record'), findsOneWidget);
    expect(find.text('Trauma Evaluation Checkpoint'), findsOneWidget);

    // Navigate back to Dashboard
    final navigator = tester.state<NavigatorState>(find.byType(Navigator).last);
    navigator.pop();
    await tester.pumpAndSettle();

    // Tap Fee Status quick action
    await tester.tap(find.text('Fee Status'));
    await tester.pumpAndSettle();

    // Verify Fee Status & Receipts screen
    expect(find.text('Fee Status & Receipts'), findsOneWidget);
    expect(find.text('Tuition & Fee Records'), findsOneWidget);
    expect(find.text('REC-TXN101'), findsOneWidget);
  });
}
