import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../domain/models/assignment_submission.dart';
import '../providers/assignment_provider.dart';
import '../widgets/create_assignment_sheet.dart';

class AssignmentDetailScreen extends ConsumerStatefulWidget {
  final String assignmentId;

  const AssignmentDetailScreen({super.key, required this.assignmentId});

  @override
  ConsumerState<AssignmentDetailScreen> createState() =>
      _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState
    extends ConsumerState<AssignmentDetailScreen> {
  void _openGradingDialog(AssignmentSubmission submission, int totalMarks) {
    final scoreController = TextEditingController(
      text: submission.score > 0 ? submission.score.toString() : '',
    );
    final feedbackController = TextEditingController(
      text: submission.feedback ?? '',
    );
    bool passed = submission.passed;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Grade: ${submission.studentName}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Maximum Marks: $totalMarks',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: scoreController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Score Awarded *',
                    hintText: 'e.g. 85.5',
                    prefixIcon: Icon(Icons.grade_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Pass Status',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    passed
                        ? 'Candidate Passed'
                        : 'Candidate Failed / Needs Revision',
                    style: TextStyle(
                      fontSize: 11,
                      color: passed ? AppColors.primaryForest : AppColors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  value: passed,
                  activeThumbColor: AppColors.primaryForest,
                  onChanged: (val) => setDialogState(() => passed = val),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: feedbackController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Faculty Feedback / Notes',
                    hintText: 'Provide clinical critique and observations...',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryForest,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final score = double.tryParse(scoreController.text.trim());
                final messenger = ScaffoldMessenger.of(context);
                if (score == null) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid numeric score'),
                    ),
                  );
                  return;
                }

                Navigator.of(ctx).pop();
                try {
                  final repo = ref.read(assignmentRepositoryProvider);
                  await repo.gradeSubmission(
                    submissionId: submission.id,
                    score: score,
                    totalMarks: totalMarks.toDouble(),
                    passed: passed,
                    feedback: feedbackController.text.trim().isNotEmpty
                        ? feedbackController.text.trim()
                        : null,
                  );

                  ref.invalidate(
                    assignmentSubmissionsProvider(widget.assignmentId),
                  );
                  ref.invalidate(assignmentDetailProvider(widget.assignmentId));

                  if (mounted) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Submission graded successfully'),
                        backgroundColor: AppColors.primaryForest,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              child: const Text('Save Grade'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final assignmentAsync = ref.watch(
      assignmentDetailProvider(widget.assignmentId),
    );
    final submissionsAsync = ref.watch(
      assignmentSubmissionsProvider(widget.assignmentId),
    );

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      appBar: AppBar(
        title: const Text('Assignment Evaluation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Assignment',
            onPressed: () {
              assignmentAsync.whenData((assignment) {
                if (assignment != null) {
                  CreateAssignmentSheet.show(
                    context,
                    existingAssignment: assignment,
                  ).then((updated) {
                    if (updated == true) {
                      ref.invalidate(
                        assignmentDetailProvider(widget.assignmentId),
                      );
                      ref
                          .read(assignmentNotifierProvider.notifier)
                          .loadAssignments();
                    }
                  });
                }
              });
            },
          ),
        ],
      ),
      body: assignmentAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryForest),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: AppColors.error,
                ),
                const SizedBox(height: 12),
                Text(
                  'Failed to load assignment: $err',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(
                    assignmentDetailProvider(widget.assignmentId),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (assignment) {
          if (assignment == null) {
            return const Center(child: Text('Assignment not found.'));
          }

          return ResponsiveLayout(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Overview Card
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryForest.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                assignment.type.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryForest,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: assignment.isActive
                                    ? AppColors.forestSoft
                                    : AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                assignment.status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: assignment.isActive
                                      ? AppColors.primaryForest
                                      : AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          assignment.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Score & Passing Metrics
                        Row(
                          children: [
                            _buildInfoChip(
                              Icons.grade_outlined,
                              'Total: ${assignment.totalMarks} Marks',
                            ),
                            const SizedBox(width: 8),
                            _buildInfoChip(
                              Icons.check_circle_outline,
                              'Pass: ${assignment.passingMarks} Marks',
                            ),
                          ],
                        ),

                        if (assignment.deadline != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.alarm_rounded,
                                size: 14,
                                color: AppColors.terracotta,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Due: ${DateFormatter.formatDateTime(assignment.deadline!)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.terracotta,
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 12),

                        // Description
                        Text(
                          'Instructions / Deliverables:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          assignment.description.isNotEmpty
                              ? assignment.description
                              : 'No specific instructions specified.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2. Assigned Courses
                  Text(
                    'Cohort Course Allocations',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (assignment.assignedCourses.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurface
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusMedium,
                        ),
                      ),
                      child: const Text(
                        'No specific courses linked to this assignment.',
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: assignment.assignedCourses.map((c) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.forestSoft,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.primaryForest.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.school_rounded,
                                size: 14,
                                color: AppColors.primaryForest,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                c.title,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryForest,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 24),

                  // 3. Submissions Header & List
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Student Submissions & Evaluation',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text(
                          'Refresh',
                          style: TextStyle(fontSize: 12),
                        ),
                        onPressed: () => ref.invalidate(
                          assignmentSubmissionsProvider(widget.assignmentId),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  submissionsAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(
                          color: AppColors.primaryForest,
                        ),
                      ),
                    ),
                    error: (err, _) =>
                        Center(child: Text('Error loading submissions: $err')),
                    data: (submissions) {
                      if (submissions.isEmpty) {
                        return Container(
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
                                Icons.assignment_turned_in_outlined,
                                size: 48,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'No submissions received yet',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'When candidates submit deliverables, they will appear here for grading.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: submissions.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final sub = submissions[index];
                          final isGraded = sub.isGraded;

                          return AppCard(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: AppColors.primaryForest
                                          .withValues(alpha: 0.15),
                                      child: Text(
                                        sub.studentName.isNotEmpty
                                            ? sub.studentName[0].toUpperCase()
                                            : 'S',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primaryForest,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            sub.studentName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            'Submitted ${DateFormatter.formatDateTime(sub.completedAt)}',
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
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isGraded
                                            ? (sub.passed
                                                  ? AppColors.forestSoft
                                                  : AppColors.error.withValues(
                                                      alpha: 0.1,
                                                    ))
                                            : Colors.amber.withValues(
                                                alpha: 0.15,
                                              ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        isGraded
                                            ? (sub.passed
                                                  ? 'PASSED'
                                                  : 'NEEDS REVISION')
                                            : 'PENDING REVIEW',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: isGraded
                                              ? (sub.passed
                                                    ? AppColors.primaryForest
                                                    : AppColors.error)
                                              : Colors.amber.shade900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),
                                const Divider(height: 1),
                                const SizedBox(height: 8),

                                Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.grade_rounded,
                                            size: 16,
                                            color: Colors.amber,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            isGraded
                                                ? 'Score: ${sub.score.toStringAsFixed(1)} / ${sub.totalMarks.toStringAsFixed(0)} (${sub.percentage.toStringAsFixed(0)}%)'
                                                : 'Unrated',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () => _openGradingDialog(
                                        sub,
                                        assignment.totalMarks,
                                      ),
                                      icon: const Icon(
                                        Icons.rate_review_outlined,
                                        size: 14,
                                      ),
                                      label: Text(
                                        isGraded
                                            ? 'Update Grade'
                                            : 'Grade Deliverable',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            AppColors.primaryForest,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                  ],
                                ),

                                if (sub.feedback != null &&
                                    sub.feedback!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.darkSurface
                                          : AppColors.warmCream,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Feedback: ${sub.feedback}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.forestSoft,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primaryForest),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryForest,
            ),
          ),
        ],
      ),
    );
  }
}
