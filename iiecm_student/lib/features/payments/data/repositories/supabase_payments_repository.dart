import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/supabase_client.dart';
import '../../domain/models/student_payment.dart';
import '../../domain/repositories/payments_repository.dart';

/// Concrete Supabase implementation of PaymentsRepository
class SupabasePaymentsRepository implements PaymentsRepository {
  SupabaseClient get _client => AppSupabase.client;

  @override
  Future<List<StudentPayment>> getStudentPayments(String studentRecordId) async {
    if (!AppSupabase.isInitialized) {
      throw StateError('Supabase is not initialized.');
    }
    if (studentRecordId.isEmpty) return [];

    try {
      // 1. Fetch payments for the authenticated student's record with joined student registration code
      try {
        final List<dynamic> rows = await _client
            .from('payments')
            .select('*, students(student_id)')
            .eq('student_id', studentRecordId)
            .order('payment_date', ascending: false)
            .timeout(const Duration(seconds: 10));

        return rows
            .map((r) => StudentPayment.fromJson(r as Map<String, dynamic>))
            .toList();
      } catch (e) {
        developer.log(
          'Joined query failed, executing fallback payments query: $e',
          name: 'SupabasePaymentsRepository',
        );
        // Fallback without relation
        final List<dynamic> fallbackRows = await _client
            .from('payments')
            .select('*')
            .eq('student_id', studentRecordId)
            .order('payment_date', ascending: false)
            .timeout(const Duration(seconds: 8));

        return fallbackRows
            .map((r) => StudentPayment.fromJson(r as Map<String, dynamic>))
            .toList();
      }
    } catch (e, stack) {
      developer.log(
        'Error fetching payments for student $studentRecordId: $e',
        name: 'SupabasePaymentsRepository',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<StudentPayment?> getPaymentDetails({
    required String paymentId,
    required String studentRecordId,
  }) async {
    if (!AppSupabase.isInitialized) {
      throw StateError('Supabase is not initialized.');
    }
    if (paymentId.isEmpty || studentRecordId.isEmpty) return null;

    try {
      try {
        final List<dynamic> rows = await _client
            .from('payments')
            .select('*, students(student_id)')
            .eq('id', paymentId)
            .eq('student_id', studentRecordId)
            .limit(1)
            .timeout(const Duration(seconds: 8));

        if (rows.isEmpty) return null;
        return StudentPayment.fromJson(rows.first as Map<String, dynamic>);
      } catch (e) {
        developer.log(
          'Joined payment details failed, fallback: $e',
          name: 'SupabasePaymentsRepository',
        );
        final List<dynamic> rows = await _client
            .from('payments')
            .select('*')
            .eq('id', paymentId)
            .eq('student_id', studentRecordId)
            .limit(1)
            .timeout(const Duration(seconds: 8));

        if (rows.isEmpty) return null;
        return StudentPayment.fromJson(rows.first as Map<String, dynamic>);
      }
    } catch (e, stack) {
      developer.log(
        'Error fetching payment details for $paymentId: $e',
        name: 'SupabasePaymentsRepository',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }
}

