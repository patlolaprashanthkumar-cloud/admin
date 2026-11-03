import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../core/widgets/stat_kpi_card.dart';
import '../../domain/models/assessment.dart';
import '../providers/assessment_provider.dart';
import '../widgets/create_assessment_sheet.dart';

class AssessmentsScreen extends ConsumerStatefulWidget {
  const AssessmentsScreen({super.key});

  @override
  ConsumerState<AssessmentsScreen> createState() => _AssessmentsScreenState();
}

class _AssessmentsScreenState extends ConsumerState<AssessmentsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showStatusDialog(Assessment assessment) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Update Status: ${assessment.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Active'),
              leading: const Icon(
                Icons.check_circle_outline,
                color: AppColors.primaryForest,
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                ref
                    .read(assessmentNotifierProvider.notifier)
                    .updateStatus(assessment.id, 'active');
              },
            ),
            ListTile(
              title: const Text('Scheduled'),
              leading: const Icon(
                Icons.schedule_rounded,
                color: Colors.blueAccent,
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                ref
                    .read(assessmentNotifierProvider.notifier)
                    .updateStatus(assessment.id, 'scheduled');
              },
            ),
            ListTile(
              title: const Text('Draft'),
              leading: const Icon(
                Icons.edit_note_rounded,
                color: Colors.orange,
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                ref
                    .read(assessmentNotifierProvider.notifier)
                    .updateStatus(assessment.id, 'draft');
              },
            ),
            ListTile(
              title: const Text('Completed'),
              leading: const Icon(Icons.done_all_rounded, color: Colors.grey),
              onTap: () {
                Navigator.of(ctx).pop();
                ref
                    .read(assessmentNotifierProvider.notifier)
                    .updateStatus(assessment.id, 'completed');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Assessment assessment) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Assessment?'),
        content: Text(
          'Are you sure you want to delete "${assessment.title}" and its questions?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref
                  .read(assessmentNotifierProvider.notifier)
                  .deleteAssessment(assessment.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(assessmentNotifierProvider);
    final notifier = ref.read(assessmentNotifierProvider.notifier);

    final totalCount = state.assessments.length;
    final activeCount = state.assessments.where((a) => a.isActive).length;
    final totalAttempts = state.assessments.fold<int>(
      0,
      (sum, a) => sum + a.totalAttempts,
    );
    final totalQuestions = state.assessments.fold<int>(
      0,
      (sum, a) => sum + a.questionCount,
    );

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      appBar: AppBar(
        title: const Text('Course Assessments & Exams'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => notifier.loadAssessments(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryForest,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.post_add_rounded),
        label: const Text('New Assessment'),
        onPressed: () => CreateAssessmentSheet.show(context),
      ),
      body: SafeArea(
        child: ResponsiveLayout(
          child: RefreshIndicator(
            onRefresh: () => notifier.loadAssessments(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. KPI Telemetry
                        Row(
                          children: [
                            Expanded(
                              child: StatKpiCard(
                                label: 'Total Exams',
                                value: '$totalCount',
                                icon: Icons.quiz_outlined,
                                accentColor: AppColors.primaryForest,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StatKpiCard(
                                label: 'Active Now',
                                value: '$activeCount',
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
                                label: 'Total Attempts',
                                value: '$totalAttempts',
                                icon: Icons.groups_rounded,
                                accentColor: Colors.blueAccent,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StatKpiCard(
                                label: 'Question Pool',
                                value: '$totalQuestions',
                                icon: Icons.help_outline_rounded,
                                accentColor: AppColors.accentTerracotta,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // 2. Search Field
                        TextField(
                          controller: _searchController,
                          onChanged: (val) => notifier.setSearchQuery(val),
                          decoration: InputDecoration(
                            hintText: 'Search exams by title or topic...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded),
                                    onPressed: () {
                                      _searchController.clear();
                                      notifier.setSearchQuery('');
                                    },
                                  )
                                : null,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // 3. Status Filters
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip(
                                'All Status',
                                'all',
                                state.selectedStatus,
                                (s) {
                                  notifier.setStatusFilter(s);
                                },
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                'Active',
                                'active',
                                state.selectedStatus,
                                (s) {
                                  notifier.setStatusFilter(s);
                                },
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                'Scheduled',
                                'scheduled',
                                state.selectedStatus,
                                (s) {
                                  notifier.setStatusFilter(s);
                                },
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                'Draft',
                                'draft',
                                state.selectedStatus,
                                (s) {
                                  notifier.setStatusFilter(s);
                                },
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                'Completed',
                                'completed',
                                state.selectedStatus,
                                (s) {
                                  notifier.setStatusFilter(s);
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        // 4. Type Filters (Horizontal Scrollable)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip(
                                'All Formats',
                                'all',
                                state.selectedType,
                                (t) {
                                  notifier.setTypeFilter(t);
                                },
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                'MCQ Exams',
                                'mcq',
                                state.selectedType,
                                (t) {
                                  notifier.setTypeFilter(t);
                                },
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                'Quizzes',
                                'quiz',
                                state.selectedType,
                                (t) {
                                  notifier.setTypeFilter(t);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 5. Assessments List
                if (state.isLoading && state.assessments.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(
                          color: AppColors.primaryForest,
                        ),
                      ),
                    ),
                  )
                else if (state.filteredAssessments.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.rule_folder_rounded,
                            size: 56,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No assessments found',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Create an assessment to build question banks and schedule exams',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: SliverList.separated(
                      itemCount: state.filteredAssessments.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final a = state.filteredAssessments[index];

                        return AppCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryForest.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.quiz_rounded,
                                      color: AppColors.primaryForest,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                a.title,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 7,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: a.isActive
                                                    ? AppColors.forestSoft
                                                    : AppColors.error
                                                          .withValues(
                                                            alpha: 0.1,
                                                          ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                a.status.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w800,
                                                  color: a.isActive
                                                      ? AppColors.primaryForest
                                                      : AppColors.error,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${a.type.toUpperCase()} • ${a.durationMinutes} Mins • Max: ${a.totalMarks} (Pass: ${a.passingMarks})',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.accentTerracotta,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: const Icon(
                                      Icons.more_vert_rounded,
                                      size: 20,
                                    ),
                                    onSelected: (val) {
                                      switch (val) {
                                        case 'questions':
                                          context.push(
                                            '/assessments/${a.id}/questions',
                                          );
                                          break;
                                        case 'analytics':
                                          context.push(
                                            '/assessments/${a.id}/results',
                                          );
                                          break;
                                        case 'edit':
                                          CreateAssessmentSheet.show(
                                            context,
                                            existingAssessment: a,
                                          );
                                          break;
                                        case 'status':
                                          _showStatusDialog(a);
                                          break;
                                        case 'delete':
                                          _confirmDelete(a);
                                          break;
                                      }
                                    },
                                    itemBuilder: (ctx) => [
                                      const PopupMenuItem(
                                        value: 'questions',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons
                                                  .format_list_numbered_rounded,
                                              size: 18,
                                            ),
                                            SizedBox(width: 8),
                                            Text('Manage Questions'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'analytics',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.analytics_outlined,
                                              size: 18,
                                            ),
                                            SizedBox(width: 8),
                                            Text('Attempts & Analytics'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit_outlined, size: 18),
                                            SizedBox(width: 8),
                                            Text('Edit Assessment'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'status',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.toggle_on_outlined,
                                              size: 18,
                                            ),
                                            SizedBox(width: 8),
                                            Text('Change Status'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.delete_outline_rounded,
                                              size: 18,
                                              color: AppColors.error,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Delete Exam',
                                              style: TextStyle(
                                                color: AppColors.error,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 8),

                              Row(
                                children: [
                                  Text(
                                    '${a.questionCount} Questions Configured',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${a.totalAttempts} Attempts',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const Spacer(),
                                  OutlinedButton.icon(
                                    onPressed: () => context.push(
                                      '/assessments/${a.id}/questions',
                                    ),
                                    icon: const Icon(
                                      Icons.help_outline_rounded,
                                      size: 14,
                                    ),
                                    label: const Text(
                                      'Questions',
                                      style: TextStyle(fontSize: 11),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  OutlinedButton.icon(
                                    onPressed: () => context.push(
                                      '/assessments/${a.id}/results',
                                    ),
                                    icon: const Icon(
                                      Icons.insights_rounded,
                                      size: 14,
                                    ),
                                    label: const Text(
                                      'Analytics',
                                      style: TextStyle(fontSize: 11),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                ],
                              ),

                              if (a.scheduledAt != null) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.alarm_rounded,
                                      size: 13,
                                      color: AppColors.accentTerracotta,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Scheduled for ${DateFormatter.formatDateTime(a.scheduledAt!)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.accentTerracotta,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
    String selectedValue,
    ValueChanged<String> onSelected,
  ) {
    final isSelected = value == selectedValue;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(value),
      selectedColor: AppColors.primaryForest.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? AppColors.primaryForest : AppColors.textSecondary,
      ),
    );
  }
}
