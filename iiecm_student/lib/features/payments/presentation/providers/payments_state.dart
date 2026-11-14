import '../../domain/models/student_payment.dart';

enum PaymentsStatus { initial, loading, loaded, error }

enum PaymentFilterType {
  all,
  verified,
  pending,
  failed,
  refunded;

  String get label {
    switch (this) {
      case PaymentFilterType.all:
        return 'All Invoices';
      case PaymentFilterType.verified:
        return 'Verified';
      case PaymentFilterType.pending:
        return 'Pending';
      case PaymentFilterType.failed:
        return 'Failed';
      case PaymentFilterType.refunded:
        return 'Refunded';
    }
  }
}

class PaymentsState {
  final PaymentsStatus status;
  final List<StudentPayment> payments;
  final PaymentFilterType filter;
  final String searchQuery;
  final String? errorMessage;

  const PaymentsState({
    this.status = PaymentsStatus.initial,
    this.payments = const [],
    this.filter = PaymentFilterType.all,
    this.searchQuery = '',
    this.errorMessage,
  });

  bool get isLoading => status == PaymentsStatus.loading;
  bool get hasError => status == PaymentsStatus.error;
  bool get isLoaded => status == PaymentsStatus.loaded;

  /// Returns payments filtered by the selected tab and search query
  List<StudentPayment> get filteredPayments {
    var list = payments;

    switch (filter) {
      case PaymentFilterType.verified:
        list = list.where((p) => p.isVerified).toList();
        break;
      case PaymentFilterType.pending:
        list = list.where((p) => p.isPending).toList();
        break;
      case PaymentFilterType.failed:
        list = list.where((p) => p.isFailed || p.isRejected).toList();
        break;
      case PaymentFilterType.refunded:
        list = list.where((p) => p.isRefunded).toList();
        break;
      case PaymentFilterType.all:
        break;
    }

    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      list = list.where((p) {
        final matchesRef = p.transactionRef.toLowerCase().contains(q);
        final matchesReceipt = p.receiptNumber.toLowerCase().contains(q);
        final matchesCourse = p.courseName?.toLowerCase().contains(q) ?? false;
        final matchesPlan = p.subscriptionPlan?.toLowerCase().contains(q) ?? false;
        final matchesNotes = p.notes?.toLowerCase().contains(q) ?? false;
        return matchesRef || matchesReceipt || matchesCourse || matchesPlan || matchesNotes;
      }).toList();
    }

    return list;
  }

  int get totalPaymentsCount => payments.length;

  int get verifiedCount => payments.where((p) => p.isVerified).length;

  int get pendingCount => payments.where((p) => p.isPending).length;

  double get totalVerifiedAmount {
    return payments
        .where((p) => p.isVerified)
        .fold<double>(0.0, (acc, p) => acc + p.amount);
  }

  PaymentsState copyWith({
    PaymentsStatus? status,
    List<StudentPayment>? payments,
    PaymentFilterType? filter,
    String? searchQuery,
    String? errorMessage,
  }) {
    return PaymentsState(
      status: status ?? this.status,
      payments: payments ?? this.payments,
      filter: filter ?? this.filter,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage,
    );
  }
}

