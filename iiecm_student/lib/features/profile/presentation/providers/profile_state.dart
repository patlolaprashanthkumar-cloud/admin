enum ProfileActionStatus { idle, loading, success, error }

class ProfileState {
  final ProfileActionStatus updateStatus;
  final ProfileActionStatus passwordStatus;
  final String? errorMessage;
  final String? successMessage;

  const ProfileState({
    this.updateStatus = ProfileActionStatus.idle,
    this.passwordStatus = ProfileActionStatus.idle,
    this.errorMessage,
    this.successMessage,
  });

  bool get isUpdating => updateStatus == ProfileActionStatus.loading;
  bool get isChangingPassword => passwordStatus == ProfileActionStatus.loading;
  bool get isPasswordUpdating => isChangingPassword;

  ProfileState copyWith({
    ProfileActionStatus? updateStatus,
    ProfileActionStatus? passwordStatus,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return ProfileState(
      updateStatus: updateStatus ?? this.updateStatus,
      passwordStatus: passwordStatus ?? this.passwordStatus,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }
}
