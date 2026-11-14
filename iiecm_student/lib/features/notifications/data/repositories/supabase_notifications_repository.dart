import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/network/supabase_client.dart';
import '../../../auth/domain/models/auth_exception.dart';
import '../../domain/models/student_notification.dart';
import '../../domain/repositories/notifications_repository.dart';

/// Concrete Supabase repository for notifications
class SupabaseNotificationsRepository implements NotificationsRepository {
  sb.SupabaseClient get _client => AppSupabase.client;

  @override
  Future<List<StudentNotification>> getStudentNotifications({
    required String userId,
  }) async {
    if (!AppSupabase.isInitialized) {
      throw const UnconfiguredAuthException();
    }

    if (userId.trim().isEmpty) {
      return [];
    }

    try {
      // Query notifications targeted specifically to this student OR system-wide broadcasts (user_id IS NULL)
      final List<dynamic> response = await _client
          .from('notifications')
          .select('*')
          .or('user_id.eq.$userId,user_id.is.null')
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 15));

      return response
          .map((item) => StudentNotification.fromMap(item as Map<String, dynamic>))
          .toList();
    } on sb.PostgrestException catch (e) {
      developer.log(
        'Supabase PostgrestException fetching notifications: ${e.message}',
        name: 'SupabaseNotificationsRepository',
        error: e,
      );
      throw GenericAuthException('Could not retrieve notifications: ${e.message}');
    } catch (e, stack) {
      developer.log(
        'Error fetching notifications: $e',
        name: 'SupabaseNotificationsRepository',
        error: e,
        stackTrace: stack,
      );
      if (e is SocketException || e is TimeoutException) {
        throw const AuthNetworkException(
          'Network connection timeout. Please check your internet connection.',
        );
      }
      throw GenericAuthException(e.toString());
    }
  }

  @override
  Future<void> markAsRead({
    required String notificationId,
    required String userId,
  }) async {
    if (!AppSupabase.isInitialized || notificationId.trim().isEmpty) {
      return;
    }

    try {
      // Only personal notifications (user_id = auth.uid()) can be updated by the student under RLS.
      // Broadcast notifications (user_id IS NULL) cannot be written by students; they are tracked in local state.
      await _client
          .from('notifications')
          .update({'read': true})
          .eq('id', notificationId)
          .eq('user_id', userId)
          .timeout(const Duration(seconds: 10));
    } on sb.PostgrestException catch (e) {
      developer.log(
        'PostgrestException marking notification read: ${e.message}',
        name: 'SupabaseNotificationsRepository',
        error: e,
      );
      // Suppress RLS failure for broadcasts so UI flow is never broken
    } catch (e) {
      developer.log(
        'Error marking notification as read: $e',
        name: 'SupabaseNotificationsRepository',
        error: e,
      );
    }
  }

  @override
  Future<void> markAllAsRead({
    required String userId,
  }) async {
    if (!AppSupabase.isInitialized || userId.trim().isEmpty) {
      return;
    }

    try {
      await _client
          .from('notifications')
          .update({'read': true})
          .eq('user_id', userId)
          .eq('read', false)
          .timeout(const Duration(seconds: 10));
    } on sb.PostgrestException catch (e) {
      developer.log(
        'PostgrestException marking all notifications read: ${e.message}',
        name: 'SupabaseNotificationsRepository',
        error: e,
      );
    } catch (e) {
      developer.log(
        'Error marking all notifications as read: $e',
        name: 'SupabaseNotificationsRepository',
        error: e,
      );
    }
  }
}

