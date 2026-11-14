import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/models/student_profile.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/supabase_payments_repository.dart';
import '../../domain/models/student_payment.dart';
import '../../domain/repositories/payments_repository.dart';
import 'payments_state.dart';

/// Provider exposing the PaymentsRepository abstraction
final paymentsRepositoryProvider = Provider<PaymentsRepository>((ref) {
  return SupabasePaymentsRepository();
});

/// StateNotifierProvider managing student payment history
final studentPaymentsNotifierProvider =
    StateNotifierProvider<StudentPaymentsNotifier, PaymentsState>((ref) {
  final repo = ref.watch(paymentsRepositoryProvider);
  final authState = ref.watch(authNotifierProvider);
  return StudentPaymentsNotifier(repo, authState.student);
});

class StudentPaymentsNotifier extends StateNotifier<PaymentsState> {
  final PaymentsRepository _repository;
  final StudentProfile? _student;

  StudentPaymentsNotifier(this._repository, this._student)
      : super(const PaymentsState()) {
    if (_student != null) {
      loadPayments();
    }
  }

  /// Loads payment transactions scoped strictly to the authenticated student's record
  Future<void> loadPayments() async {
    if (_student == null) {
      state = state.copyWith(
        status: PaymentsStatus.error,
        errorMessage: 'No active authenticated student session found.',
      );
      return;
    }

    state = state.copyWith(status: PaymentsStatus.loading);

    try {
      final payments =
          await _repository.getStudentPayments(_student.studentRecordId);
      state = state.copyWith(
        status: PaymentsStatus.loaded,
        payments: payments,
        errorMessage: null,
      );
    } catch (e, stack) {
      developer.log(
        'Failed to load student payments: $e',
        name: 'StudentPaymentsNotifier',
        error: e,
        stackTrace: stack,
      );
      state = state.copyWith(
        status: PaymentsStatus.error,
        errorMessage:
            'Unable to retrieve payment records. Please verify your internet connection.',
      );
    }
  }

  Future<void> refresh() => loadPayments();

  void setFilter(PaymentFilterType filter) {
    state = state.copyWith(filter: filter);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }
}

/// Provider for retrieving specific payment details by paymentId
final studentPaymentDetailProvider =
    FutureProvider.family<StudentPayment?, String>((ref, paymentId) async {
  final repo = ref.watch(paymentsRepositoryProvider);
  final authState = ref.watch(authNotifierProvider);
  final student = authState.student;

  if (student == null || paymentId.isEmpty) return null;

  return repo.getPaymentDetails(
    paymentId: paymentId,
    studentRecordId: student.studentRecordId,
  );
});

