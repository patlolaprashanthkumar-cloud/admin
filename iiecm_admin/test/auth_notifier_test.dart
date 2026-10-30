import 'package:flutter_test/flutter_test.dart';
import 'package:iiecm_admin/features/auth/domain/models/admin_user.dart';
import 'package:iiecm_admin/features/auth/domain/models/auth_exception.dart';
import 'package:iiecm_admin/features/auth/domain/models/user_role.dart';
import 'package:iiecm_admin/features/auth/domain/repositories/auth_repository.dart';
import 'package:iiecm_admin/features/auth/presentation/providers/auth_provider.dart';
import 'package:iiecm_admin/features/auth/presentation/providers/auth_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class FakeAuthRepository implements AuthRepository {
  bool shouldThrowAccessDenied = false;
  bool shouldThrowProfileNotFound = false;
  bool shouldThrowNetworkError = false;

  final AdminUser sampleAdmin = const AdminUser(
    id: 'admin-uuid-1',
    email: 'admin@iiecm.org',
    fullName: 'Verified Administrator',
    role: UserRole.admin,
  );

  @override
  sb.Session? get currentSession => null;

  @override
  Stream<sb.AuthState> get onAuthStateChange => const Stream.empty();

  @override
  Future<AdminUser> signIn({required String email, required String password}) async {
    if (shouldThrowAccessDenied) {
      throw const AccessDeniedNonAdminException('student');
    }
    if (shouldThrowProfileNotFound) {
      throw const ProfileNotFoundException();
    }
    if (shouldThrowNetworkError) {
      throw const ProfileVerificationNetworkException();
    }
    return sampleAdmin;
  }

  @override
  Future<AdminUser> fetchAuthoritativeProfile({required String userId, String? emailFallback}) async {
    if (shouldThrowAccessDenied) {
      throw const AccessDeniedNonAdminException('student');
    }
    if (shouldThrowNetworkError) {
      throw const ProfileVerificationNetworkException();
    }
    return sampleAdmin;
  }

  @override
  Future<AdminUser?> restoreSession() async => null;

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> signOut() async {}
}

void main() {
  late FakeAuthRepository fakeRepo;
  late AuthNotifier notifier;

  setUp(() {
    fakeRepo = FakeAuthRepository();
    notifier = AuthNotifier(fakeRepo);
  });

  group('AuthNotifier Tests', () {
    test('Valid admin credentials transition state to authenticated', () async {
      final success = await notifier.login(email: 'admin@iiecm.org', password: 'password123');
      expect(success, isTrue);
      expect(notifier.state.status, AuthStatus.authenticated);
      expect(notifier.state.adminUser?.email, 'admin@iiecm.org');
      expect(notifier.state.adminUser?.role, UserRole.admin);
    });

    test('Non-admin credentials trigger AccessDenied error and deny authentication', () async {
      fakeRepo.shouldThrowAccessDenied = true;
      final success = await notifier.login(email: 'student@iiecm.org', password: 'password123');
      expect(success, isFalse);
      expect(notifier.state.status, AuthStatus.unauthenticated);
      expect(notifier.state.errorMessage, contains('Access denied'));
    });

    test('Missing public.profiles row triggers profile missing error', () async {
      fakeRepo.shouldThrowProfileNotFound = true;
      final success = await notifier.login(email: 'orphan@iiecm.org', password: 'password123');
      expect(success, isFalse);
      expect(notifier.state.status, AuthStatus.unauthenticated);
      expect(notifier.state.errorMessage, contains('profile was not found'));
    });

    test('Temporary network error enters profileVerificationError and allows retry', () async {
      fakeRepo.shouldThrowNetworkError = true;
      final success = await notifier.login(email: 'admin@iiecm.org', password: 'password123');
      expect(success, isFalse);
      expect(notifier.state.status, AuthStatus.profileVerificationError);
      expect(notifier.state.isRetryable, isTrue);

      // Network recovers:
      fakeRepo.shouldThrowNetworkError = false;
      final retrySuccess = await notifier.retryProfileVerification();
      expect(retrySuccess, isTrue);
      expect(notifier.state.status, AuthStatus.authenticated);
    });

    test('Logout resets state to unauthenticated', () async {
      await notifier.login(email: 'admin@iiecm.org', password: 'password123');
      expect(notifier.state.status, AuthStatus.authenticated);

      await notifier.logout();
      expect(notifier.state.status, AuthStatus.unauthenticated);
      expect(notifier.state.adminUser, isNull);
    });
  });
}

