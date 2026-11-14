import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iiecm_student/features/auth/domain/models/student_profile.dart';
import 'package:iiecm_student/features/auth/presentation/providers/auth_provider.dart';
import 'package:iiecm_student/features/auth/presentation/providers/auth_state.dart';
import 'package:iiecm_student/features/profile/domain/repositories/profile_repository.dart';
import 'package:iiecm_student/features/profile/presentation/providers/profile_provider.dart';
import 'package:iiecm_student/features/profile/presentation/student_profile_screen.dart';
import 'package:iiecm_student/features/profile/presentation/widgets/change_password_dialog.dart';
import 'package:iiecm_student/features/profile/presentation/widgets/edit_profile_dialog.dart';

class FakeProfileRepository implements ProfileRepository {
  bool shouldFail = false;
  bool passwordShouldFail = false;
  String? lastUpdatedName;
  String? lastUpdatedPhone;
  String? lastUpdatedPassword;

  @override
  Future<StudentProfile> updateProfile({
    required String userId,
    required String studentRecordId,
    required String fullName,
    required String phone,
    String? qualification,
    String? educationLevel,
    String? preferredCategory,
    String? city,
  }) async {
    if (shouldFail) {
      throw Exception('Simulated database update failure');
    }
    lastUpdatedName = fullName;
    lastUpdatedPhone = phone;

    return StudentProfile(
      userId: userId,
      studentRecordId: studentRecordId,
      studentId: 'IIECM-2026-STU-001',
      fullName: fullName,
      email: 'anita.roy@iiecm.org',
      role: 'student',
      phone: phone,
      accountStatus: 'active',
      qualification: qualification ?? 'MBBS',
      educationLevel: educationLevel ?? 'Postgraduate',
      preferredCategory: preferredCategory ?? 'Emergency Medicine',
    );
  }

  @override
  Future<void> changePassword({required String newPassword}) async {
    if (passwordShouldFail) {
      throw Exception('Weak password or authentication expired');
    }
    lastUpdatedPassword = newPassword;
  }
}

const mockStudent = StudentProfile(
  userId: 'user-123',
  studentRecordId: 'rec-456',
  studentId: 'IIECM-2026-STU-001',
  fullName: 'Dr. Anita Roy',
  email: 'anita.roy@iiecm.org',
  role: 'student',
  phone: '+91 9876543210',
  accountStatus: 'active',
  qualification: 'MBBS, MD',
  educationLevel: 'Postgraduate',
  preferredCategory: 'Emergency Medicine',
  subscriptionPlan: '2026 Emergency Residency',
);

void main() {
  group('Profile Feature Tests', () {
    late FakeProfileRepository fakeRepo;

    setUp(() {
      fakeRepo = FakeProfileRepository();
    });

    testWidgets('StudentProfileScreen renders student details and action buttons', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(
              (ref) => AuthNotifier(ref.watch(authRepositoryProvider))
                ..state = const AuthState.authenticated(mockStudent),
            ),
            profileRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: StudentProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Student Dossier & Profile'), findsOneWidget);
      expect(find.text('Dr. Anita Roy'), findsOneWidget);
      expect(find.text('IIECM-2026-STU-001'), findsNWidgets(2));
      expect(find.text('anita.roy@iiecm.org'), findsOneWidget);
      expect(find.text('+91 9876543210'), findsOneWidget);
      expect(find.text('Change Password'), findsOneWidget);
      expect(find.text('Sign Out of Student Portal'), findsOneWidget);
    });

    testWidgets('EditProfileDialog pre-fills data and locks student ID and email', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(
              (ref) => AuthNotifier(ref.watch(authRepositoryProvider))
                ..state = const AuthState.authenticated(mockStudent),
            ),
            profileRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: EditProfileDialog(student: mockStudent),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit Contact & Profile'), findsOneWidget);
      expect(find.text('IIECM-2026-STU-001'), findsOneWidget);
      expect(find.text('anita.roy@iiecm.org'), findsOneWidget);
      expect(find.text('Institutional Student ID (Registry Locked)'), findsOneWidget);
      expect(find.text('Institutional Registered Email (Locked)'), findsOneWidget);

      // Verify editable text field values
      expect(find.widgetWithText(TextFormField, 'Dr. Anita Roy'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '+91 9876543210'), findsOneWidget);
    });

    testWidgets('EditProfileDialog validates input fields', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(
              (ref) => AuthNotifier(ref.watch(authRepositoryProvider))
                ..state = const AuthState.authenticated(mockStudent),
            ),
            profileRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: EditProfileDialog(student: mockStudent),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Clear full name
      final nameFinder = find.widgetWithText(TextFormField, 'Dr. Anita Roy');
      await tester.enterText(nameFinder, '');
      await tester.pumpAndSettle();

      // Tap save
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your full legal name.'), findsOneWidget);
    });

    testWidgets('ChangePasswordDialog validates length and confirmation match', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ChangePasswordDialog(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Update Account Password'), findsOneWidget);

      // Tap update without input
      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a new password.'), findsOneWidget);

      // Enter short password
      final passwordFields = find.byType(TextFormField);
      await tester.enterText(passwordFields.at(0), '123');
      await tester.enterText(passwordFields.at(1), '123456');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();

      expect(find.text('Password must be at least 6 characters.'), findsOneWidget);

      // Enter mismatched confirmation
      await tester.enterText(passwordFields.at(0), 'secret123');
      await tester.enterText(passwordFields.at(1), 'mismatch456');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match.'), findsOneWidget);
    });
  });
}

