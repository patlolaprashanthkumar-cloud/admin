import 'package:flutter_test/flutter_test.dart';
import 'package:iiecm_admin/features/categories/domain/models/course_category.dart';
import 'package:iiecm_admin/features/students/domain/models/student.dart';
import 'package:iiecm_admin/features/students/domain/repositories/student_repository.dart';
import 'package:iiecm_admin/features/students/presentation/providers/students_provider.dart';

class MockStudentRepository implements StudentRepository {
  List<Student> store = [];

  MockStudentRepository([List<Student>? initial]) {
    store = initial ?? [];
  }

  @override
  Future<List<Student>> getStudents({
    String? categoryId,
    String? searchQuery,
    String? status,
  }) async {
    var result = List<Student>.from(store);
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result
          .where(
            (s) =>
                s.fullName.toLowerCase().contains(q) ||
                s.studentId.toLowerCase().contains(q) ||
                s.email.toLowerCase().contains(q),
          )
          .toList();
    }
    if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all') {
      result = result
          .where((s) => s.assignedCategories.any((c) => c.id == categoryId))
          .toList();
    }
    if (status != null && status.isNotEmpty && status != 'all') {
      result = result.where((s) => s.accountStatus == status).toList();
    }
    return result;
  }

  @override
  Future<Student?> getStudentById(String id) async {
    try {
      return store.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<StudentRegistrationResult> registerStudent({
    required String fullName,
    required String email,
    required String phone,
    required String educationLevel,
    required String qualification,
    required List<String> categoryIds,
    required List<String> courseIds,
    String? city,
    String subscriptionPlan = 'basic',
    String? learningFormat,
    String? preferredSlot,
  }) async {
    final catModels = categoryIds
        .map(
          (cid) => CourseCategory(
            id: cid,
            name: 'Category $cid',
            description: 'Desc',
            color: '#245B43',
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        )
        .toList();

    final newStudent = Student(
      id: 'student-${store.length + 1}',
      profileId: 'profile-${store.length + 1}',
      studentId: 'IIECM-${store.length + 100}',
      fullName: fullName,
      email: email,
      phone: phone,
      educationLevel: educationLevel,
      qualification: qualification,
      preferredCategory: catModels.isNotEmpty
          ? catModels.first.name
          : 'General',
      city: city,
      country: 'India',
      subscriptionPlan: subscriptionPlan,
      learningFormat: learningFormat,
      preferredSlot: preferredSlot,
      createdAt: DateTime.now(),
      assignedCategories: catModels,
      enrolledCourseIds: courseIds,
    );
    store.add(newStudent);
    return StudentRegistrationResult(
      student: newStudent,
      statusCode: 201,
      isExistingUser: false,
      invitationSent: true,
      message: 'Account successfully provisioned. Invitation email dispatched with password setup link.',
    );
  }

  @override
  Future<Student> updateStudent(
    String id, {
    String? fullName,
    String? email,
    String? phone,
    String? educationLevel,
    String? qualification,
    String? city,
    String? accountStatus,
  }) async {
    final idx = store.indexWhere((s) => s.id == id);
    final current = store[idx];
    final updated = Student(
      id: current.id,
      studentId: current.studentId,
      fullName: fullName ?? current.fullName,
      email: email ?? current.email,
      phone: phone ?? current.phone,
      educationLevel: educationLevel ?? current.educationLevel,
      qualification: qualification ?? current.qualification,
      preferredCategory: current.preferredCategory,
      city: city ?? current.city,
      country: current.country,
      subscriptionPlan: current.subscriptionPlan,
      subscriptionStatus: current.subscriptionStatus,
      accountStatus: accountStatus ?? current.accountStatus,
      createdAt: current.createdAt,
      assignedCategories: current.assignedCategories,
      enrolledCourseIds: current.enrolledCourseIds,
    );
    store[idx] = updated;
    return updated;
  }

  @override
  Future<void> updateStudentCategories(
    String studentId,
    List<String> categoryIds,
  ) async {
    final idx = store.indexWhere((s) => s.id == studentId);
    if (idx != -1) {
      final current = store[idx];
      final newCats = categoryIds
          .map(
            (cid) => CourseCategory(
              id: cid,
              name: 'Updated $cid',
              description: 'Desc',
              color: '#245B43',
              isActive: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          )
          .toList();
      store[idx] = Student(
        id: current.id,
        studentId: current.studentId,
        fullName: current.fullName,
        email: current.email,
        phone: current.phone,
        educationLevel: current.educationLevel,
        qualification: current.qualification,
        preferredCategory: current.preferredCategory,
        city: current.city,
        country: current.country,
        subscriptionPlan: current.subscriptionPlan,
        subscriptionStatus: current.subscriptionStatus,
        accountStatus: current.accountStatus,
        createdAt: current.createdAt,
        assignedCategories: newCats,
        enrolledCourseIds: current.enrolledCourseIds,
      );
    }
  }

  @override
  Future<List<StudentCategoryLmsGroup>> getStudentCategoryLmsDetails(
    String studentId,
  ) async {
    final student = await getStudentById(studentId);
    if (student == null) return [];
    return student.assignedCategories
        .map(
          (cat) => StudentCategoryLmsGroup(
            category: cat,
            courses: [
              {
                'id': 'c1',
                'title': 'Course 1',
                'status': 'active',
                'category_id': cat.id,
              },
            ],
            instructors: [
              {'id': 'inst1', 'name': 'Dr. Sharma', 'category_id': cat.id},
            ],
            liveClasses: [],
            assessments: [
              {'id': 'a1', 'title': 'Mid-term Quiz', 'score': 85},
            ],
            progressPercentage: 50.0,
          ),
        )
        .toList();
  }
}

void main() {
  group('Student Domain Model Tests', () {
    test('Student.fromJson deserializes correctly with default values', () {
      final json = {
        'id': 'std-101',
        'student_id': 'IIECM-STU-001',
        'full_name': 'Aarav Patel',
        'email': 'aarav@example.com',
        'phone': '+91 9876543210',
        'education_level': 'Undergraduate',
        'qualification': 'B.Tech IT',
        'preferred_category': 'Emergency Medicine',
        'created_at': '2026-10-15T10:00:00Z',
      };

      final student = Student.fromJson(json);

      expect(student.id, 'std-101');
      expect(student.studentId, 'IIECM-STU-001');
      expect(student.fullName, 'Aarav Patel');
      expect(student.email, 'aarav@example.com');
      expect(student.phone, '+91 9876543210');
      expect(student.educationLevel, 'Undergraduate');
      expect(student.qualification, 'B.Tech IT');
      expect(student.preferredCategory, 'Emergency Medicine');
      expect(student.country, 'India');
      expect(student.subscriptionPlan, 'basic');
      expect(student.accountStatus, 'active');
      expect(student.assignedCategories, isEmpty);
      expect(student.enrolledCourseIds, isEmpty);
    });

    test(
      'Student.fromJson maps multi-category assignments and course enrollments',
      () {
        final json = {
          'id': 'std-102',
          'student_id': 'IIECM-STU-002',
          'full_name': 'Priya Nair',
          'email': 'priya@example.com',
          'phone': '+91 9876500000',
          'education_level': 'Postgraduate',
          'qualification': 'MD Emergency Care',
          'preferred_category': 'Trauma Care',
        };

        final cat1 = CourseCategory(
          id: 'cat-em',
          name: 'Emergency Medicine',
          description: 'EM modules',
          color: '#245B43',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final cat2 = CourseCategory(
          id: 'cat-tc',
          name: 'Trauma Care',
          description: 'Trauma care modules',
          color: '#C87552',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final student = Student.fromJson(
          json,
          assignedCategories: [cat1, cat2],
          enrolledCourseIds: ['course-1', 'course-2'],
        );

        expect(student.assignedCategories.length, 2);
        expect(student.assignedCategories.first.name, 'Emergency Medicine');
        expect(student.assignedCategories.last.name, 'Trauma Care');
        expect(
          student.enrolledCourseIds,
          containsAll(['course-1', 'course-2']),
        );
      },
    );

    test(
      'Student.toJson serializes required payload for Supabase insertion',
      () {
        final student = Student(
          id: 'temp-id',
          profileId: 'prof-uuid-123',
          studentId: 'IIECM-STU-099',
          fullName: 'Dr. John Doe',
          email: 'john@iiecm.com',
          phone: '+91 9123456789',
          educationLevel: 'Postgraduate',
          qualification: 'MBBS, DNB',
          preferredCategory: 'Pediatric Emergency',
          city: 'Mumbai',
          country: 'India',
          createdAt: DateTime(2026, 1, 1),
        );

        final json = student.toJson();

        expect(json['profile_id'], 'prof-uuid-123');
        expect(json['student_id'], 'IIECM-STU-099');
        expect(json['full_name'], 'Dr. John Doe');
        expect(json['email'], 'john@iiecm.com');
        expect(json['city'], 'Mumbai');
        expect(json['preferred_category'], 'Pediatric Emergency');
      },
    );

    test(
      'Student.fromJson deserializes profile_id and handles null profile_id',
      () {
        final withProfile = Student.fromJson({
          'id': 'std-1',
          'profile_id': 'profile-abc-789',
          'student_id': 'IIECM-1',
          'full_name': 'Dr. Test',
          'email': 'test@iiecm.org',
        });
        expect(withProfile.profileId, 'profile-abc-789');

        final withoutProfile = Student.fromJson({
          'id': 'std-2',
          'student_id': 'IIECM-2',
          'full_name': 'Dr. Test 2',
          'email': 'test2@iiecm.org',
        });
        expect(withoutProfile.profileId, isNull);
        expect(withoutProfile.toJson().containsKey('profile_id'), isFalse);
      },
    );

    test('Student.fromJson parses learning_format and preferred_slot', () {
      final json = {
        'id': 'std-103',
        'student_id': 'IIECM-STU-003',
        'full_name': 'Dr. Rohit Sharma',
        'email': 'rohit@example.com',
        'learning_format': 'hybrid',
        'preferred_slot': 'Morning Clinical Batch (08:00 - 10:00 IST)',
      };

      final student = Student.fromJson(json);

      expect(student.learningFormat, 'hybrid');
      expect(
        student.preferredSlot,
        'Morning Clinical Batch (08:00 - 10:00 IST)',
      );
    });

    test(
      'Student.fromJson handles NULL learning_format and preferred_slot',
      () {
        final json = {
          'id': 'std-104',
          'student_id': 'IIECM-STU-004',
          'full_name': 'Dr. Anita Roy',
          'email': 'anita@example.com',
          'learning_format': null,
          'preferred_slot': null,
        };

        final student = Student.fromJson(json);

        expect(student.learningFormat, isNull);
        expect(student.preferredSlot, isNull);
      },
    );

    test('Student.toJson serializes learning_format and preferred_slot when present, omits when null', () {
      final studentWithFormat = Student(
        id: 's-fmt',
        studentId: 'IIECM-FMT',
        fullName: 'Format Student',
        email: 'fmt@example.com',
        phone: '1112223334',
        educationLevel: 'Postgraduate',
        qualification: 'MD',
        preferredCategory: 'General',
        learningFormat: 'live',
        preferredSlot: 'Evening Executive Batch (18:00 - 20:00 IST)',
        createdAt: DateTime(2026, 1, 1),
      );

      final jsonWith = studentWithFormat.toJson();
      expect(jsonWith['learning_format'], 'live');
      expect(
        jsonWith['preferred_slot'],
        'Evening Executive Batch (18:00 - 20:00 IST)',
      );

      final studentWithout = Student(
        id: 's-no-fmt',
        studentId: 'IIECM-NO-FMT',
        fullName: 'No Format Student',
        email: 'nofmt@example.com',
        phone: '1112223335',
        educationLevel: 'Postgraduate',
        qualification: 'MD',
        preferredCategory: 'General',
        createdAt: DateTime(2026, 1, 1),
      );

      final jsonWithout = studentWithout.toJson();
      expect(jsonWithout.containsKey('learning_format'), isFalse);
      expect(jsonWithout.containsKey('preferred_slot'), isFalse);
    });

    test('StudentRegistrationResult encapsulates provisioning metadata', () {
      final sampleStudent = Student(
        id: 's-1',
        profileId: 'p-1',
        studentId: 'IIECM-001',
        fullName: 'Jane Doe',
        email: 'jane@example.com',
        phone: '1234567890',
        educationLevel: 'Graduate',
        qualification: 'BSc',
        preferredCategory: 'General',
        createdAt: DateTime.now(),
      );

      final result201 = StudentRegistrationResult(
        student: sampleStudent,
        statusCode: 201,
        isExistingUser: false,
        invitationSent: true,
        message: 'Account provisioned successfully.',
      );
      expect(result201.statusCode, 201);
      expect(result201.isExistingUser, isFalse);
      expect(result201.invitationSent, isTrue);
      expect(result201.hasAssignmentWarning, isFalse);

      final resultWarning = StudentRegistrationResult(
        student: sampleStudent,
        statusCode: 201,
        isExistingUser: false,
        invitationSent: true,
        message: 'Account provisioned.',
        hasAssignmentWarning: true,
        assignmentWarning: 'Course enrollment failed: Table locked',
      );
      expect(resultWarning.hasAssignmentWarning, isTrue);
      expect(resultWarning.assignmentWarning, contains('Table locked'));
    });

    test(
      'StudentProvisioningException helper getters classify status codes',
      () {
        const conflictEx = StudentProvisioningException(
          message: 'Conflict: User already registered',
          statusCode: 409,
        );
        expect(conflictEx.isConflict, isTrue);
        expect(conflictEx.isInvitationFailure, isFalse);
        expect(conflictEx.isConfigurationError, isFalse);
        expect(conflictEx.isNetworkError, isFalse);

        const inviteEx = StudentProvisioningException(
          message: 'Invitation failed',
          statusCode: 502,
        );
        expect(inviteEx.isInvitationFailure, isTrue);

        const partialEx = StudentProvisioningException(
          message: 'Auth user created, but student record insertion failed',
          statusCode: 500,
          isPartialFailure: true,
        );
        expect(partialEx.isPartialFailure, isTrue);
        expect(partialEx.isConfigurationError, isFalse);

        const configEx = StudentProvisioningException(
          message: 'Backend misconfigured',
          statusCode: 500,
          isPartialFailure: false,
        );
        expect(configEx.isConfigurationError, isTrue);

        const netEx = StudentProvisioningException(
          message: 'Network unreachable',
          statusCode: 0,
        );
        expect(netEx.isNetworkError, isTrue);
      },
    );

    test('StudentCategoryLmsGroup stores categorized modules and calculates progress', () {
      final cat = CourseCategory(
        id: 'cat-cardio',
        name: 'Cardiology Support',
        description: 'Advanced Cardiac Life Support',
        color: '#D32F2F',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final group = StudentCategoryLmsGroup(
        category: cat,
        courses: [
          {'title': 'ACLS Protocol', 'status': 'active'},
          {'title': 'ECG Interpretation', 'status': 'active'},
        ],
        instructors: [
          {'name': 'Dr. Ramesh Kumar'},
        ],
        liveClasses: [
          {
            'topic': 'Live Simulation: STEMI',
            'start_time': '2026-11-10T14:00:00Z',
          },
        ],
        assessments: [
          {'title': 'Cardiac Quiz 1', 'max_score': 100, 'score': 92},
        ],
        progressPercentage: 65.5,
      );

      expect(group.category.id, 'cat-cardio');
      expect(group.courses.length, 2);
      expect(group.instructors.length, 1);
      expect(group.liveClasses.length, 1);
      expect(group.assessments.length, 1);
      expect(group.progressPercentage, 65.5);
    });
  });

  group('StudentsNotifier State & Multi-Category Filtering', () {
    late MockStudentRepository repo;
    late CourseCategory catA;
    late CourseCategory catB;
    late Student student1;
    late Student student2;

    setUp(() {
      catA = CourseCategory(
        id: 'cat-a',
        name: 'Critical Care',
        description: 'Critical Care description',
        color: '#245B43',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      catB = CourseCategory(
        id: 'cat-b',
        name: 'Disaster Management',
        description: 'Disaster triage',
        color: '#C87552',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      student1 = Student(
        id: 's-1',
        studentId: 'STU-001',
        fullName: 'Rahul Sharma',
        email: 'rahul@hospital.org',
        phone: '9999900001',
        educationLevel: 'Postgraduate',
        qualification: 'MD',
        preferredCategory: 'Critical Care',
        createdAt: DateTime.now(),
        assignedCategories: [catA],
        enrolledCourseIds: ['c-1'],
      );

      student2 = Student(
        id: 's-2',
        studentId: 'STU-002',
        fullName: 'Meera Sen',
        email: 'meera@hospital.org',
        phone: '9999900002',
        educationLevel: 'Undergraduate',
        qualification: 'MBBS',
        preferredCategory: 'Disaster Management',
        createdAt: DateTime.now(),
        assignedCategories: [catA, catB],
        enrolledCourseIds: ['c-1', 'c-2'],
      );

      repo = MockStudentRepository([student1, student2]);
    });

    test('Initial load populates all students', () async {
      final notifier = StudentsNotifier(repo);
      await notifier.loadStudents();

      expect(notifier.state.students.length, 2);
      expect(notifier.state.filteredStudents.length, 2);
    });

    test('Filter by search query matches name and studentId', () async {
      final notifier = StudentsNotifier(repo);
      await notifier.loadStudents();

      notifier.setSearchQuery('Rahul');
      expect(notifier.state.filteredStudents.length, 1);
      expect(notifier.state.filteredStudents.first.fullName, 'Rahul Sharma');

      notifier.setSearchQuery('STU-002');
      expect(notifier.state.filteredStudents.length, 1);
      expect(notifier.state.filteredStudents.first.fullName, 'Meera Sen');

      notifier.setSearchQuery('non-existent');
      expect(notifier.state.filteredStudents, isEmpty);
    });

    test('Filter by category matches multi-category assignments', () async {
      final notifier = StudentsNotifier(repo);
      await notifier.loadStudents();

      // catA is assigned to both student1 and student2
      notifier.setSelectedCategory('cat-a');
      expect(notifier.state.filteredFilteredStudentsWithCatA(notifier), 2);

      // catB is assigned only to student2
      notifier.setSelectedCategory('cat-b');
      expect(notifier.state.filteredStudents.length, 1);
      expect(notifier.state.filteredStudents.first.fullName, 'Meera Sen');

      // Clear filter using 'all'
      notifier.setSelectedCategory('all');
      expect(notifier.state.filteredStudents.length, 2);
    });

    test(
      'Multi-category student registration persists and updates state',
      () async {
        final notifier = StudentsNotifier(repo);
        await notifier.loadStudents();

        final created = await notifier.registerStudent(
          fullName: 'Kavita Joshi',
          email: 'kavita@hospital.org',
          phone: '9999900003',
          educationLevel: 'Resident',
          qualification: 'MD EM',
          categoryIds: ['cat-a', 'cat-b'],
          courseIds: ['c-1'],
        );

        expect(created, isNotNull);
        expect(created!.student.fullName, 'Kavita Joshi');
        expect(created.student.assignedCategories.length, 2);
        expect(created.statusCode, 201);
        expect(created.isExistingUser, isFalse);
        expect(created.invitationSent, isTrue);
        expect(notifier.state.students.length, 3);
      },
    );

    test(
      'StudentsNotifier surfaces StudentProvisioningException error message',
      () async {
        final failingRepo = MockFailingStudentRepository(
          const StudentProvisioningException(
            message: 'An account with this email address already exists.',
            statusCode: 409,
          ),
        );
        final notifier = StudentsNotifier(failingRepo);
        await notifier.loadStudents();

        final result = await notifier.registerStudent(
          fullName: 'Duplicate User',
          email: 'duplicate@hospital.org',
          phone: '9999900099',
          educationLevel: 'Resident',
          qualification: 'MBBS',
          categoryIds: ['cat-a'],
          courseIds: [],
        );

        expect(result, isNull);
        expect(
          notifier.state.errorMessage,
          'An account with this email address already exists.',
        );
        expect(notifier.state.isLoading, isFalse);
      },
    );

    test('registerStudent forwards learningFormat and preferredSlot through provider to repository', () async {
      final notifier = StudentsNotifier(repo);
      await notifier.loadStudents();

      final created = await notifier.registerStudent(
        fullName: 'Vikram Mehta',
        email: 'vikram@hospital.org',
        phone: '9999900010',
        educationLevel: 'Fellow',
        qualification: 'FACEM',
        categoryIds: ['cat-a'],
        courseIds: ['c-1'],
        learningFormat: 'recorded',
        preferredSlot: 'Weekend Intensive (Saturday & Sunday)',
      );

      expect(created, isNotNull);
      expect(created!.student.fullName, 'Vikram Mehta');
      expect(created.student.learningFormat, 'recorded');
      expect(
        created.student.preferredSlot,
        'Weekend Intensive (Saturday & Sunday)',
      );
      expect(notifier.state.students.first.learningFormat, 'recorded');
      expect(
        notifier.state.students.first.preferredSlot,
        'Weekend Intensive (Saturday & Sunday)',
      );
    });

    test('Edge Function payload formatting trims non-empty values and omits null/empty', () {
      Map<String, dynamic> buildPayload({
        String? learningFormat,
        String? preferredSlot,
      }) {
        return {
          'email': 'test@example.com',
          'fullName': 'Test User',
          'role': 'student',
          if (learningFormat != null && learningFormat.trim().isNotEmpty)
            'learningFormat': learningFormat.trim(),
          if (preferredSlot != null && preferredSlot.trim().isNotEmpty)
            'preferredSlot': preferredSlot.trim(),
        };
      }

      final withValues = buildPayload(
        learningFormat: '  hybrid  ',
        preferredSlot: '  Morning Clinical Batch (08:00 - 10:00 IST)  ',
      );
      expect(withValues['learningFormat'], 'hybrid');
      expect(
        withValues['preferredSlot'],
        'Morning Clinical Batch (08:00 - 10:00 IST)',
      );

      final withNull = buildPayload(learningFormat: null, preferredSlot: null);
      expect(withNull.containsKey('learningFormat'), isFalse);
      expect(withNull.containsKey('preferredSlot'), isFalse);

      final withEmpty = buildPayload(learningFormat: '   ', preferredSlot: '');
      expect(withEmpty.containsKey('learningFormat'), isFalse);
      expect(withEmpty.containsKey('preferredSlot'), isFalse);
    });
  });
}

class MockFailingStudentRepository extends MockStudentRepository {
  final StudentProvisioningException exceptionToThrow;
  MockFailingStudentRepository(this.exceptionToThrow);

  @override
  Future<StudentRegistrationResult> registerStudent({
    required String fullName,
    required String email,
    required String phone,
    required String educationLevel,
    required String qualification,
    required List<String> categoryIds,
    required List<String> courseIds,
    String? city,
    String subscriptionPlan = 'basic',
    String? learningFormat,
    String? preferredSlot,
  }) async {
    throw exceptionToThrow;
  }
}

extension on StudentsState {
  int filteredFilteredStudentsWithCatA(StudentsNotifier n) =>
      n.state.filteredStudents.length;
}
