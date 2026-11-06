import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../data/repositories/supabase_payment_repository.dart';
import '../../domain/models/payment.dart';
import '../../domain/models/payment_filter.dart';
import '../../domain/models/payment_summary.dart';
import '../../domain/models/razorpay_models.dart';
import '../../domain/models/student_fee_profile.dart';
import '../../domain/repositories/payment_repository.dart';

/// Central Payment Repository Provider
final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return SupabasePaymentRepository();
});

/// Filter State Notifier
class PaymentFilterNotifier extends StateNotifier<PaymentFilter> {
  PaymentFilterNotifier() : super(const PaymentFilter());

  void setDateFilter(
    PaymentDateFilterType type, {
    DateTime? customStart,
    DateTime? customEnd,
  }) {
    state = state.copyWith(
      dateFilterType: type,
      customStartDate: customStart,
      customEndDate: customEnd,
    );
  }

  void setStatus(String? status) {
    if (status == null || status == 'all' || status.isEmpty) {
      state = state.copyWith(clearStatus: true);
    } else {
      state = state.copyWith(status: status);
    }
  }

  void setPaymentMethod(String? method) {
    if (method == null || method == 'all' || method.isEmpty) {
      state = state.copyWith(clearPaymentMethod: true);
    } else {
      state = state.copyWith(paymentMethod: method);
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setSorting({required String sortBy, required bool descending}) {
    state = state.copyWith(sortBy: sortBy, sortDescending: descending);
  }

  void resetFilters() {
    state = const PaymentFilter();
  }
}

final paymentFilterProvider =
    StateNotifierProvider<PaymentFilterNotifier, PaymentFilter>((ref) {
      return PaymentFilterNotifier();
    });

/// Payments List Provider
final paymentsListProvider = FutureProvider<List<Payment>>((ref) async {
  final repo = ref.watch(paymentRepositoryProvider);
  final filter = ref.watch(paymentFilterProvider);
  return repo.fetchPayments(filter: filter);
});

/// Payment Summary Provider
final paymentSummaryProvider = FutureProvider<PaymentSummary>((ref) async {
  final repo = ref.watch(paymentRepositoryProvider);
  final filter = ref.watch(paymentFilterProvider);
  return repo.fetchPaymentSummary(filter: filter);
});

/// Student Fee Profile Family Provider
final studentFeeProfileProvider =
    FutureProvider.family<StudentFeeProfile?, String>((ref, studentId) async {
      final repo = ref.watch(paymentRepositoryProvider);
      return repo.fetchStudentFeeProfile(studentId);
    });

/// All Student Fee Profiles Provider
final allStudentFeeProfilesProvider = FutureProvider<List<StudentFeeProfile>>((
  ref,
) async {
  final repo = ref.watch(paymentRepositoryProvider);
  return repo.fetchAllStudentFeeProfiles();
});

/// Students With Enrollments Provider for Payment Recording
final studentsWithEnrollmentsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
      final repo = ref.watch(paymentRepositoryProvider);
      return repo.fetchStudentsWithEnrollments();
    });

/// Payment Mutations & Controller
class PaymentActionsState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const PaymentActionsState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  PaymentActionsState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool clearErrors = false,
  }) {
    return PaymentActionsState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearErrors ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearErrors
          ? null
          : (successMessage ?? this.successMessage),
    );
  }
}

class PaymentActionsNotifier extends StateNotifier<PaymentActionsState> {
  final Ref _ref;

  PaymentActionsNotifier(this._ref) : super(const PaymentActionsState());

  void clearMessages() {
    state = state.copyWith(clearErrors: true);
  }

  void _invalidateAll() {
    _ref.invalidate(paymentsListProvider);
    _ref.invalidate(paymentSummaryProvider);
    _ref.invalidate(allStudentFeeProfilesProvider);
    _ref.invalidate(studentsWithEnrollmentsProvider);
    _ref.invalidate(dashboardStatsProvider);
  }

  Future<bool> recordPayment({
    required String studentId,
    required String studentName,
    String? studentCode,
    String? courseId,
    String? courseName,
    String? subscriptionPlan,
    required double amount,
    required String paymentMethod,
    required String status,
    required DateTime paymentDate,
    required String transactionRef,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, clearErrors: true);

    try {
      final repo = _ref.read(paymentRepositoryProvider);
      final authState = _ref.read(authNotifierProvider);
      final verifiedBy = authState.adminUser?.fullName ?? 'Institutional Admin';

      await repo.recordPayment(
        studentId: studentId,
        studentName: studentName,
        studentCode: studentCode,
        courseId: courseId,
        courseName: courseName,
        subscriptionPlan: subscriptionPlan,
        amount: amount,
        paymentMethod: paymentMethod,
        status: status,
        paymentDate: paymentDate,
        transactionRef: transactionRef,
        notes: notes,
        verifiedBy: status == 'verified' ? verifiedBy : null,
      );

      _invalidateAll();
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Payment transaction recorded successfully.',
      );
      return true;
    } catch (e, stack) {
      developer.log(
        'Error recording payment: $e',
        name: 'PaymentActionsNotifier',
        error: e,
        stackTrace: stack,
      );
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> verifyPayment(String paymentId) async {
    state = state.copyWith(isLoading: true, clearErrors: true);

    try {
      final repo = _ref.read(paymentRepositoryProvider);
      final authState = _ref.read(authNotifierProvider);
      final verifiedBy = authState.adminUser?.fullName ?? 'Institutional Admin';

      await repo.verifyPayment(paymentId, verifiedBy: verifiedBy);

      _invalidateAll();
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Payment transaction verified and credited.',
      );
      return true;
    } catch (e, stack) {
      developer.log(
        'Error verifying payment: $e',
        name: 'PaymentActionsNotifier',
        error: e,
        stackTrace: stack,
      );
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> rejectPayment(String paymentId, {required String reason}) async {
    state = state.copyWith(isLoading: true, clearErrors: true);

    try {
      final repo = _ref.read(paymentRepositoryProvider);
      await repo.rejectPayment(paymentId, reason: reason);

      _invalidateAll();
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Payment transaction rejected.',
      );
      return true;
    } catch (e, stack) {
      developer.log(
        'Error rejecting payment: $e',
        name: 'PaymentActionsNotifier',
        error: e,
        stackTrace: stack,
      );
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> processRefund(
    String paymentId, {
    required double amount,
    required String reason,
  }) async {
    state = state.copyWith(isLoading: true, clearErrors: true);

    try {
      final repo = _ref.read(paymentRepositoryProvider);
      await repo.processRefund(paymentId, amount: amount, reason: reason);

      _invalidateAll();
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Refund processed and audited successfully.',
      );
      return true;
    } catch (e, stack) {
      developer.log(
        'Error processing refund: $e',
        name: 'PaymentActionsNotifier',
        error: e,
        stackTrace: stack,
      );
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<RazorpayOrderResponse?> createRazorpayOrder(
    RazorpayOrderRequest request,
  ) async {
    state = state.copyWith(isLoading: true, clearErrors: true);

    try {
      final repo = _ref.read(paymentRepositoryProvider);
      final orderResponse = await repo.createRazorpayOrder(request);
      state = state.copyWith(isLoading: false);
      return orderResponse;
    } catch (e, stack) {
      developer.log(
        'Error creating Razorpay order: $e',
        name: 'PaymentActionsNotifier',
        error: e,
        stackTrace: stack,
      );
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return null;
    }
  }

  Future<RazorpayVerificationResult> verifyRazorpayPayment(
    RazorpayVerificationRequest request,
  ) async {
    state = state.copyWith(isLoading: true, clearErrors: true);

    try {
      final repo = _ref.read(paymentRepositoryProvider);
      final result = await repo.verifyRazorpayPayment(request);

      if (result.success) {
        _invalidateAll();
        state = state.copyWith(
          isLoading: false,
          successMessage:
              'Razorpay payment successfully verified and captured.',
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result.error ?? 'Server payment verification failed.',
        );
      }

      return result;
    } catch (e, stack) {
      developer.log(
        'Error verifying Razorpay payment: $e',
        name: 'PaymentActionsNotifier',
        error: e,
        stackTrace: stack,
      );
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isLoading: false, errorMessage: errorMsg);
      return RazorpayVerificationResult.failure(error: errorMsg);
    }
  }
}

final paymentActionsProvider =
    StateNotifierProvider<PaymentActionsNotifier, PaymentActionsState>((ref) {
      return PaymentActionsNotifier(ref);
    });
