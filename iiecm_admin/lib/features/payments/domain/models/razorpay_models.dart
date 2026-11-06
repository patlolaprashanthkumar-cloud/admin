import 'payment.dart';

/// Request payload to create an official Razorpay Order via Supabase Edge Function
class RazorpayOrderRequest {
  final String studentId;
  final String? courseId;
  final double amount;
  final String? notes;

  const RazorpayOrderRequest({
    required this.studentId,
    this.courseId,
    required this.amount,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      if (courseId != null && courseId!.isNotEmpty) 'courseId': courseId,
      'amount': amount,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }
}

/// Response received from Supabase Edge Function `create-razorpay-order`
class RazorpayOrderResponse {
  final bool success;
  final String paymentId;
  final String orderId;
  final int amountPaise;
  final double amountInr;
  final String currency;
  final String keyId;
  final Map<String, dynamic> student;
  final Map<String, dynamic>? course;

  const RazorpayOrderResponse({
    required this.success,
    required this.paymentId,
    required this.orderId,
    required this.amountPaise,
    required this.amountInr,
    required this.currency,
    required this.keyId,
    required this.student,
    this.course,
  });

  factory RazorpayOrderResponse.fromJson(Map<String, dynamic> json) {
    return RazorpayOrderResponse(
      success: json['success'] == true,
      paymentId: json['paymentId']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      amountPaise: (json['amountPaise'] as num?)?.toInt() ?? 0,
      amountInr: (json['amountInr'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency']?.toString() ?? 'INR',
      keyId: json['keyId']?.toString() ?? '',
      student: json['student'] != null
          ? Map<String, dynamic>.from(json['student'] as Map)
          : {},
      course: json['course'] != null
          ? Map<String, dynamic>.from(json['course'] as Map)
          : null,
    );
  }
}

/// Verification tokens sent to Supabase Edge Function `verify-razorpay-payment`
class RazorpayVerificationRequest {
  final String paymentId;
  final String razorpayPaymentId;
  final String razorpayOrderId;
  final String razorpaySignature;

  const RazorpayVerificationRequest({
    required this.paymentId,
    required this.razorpayPaymentId,
    required this.razorpayOrderId,
    required this.razorpaySignature,
  });

  Map<String, dynamic> toJson() {
    return {
      'paymentId': paymentId,
      'razorpayPaymentId': razorpayPaymentId,
      'razorpayOrderId': razorpayOrderId,
      'razorpaySignature': razorpaySignature,
    };
  }
}

/// Result returned from server-side cryptographic and status verification
class RazorpayVerificationResult {
  final bool success;
  final String? message;
  final Payment? payment;
  final String? receiptNumber;
  final String? error;

  const RazorpayVerificationResult({
    required this.success,
    this.message,
    this.payment,
    this.receiptNumber,
    this.error,
  });

  factory RazorpayVerificationResult.success({
    required Payment payment,
    String? receiptNumber,
    String? message,
  }) {
    return RazorpayVerificationResult(
      success: true,
      payment: payment,
      receiptNumber: receiptNumber ?? payment.receiptNumber,
      message: message,
    );
  }

  factory RazorpayVerificationResult.failure({required String error}) {
    return RazorpayVerificationResult(success: false, error: error);
  }
}
