import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/supabase_profile_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import 'profile_state.dart';

/// Provider exposing the ProfileRepository abstraction
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return SupabaseProfileRepository();
});

/// StateNotifierProvider managing profile editing and password updates
final profileNotifierProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final repo = ref.watch(profileRepositoryProvider);
  return ProfileNotifier(repo, ref);
});

class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileRepository _repository;
  final Ref _ref;

  ProfileNotifier(this._repository, this._ref) : super(const ProfileState());

  /// Updates student's personal contact details
  Future<bool> updateProfile({
    required String fullName,
    required String phone,
    String? qualification,
    String? educationLevel,
    String? preferredCategory,
    String? city,
  }) async {
    final authState = _ref.read(authNotifierProvider);
    final student = authState.student;

    if (student == null) {
      state = state.copyWith(
        updateStatus: ProfileActionStatus.error,
        errorMessage: 'No active student session found.',
      );
      return false;
    }

    state = state.copyWith(
      updateStatus: ProfileActionStatus.loading,
      clearMessages: true,
    );

    try {
      final updated = await _repository.updateProfile(
        userId: student.userId,
        studentRecordId: student.studentRecordId,
        fullName: fullName,
        phone: phone,
        qualification: qualification,
        educationLevel: educationLevel,
        preferredCategory: preferredCategory,
        city: city,
      );

      // Propagate updated profile into the app's global AuthState
      _ref.read(authNotifierProvider.notifier).updateStudentProfile(updated);

      state = state.copyWith(
        updateStatus: ProfileActionStatus.success,
        successMessage: 'Profile information updated successfully.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        updateStatus: ProfileActionStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Changes the student's password securely via Supabase Auth
  Future<bool> changePassword({required String newPassword}) async {
    state = state.copyWith(
      passwordStatus: ProfileActionStatus.loading,
      clearMessages: true,
    );

    try {
      await _repository.changePassword(newPassword: newPassword);
      state = state.copyWith(
        passwordStatus: ProfileActionStatus.success,
        successMessage: 'Password updated successfully.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        passwordStatus: ProfileActionStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(clearMessages: true);
  }
}

