import 'dart:convert';

/// Authoritative Payment Entity matching Supabase `public.payments` schema
class StudentPayment {
  final String id;
  final String transactionRef;
  final String studentId;
  final String studentName;
  final String? studentCode;
  final String? courseId;
  final String? courseName;
  final String? subscriptionPlan;
  final double amount;
  final String currency;
  final String paymentMethod;
  final String status;
  final DateTime paymentDate;
  final String? verifiedBy;
  final String? rejectionReason;
  final String refundStatus;
  final DateTime? subscriptionStart;
  final DateTime? subscriptionExpiry;
  final String? notes;
  final Map<String, dynamic>? rawProviderPayload;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StudentPayment({
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

  /// Deterministic Receipt Number matching IIECM Admin convention
  String get receiptNumber {
    if (rawProviderPayload != null &&
        rawProviderPayload!['receipt_number'] != null &&
        rawProviderPayload!['receipt_number'].toString().isNotEmpty) {
      return rawProviderPayload!['receipt_number'].toString();
    }
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

  String get displayStatus {
    if (isRefunded) return 'REFUNDED';
    switch (status.toLowerCase()) {
      case 'verified':
        return 'VERIFIED';
      case 'pending':
        return 'PENDING';
      case 'rejected':
        return 'REJECTED';
      case 'failed':
        return 'FAILED';
      default:
        return status.toUpperCase();
    }
  }

  /// Formatted method string for institutional display
  String get formattedMethod {
    switch (paymentMethod.toLowerCase()) {
      case 'bank_transfer':
        return 'Bank Transfer / NEFT';
      case 'upi':
        return 'UPI';
      case 'card':
        return 'Credit / Debit Card';
      case 'cash':
        return 'Cash (Accounts Counter)';
      case 'cheque':
        return 'Cheque / DD';
      case 'razorpay':
        return 'Razorpay / Online';
      default:
        return paymentMethod
            .replaceAll('_', ' ')
            .split(' ')
            .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
            .join(' ');
    }
  }

  /// Formatted INR Amount
  String get formattedAmount {
    return '₹${amount.toStringAsFixed(2)}';
  }

  /// Institutional purpose or package description
  String get purposeDescription {
    if (courseName != null && courseName!.isNotEmpty) {
      return 'Course Tuition: $courseName';
    }
    if (subscriptionPlan != null && subscriptionPlan!.isNotEmpty) {
      final planName =
          '${subscriptionPlan![0].toUpperCase()}${subscriptionPlan!.substring(1)}';
      return 'Academic Subscription: $planName Plan';
    }
    return notes ?? 'Academic Tuition & Registration Fee';
  }

  factory StudentPayment.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? payload;
    if (json['raw_provider_payload'] != null) {
      if (json['raw_provider_payload'] is Map) {
        payload = Map<String, dynamic>.from(json['raw_provider_payload'] as Map);
      } else if (json['raw_provider_payload'] is String) {
        try {
          payload = jsonDecode(json['raw_provider_payload'] as String);
        } catch (_) {}
      }
    }

    String? code;
    if (json['students'] != null && json['students'] is Map) {
      code = json['students']['student_id']?.toString();
    } else if (json['student_code'] != null) {
      code = json['student_code']?.toString();
    } else if (payload != null && payload['student_code'] != null) {
      code = payload['student_code']?.toString();
    }

    DateTime parseDate(dynamic val) {
      if (val is DateTime) return val;
      return DateTime.tryParse(val?.toString() ?? '') ?? DateTime.now();
    }

    DateTime? tryParseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString());
    }

    return StudentPayment(
      id: json['id']?.toString() ?? '',
      transactionRef: json['transaction_ref']?.toString() ?? '',
      studentId: json['student_id']?.toString() ?? '',
      studentName: json['student_name']?.toString() ?? 'Student',
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
      paymentDate: parseDate(json['payment_date'] ?? json['created_at']),
      verifiedBy: json['verified_by']?.toString(),
      rejectionReason: json['rejection_reason']?.toString(),
      refundStatus: json['refund_status']?.toString() ?? 'none',
      subscriptionStart: tryParseDate(json['subscription_start']),
      subscriptionExpiry: tryParseDate(json['subscription_expiry']),
      notes: json['notes']?.toString(),
      rawProviderPayload: payload,
      createdAt: tryParseDate(json['created_at']),
      updatedAt: tryParseDate(json['updated_at']),
    );
  }
}

