import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../core/widgets/stat_kpi_card.dart';
import '../../domain/models/assignment.dart';
import '../providers/assignment_provider.dart';
import '../widgets/create_assignment_sheet.dart';

class AssignmentsScreen extends ConsumerStatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  ConsumerState<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends ConsumerState<AssignmentsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showStatusDialog(Assignment assignment) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Update Status: ${assignment.title}'),
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
                    .read(assignmentNotifierProvider.notifier)
                    .updateStatus(assignment.id, 'active');
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
                    .read(assignmentNotifierProvider.notifier)
                    .updateStatus(assignment.id, 'scheduled');
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
                    .read(assignmentNotifierProvider.notifier)
                    .updateStatus(assignment.id, 'draft');
              },
            ),
            ListTile(
              title: const Text('Completed'),
              leading: const Icon(Icons.done_all_rounded, color: Colors.grey),
              onTap: () {
                Navigator.of(ctx).pop();
                ref
                    .read(assignmentNotifierProvider.notifier)
                    .updateStatus(assignment.id, 'completed');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Assignment assignment) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Assignment?'),
        content: Text(
          'Are you sure you want to delete "${assignment.title}"? This cannot be undone.',
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
                  .read(assignmentNotifierProvider.notifier)
                  .deleteAssignment(assignment.id);
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
    final state = ref.watch(assignmentNotifierProvider);
    final notifier = ref.read(assignmentNotifierProvider.notifier);

    final totalAssignments = state.assignments.length;
    final activeCount = state.assignments.where((a) => a.isActive).length;
    final totalSubmissions = state.assignments.fold<int>(
      0,
      (sum, a) => sum + a.totalSubmissions,
    );
    final gradedSubmissions = state.assignments.fold<int>(
      0,
      (sum, a) => sum + a.gradedSubmissions,
    );

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      appBar: AppBar(
        title: const Text('Assignments & Projects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => notifier.loadAssignments(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryForest,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('New Assignment'),
        onPressed: () => CreateAssignmentSheet.show(context),
      ),
      body: SafeArea(
        child: ResponsiveLayout(
          child: RefreshIndicator(
            onRefresh: () => notifier.loadAssignments(),
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
                                label: 'Total Tasks',
                                value: '$totalAssignments',
                                icon: Icons.assignment_outlined,
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
                                label: 'Submissions',
                                value: '$totalSubmissions',
                                icon: Icons.send_rounded,
                                accentColor: Colors.blueAccent,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StatKpiCard(
                                label: 'Evaluated',
                                value: '$gradedSubmissions',
                                icon: Icons.grade_rounded,
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
                            hintText: 'Search assignments by title, description, course...',
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
                                'All Types',
                                'all',
                                state.selectedType,
                                (t) {
                                  notifier.setTypeFilter(t);
                                },
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                'Assignments',
                                'assignment',
                                state.selectedType,
                                (t) {
                                  notifier.setTypeFilter(t);
                                },
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                'Clinical Projects',
                                'project',
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

                // 5. Assignments List
                if (state.isLoading && state.assignments.isEmpty)
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
                else if (state.filteredAssignments.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.task_alt_rounded,
                            size: 56,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No assignments found',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Create an assignment or adjust filters to get started',
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
                      itemCount: state.filteredAssignments.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final assignment = state.filteredAssignments[index];

                        return AppCard(
                          padding: const EdgeInsets.all(16),
                          child: InkWell(
                            onTap: () =>
                                context.push('/assignments/${assignment.id}'),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryForest
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        assignment.type == 'project'
                                            ? Icons.assessment_outlined
                                            : Icons.assignment_outlined,
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
                                                  assignment.title,
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
                                                  color: assignment.isActive
                                                      ? AppColors.forestSoft
                                                      : AppColors.error
                                                            .withValues(
                                                              alpha: 0.1,
                                                            ),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  assignment.status
                                                      .toUpperCase(),
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w800,
                                                    color: assignment.isActive
                                                        ? AppColors
                                                              .primaryForest
                                                        : AppColors.error,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${assignment.type.toUpperCase()} • Max: ${assignment.totalMarks} Marks (Pass: ${assignment.passingMarks})',
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
                                          case 'details':
                                            context.push(
                                              '/assignments/${assignment.id}',
                                            );
                                            break;
                                          case 'edit':
                                            CreateAssignmentSheet.show(
                                              context,
                                              existingAssignment: assignment,
                                            );
                                            break;
                                          case 'status':
                                            _showStatusDialog(assignment);
                                            break;
                                          case 'delete':
                                            _confirmDelete(assignment);
                                            break;
                                        }
                                      },
                                      itemBuilder: (ctx) => [
                                        const PopupMenuItem(
                                          value: 'details',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.remove_red_eye_outlined,
                                                size: 18,
                                              ),
                                              SizedBox(width: 8),
                                              Text('Submissions & Evaluation'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.edit_outlined,
                                                size: 18,
                                              ),
                                              SizedBox(width: 8),
                                              Text('Edit Assignment'),
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
                                                'Delete Task',
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

                                // Submissions progress bar & deadline
                                Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.how_to_reg_rounded,
                                            size: 14,
                                            color: AppColors.textSecondary,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              '${assignment.totalSubmissions} Submitted • ${assignment.gradedSubmissions} Graded',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (assignment.deadline != null) ...[
                                      const SizedBox(width: 8),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.alarm_rounded,
                                            size: 14,
                                            color: AppColors.accentTerracotta,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            DateFormatter.formatDate(
                                              assignment.deadline!,
                                            ),
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

                                if (assignment.assignedCourses.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: assignment.assignedCourses
                                        .take(2)
                                        .map((c) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.forestSoft,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              c.title,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.primaryForest,
                                              ),
                                            ),
                                          );
                                        })
                                        .toList(),
                                  ),
                                ],
                              ],
                            ),
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
