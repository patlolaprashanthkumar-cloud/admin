import 'package:flutter_test/flutter_test.dart';
import 'package:iiecm_admin/features/payments/domain/models/payment.dart';
import 'package:iiecm_admin/features/payments/domain/models/payment_filter.dart';
import 'package:iiecm_admin/features/payments/domain/models/student_fee_profile.dart';

void main() {
  group('Payment Domain Model Tests', () {
    test('Constructs Payment from JSON map correctly', () {
      final json = {
        'id': 'pay-123',
        'transaction_ref': 'TXN-20261103-9999',
        'student_id': 'stu-uuid-001',
        'student_name': 'Dr. Rajesh Gupta',
        'course_id': 'course-uuid-002',
        'course_name': 'Emergency Critical Care Fellowship',
        'subscription_plan': 'premium',
        'amount': 45000.0,
        'currency': 'INR',
        'payment_method': 'bank_transfer',
        'status': 'verified',
        'payment_date': '2026-11-03T10:30:00.000Z',
        'verified_by': 'Admin Controller',
        'refund_status': 'none',
        'notes': 'NEFT transfer acknowledged',
        'raw_provider_payload': {
          'receipt_number': 'IIECM-REC-2026-9999',
          'student_code': 'STU-2026-001',
        },
      };

      final payment = Payment.fromJson(json);

      expect(payment.id, 'pay-123');
      expect(payment.transactionRef, 'TXN-20261103-9999');
      expect(payment.studentName, 'Dr. Rajesh Gupta');
      expect(payment.studentCode, 'STU-2026-001');
      expect(payment.amount, 45000.0);
      expect(payment.isVerified, isTrue);
      expect(payment.isPending, isFalse);
      expect(payment.isRefunded, isFalse);
      expect(payment.formattedMethod, 'Bank Transfer');
      expect(payment.receiptNumber, 'IIECM-REC-2026-9999');
    });

    test('Derived receipt number fallback uses transaction ref when omitted in payload', () {
      final payment = Payment(
        id: 'p-1',
        transactionRef: 'TXN-ABCD-1234',
        studentId: 's-1',
        studentName: 'Ananya Roy',
        amount: 25000.0,
        paymentMethod: 'upi',
        status: 'pending',
        paymentDate: DateTime(2026, 11, 3),
      );

      expect(payment.receiptNumber, 'REC-TXNABCD1234');
      expect(payment.isPending, isTrue);
      expect(payment.formattedMethod, 'UPI');
    });

    test('Payment.toJson produces authoritative schema columns for Supabase insert', () {
      final payment = Payment(
        id: 'p-2',
        transactionRef: 'TXN-777',
        studentId: 's-2',
        studentName: 'Rohan Verma',
        courseId: 'c-1',
        courseName: 'Fellowship in Emergency Medicine',
        amount: 30000.0,
        paymentMethod: 'card',
        status: 'verified',
        paymentDate: DateTime(2026, 11, 3, 14, 0),
        notes: 'Card payment via POS machine',
      );

      final map = payment.toJson();

      expect(map['transaction_ref'], 'TXN-777');
      expect(map['student_id'], 's-2');
      expect(map['student_name'], 'Rohan Verma');
      expect(map['course_id'], 'c-1');
      expect(map['amount'], 30000.0);
      expect(map['currency'], 'INR');
      expect(map['payment_method'], 'card');
      expect(map['status'], 'verified');
    });
  });

  group('StudentFeeProfile Business Calculation Tests', () {
    test(
      'Calculates fully paid status correctly when net paid equals total fee',
      () {
        final courses = [
          const EnrolledCourseFeeInfo(
            courseId: 'c-1',
            title: 'Advanced Trauma Care',
            fee: 50000.0,
            categoryName: 'Trauma',
          ),
        ];

        final payments = [
          Payment(
            id: 'p-1',
            transactionRef: 'TXN-001',
            studentId: 'stu-1',
            studentName: 'Rahul',
            amount: 50000.0,
            paymentMethod: 'bank_transfer',
            status: 'verified',
            paymentDate: DateTime.now(),
          ),
        ];

        final profile = StudentFeeProfile.calculate(
          studentId: 'stu-1',
          studentCode: 'STU-001',
          studentName: 'Rahul',
          email: 'rahul@test.com',
          phone: '9876543210',
          enrolledCourses: courses,
          payments: payments,
        );

        expect(profile.totalCourseFee, 50000.0);
        expect(profile.totalPaid, 50000.0);
        expect(profile.outstandingBalance, 0.0);
        expect(profile.paymentCompletionPercentage, 100.0);
        expect(profile.derivedStatus, 'paid');
      },
    );

    test(
      'Calculates partially paid status and outstanding balance accurately',
      () {
        final courses = [
          const EnrolledCourseFeeInfo(
            courseId: 'c-1',
            title: 'Emergency Medicine',
            fee: 80000.0,
            categoryName: 'EM',
          ),
        ];

        final payments = [
          Payment(
            id: 'p-1',
            transactionRef: 'TXN-001',
            studentId: 'stu-2',
            studentName: 'Pooja',
            amount: 30000.0,
            paymentMethod: 'upi',
            status: 'verified',
            paymentDate: DateTime.now(),
          ),
        ];

        final profile = StudentFeeProfile.calculate(
          studentId: 'stu-2',
          studentCode: 'STU-002',
          studentName: 'Pooja',
          email: 'pooja@test.com',
          phone: '9876543211',
          enrolledCourses: courses,
          payments: payments,
        );

        expect(profile.totalCourseFee, 80000.0);
        expect(profile.totalPaid, 30000.0);
        expect(profile.outstandingBalance, 50000.0);
        expect(profile.paymentCompletionPercentage, 37.5);
        expect(profile.derivedStatus, 'partially_paid');
      },
    );

    test(
      'Distinguishes pending and unverified payments from actual paid balance',
      () {
        final courses = [
          const EnrolledCourseFeeInfo(
            courseId: 'c-1',
            title: 'Pediatric Emergencies',
            fee: 40000.0,
            categoryName: 'Pediatrics',
          ),
        ];

        // Payment is pending, not yet verified
        final payments = [
          Payment(
            id: 'p-1',
            transactionRef: 'TXN-PENDING-001',
            studentId: 'stu-3',
            studentName: 'Kunal',
            amount: 40000.0,
            paymentMethod: 'bank_transfer',
            status: 'pending',
            paymentDate: DateTime.now(),
          ),
        ];

        final profile = StudentFeeProfile.calculate(
          studentId: 'stu-3',
          studentCode: 'STU-003',
          studentName: 'Kunal',
          email: 'kunal@test.com',
          phone: '9876543212',
          enrolledCourses: courses,
          payments: payments,
        );

        // Pending payments must NOT be treated as collected revenue
        expect(profile.totalPaid, 0.0);
        expect(profile.outstandingBalance, 40000.0);
        expect(profile.paymentCompletionPercentage, 0.0);
        expect(profile.pendingPayments.length, 1);
      },
    );

    test('Refund deduction recalculates outstanding balance and identifies refunded status', () {
      final courses = [
        const EnrolledCourseFeeInfo(
          courseId: 'c-1',
          title: 'Toxicology',
          fee: 25000.0,
          categoryName: 'Toxicology',
        ),
      ];

      final payments = [
        Payment(
          id: 'p-1',
          transactionRef: 'TXN-REFUNDED-01',
          studentId: 'stu-4',
          studentName: 'Meera',
          amount: 25000.0,
          paymentMethod: 'card',
          status: 'refunded',
          refundStatus: 'completed',
          paymentDate: DateTime.now(),
        ),
      ];

      final profile = StudentFeeProfile.calculate(
        studentId: 'stu-4',
        studentCode: 'STU-004',
        studentName: 'Meera',
        email: 'meera@test.com',
        phone: '9876543213',
        enrolledCourses: courses,
        payments: payments,
      );

      expect(profile.totalPaid, 0.0);
      expect(profile.outstandingBalance, 25000.0);
      expect(profile.derivedStatus, 'refunded');
      expect(profile.refundPayments.length, 1);
    });
  });

  group('PaymentFilter Date Range Tests', () {
    test('Calculates today date boundaries', () {
      const filter = PaymentFilter(dateFilterType: PaymentDateFilterType.today);
      final range = filter.dateRange;

      final now = DateTime.now();
      expect(range.start?.year, now.year);
      expect(range.start?.month, now.month);
      expect(range.start?.day, now.day);
      expect(range.start?.hour, 0);
      expect(range.end?.hour, 23);
    });

    test('Calculates this month boundaries', () {
      const filter = PaymentFilter(
        dateFilterType: PaymentDateFilterType.thisMonth,
      );
      final range = filter.dateRange;

      final now = DateTime.now();
      expect(range.start?.day, 1);
      expect(range.start?.month, now.month);
      expect(range.end?.month, now.month);
    });

    test('Calculates custom date range boundaries', () {
      final start = DateTime(2026, 1, 10);
      final end = DateTime(2026, 1, 20);
      final filter = PaymentFilter(
        dateFilterType: PaymentDateFilterType.custom,
        customStartDate: start,
        customEndDate: end,
      );

      final range = filter.dateRange;
      expect(range.start?.day, 10);
      expect(range.end?.day, 20);
      expect(range.end?.hour, 23);
    });
  });
}
