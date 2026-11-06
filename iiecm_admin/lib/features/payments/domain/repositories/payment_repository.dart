import '../models/payment.dart';
import '../models/payment_filter.dart';
import '../models/payment_summary.dart';
import '../models/razorpay_models.dart';
import '../models/student_fee_profile.dart';

abstract class PaymentRepository {
  /// Fetches payments filtered, searched, and sorted
  Future<List<Payment>> fetchPayments({PaymentFilter? filter});

  /// Fetches aggregated financial summary and telemetry
  Future<PaymentSummary> fetchPaymentSummary({PaymentFilter? filter});

  /// Fetches full fee ledger and enrolled course billing for a specific student
  Future<StudentFeeProfile?> fetchStudentFeeProfile(String studentId);

  /// Fetches fee profiles for all students to calculate institutional outstanding balances
  Future<List<StudentFeeProfile>> fetchAllStudentFeeProfiles();

  /// Checks if a transaction reference already exists in the system
  Future<bool> checkTransactionRefExists(String transactionRef);

  /// Records a new payment transaction with atomic integrity
  Future<Payment> recordPayment({
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
    String? verifiedBy,
    Map<String, dynamic>? rawProviderPayload,
  });

  /// Marks a pending payment as verified by an authorized administrator
  Future<Payment> verifyPayment(String paymentId, {required String verifiedBy});

  /// Rejects a pending payment with an institutional reason
  Future<Payment> rejectPayment(String paymentId, {required String reason});

  /// Processes a refund for an existing payment
  Future<Payment> processRefund(
    String paymentId, {
    required double amount,
    required String reason,
  });

  /// Fetches all active students and their enrolled courses for payment recording
  Future<List<Map<String, dynamic>>> fetchStudentsWithEnrollments();

  /// Creates an authoritative server-side Razorpay order via Supabase Edge Function
  Future<RazorpayOrderResponse> createRazorpayOrder(
    RazorpayOrderRequest request,
  );

  /// Cryptographically verifies Razorpay payment on server via Supabase Edge Function
  Future<RazorpayVerificationResult> verifyRazorpayPayment(
    RazorpayVerificationRequest request,
  );
}
