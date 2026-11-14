import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/models/student_assignment.dart';
import '../providers/assignments_provider.dart';
import '../providers/assignments_state.dart';

/// Full assignment detail and student deliverable submission screen
class AssignmentDetailScreen extends ConsumerStatefulWidget {
  final String assignmentId;

  const AssignmentDetailScreen({
    super.key,
    required this.assignmentId,
  });

  @override
  ConsumerState<AssignmentDetailScreen> createState() =>
      _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState
    extends ConsumerState<AssignmentDetailScreen> {
  final _submissionController = TextEditingController();
  final _attachmentUrlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _submissionController.dispose();
    _attachmentUrlController.dispose();
    super.dispose();
  }

  void _showSubmitConfirmation(
    AssignmentDetailNotifier notifier,
  ) {
    if (!_formKey.currentState!.validate()) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.upload_file_rounded, color: AppColors.primaryForest),
            SizedBox(width: 8),
            Text('Submit Assignment?'),
          ],
        ),
        content: const Text(
          'Are you sure you want to submit your clinical deliverable? You can update your submission before faculty evaluation.',
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
              Navigator.of(ctx).pop();
              final success = await notifier.submitDeliverable(
                submissionText: _submissionController.text,
                attachmentUrl: _attachmentUrlController.text.trim().isNotEmpty
                    ? _attachmentUrlController.text.trim()
                    : null,
              );

              if (!mounted) return;

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text('Assignment submitted successfully'),
                      ],
                    ),
                    backgroundColor: AppColors.primaryForest,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to submit assignment. Please retry.'),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Confirm & Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(assignmentDetailProvider(widget.assignmentId));
    final notifier =
        ref.read(assignmentDetailProvider(widget.assignmentId).notifier);

    final assignment = state.assignment;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          assignment?.title ?? 'Assignment Details',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => notifier.refresh(),
          ),
          const SizedBox(width: AppConstants.spacingSm),
        ],
      ),
      body: state.isLoading && assignment == null
          ? _buildLoadingState(isDark)
          : state.hasError && assignment == null
              ? _buildErrorState(context, state.errorMessage, notifier, isDark, theme)
              : assignment == null
                  ? _buildNotFoundState(context, isDark, theme)
                  : RefreshIndicator(
                      color: AppColors.primaryForest,
                      onRefresh: () => notifier.refresh(),
                      child: ListView(
                        padding: const EdgeInsets.all(AppConstants.spacingMd),
                        children: [
                          // 1. Header Overview Card
                          _buildHeaderCard(assignment, isDark, theme),
                          const SizedBox(height: AppConstants.spacingMd),

                          // 2. Instructions & Deliverables Card
                          _buildInstructionsCard(assignment, isDark, theme),
                          const SizedBox(height: AppConstants.spacingMd),

                          // 3. Existing Submission & Evaluation Card (if submitted)
                          if (assignment.isSubmitted) ...[
                            _buildEvaluationCard(assignment, isDark, theme),
                            const SizedBox(height: AppConstants.spacingMd),
                          ],

                          // 4. Submission Form (if not graded yet)
                          if (!assignment.isGraded)
                            _buildSubmissionFormCard(
                              context,
                              assignment,
                              state,
                              notifier,
                              isDark,
                              theme,
                            ),

                          const SizedBox(height: AppConstants.spacingXl),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryForest),
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Text(
            'Loading assignment details...',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    String? errorMessage,
    AssignmentDetailNotifier notifier,
    bool isDark,
    ThemeData theme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: AppCard(
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 44),
              const SizedBox(height: AppConstants.spacingSm),
              Text(
                'Unable to Load Assignment',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                errorMessage ?? 'A network or server error occurred.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppConstants.spacingMd),
              AppButton(
                label: 'Retry Connection',
                icon: Icons.refresh_rounded,
                isFullWidth: false,
                height: 38,
                onPressed: () => notifier.refresh(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotFoundState(BuildContext context, bool isDark, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: isDark ? AppColors.darkTextSecondary : AppColors.textMuted),
            const SizedBox(height: AppConstants.spacingMd),
            Text(
              'Assignment Not Found',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'This assignment could not be located or you are not enrolled in its course.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppConstants.spacingLg),
            AppButton(
              label: 'Back to Assignments',
              icon: Icons.arrow_back_rounded,
              isFullWidth: false,
              height: 38,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(
    StudentAssignment assignment,
    bool isDark,
    ThemeData theme,
  ) {
    final deadlineFormatted = assignment.deadline != null
        ? DateFormat('EEEE, d MMMM yyyy • h:mm a').format(assignment.deadline!)
        : 'Open Submission (No strict deadline)';

    return AppCard(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceElevated : AppColors.forestSoft,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                ),
                child: Text(
                  assignment.courseTitle.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryForest,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBackground : AppColors.warmCream,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                ),
                child: Text(
                  assignment.type.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: assignment.isSubmitted
                      ? AppColors.successSoft
                      : (assignment.isOverdue ? AppColors.errorSoft : AppColors.warningSoft),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                ),
                child: Text(
                  assignment.displayStatus,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: assignment.isSubmitted
                        ? AppColors.success
                        : (assignment.isOverdue ? AppColors.error : AppColors.warning),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingSm),

          Text(
            assignment.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              height: 1.25,
            ),
          ),
          const SizedBox(height: AppConstants.spacingMd),

          const Divider(height: 1),
          const SizedBox(height: AppConstants.spacingSm),

          Row(
            children: [
              Icon(
                Icons.alarm_rounded,
                size: 14,
                color: assignment.isOverdue ? AppColors.error : AppColors.terracotta,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Deadline: $deadlineFormatted',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: assignment.isOverdue ? AppColors.error : AppColors.terracotta,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          Row(
            children: [
              const Icon(Icons.grade_outlined, size: 14, color: AppColors.primaryForest),
              const SizedBox(width: 6),
              Text(
                'Total Marks: ${assignment.totalMarks}   •   Passing Criteria: ${assignment.passingMarks} Marks',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard(
    StudentAssignment assignment,
    bool isDark,
    ThemeData theme,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description_outlined, size: 18, color: AppColors.primaryForest),
              const SizedBox(width: 8),
              Text(
                'Instructions & Case Deliverables',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            assignment.description.isNotEmpty
                ? assignment.description
                : 'Follow clinical case study guidelines provided during emergency department ward rounds. Prepare your findings and submit your case synthesis below.',
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.45,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvaluationCard(
    StudentAssignment assignment,
    bool isDark,
    ThemeData theme,
  ) {
    final submittedFormatted = assignment.submittedAt != null
        ? DateFormat('EEEE, d MMMM yyyy • h:mm a').format(assignment.submittedAt!)
        : 'Submitted';

    return AppCard(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                assignment.isGraded ? Icons.verified_rounded : Icons.pending_actions_rounded,
                size: 18,
                color: assignment.isGraded
                    ? (assignment.isPassed == true ? AppColors.success : AppColors.error)
                    : AppColors.info,
              ),
              const SizedBox(width: 8),
              Text(
                assignment.isGraded ? 'Evaluation Result' : 'Submission Status',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: assignment.isGraded
                      ? (assignment.isPassed == true ? AppColors.successSoft : AppColors.errorSoft)
                      : AppColors.infoSoft,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                ),
                child: Text(
                  assignment.isGraded
                      ? (assignment.isPassed == true ? 'PASSED' : 'NEEDS REVISION')
                      : 'PENDING REVIEW',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: assignment.isGraded
                        ? (assignment.isPassed == true ? AppColors.success : AppColors.error)
                        : AppColors.info,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingSm),

          Text(
            'Submitted on $submittedFormatted',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),

          if (assignment.isGraded) ...[
            const SizedBox(height: AppConstants.spacingMd),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : AppColors.warmCreamLight,
                borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Score Awarded:',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      Text(
                        '${assignment.score?.toStringAsFixed(1) ?? "0"} / ${assignment.totalMarks} (${assignment.percentage?.toStringAsFixed(0) ?? "0"}%)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: assignment.isPassed == true ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                  if (assignment.feedback != null && assignment.feedback!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 6),
                    Text(
                      'Faculty Feedback:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      assignment.feedback!,
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          if (assignment.submissionNotes != null && assignment.submissionNotes!.isNotEmpty) ...[
            const SizedBox(height: AppConstants.spacingMd),
            Text(
              'Your Submitted Solution:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBackground : AppColors.warmCream,
                borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                ),
              ),
              child: Text(
                assignment.submissionNotes!,
                style: const TextStyle(fontSize: 12, height: 1.4),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmissionFormCard(
    BuildContext context,
    StudentAssignment assignment,
    AssignmentDetailState state,
    AssignmentDetailNotifier notifier,
    bool isDark,
    ThemeData theme,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.drive_file_rename_outline_rounded,
                    size: 18, color: AppColors.primaryForest),
                const SizedBox(width: 8),
                Text(
                  assignment.isSubmitted ? 'Update Submission' : 'Submit Clinical Deliverable',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingSm),

            Text(
              'Provide your clinical case summary, discussion, and solutions below:',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppConstants.spacingMd),

            TextFormField(
              controller: _submissionController,
              maxLines: 5,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please write your case response or findings before submitting.';
                }
                return null;
              },
              decoration: InputDecoration(
                hintText: 'Enter clinical observations, patient care analysis, or assignment write-up...',
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textMuted,
                ),
                filled: true,
                fillColor: isDark ? AppColors.darkSurfaceElevated : AppColors.white,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                  borderSide: const BorderSide(
                    color: AppColors.primaryForest,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spacingMd),

            TextFormField(
              controller: _attachmentUrlController,
              decoration: InputDecoration(
                labelText: 'External Document Link / Reference (Optional)',
                hintText: 'e.g. Google Drive, hospital protocol link, or PDF URL',
                prefixIcon: const Icon(Icons.link_rounded, size: 20),
                filled: true,
                fillColor: isDark ? AppColors.darkSurfaceElevated : AppColors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                  borderSide: const BorderSide(
                    color: AppColors.primaryForest,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spacingLg),

            AppButton(
              label: assignment.isSubmitted ? 'Update Submission' : 'Submit Assignment',
              icon: Icons.check_circle_outline_rounded,
              isLoading: state.isSubmitting,
              onPressed: () => _showSubmitConfirmation(notifier),
            ),
          ],
        ),
      ),
    );
  }
}

