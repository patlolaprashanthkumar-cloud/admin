import 'dart:math' as math;

import 'payment.dart';

class EnrolledCourseFeeInfo {
  final String courseId;
  final String title;
  final double fee;
  final String categoryName;
  final String enrollmentStatus;
  final DateTime? enrolledAt;

  const EnrolledCourseFeeInfo({
    required this.courseId,
    required this.title,
    required this.fee,
    required this.categoryName,
    this.enrollmentStatus = 'active',
    this.enrolledAt,
  });

  factory EnrolledCourseFeeInfo.fromJson(Map<String, dynamic> json) {
    return EnrolledCourseFeeInfo(
      courseId: json['course_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Course',
      fee: (json['fee'] is num)
          ? (json['fee'] as num).toDouble()
          : double.tryParse(json['fee']?.toString() ?? '0') ?? 0.0,
      categoryName: json['category_name']?.toString() ?? 'General',
      enrollmentStatus: json['status']?.toString() ?? 'active',
      enrolledAt: json['enrolled_at'] != null
          ? DateTime.tryParse(json['enrolled_at'].toString())
          : null,
    );
  }
}

/// Comprehensive fee and billing profile for a student
class StudentFeeProfile {
  final String studentId; // Supabase UUID
  final String studentCode; // e.g. STU-2026-001
  final String studentName;
  final String email;
  final String phone;
  final List<EnrolledCourseFeeInfo> enrolledCourses;
  final List<Payment> payments;
  final double totalCourseFee;
  final double totalPaid;
  final double outstandingBalance;
  final double paymentCompletionPercentage;
  final String derivedStatus; // 'paid', 'partially_paid', 'pending', 'overdue', 'refunded', 'partially_refunded'

  const StudentFeeProfile({
    required this.studentId,
    required this.studentCode,
    required this.studentName,
    required this.email,
    required this.phone,
    required this.enrolledCourses,
    required this.payments,
    required this.totalCourseFee,
    required this.totalPaid,
    required this.outstandingBalance,
    required this.paymentCompletionPercentage,
    required this.derivedStatus,
  });

  List<Payment> get verifiedPayments =>
      payments.where((p) => p.isVerified).toList();

  List<Payment> get pendingPayments =>
      payments.where((p) => p.isPending).toList();

  List<Payment> get refundPayments =>
      payments.where((p) => p.isRefunded).toList();

  DateTime? get lastPaymentDate {
    final verified = verifiedPayments;
    if (verified.isEmpty) return null;
    verified.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
    return verified.first.paymentDate;
  }

  /// Calculates student fee profile deterministically from courses and payments
  factory StudentFeeProfile.calculate({
    required String studentId,
    required String studentCode,
    required String studentName,
    required String email,
    required String phone,
    required List<EnrolledCourseFeeInfo> enrolledCourses,
    required List<Payment> payments,
  }) {
    // 1. Total fee is sum of enrolled course fees
    final totalFee = enrolledCourses.fold<double>(0.0, (sum, c) => sum + c.fee);

    // 2. Net verified paid amount accounting for partial and full refunds
    final netPaid = payments
        .where((p) => p.isVerified)
        .fold<double>(0.0, (sum, p) => sum + p.netRetainedAmount);

    // 3. Total refunded amount across all transactions
    final refundedAmount = payments.fold<double>(
      0.0,
      (sum, p) => sum + p.refundedAmount,
    );

    final balance = math.max(0.0, totalFee - netPaid);

    final percentage = totalFee > 0
        ? ((netPaid / totalFee) * 100).clamp(0.0, 100.0)
        : (netPaid > 0 ? 100.0 : 0.0);

    // 4. Determine authoritative derived status
    String status = 'pending';
    if (refundedAmount > 0 && netPaid == 0) {
      status = 'refunded';
    } else if (refundedAmount > 0 && netPaid > 0) {
      status = 'partially_refunded';
    } else if (netPaid >= totalFee && totalFee > 0) {
      status = 'paid';
    } else if (netPaid > 0 && netPaid < totalFee) {
      status = 'partially_paid';
    } else if (netPaid == 0) {
      // Check if any enrollment has been active for more than 30 days without payment
      final isOverdue = enrolledCourses.any((c) {
        if (c.enrolledAt == null) return false;
        final days = DateTime.now().difference(c.enrolledAt!).inDays;
        return days > 30;
      });
      status = isOverdue ? 'overdue' : 'pending';
    }

    return StudentFeeProfile(
      studentId: studentId,
      studentCode: studentCode,
      studentName: studentName,
      email: email,
      phone: phone,
      enrolledCourses: enrolledCourses,
      payments: payments,
      totalCourseFee: totalFee,
      totalPaid: netPaid,
      outstandingBalance: balance,
      paymentCompletionPercentage: percentage,
      derivedStatus: status,
    );
  }
}
