import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iiecm_student/features/payments/domain/models/student_payment.dart';
import 'package:iiecm_student/features/payments/presentation/providers/payments_state.dart';
import 'package:iiecm_student/features/payments/presentation/widgets/payment_card.dart';
import 'package:iiecm_student/features/payments/presentation/widgets/payment_receipt_card.dart';

void main() {
  group('StudentPayment Model Tests', () {
    test('Parses verified payment correctly from JSON', () {
      final payment = StudentPayment.fromJson({
        'id': 'pay-001',
        'transaction_ref': 'pay_ONL123456789',
        'student_id': 'stu-uuid-1',
        'student_name': 'Dr. Aditi Sharma',
        'student_code': 'STU-2026-089',
        'course_id': 'c-101',
        'course_name': 'Emergency Critical Care Fellowship',
        'amount': 24999.00,
        'currency': 'INR',
        'payment_method': 'razorpay',
        'status': 'verified',
        'payment_date': '2026-11-05T12:00:00Z',
        'raw_provider_payload': {
          'receipt_number': 'IIECM-REC-2026-991',
        },
      });

      expect(payment.id, 'pay-001');
      expect(payment.transactionRef, 'pay_ONL123456789');
      expect(payment.receiptNumber, 'IIECM-REC-2026-991');
      expect(payment.studentName, 'Dr. Aditi Sharma');
      expect(payment.studentCode, 'STU-2026-089');
      expect(payment.amount, 24999.00);
      expect(payment.formattedAmount, '₹24999.00');
      expect(payment.isVerified, isTrue);
      expect(payment.isPending, isFalse);
      expect(payment.displayStatus, 'VERIFIED');
      expect(payment.formattedMethod, 'Razorpay / Online');
      expect(payment.purposeDescription, contains('Course Tuition: Emergency Critical Care Fellowship'));
    });

    test('Derives deterministic receipt number when payload receipt is absent', () {
      final payment = StudentPayment.fromJson({
        'id': 'pay-002',
        'transaction_ref': 'TXN_987654_ABC',
        'student_id': 'stu-uuid-2',
        'student_name': 'Rohan Patel',
        'subscription_plan': 'premium',
        'amount': 9999.00,
        'currency': 'INR',
        'payment_method': 'upi',
        'status': 'pending',
        'payment_date': '2026-11-12T08:30:00Z',
      });

      expect(payment.receiptNumber, 'REC-TXN987654ABC');
      expect(payment.isPending, isTrue);
      expect(payment.isVerified, isFalse);
      expect(payment.displayStatus, 'PENDING');
      expect(payment.formattedMethod, 'UPI');
      expect(payment.purposeDescription, contains('Academic Subscription: Premium Plan'));
    });
  });

  group('PaymentsState Filtering Tests', () {
    final p1 = StudentPayment(
      id: '1',
      transactionRef: 'TXN-1',
      studentId: 's1',
      studentName: 'Student 1',
      courseName: 'Cardiology',
      amount: 15000.0,
      paymentMethod: 'razorpay',
      status: 'verified',
      paymentDate: DateTime.now(),
    );

    final p2 = StudentPayment(
      id: '2',
      transactionRef: 'TXN-2',
      studentId: 's1',
      studentName: 'Student 1',
      courseName: 'Neurology',
      amount: 12000.0,
      paymentMethod: 'bank_transfer',
      status: 'pending',
      paymentDate: DateTime.now(),
    );

    final p3 = StudentPayment(
      id: '3',
      transactionRef: 'TXN-3',
      studentId: 's1',
      studentName: 'Student 1',
      courseName: 'Trauma Life Support',
      amount: 8000.0,
      paymentMethod: 'upi',
      status: 'failed',
      paymentDate: DateTime.now(),
    );

    final p4 = StudentPayment(
      id: '4',
      transactionRef: 'TXN-4',
      studentId: 's1',
      studentName: 'Student 1',
      courseName: 'Pediatrics',
      amount: 5000.0,
      paymentMethod: 'card',
      status: 'refunded',
      paymentDate: DateTime.now(),
    );

    final state = PaymentsState(
      status: PaymentsStatus.loaded,
      payments: [p1, p2, p3, p4],
    );

    test('Filters by verified payments', () {
      final filtered = state.copyWith(filter: PaymentFilterType.verified).filteredPayments;
      expect(filtered.length, 1);
      expect(filtered.first.id, '1');
    });

    test('Filters by pending payments', () {
      final filtered = state.copyWith(filter: PaymentFilterType.pending).filteredPayments;
      expect(filtered.length, 1);
      expect(filtered.first.id, '2');
    });

    test('Filters by failed payments', () {
      final filtered = state.copyWith(filter: PaymentFilterType.failed).filteredPayments;
      expect(filtered.length, 1);
      expect(filtered.first.id, '3');
    });

    test('Filters by refunded payments', () {
      final filtered = state.copyWith(filter: PaymentFilterType.refunded).filteredPayments;
      expect(filtered.length, 1);
      expect(filtered.first.id, '4');
    });

    test('Filters by search query matching course or ref', () {
      final filtered = state.copyWith(searchQuery: 'Neurology').filteredPayments;
      expect(filtered.length, 1);
      expect(filtered.first.courseName, 'Neurology');
    });

    test('Calculates aggregate financial metrics', () {
      expect(state.totalPaymentsCount, 4);
      expect(state.verifiedCount, 1);
      expect(state.pendingCount, 1);
      expect(state.totalVerifiedAmount, 15000.0);
    });
  });

  group('Payment Widgets Tests', () {
    testWidgets('PaymentCard renders receipt number, amount and method', (tester) async {
      final payment = StudentPayment(
        id: 'p-1',
        transactionRef: 'PAY123456',
        studentId: 's1',
        studentName: 'Student',
        amount: 25000.0,
        paymentMethod: 'razorpay',
        status: 'verified',
        courseName: 'Critical Care Fellowship',
        paymentDate: DateTime(2026, 11, 5),
      );

      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentCard(
              payment: payment,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('REC-PAY123456'), findsOneWidget);
      expect(find.text('₹25000.00'), findsOneWidget);
      expect(find.text('Razorpay / Online'), findsOneWidget);
      expect(find.text('VERIFIED'), findsOneWidget);

      await tester.tap(find.byType(PaymentCard));
      expect(tapped, isTrue);
    });

    testWidgets('PaymentReceiptCard renders institutional receipt details', (tester) async {
      final payment = StudentPayment(
        id: 'p-1',
        transactionRef: 'PAY_998877',
        studentId: 's1',
        studentName: 'Dr. Aditi Sharma',
        studentCode: 'STU-2026-089',
        amount: 19999.0,
        paymentMethod: 'upi',
        status: 'verified',
        courseName: 'Emergency Medicine Fellowship',
        paymentDate: DateTime(2026, 11, 8, 14, 30),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentReceiptCard(payment: payment),
          ),
        ),
      );

      expect(find.text('OFFICIAL FEE RECEIPT'), findsOneWidget);
      expect(find.text('Indian Institute of Emergency & Critical Care Medicine'), findsOneWidget);
      expect(find.text('Dr. Aditi Sharma'), findsOneWidget);
      expect(find.text('STU-2026-089'), findsOneWidget);
      expect(find.text('₹19999.00'), findsOneWidget);
      expect(find.text('Copy Receipt Voucher'), findsOneWidget);
    });
  });
}

