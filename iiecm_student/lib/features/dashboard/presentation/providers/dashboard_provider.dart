import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/models/student_profile.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/supabase_dashboard_repository.dart';
import '../../domain/repositories/dashboard_repository.dart';
import 'dashboard_state.dart';

/// Provider exposing the DashboardRepository contract
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return SupabaseDashboardRepository();
});

/// Riverpod StateNotifier managing the student dashboard lifecycle
final dashboardNotifierProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final repo = ref.watch(dashboardRepositoryProvider);
  final authState = ref.watch(authNotifierProvider);
  final notifier = DashboardNotifier(repo, authState.student);
  return notifier;
});

class DashboardNotifier extends StateNotifier<DashboardState> {
  final DashboardRepository _repository;
  final StudentProfile? _student;

  DashboardNotifier(this._repository, this._student) : super(const DashboardState.initial()) {
    if (_student != null) {
      loadDashboard();
    }
  }

  /// Loads or reloads dashboard data for the authenticated student
  Future<void> loadDashboard() async {
    if (_student == null) {
      state = const DashboardState.error('No authenticated student session found.');
      return;
    }

    state = DashboardState.loading(data: state.data);

    try {
      final dashboardData = await _repository.getDashboardData(_student);
      state = DashboardState.loaded(dashboardData);
    } catch (e, stack) {
      developer.log(
        'Failed to load student dashboard: $e',
        name: 'DashboardNotifier',
        error: e,
        stackTrace: stack,
      );
      state = DashboardState.error(
        'Unable to load dashboard information. Check connection and retry.',
        data: state.data,
      );
    }
  }

  /// Pull-to-refresh action
  Future<void> refresh() async {
    await loadDashboard();
  }
}

