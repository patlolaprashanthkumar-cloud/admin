import 'dart:developer' as developer;
import 'dart:math' as math;

import '../../../../core/network/supabase_client.dart';
import '../../domain/models/payment.dart';
import '../../domain/models/payment_filter.dart';
import '../../domain/models/payment_summary.dart';
import '../../domain/models/student_fee_profile.dart';
import '../../domain/repositories/payment_repository.dart';

class SupabasePaymentRepository implements PaymentRepository {
  @override
  Future<List<Payment>> fetchPayments({PaymentFilter? filter}) async {
    final client = AppSupabase.client;

    try {
      var query = client.from('payments').select('*, students(student_id)');

      if (filter != null) {
        // Status filter
        if (filter.status != null &&
            filter.status!.isNotEmpty &&
            filter.status != 'all') {
          query = query.eq('status', filter.status!.toLowerCase());
        }

        // Method filter
        if (filter.paymentMethod != null &&
            filter.paymentMethod!.isNotEmpty &&
            filter.paymentMethod != 'all') {
          query = query.eq(
            'payment_method',
            filter.paymentMethod!.toLowerCase(),
          );
        }

        // Date range filter
        final range = filter.dateRange;
        if (range.start != null) {
          query = query.gte('payment_date', range.start!.toIso8601String());
        }
        if (range.end != null) {
          query = query.lte('payment_date', range.end!.toIso8601String());
        }
      }

      final sortField = (filter != null && filter.sortBy == 'amount')
          ? 'amount'
          : 'payment_date';
      final ascending = (filter != null && !filter.sortDescending);

      final List<dynamic> rows = await query.order(
        sortField,
        ascending: ascending,
      );
      List<Payment> payments = rows
          .map((r) => Payment.fromJson(r as Map<String, dynamic>))
          .toList();

      // Search query in memory for cross-field matching (student name, code, txn ref, course)
      if (filter != null && filter.searchQuery.trim().isNotEmpty) {
        final q = filter.searchQuery.trim().toLowerCase();
        payments = payments.where((p) {
          final matchesRef = p.transactionRef.toLowerCase().contains(q);
          final matchesStudent = p.studentName.toLowerCase().contains(q);
          final matchesCode = p.studentCode?.toLowerCase().contains(q) ?? false;
          final matchesCourse =
              p.courseName?.toLowerCase().contains(q) ?? false;
          final matchesReceipt = p.receiptNumber.toLowerCase().contains(q);
          return matchesRef ||
              matchesStudent ||
              matchesCode ||
              matchesCourse ||
              matchesReceipt;
        }).toList();
      }

      return payments;
    } catch (e, stack) {
      developer.log(
        'Error fetching payments: $e',
        name: 'SupabasePaymentRepository',
        error: e,
        stackTrace: stack,
      );
      // Fallback query without relation if students join fails
      try {
        final List<dynamic> fallbackRows = await client
            .from('payments')
            .select('*')
            .order('payment_date', ascending: false);
        return fallbackRows
            .map((r) => Payment.fromJson(r as Map<String, dynamic>))
            .toList();
      } catch (fallbackError) {
        developer.log('Fallback payments fetch failed: $fallbackError');
        return [];
      }
    }
  }

  @override
  Future<PaymentSummary> fetchPaymentSummary({PaymentFilter? filter}) async {
    try {
      // 1. Fetch filtered payments for collections/revenue
      final payments = await fetchPayments(filter: filter);

      // 2. Fetch all student fee profiles to compute institutional outstanding balances
      final feeProfiles = await fetchAllStudentFeeProfiles();

      double totalFeesCollected = 0.0;
      int totalPaymentsReceived = 0;
      int pendingPaymentsCount = 0;
      double pendingPaymentsAmount = 0.0;
      double refundTotal = 0.0;
      final Map<String, double> dailyCollections = {};
      final Map<String, double> monthlyCollections = {};
      final Map<String, double> courseWiseCollections = {};
      final Map<String, double> methodBreakdown = {};
      final Map<String, int> statusBreakdown = {
        'verified': 0,
        'pending': 0,
        'rejected': 0,
        'failed': 0,
        'refunded': 0,
      };

      final now = DateTime.now();
      double currentMonthRevenue = 0.0;

      for (final p in payments) {
        final st = p.status.toLowerCase();
        statusBreakdown[st] = (statusBreakdown[st] ?? 0) + 1;

        if (p.isVerified) {
          totalFeesCollected += p.amount;
          totalPaymentsReceived += 1;

          // Daily key: YYYY-MM-DD
          final dayKey = p.paymentDate.toIso8601String().substring(0, 10);
          dailyCollections[dayKey] =
              (dailyCollections[dayKey] ?? 0.0) + p.amount;

          // Monthly key: YYYY-MM
          final monthKey = p.paymentDate.toIso8601String().substring(0, 7);
          monthlyCollections[monthKey] =
              (monthlyCollections[monthKey] ?? 0.0) + p.amount;

          if (p.paymentDate.year == now.year &&
              p.paymentDate.month == now.month) {
            currentMonthRevenue += p.amount;
          }

          // Course-wise
          final courseKey = p.courseName ?? 'General / Subscription';
          courseWiseCollections[courseKey] =
              (courseWiseCollections[courseKey] ?? 0.0) + p.amount;

          // Method breakdown
          final methodKey = p.formattedMethod;
          methodBreakdown[methodKey] =
              (methodBreakdown[methodKey] ?? 0.0) + p.amount;
        } else if (p.isPending) {
          pendingPaymentsCount += 1;
          pendingPaymentsAmount += p.amount;
        }

        if (p.isRefunded) {
          refundTotal += p.amount;
        }
      }

      // Compute student-level totals
      double totalOutstanding = 0.0;
      int overdueCount = 0;
      int partiallyPaidCount = 0;

      for (final profile in feeProfiles) {
        totalOutstanding += profile.outstandingBalance;
        if (profile.derivedStatus == 'overdue') {
          overdueCount++;
        } else if (profile.derivedStatus == 'partially_paid') {
          partiallyPaidCount++;
        }
      }

      final recentTxns = payments.take(10).toList();

      return PaymentSummary(
        totalFeesCollected: totalFeesCollected,
        totalPaymentsReceived: totalPaymentsReceived,
        totalOutstandingAmount: totalOutstanding,
        pendingPaymentsCount: pendingPaymentsCount,
        pendingPaymentsAmount: pendingPaymentsAmount,
        overduePaymentsCount: overdueCount,
        partiallyPaidStudentsCount: partiallyPaidCount,
        refundTotal: refundTotal,
        monthlyRevenue: currentMonthRevenue,
        dailyCollections: dailyCollections,
        monthlyCollections: monthlyCollections,
        courseWiseCollections: courseWiseCollections,
        methodBreakdown: methodBreakdown,
        statusBreakdown: statusBreakdown,
        recentTransactions: recentTxns,
      );
    } catch (e, stack) {
      developer.log(
        'Error calculating payment summary: $e',
        name: 'SupabasePaymentRepository',
        error: e,
        stackTrace: stack,
      );
      return PaymentSummary.empty();
    }
  }

  @override
  Future<StudentFeeProfile?> fetchStudentFeeProfile(String studentId) async {
    final client = AppSupabase.client;

    try {
      // 1. Fetch student row
      final studentRow = await client
          .from('students')
          .select('id, student_id, full_name, email, phone')
          .eq('id', studentId)
          .maybeSingle();

      if (studentRow == null) return null;

      // 2. Fetch enrolled courses with course details
      final List<dynamic> enrollments = await client
          .from('course_enrollments')
          .select('status, enrolled_at, courses(id, title, fee, category_name)')
          .eq('student_id', studentId);

      final List<EnrolledCourseFeeInfo> courses = [];
      for (final e in enrollments) {
        if (e['courses'] != null && e['courses'] is Map) {
          final cMap = Map<String, dynamic>.from(e['courses'] as Map);
          cMap['status'] = e['status'];
          cMap['enrolled_at'] = e['enrolled_at'];
          courses.add(EnrolledCourseFeeInfo.fromJson(cMap));
        }
      }

      // 3. Fetch all payments for this student
      final List<dynamic> paymentRows = await client
          .from('payments')
          .select('*')
          .eq('student_id', studentId)
          .order('payment_date', ascending: false);

      final List<Payment> payments = paymentRows
          .map((p) => Payment.fromJson(p as Map<String, dynamic>))
          .toList();

      return StudentFeeProfile.calculate(
        studentId: studentRow['id']?.toString() ?? '',
        studentCode: studentRow['student_id']?.toString() ?? 'N/A',
        studentName: studentRow['full_name']?.toString() ?? '',
        email: studentRow['email']?.toString() ?? '',
        phone: studentRow['phone']?.toString() ?? '',
        enrolledCourses: courses,
        payments: payments,
      );
    } catch (e, stack) {
      developer.log(
        'Error fetching student fee profile: $e',
        name: 'SupabasePaymentRepository',
        error: e,
        stackTrace: stack,
      );
      return null;
    }
  }

  @override
  Future<List<StudentFeeProfile>> fetchAllStudentFeeProfiles() async {
    final client = AppSupabase.client;

    try {
      // 1. Fetch all students
      final List<dynamic> studentRows = await client
          .from('students')
          .select('id, student_id, full_name, email, phone')
          .order('full_name');

      // 2. Fetch all course enrollments with course fee info
      final List<dynamic> allEnrollments = await client
          .from('course_enrollments')
          .select(
            'student_id, status, enrolled_at, courses(id, title, fee, category_name)',
          );

      final Map<String, List<EnrolledCourseFeeInfo>> studentCourses = {};
      for (final e in allEnrollments) {
        final sId = e['student_id']?.toString() ?? '';
        if (e['courses'] != null && e['courses'] is Map) {
          final cMap = Map<String, dynamic>.from(e['courses'] as Map);
          cMap['status'] = e['status'];
          cMap['enrolled_at'] = e['enrolled_at'];
          studentCourses
              .putIfAbsent(sId, () => [])
              .add(EnrolledCourseFeeInfo.fromJson(cMap));
        }
      }

      // 3. Fetch all payments
      final List<dynamic> allPayments = await client
          .from('payments')
          .select('*')
          .order('payment_date', ascending: false);

      final Map<String, List<Payment>> studentPayments = {};
      for (final p in allPayments) {
        final sId = p['student_id']?.toString() ?? '';
        studentPayments
            .putIfAbsent(sId, () => [])
            .add(Payment.fromJson(p as Map<String, dynamic>));
      }

      // 4. Assemble profiles
      return studentRows.map((s) {
        final sId = s['id']?.toString() ?? '';
        return StudentFeeProfile.calculate(
          studentId: sId,
          studentCode: s['student_id']?.toString() ?? 'N/A',
          studentName: s['full_name']?.toString() ?? '',
          email: s['email']?.toString() ?? '',
          phone: s['phone']?.toString() ?? '',
          enrolledCourses: studentCourses[sId] ?? [],
          payments: studentPayments[sId] ?? [],
        );
      }).toList();
    } catch (e, stack) {
      developer.log(
        'Error fetching all student fee profiles: $e',
        name: 'SupabasePaymentRepository',
        error: e,
        stackTrace: stack,
      );
      return [];
    }
  }

  @override
  Future<bool> checkTransactionRefExists(String transactionRef) async {
    final client = AppSupabase.client;
    try {
      final res = await client
          .from('payments')
          .select('id')
          .eq('transaction_ref', transactionRef.trim())
          .maybeSingle();
      return res != null;
    } catch (_) {
      return false;
    }
  }

  @override
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
  }) async {
    final client = AppSupabase.client;

    // 1. Guard against duplicate reference ID
    final exists = await checkTransactionRefExists(transactionRef);
    if (exists) {
      throw Exception(
        'Transaction reference "$transactionRef" already exists. Duplicate transactions are prevented.',
      );
    }

    // 2. Validate amount
    if (amount <= 0) {
      throw Exception('Payment amount must be greater than zero.');
    }

    // 3. Assemble payload
    final Map<String, dynamic> payload = Map<String, dynamic>.from(
      rawProviderPayload ?? {},
    );
    if (studentCode != null && studentCode.isNotEmpty) {
      payload['student_code'] = studentCode;
    }
    // Deterministic institutional receipt number
    payload['receipt_number'] =
        'IIECM-REC-${DateTime.now().year}-${transactionRef.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}';
    if (verifiedBy != null) {
      payload['recorded_by'] = verifiedBy;
    }

    final insertData = {
      'transaction_ref': transactionRef.trim(),
      'student_id': studentId,
      'student_name': studentName.trim(),
      if (courseId != null && courseId.isNotEmpty) 'course_id': courseId,
      if (courseName != null && courseName.isNotEmpty)
        'course_name': courseName.trim(),
      if (subscriptionPlan != null && subscriptionPlan.isNotEmpty)
        'subscription_plan': subscriptionPlan,
      'amount': amount,
      'currency': 'INR',
      'payment_method': paymentMethod.toLowerCase(),
      'status': status.toLowerCase(),
      'payment_date': paymentDate.toIso8601String(),
      'refund_status': 'none',
      if (verifiedBy != null && verifiedBy.isNotEmpty)
        'verified_by': verifiedBy,
      if (notes != null && notes.isNotEmpty) 'notes': notes.trim(),
      'raw_provider_payload': payload,
    };

    final Map<String, dynamic> row = await client
        .from('payments')
        .insert(insertData)
        .select()
        .single();

    return Payment.fromJson(row);
  }

  @override
  Future<Payment> verifyPayment(
    String paymentId, {
    required String verifiedBy,
  }) async {
    final client = AppSupabase.client;
    final Map<String, dynamic> row = await client
        .from('payments')
        .update({
          'status': 'verified',
          'verified_by': verifiedBy,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', paymentId)
        .select()
        .single();
    return Payment.fromJson(row);
  }

  @override
  Future<Payment> rejectPayment(
    String paymentId, {
    required String reason,
  }) async {
    final client = AppSupabase.client;
    final Map<String, dynamic> row = await client
        .from('payments')
        .update({
          'status': 'rejected',
          'rejection_reason': reason.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', paymentId)
        .select()
        .single();
    return Payment.fromJson(row);
  }

  @override
  Future<Payment> processRefund(
    String paymentId, {
    required double amount,
    required String reason,
  }) async {
    final client = AppSupabase.client;

    // Fetch existing payment
    final current = await client
        .from('payments')
        .select('*')
        .eq('id', paymentId)
        .single();

    final currentPayment = Payment.fromJson(current);
    final currentPayload = Map<String, dynamic>.from(
      currentPayment.rawProviderPayload ?? {},
    );

    final refundAudit = {
      'refunded_at': DateTime.now().toIso8601String(),
      'refund_amount': amount,
      'refund_reason': reason,
      'original_amount': currentPayment.amount,
    };
    currentPayload['refund_audit'] = refundAudit;

    // Check if full refund or partial
    final isFullRefund = amount >= currentPayment.amount;

    final Map<String, dynamic> row = await client
        .from('payments')
        .update({
          'status': isFullRefund ? 'refunded' : currentPayment.status,
          'refund_status': 'completed',
          'notes': currentPayment.notes != null
              ? '${currentPayment.notes}\n[Refund: ₹$amount - $reason]'
              : '[Refund: ₹$amount - $reason]',
          'raw_provider_payload': currentPayload,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', paymentId)
        .select()
        .single();

    return Payment.fromJson(row);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchStudentsWithEnrollments() async {
    final client = AppSupabase.client;

    try {
      final List<dynamic> students = await client
          .from('students')
          .select('id, student_id, full_name, email, phone')
          .eq('account_status', 'active')
          .order('full_name');

      final List<dynamic> enrollments = await client
          .from('course_enrollments')
          .select('student_id, courses(id, title, fee, category_name)');

      final Map<String, List<Map<String, dynamic>>> enrolledMap = {};
      for (final e in enrollments) {
        final sId = e['student_id']?.toString() ?? '';
        if (e['courses'] != null && e['courses'] is Map) {
          enrolledMap
              .putIfAbsent(sId, () => [])
              .add(Map<String, dynamic>.from(e['courses'] as Map));
        }
      }

      // Also get all verified payments to calculate current balances
      final List<dynamic> payments = await client
          .from('payments')
          .select('student_id, course_id, amount, status');

      final Map<String, double> studentTotalPaid = {};
      final Map<String, Map<String, double>> studentCoursePaid = {};

      for (final p in payments) {
        if (p['status']?.toString().toLowerCase() == 'verified') {
          final sId = p['student_id']?.toString() ?? '';
          final cId = p['course_id']?.toString();
          final amt = (p['amount'] is num)
              ? (p['amount'] as num).toDouble()
              : double.tryParse(p['amount']?.toString() ?? '0') ?? 0.0;

          studentTotalPaid[sId] = (studentTotalPaid[sId] ?? 0.0) + amt;
          if (cId != null && cId.isNotEmpty) {
            studentCoursePaid.putIfAbsent(sId, () => {});
            studentCoursePaid[sId]![cId] =
                (studentCoursePaid[sId]![cId] ?? 0.0) + amt;
          }
        }
      }

      return students.map((s) {
        final sId = s['id']?.toString() ?? '';
        final courses = enrolledMap[sId] ?? [];

        final courseDetails = courses.map((c) {
          final cId = c['id']?.toString() ?? '';
          final fee = (c['fee'] is num)
              ? (c['fee'] as num).toDouble()
              : double.tryParse(c['fee']?.toString() ?? '0') ?? 0.0;
          final paidForCourse = studentCoursePaid[sId]?[cId] ?? 0.0;
          final balance = math.max(0.0, fee - paidForCourse);

          return {
            'id': cId,
            'title': c['title']?.toString() ?? 'Course',
            'fee': fee,
            'paid': paidForCourse,
            'balance': balance,
            'category_name': c['category_name']?.toString() ?? 'General',
          };
        }).toList();

        final totalFee = courseDetails.fold<double>(
          0.0,
          (sum, c) => sum + (c['fee'] as double),
        );
        final totalPaid = studentTotalPaid[sId] ?? 0.0;
        final outstandingBalance = math.max(0.0, totalFee - totalPaid);

        return {
          'id': sId,
          'student_id': s['student_id']?.toString() ?? 'N/A',
          'full_name': s['full_name']?.toString() ?? '',
          'email': s['email']?.toString() ?? '',
          'phone': s['phone']?.toString() ?? '',
          'courses': courseDetails,
          'total_fee': totalFee,
          'total_paid': totalPaid,
          'outstanding_balance': outstandingBalance,
        };
      }).toList();
    } catch (e, stack) {
      developer.log(
        'Error fetching students with enrollments: $e',
        name: 'SupabasePaymentRepository',
        error: e,
        stackTrace: stack,
      );
      return [];
    }
  }
}
