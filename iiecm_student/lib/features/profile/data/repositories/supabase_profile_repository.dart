import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/network/supabase_client.dart';
import '../../../auth/data/repositories/supabase_auth_repository.dart';
import '../../../auth/domain/models/auth_exception.dart';
import '../../../auth/domain/models/student_profile.dart';
import '../../domain/repositories/profile_repository.dart';

/// Concrete Supabase implementation of ProfileRepository
class SupabaseProfileRepository implements ProfileRepository {
  sb.SupabaseClient get _client => AppSupabase.client;

  @override
  Future<StudentProfile> updateProfile({
    required String userId,
    required String studentRecordId,
    required String fullName,
    required String phone,
    String? qualification,
    String? educationLevel,
    String? preferredCategory,
    String? city,
  }) async {
    if (!AppSupabase.isInitialized) {
      throw const UnconfiguredAuthException();
    }
    if (userId.isEmpty || studentRecordId.isEmpty) {
      throw const GenericAuthException('Missing user or student identifier.');
    }

    try {
      final trimmedName = fullName.trim();
      final trimmedPhone = phone.trim();

      // 1. Update public.profiles personal fields (allowed under RLS: id = auth.uid())
      final profilePayload = <String, dynamic>{
        'full_name': trimmedName,
        'phone': trimmedPhone,
      };

      await _client
          .from('profiles')
          .update(profilePayload)
          .eq('id', userId)
          .timeout(const Duration(seconds: 10));

      // 2. Update public.students personal contact details (allowed under RLS: profile_id = auth.uid())
      final studentPayload = <String, dynamic>{
        'full_name': trimmedName,
        'phone': trimmedPhone,
        if (qualification != null) 'qualification': qualification.trim(),
        if (educationLevel != null) 'education_level': educationLevel.trim(),
        if (preferredCategory != null) 'preferred_category': preferredCategory.trim(),
        if (city != null) 'city': city.trim(),
      };

      await _client
          .from('students')
          .update(studentPayload)
          .eq('id', studentRecordId)
          .timeout(const Duration(seconds: 10));

      // 3. Return updated authoritative StudentProfile
      final authRepo = SupabaseAuthRepository();
      return await authRepo.fetchAuthoritativeStudentProfile(userId: userId);
    } on sb.PostgrestException catch (e) {
      developer.log(
        'Database error during profile update: ${e.message}',
        name: 'SupabaseProfileRepository',
        error: e,
      );
      throw GenericAuthException(e.message);
    } catch (e, stack) {
      developer.log(
        'Error updating student profile: $e',
        name: 'SupabaseProfileRepository',
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
  Future<void> changePassword({
    required String newPassword,
  }) async {
    if (!AppSupabase.isInitialized) {
      throw const UnconfiguredAuthException();
    }
    if (newPassword.trim().length < 6) {
      throw const GenericAuthException(
        'Password must be at least 6 characters long.',
      );
    }

    try {
      await _client.auth
          .updateUser(
            sb.UserAttributes(password: newPassword.trim()),
          )
          .timeout(const Duration(seconds: 15));
    } on sb.AuthException catch (e) {
      developer.log(
        'Auth error during password change: ${e.message}',
        name: 'SupabaseProfileRepository',
        error: e,
      );
      throw GenericAuthException(e.message);
    } catch (e, stack) {
      developer.log(
        'Error changing password: $e',
        name: 'SupabaseProfileRepository',
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
}

