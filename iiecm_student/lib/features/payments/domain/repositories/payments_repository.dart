import '../models/student_payment.dart';

/// Contract defining payment access for the authenticated student
abstract class PaymentsRepository {
  /// Fetches all payment transactions belonging to the student record, sorted newest first
  Future<List<StudentPayment>> getStudentPayments(String studentRecordId);

  /// Fetches detailed transaction information for a specific payment ID
  Future<StudentPayment?> getPaymentDetails({
    required String paymentId,
    required String studentRecordId,
  });
}

