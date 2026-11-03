import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../core/widgets/stat_kpi_card.dart';
import '../providers/assessment_provider.dart';

class AssessmentMonitoringScreen extends ConsumerWidget {
  final String assessmentId;

  const AssessmentMonitoringScreen({super.key, required this.assessmentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final assessmentAsync = ref.watch(assessmentDetailProvider(assessmentId));
    final resultsAsync = ref.watch(assessmentResultsProvider(assessmentId));

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      appBar: AppBar(
        title: const Text('Exam Monitoring & Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(assessmentResultsProvider(assessmentId));
              ref.invalidate(assessmentDetailProvider(assessmentId));
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveLayout(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(assessmentResultsProvider(assessmentId));
              ref.invalidate(assessmentDetailProvider(assessmentId));
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: [
                // 1. Assessment Header
                assessmentAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (assessment) {
                    if (assessment == null) return const SizedBox.shrink();

                    return AppCard(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryForest.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  assessment.type.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryForest,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Pass Mark: ${assessment.passingMarks} / ${assessment.totalMarks}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.terracotta,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            assessment.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // 2. Metrics Telemetry Cards
                resultsAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(
                        color: AppColors.primaryForest,
                      ),
                    ),
                  ),
                  error: (err, _) => Center(child: Text('Error: $err')),
                  data: (results) {
                    final total = results.length;
                    final passed = results.where((r) => r.passed).length;
                    final passRate = total > 0
                        ? ((passed / total) * 100).toStringAsFixed(1)
                        : '0.0';
                    final avgScore = total > 0
                        ? (results.fold<double>(
                                    0.0,
                                    (s, r) => s + r.percentage,
                                  ) /
                                  total)
                              .toStringAsFixed(1)
                        : '0.0';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: StatKpiCard(
                                label: 'Candidates',
                                value: '$total',
                                icon: Icons.groups_rounded,
                                accentColor: AppColors.primaryForest,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StatKpiCard(
                                label: 'Candidates Passed',
                                value: '$passed',
                                icon: Icons.check_circle_outline_rounded,
                                accentColor: AppColors.primaryForest,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: StatKpiCard(
                                label: 'Pass Rate',
                                value: '$passRate%',
                                icon: Icons.insights_rounded,
                                accentColor: AppColors.accentTerracotta,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StatKpiCard(
                                label: 'Average Score',
                                value: '$avgScore%',
                                icon: Icons.trending_up_rounded,
                                accentColor: Colors.blueAccent,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Attempts List
                        Text(
                          'Candidate Results & Scores',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),

                        if (results.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurface
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(
                                AppConstants.radiusMedium,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.assignment_late_outlined,
                                  size: 48,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'No exam attempts recorded yet',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'When candidates complete the exam, scores and pass/fail analytics will appear here.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: results.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final res = results[index];
                              final isPassed = res.passed;

                              return AppCard(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: isPassed
                                          ? AppColors.primaryForest.withValues(
                                              alpha: 0.15,
                                            )
                                          : AppColors.error.withValues(
                                              alpha: 0.1,
                                            ),
                                      child: Icon(
                                        isPassed
                                            ? Icons.check_circle_outline
                                            : Icons.cancel_outlined,
                                        color: isPassed
                                            ? AppColors.primaryForest
                                            : AppColors.error,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            res.studentName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Completed on ${DateFormatter.formatDateTime(res.completedAt)}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDark
                                                  ? AppColors.darkTextSecondary
                                                  : AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${res.score.toStringAsFixed(1)} / ${res.totalMarks.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          '${res.percentage.toStringAsFixed(1)}% • ${isPassed ? 'PASS' : 'FAIL'}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: isPassed
                                                ? AppColors.primaryForest
                                                : AppColors.error,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                        const SizedBox(height: 40),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
