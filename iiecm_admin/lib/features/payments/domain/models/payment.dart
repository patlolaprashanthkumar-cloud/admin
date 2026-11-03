import 'dart:convert';

/// Authoritative Payment Entity matching Supabase `public.payments` schema
class Payment {
  final String id;
  final String transactionRef;
  final String studentId;
  final String studentName;
  final String? studentCode; // e.g. STU-2026-001 (joined or in payload)
  final String? courseId;
  final String? courseName;
  final String? subscriptionPlan; // 'free', 'basic', 'premium', 'enterprise'
  final double amount;
  final String currency; // 'INR'
  final String
  paymentMethod; // 'razorpay', 'bank_transfer', 'upi', 'card', 'cash', 'cheque'
  final String
  status; // 'pending', 'verified', 'rejected', 'failed', 'refunded'
  final DateTime paymentDate;
  final String? verifiedBy;
  final String? rejectionReason;
  final String refundStatus; // 'none', 'initiated', 'completed', 'rejected'
  final DateTime? subscriptionStart;
  final DateTime? subscriptionExpiry;
  final String? notes;
  final Map<String, dynamic>? rawProviderPayload;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Payment({
    required this.id,
    required this.transactionRef,
    required this.studentId,
    required this.studentName,
    this.studentCode,
    this.courseId,
    this.courseName,
    this.subscriptionPlan,
    required this.amount,
    this.currency = 'INR',
    required this.paymentMethod,
    this.status = 'pending',
    required this.paymentDate,
    this.verifiedBy,
    this.rejectionReason,
    this.refundStatus = 'none',
    this.subscriptionStart,
    this.subscriptionExpiry,
    this.notes,
    this.rawProviderPayload,
    this.createdAt,
    this.updatedAt,
  });

  /// Deterministic Receipt Number from payload or transaction reference
  String get receiptNumber {
    if (rawProviderPayload != null &&
        rawProviderPayload!['receipt_number'] != null &&
        rawProviderPayload!['receipt_number'].toString().isNotEmpty) {
      return rawProviderPayload!['receipt_number'].toString();
    }
    // Standard institutional receipt prefix
    final cleanRef = transactionRef.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    return 'REC-$cleanRef';
  }

  bool get isVerified => status.toLowerCase() == 'verified';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isRejected => status.toLowerCase() == 'rejected';
  bool get isFailed => status.toLowerCase() == 'failed';
  bool get isRefunded =>
      status.toLowerCase() == 'refunded' ||
      refundStatus.toLowerCase() == 'completed';

  String get formattedMethod {
    switch (paymentMethod.toLowerCase()) {
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'upi':
        return 'UPI';
      case 'card':
        return 'Credit/Debit Card';
      case 'cash':
        return 'Cash';
      case 'cheque':
        return 'Cheque';
      case 'razorpay':
        return 'Razorpay / Online';
      default:
        return paymentMethod
            .replaceAll('_', ' ')
            .split(' ')
            .map(
              (w) =>
                  w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '',
            )
            .join(' ');
    }
  }

  factory Payment.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? payload;
    if (json['raw_provider_payload'] != null) {
      if (json['raw_provider_payload'] is Map) {
        payload = Map<String, dynamic>.from(
          json['raw_provider_payload'] as Map,
        );
      } else if (json['raw_provider_payload'] is String) {
        try {
          payload = jsonDecode(json['raw_provider_payload'] as String);
        } catch (_) {}
      }
    }

    // Check studentCode from joined student relation if available
    String? code;
    if (json['students'] != null && json['students'] is Map) {
      code = json['students']['student_id']?.toString();
    } else if (json['student_code'] != null) {
      code = json['student_code']?.toString();
    } else if (payload != null && payload['student_code'] != null) {
      code = payload['student_code']?.toString();
    }

    return Payment(
      id: json['id']?.toString() ?? '',
      transactionRef: json['transaction_ref']?.toString() ?? '',
      studentId: json['student_id']?.toString() ?? '',
      studentName: json['student_name']?.toString() ?? '',
      studentCode: code,
      courseId: json['course_id']?.toString(),
      courseName: json['course_name']?.toString(),
      subscriptionPlan: json['subscription_plan']?.toString(),
      amount: (json['amount'] is num)
          ? (json['amount'] as num).toDouble()
          : double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      currency: json['currency']?.toString() ?? 'INR',
      paymentMethod: json['payment_method']?.toString() ?? 'cash',
      status: json['status']?.toString() ?? 'pending',
      paymentDate: json['payment_date'] != null
          ? DateTime.tryParse(json['payment_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      verifiedBy: json['verified_by']?.toString(),
      rejectionReason: json['rejection_reason']?.toString(),
      refundStatus: json['refund_status']?.toString() ?? 'none',
      subscriptionStart: json['subscription_start'] != null
          ? DateTime.tryParse(json['subscription_start'].toString())
          : null,
      subscriptionExpiry: json['subscription_expiry'] != null
          ? DateTime.tryParse(json['subscription_expiry'].toString())
          : null,
      notes: json['notes']?.toString(),
      rawProviderPayload: payload,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transaction_ref': transactionRef,
      'student_id': studentId,
      'student_name': studentName,
      if (courseId != null) 'course_id': courseId,
      if (courseName != null) 'course_name': courseName,
      if (subscriptionPlan != null) 'subscription_plan': subscriptionPlan,
      'amount': amount,
      'currency': currency,
      'payment_method': paymentMethod,
      'status': status,
      'payment_date': paymentDate.toIso8601String(),
      if (verifiedBy != null) 'verified_by': verifiedBy,
      if (rejectionReason != null) 'rejection_reason': rejectionReason,
      'refund_status': refundStatus,
      if (subscriptionStart != null)
        'subscription_start': subscriptionStart!.toIso8601String(),
      if (subscriptionExpiry != null)
        'subscription_expiry': subscriptionExpiry!.toIso8601String(),
      if (notes != null) 'notes': notes,
      if (rawProviderPayload != null)
        'raw_provider_payload': rawProviderPayload,
    };
  }

  Payment copyWith({
    String? id,
    String? transactionRef,
    String? studentId,
    String? studentName,
    String? studentCode,
    String? courseId,
    String? courseName,
    String? subscriptionPlan,
    double? amount,
    String? currency,
    String? paymentMethod,
    String? status,
    DateTime? paymentDate,
    String? verifiedBy,
    String? rejectionReason,
    String? refundStatus,
    DateTime? subscriptionStart,
    DateTime? subscriptionExpiry,
    String? notes,
    Map<String, dynamic>? rawProviderPayload,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Payment(
      id: id ?? this.id,
      transactionRef: transactionRef ?? this.transactionRef,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentCode: studentCode ?? this.studentCode,
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      paymentDate: paymentDate ?? this.paymentDate,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      refundStatus: refundStatus ?? this.refundStatus,
      subscriptionStart: subscriptionStart ?? this.subscriptionStart,
      subscriptionExpiry: subscriptionExpiry ?? this.subscriptionExpiry,
      notes: notes ?? this.notes,
      rawProviderPayload: rawProviderPayload ?? this.rawProviderPayload,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
