import 'package:flutter_test/flutter_test.dart';
import 'package:iiecm_admin/features/categories/domain/models/course_category.dart';
import 'package:iiecm_admin/features/faculty/domain/models/faculty.dart';
import 'package:iiecm_admin/features/faculty/domain/repositories/faculty_repository.dart';
import 'package:iiecm_admin/features/faculty/presentation/providers/faculty_provider.dart';

class MockFacultyRepository implements FacultyRepository {
  List<Faculty> store = [];
  final int nextStatusCode;
  final bool nextIsExistingUser;
  final bool nextInvitationSent;
  final bool nextHasAssignmentWarning;
  final String? nextAssignmentWarning;

  MockFacultyRepository({
    List<Faculty>? initial,
    this.nextStatusCode = 201,
    this.nextIsExistingUser = false,
    this.nextInvitationSent = true,
    this.nextHasAssignmentWarning = false,
    this.nextAssignmentWarning,
  }) {
    store = initial ?? [];
  }

  @override
  Future<List<Faculty>> getFaculty({
    String? categoryId,
    String? status,
    String? searchQuery,
  }) async {
    return List<Faculty>.from(store);
  }

  @override
  Future<Faculty?> getFacultyById(String id) async {
    try {
      return store.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<FacultyRegistrationResult> createFaculty(
    Faculty faculty, {
    List<String> categoryIds = const [],
    List<String> courseIds = const [],
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

    final courseRefs = courseIds
        .map(
          (cId) => FacultyCourseRef(
            id: cId,
            title: 'Course $cId',
            categoryName: 'General',
          ),
        )
        .toList();

    final newFaculty = faculty.copyWith(
      id: faculty.id.isNotEmpty ? faculty.id : 'inst-${store.length + 1}',
      profileId: faculty.profileId ?? 'prof-${store.length + 1}',
      assignedCategories: catModels,
      assignedCourseIds: courseIds,
      assignedCourses: courseRefs,
    );

    store.add(newFaculty);

    return FacultyRegistrationResult(
      faculty: newFaculty,
      statusCode: nextStatusCode,
      isExistingUser: nextIsExistingUser,
      invitationSent: nextInvitationSent,
      hasAssignmentWarning: nextHasAssignmentWarning,
      assignmentWarning: nextAssignmentWarning,
      message: nextIsExistingUser
          ? 'Existing account recognized and linked to instructor profile.'
          : 'Account successfully provisioned. Invitation email dispatched with password setup link.',
    );
  }

  @override
  Future<Faculty> updateFaculty(
    Faculty faculty, {
    List<String>? categoryIds,
    List<String>? courseIds,
  }) async {
    final idx = store.indexWhere((f) => f.id == faculty.id);

    if (idx != -1) {
      store[idx] = faculty;
    }

    return faculty;
  }

  @override
  Future<void> updateFacultyStatus(String id, String status) async {
    final idx = store.indexWhere((f) => f.id == id);

    if (idx != -1) {
      store[idx] = store[idx].copyWith(accountStatus: status);
    }
  }

  @override
  Future<void> deleteFaculty(String id) async {
    store.removeWhere((f) => f.id == id);
  }
}

class MockFailingFacultyRepository extends MockFacultyRepository {
  final FacultyProvisioningException exceptionToThrow;

  MockFailingFacultyRepository(this.exceptionToThrow);

  @override
  Future<FacultyRegistrationResult> createFaculty(
    Faculty faculty, {
    List<String> categoryIds = const [],
    List<String> courseIds = const [],
  }) async {
    throw exceptionToThrow;
  }
}

void main() {
  group('Faculty Domain Model Tests', () {
    test('Constructs Faculty correctly from JSON map', () {
      final json = {
        'id': 'f101',
        'profile_id': 'p101',
        'full_name': 'Dr. Sarah Connor',
        'email': 'sarah@iiecm.com',
        'phone': '+91 9876543210',
        'qualifications': 'MBBS, MD',
        'specialization': 'Emergency Medicine',
        'experience_years': 10,
        'account_status': 'active',
        'bio': 'Senior consultant',
        'rating': 4.85,
        'total_students': 150,
        'total_classes': 45,
        'created_at': '2026-01-01T10:00:00Z',
      };

      final category = CourseCategory(
        id: 'cat-1',
        name: 'Critical Care',
        description: 'Critical Care stream',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final faculty = Faculty.fromJson(
        json,
        assignedCategories: [category],
        assignedCourseIds: ['c1'],
      );

      expect(faculty.id, equals('f101'));
      expect(faculty.profileId, equals('p101'));
      expect(faculty.fullName, equals('Dr. Sarah Connor'));
      expect(faculty.isActive, isTrue);
      expect(faculty.rating, equals(4.85));
      expect(faculty.assignedCategories.length, equals(1));
      expect(faculty.assignedCategories.first.name, equals('Critical Care'));
      expect(faculty.assignedCourseIds, contains('c1'));
    });

    test('Faculty.toJson produces correct Supabase columns', () {
      final faculty = Faculty(
        id: 'f102',
        profileId: 'p102',
        fullName: 'Dr. John Watson',
        email: 'john@iiecm.com',
        phone: '+91 9999988888',
        specialization: 'Diagnostic Medicine',
        bio: 'Clinical specialist bio',
        createdAt: DateTime.now(),
      );

      final json = faculty.toJson();

      expect(json['full_name'], equals('Dr. John Watson'));
      expect(json['email'], equals('john@iiecm.com'));
      expect(json['specialization'], equals('Diagnostic Medicine'));
      expect(json['bio'], equals('Clinical specialist bio'));
      expect(json['account_status'], equals('active'));
      expect(json['profile_id'], equals('p102'));
    });

    test('Faculty.copyWith works immutably', () {
      final faculty = Faculty(
        id: 'f103',
        fullName: 'Dr. House',
        email: 'house@iiecm.com',
        phone: '+91 1234567890',
        specialization: 'Nephrology',
        createdAt: DateTime.now(),
      );

      final updated = faculty.copyWith(accountStatus: 'suspended');

      expect(updated.accountStatus, equals('suspended'));
      expect(updated.fullName, equals('Dr. House'));
    });

    test('FacultyRegistrationResult encapsulates provisioning metadata', () {
      final sampleFaculty = Faculty(
        id: 'inst-1',
        profileId: 'prof-1',
        fullName: 'Dr. Priya Sharma',
        email: 'priya@iiecm.org',
        phone: '9876543210',
        specialization: 'Critical Care',
        createdAt: DateTime(2026, 1, 1),
      );

      final result201 = FacultyRegistrationResult(
        faculty: sampleFaculty,
        statusCode: 201,
        isExistingUser: false,
        invitationSent: true,
        message: 'Account provisioned successfully.',
      );

      expect(result201.statusCode, equals(201));
      expect(result201.isExistingUser, isFalse);
      expect(result201.invitationSent, isTrue);
      expect(result201.hasAssignmentWarning, isFalse);

      final result200 = FacultyRegistrationResult(
        faculty: sampleFaculty,
        statusCode: 200,
        isExistingUser: true,
        invitationSent: true,
        message:
            'Existing account recognized and linked to instructor profile.',
      );

      expect(result200.statusCode, equals(200));
      expect(result200.isExistingUser, isTrue);

      final resultWarning = FacultyRegistrationResult(
        faculty: sampleFaculty,
        statusCode: 201,
        isExistingUser: false,
        invitationSent: true,
        message: 'Account provisioned.',
        hasAssignmentWarning: true,
        assignmentWarning: 'Category assignments incomplete: timeout',
      );

      expect(resultWarning.hasAssignmentWarning, isTrue);
      expect(resultWarning.assignmentWarning, contains('timeout'));

      final result200NoEmail = FacultyRegistrationResult(
        faculty: sampleFaculty,
        statusCode: 200,
        isExistingUser: true,
        invitationSent: false,
        message: 'Existing account recognized and linked for Dr. Priya Sharma, but password activation email dispatch could not be confirmed.',
      );
      expect(result200NoEmail.statusCode, equals(200));
      expect(result200NoEmail.isExistingUser, isTrue);
      expect(result200NoEmail.invitationSent, isFalse);

      final result201NoEmail = FacultyRegistrationResult(
        faculty: sampleFaculty,
        statusCode: 201,
        isExistingUser: false,
        invitationSent: false,
        message: 'Faculty member Dr. Priya Sharma provisioned, but setup invitation email dispatch could not be confirmed.',
      );
      expect(result201NoEmail.statusCode, equals(201));
      expect(result201NoEmail.isExistingUser, isFalse);
      expect(result201NoEmail.invitationSent, isFalse);

      final resultBioWarning = FacultyRegistrationResult(
        faculty: sampleFaculty,
        statusCode: 201,
        isExistingUser: false,
        invitationSent: true,
        message: 'Account provisioned.',
        hasAssignmentWarning: true,
        assignmentWarning: 'Instructor bio could not be saved: write timeout',
      );
      expect(resultBioWarning.hasAssignmentWarning, isTrue);
      expect(
        resultBioWarning.assignmentWarning,
        contains('Instructor bio could not be saved'),
      );

      final resultCombinedWarning = FacultyRegistrationResult(
        faculty: sampleFaculty,
        statusCode: 201,
        isExistingUser: false,
        invitationSent: true,
        message: 'Account provisioned.',
        hasAssignmentWarning: true,
        assignmentWarning: 'Instructor bio could not be saved: write timeout; Category assignments incomplete: network error',
      );
      expect(resultCombinedWarning.hasAssignmentWarning, isTrue);
      expect(
        resultCombinedWarning.assignmentWarning,
        contains('Instructor bio could not be saved'),
      );
      expect(
        resultCombinedWarning.assignmentWarning,
        contains('Category assignments incomplete'),
      );
    });

    test('FacultyProvisioningException helper getters classify status codes', () {
      const conflictEx = FacultyProvisioningException(
        message: 'Conflict: User already registered under role student',
        statusCode: 409,
      );

      expect(conflictEx.isConflict, isTrue);
      expect(conflictEx.isInvitationFailure, isFalse);
      expect(conflictEx.isConfigurationError, isFalse);
      expect(conflictEx.isNetworkError, isFalse);

      const inviteEx = FacultyProvisioningException(
        message: 'Failed to dispatch invitation email',
        statusCode: 502,
      );

      expect(inviteEx.isInvitationFailure, isTrue);

      const partialEx = FacultyProvisioningException(
        message:
            'Auth user created (UUID), but failed to insert instructor record',
        statusCode: 500,
        isPartialFailure: true,
      );

      expect(partialEx.isPartialFailure, isTrue);
      expect(partialEx.isConfigurationError, isFalse);

      const configEx = FacultyProvisioningException(
        message: 'Server configuration error',
        statusCode: 500,
        isPartialFailure: false,
      );

      expect(configEx.isConfigurationError, isTrue);

      const netEx = FacultyProvisioningException(
        message: 'Network unreachable',
        statusCode: 0,
      );

      expect(netEx.isNetworkError, isTrue);
    });

    test('FacultyProvisioningException handles missing and mismatched profileId integrity errors', () {
      const missingProfileEx = FacultyProvisioningException(
        message: 'Instructor record was provisioned, but authentication profile relationship is missing.',
        statusCode: 500,
        isPartialFailure: true,
      );
      expect(missingProfileEx.isPartialFailure, isTrue);
      expect(
        missingProfileEx.message,
        contains('profile relationship is missing'),
      );

      const mismatchEx = FacultyProvisioningException(
        message: 'Instructor provisioning integrity failure: linked profile does not match authentication user identity.',
        statusCode: 500,
        isPartialFailure: true,
      );
      expect(mismatchEx.isPartialFailure, isTrue);
      expect(
        mismatchEx.message,
        contains('does not match authentication user identity'),
      );
    });
  });

  group('FacultyNotifier Provisioning & State Management', () {
    late MockFacultyRepository repo;
    late Faculty existingFaculty;

    setUp(() {
      existingFaculty = Faculty(
        id: 'inst-100',
        profileId: 'prof-100',
        fullName: 'Dr. Anand Verma',
        email: 'anand@iiecm.org',
        phone: '9876543210',
        specialization: 'Cardiology',
        createdAt: DateTime.now(),
      );

      repo = MockFacultyRepository(initial: [existingFaculty]);
    });

    test('createFaculty updates state on HTTP 201 success', () async {
      final notifier = FacultyNotifier(repo);

      await notifier.loadFaculty();

      expect(notifier.state.facultyList.length, equals(1));

      final newFaculty = Faculty(
        id: '',
        fullName: 'Dr. Meenakshi Sundaram',
        email: 'meenakshi@iiecm.org',
        phone: '9876500001',
        specialization: 'Emergency Trauma',
        qualifications: 'MS, MCh',
        experienceYears: 12,
        bio: 'Senior trauma surgeon',
        createdAt: DateTime.now(),
      );

      final result = await notifier.createFaculty(
        newFaculty,
        categoryIds: ['cat-1', 'cat-2'],
        courseIds: ['crs-1'],
      );

      expect(result, isNotNull);
      expect(result!.statusCode, equals(201));
      expect(result.faculty.fullName, equals('Dr. Meenakshi Sundaram'));
      expect(result.faculty.assignedCategories.length, equals(2));
      expect(result.faculty.assignedCourseIds, contains('crs-1'));
      expect(result.invitationSent, isTrue);
      expect(notifier.state.facultyList.length, equals(2));
      expect(notifier.state.errorMessage, isNull);
    });

    test(
      'createFaculty surfaces FacultyProvisioningException error message',
      () async {
        final failingRepo = MockFailingFacultyRepository(
          const FacultyProvisioningException(
            message: 'Conflict: An account with email already exists with role student.',
            statusCode: 409,
          ),
        );

        final notifier = FacultyNotifier(failingRepo);

        await notifier.loadFaculty();

        final result = await notifier.createFaculty(
          Faculty(
            id: '',
            fullName: 'Dr. Duplicate',
            email: 'duplicate@iiecm.org',
            phone: '9999999999',
            specialization: 'General',
            createdAt: DateTime.now(),
          ),
        );

        expect(result, isNull);
        expect(
          notifier.state.errorMessage,
          equals(
            'Conflict: An account with email already exists with role student.',
          ),
        );
        expect(notifier.state.isLoading, isFalse);
      },
    );

    test('updateFaculty preserves direct editing behavior without invoking provisioning', () async {
      final notifier = FacultyNotifier(repo);

      await notifier.loadFaculty();

      final updated = existingFaculty.copyWith(
        specialization: 'Interventional Cardiology',
        bio: 'Updated bio information',
      );

      final success = await notifier.updateFaculty(updated);

      expect(success, isTrue);
      expect(
        notifier.state.facultyList.first.specialization,
        equals('Interventional Cardiology'),
      );
      expect(
        notifier.state.facultyList.first.bio,
        equals('Updated bio information'),
      );
    });

    test(
      'createFaculty handles HTTP 200 existing user with invitationSent: true',
      () async {
        final repo200 = MockFacultyRepository(
          initial: [existingFaculty],
          nextStatusCode: 200,
          nextIsExistingUser: true,
          nextInvitationSent: true,
        );
        final notifier = FacultyNotifier(repo200);
        await notifier.loadFaculty();

        final newFaculty = Faculty(
          id: '',
          fullName: 'Dr. Existing Account',
          email: 'existing@iiecm.org',
          phone: '9876500002',
          specialization: 'Pulmonology',
          createdAt: DateTime.now(),
        );

        final result = await notifier.createFaculty(newFaculty);
        expect(result, isNotNull);
        expect(result!.statusCode, equals(200));
        expect(result.isExistingUser, isTrue);
        expect(result.invitationSent, isTrue);
        expect(result.hasAssignmentWarning, isFalse);
        expect(notifier.state.facultyList.length, equals(2));
        expect(notifier.state.errorMessage, isNull);
      },
    );

    test(
      'createFaculty handles HTTP 200 existing user with invitationSent: false',
      () async {
        final repo200NoInvite = MockFacultyRepository(
          initial: [existingFaculty],
          nextStatusCode: 200,
          nextIsExistingUser: true,
          nextInvitationSent: false,
        );
        final notifier = FacultyNotifier(repo200NoInvite);
        await notifier.loadFaculty();

        final newFaculty = Faculty(
          id: '',
          fullName: 'Dr. Re-linked Unsent',
          email: 'relink@iiecm.org',
          phone: '9876500003',
          specialization: 'Radiology',
          createdAt: DateTime.now(),
        );

        final result = await notifier.createFaculty(newFaculty);
        expect(result, isNotNull);
        expect(result!.statusCode, equals(200));
        expect(result.isExistingUser, isTrue);
        expect(result.invitationSent, isFalse);
        expect(notifier.state.facultyList.length, equals(2));
      },
    );

    test(
      'createFaculty handles HTTP 201 new user with invitationSent: false',
      () async {
        final repo201NoInvite = MockFacultyRepository(
          initial: [existingFaculty],
          nextStatusCode: 201,
          nextIsExistingUser: false,
          nextInvitationSent: false,
        );
        final notifier = FacultyNotifier(repo201NoInvite);
        await notifier.loadFaculty();

        final newFaculty = Faculty(
          id: '',
          fullName: 'Dr. New User No Invite',
          email: 'newnoinvite@iiecm.org',
          phone: '9876500004',
          specialization: 'Pediatrics',
          createdAt: DateTime.now(),
        );

        final result = await notifier.createFaculty(newFaculty);
        expect(result, isNotNull);
        expect(result!.statusCode, equals(201));
        expect(result.isExistingUser, isFalse);
        expect(result.invitationSent, isFalse);
        expect(notifier.state.facultyList.length, equals(2));
      },
    );

    test(
      'createFaculty handles bio update failure warning without aborting',
      () async {
        final repoBioWarn = MockFacultyRepository(
          initial: [existingFaculty],
          nextStatusCode: 201,
          nextIsExistingUser: false,
          nextInvitationSent: true,
          nextHasAssignmentWarning: true,
          nextAssignmentWarning:
              'Instructor bio could not be saved: write timeout',
        );
        final notifier = FacultyNotifier(repoBioWarn);
        await notifier.loadFaculty();

        final newFaculty = Faculty(
          id: '',
          fullName: 'Dr. Bio Warn',
          email: 'biowarn@iiecm.org',
          phone: '9876500005',
          specialization: 'Neurology',
          bio: 'Bio text that failed to save',
          createdAt: DateTime.now(),
        );

        final result = await notifier.createFaculty(newFaculty);
        expect(result, isNotNull);
        expect(result!.statusCode, equals(201));
        expect(result.hasAssignmentWarning, isTrue);
        expect(
          result.assignmentWarning,
          contains('Instructor bio could not be saved'),
        );
        expect(notifier.state.facultyList.length, equals(2));
        expect(notifier.state.errorMessage, isNull);
      },
    );

    test(
      'createFaculty handles combined bio and assignment warnings',
      () async {
        final repoCombined = MockFacultyRepository(
          initial: [existingFaculty],
          nextStatusCode: 201,
          nextIsExistingUser: false,
          nextInvitationSent: true,
          nextHasAssignmentWarning: true,
          nextAssignmentWarning: 'Instructor bio could not be saved: write timeout; Category assignments incomplete: network error',
        );
        final notifier = FacultyNotifier(repoCombined);
        await notifier.loadFaculty();

        final newFaculty = Faculty(
          id: '',
          fullName: 'Dr. Multi Warning',
          email: 'multiwarn@iiecm.org',
          phone: '9876500006',
          specialization: 'Dermatology',
          bio: 'Multi bio',
          createdAt: DateTime.now(),
        );

        final result = await notifier.createFaculty(
          newFaculty,
          categoryIds: ['cat-1'],
        );
        expect(result, isNotNull);
        expect(result!.hasAssignmentWarning, isTrue);
        expect(
          result.assignmentWarning,
          contains('Instructor bio could not be saved'),
        );
        expect(
          result.assignmentWarning,
          contains('Category assignments incomplete'),
        );
        expect(notifier.state.facultyList.length, equals(2));
        expect(notifier.state.errorMessage, isNull);
      },
    );
  });
}
