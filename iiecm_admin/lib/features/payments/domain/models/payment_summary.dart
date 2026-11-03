import 'payment.dart';

/// Aggregated Financial & Billing Telemetry Model
class PaymentSummary {
  final double totalFeesCollected;
  final int totalPaymentsReceived;
  final double totalOutstandingAmount;
  final int pendingPaymentsCount;
  final double pendingPaymentsAmount;
  final int overduePaymentsCount;
  final int partiallyPaidStudentsCount;
  final double refundTotal;
  final double monthlyRevenue;
  final Map<String, double> dailyCollections;
  final Map<String, double> monthlyCollections;
  final Map<String, double> courseWiseCollections;
  final Map<String, double> methodBreakdown;
  final Map<String, int> statusBreakdown;
  final List<Payment> recentTransactions;

  const PaymentSummary({
    required this.totalFeesCollected,
    required this.totalPaymentsReceived,
    required this.totalOutstandingAmount,
    required this.pendingPaymentsCount,
    required this.pendingPaymentsAmount,
    required this.overduePaymentsCount,
    required this.partiallyPaidStudentsCount,
    required this.refundTotal,
    required this.monthlyRevenue,
    required this.dailyCollections,
    required this.monthlyCollections,
    required this.courseWiseCollections,
    required this.methodBreakdown,
    required this.statusBreakdown,
    required this.recentTransactions,
  });

  factory PaymentSummary.empty() {
    return const PaymentSummary(
      totalFeesCollected: 0.0,
      totalPaymentsReceived: 0,
      totalOutstandingAmount: 0.0,
      pendingPaymentsCount: 0,
      pendingPaymentsAmount: 0.0,
      overduePaymentsCount: 0,
      partiallyPaidStudentsCount: 0,
      refundTotal: 0.0,
      monthlyRevenue: 0.0,
      dailyCollections: {},
      monthlyCollections: {},
      courseWiseCollections: {},
      methodBreakdown: {},
      statusBreakdown: {},
      recentTransactions: [],
    );
  }
}

