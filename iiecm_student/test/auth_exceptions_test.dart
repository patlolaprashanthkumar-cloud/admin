import 'package:flutter_test/flutter_test.dart';
import 'package:iiecm_student/features/auth/domain/models/auth_exception.dart';

void main() {
  group('AuthException Hierarchy & Messages', () {
    test('UnconfiguredAuthException provides clear configuration guidance', () {
      const ex = UnconfiguredAuthException();
      expect(ex.isRetryable, isFalse);
      expect(ex.toString(), contains('--dart-define-from-file=.env.json'));
    });

    test('InvalidCredentialsException has user-friendly message', () {
      const ex = InvalidCredentialsException();
      expect(ex.isRetryable, isFalse);
      expect(ex.toString(), contains('Invalid email or password'));
    });

    test('AccessDeniedNonStudentException identifies offending role', () {
      const ex = AccessDeniedNonStudentException('instructor');
      expect(ex.isRetryable, isFalse);
      expect(ex.currentRole, 'instructor');
      expect(ex.toString(), contains('instructor'));
      expect(ex.toString(), contains('strictly for enrolled students'));
    });

    test('StudentProfileNotFoundException communicates missing database profile', () {
      const ex = StudentProfileNotFoundException();
      expect(ex.isRetryable, isFalse);
      expect(ex.toString(), contains('profile record not found'));
    });

    test('StudentRecordNotFoundException communicates missing institutional enrollment record', () {
      const ex = StudentRecordNotFoundException();
      expect(ex.isRetryable, isFalse);
      expect(ex.toString(), contains('enrollment record not found'));
    });

    test('StudentAccountSuspendedException identifies suspension status', () {
      const ex = StudentAccountSuspendedException('suspended');
      expect(ex.isRetryable, isFalse);
      expect(ex.status, 'suspended');
      expect(ex.toString(), contains('suspended'));
    });

    test('AuthNetworkException is marked as retryable', () {
      const ex = AuthNetworkException('Connection timeout');
      expect(ex.isRetryable, isTrue);
      expect(ex.toString(), contains('Connection timeout'));
    });
  });
}

