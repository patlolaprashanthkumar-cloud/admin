import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/supabase_dashboard_repository.dart';
import '../../domain/models/dashboard_stats.dart';
import '../../domain/repositories/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return SupabaseDashboardRepository();
});

final dashboardStatsProvider = FutureProvider.autoDispose<DashboardStats>((ref) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  return repository.getDashboardStats();
});

