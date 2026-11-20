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
///
/// Follows the IIECM Modern Academic design language with institutional branding,
/// structured overview metadata, instructions viewer, submission history,
/// interactive submission form, and faculty evaluation presentation.
class AssignmentDetailScreen extends ConsumerStatefulWidget {
  final String assignmentId;

  const AssignmentDetailScreen({super.key, required this.assignmentId});

  @override
  ConsumerState<AssignmentDetailScreen> createState() =>
      _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState
    extends ConsumerState<AssignmentDetailScreen> {
  final _submissionController = TextEditingController();
  final _attachmentUrlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _formInitialized = false;

  @override
  void dispose() {
    _submissionController.dispose();
    _attachmentUrlController.dispose();
    super.dispose();
  }

  void _syncInitialFormValues(StudentAssignment assignment) {
    if (!_formInitialized && assignment.isSubmitted) {
      if (assignment.submissionNotes != null &&
          assignment.submissionNotes!.isNotEmpty &&
          _submissionController.text.isEmpty) {
        _submissionController.text = assignment.submissionNotes!;
      }
      _formInitialized = true;
    }
  }

  void _showSubmitConfirmation(AssignmentDetailNotifier notifier) {
    if (!_formKey.currentState!.validate()) return;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark
            ? AppColors.darkSurface
            : AppColors.backgroundWarmOffWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          side: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceElevated
                    : AppColors.forestSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.upload_file_rounded,
                color: AppColors.primaryNavy,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Submit Assignment?',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to submit your clinical deliverable? You can update your submission before faculty evaluation.',
          style: TextStyle(
            fontSize: 13,
            height: 1.45,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: TextButton.styleFrom(
              foregroundColor: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryNavy,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusMd),
              ),
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
                        Icon(
                          Icons.check_circle_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
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
            child: const Text(
              'Confirm & Submit',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
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
    final notifier = ref.read(
      assignmentDetailProvider(widget.assignmentId).notifier,
    );

    final assignment = state.assignment;
    if (assignment != null) {
      _syncInitialFormValues(assignment);
    }

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.backgroundWarmOffWhite,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.darkSurface
            : AppColors.backgroundWarmOffWhite,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              assignment?.title ?? 'Assignment Details',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            Text(
              assignment?.courseTitle ?? 'Clinical Deliverable Dossier',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            onPressed: () => notifier.refresh(),
          ),
          const SizedBox(width: AppConstants.spacingSm),
        ],
      ),
      body: state.isLoading && assignment == null
          ? _buildLoadingState(isDark)
          : state.hasError && assignment == null
          ? _buildErrorState(
              context,
              state.errorMessage,
              notifier,
              isDark,
              theme,
            )
          : assignment == null
          ? _buildNotFoundState(context, isDark, theme)
          : RefreshIndicator(
              color: AppColors.primaryForest,
              onRefresh: () => notifier.refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
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
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryNavy),
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Text(
            'Loading assignment details...',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
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
          borderRadius: AppConstants.radiusLg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.error.withValues(alpha: 0.15)
                      : AppColors.errorSoft,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.error,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingMd),
              Text(
                'Unable to Load Assignment',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                errorMessage ?? 'A network or server error occurred.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppConstants.spacingMd + 4),
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

  Widget _buildNotFoundState(
    BuildContext context,
    bool isDark,
    ThemeData theme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: AppCard(
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          borderRadius: AppConstants.radiusLg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceElevated
                      : AppColors.forestSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: 28,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: AppConstants.spacingMd),
              Text(
                'Assignment Not Found',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'This assignment could not be located or you are not enrolled in its course.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                  height: 1.4,
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

    final statusColor = _getStatusColor(assignment);
    final statusBgColor = _getStatusBackgroundColor(assignment, isDark);
    final statusBorderColor = _getStatusBorderColor(assignment, isDark);

    return AppCard(
      padding: const EdgeInsets.all(AppConstants.spacingMd + 2),
      borderRadius: AppConstants.radiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course Taxonomy Badges & Status Pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceElevated
                            : AppColors.forestSoft,
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusSm,
                        ),
                        border: Border.all(
                          color: AppColors.primaryNavy.withValues(
                            alpha: isDark ? 0.25 : 0.12,
                          ),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        assignment.courseTitle.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: isDark
                              ? AppColors.accentOrangeLight
                              : AppColors.primaryNavy,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkBackground
                            : (assignment.isProject
                                  ? AppColors.accentOrangeSoft
                                  : AppColors.warmCream),
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusSm,
                        ),
                        border: Border.all(
                          color: assignment.isProject
                              ? AppColors.accentOrange.withValues(
                                  alpha: isDark ? 0.35 : 0.25,
                                )
                              : (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.border),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        assignment.isProject
                            ? 'CLINICAL PROJECT'
                            : assignment.type.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          color: assignment.isProject
                              ? AppColors.terracotta
                              : (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                  border: Border.all(color: statusBorderColor, width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getStatusIcon(assignment),
                      size: 11.5,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4.5),
                    Text(
                      assignment.displayStatus,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingSm + 4),

          // Assignment Title
          Text(
            assignment.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 17.5,
              color: isDark ? Colors.white : AppColors.textPrimary,
              height: 1.25,
            ),
          ),
          const SizedBox(height: AppConstants.spacingMd),

          Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
          ),
          const SizedBox(height: AppConstants.spacingSm + 4),

          // Deadline Information
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                assignment.isOverdue
                    ? Icons.alarm_off_rounded
                    : Icons.event_available_outlined,
                size: 14.5,
                color: assignment.isOverdue
                    ? AppColors.error
                    : AppColors.terracotta,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Deadline: $deadlineFormatted',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: assignment.isOverdue
                        ? AppColors.error
                        : AppColors.terracotta,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Marks Criteria Information
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.workspace_premium_outlined,
                size: 14.5,
                color: isDark
                    ? AppColors.accentOrangeLight
                    : AppColors.primaryNavy,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Total Marks: ${assignment.totalMarks}   •   Passing Criteria: ${assignment.passingMarks} Marks',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.primaryNavy,
                  ),
                ),
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
      padding: const EdgeInsets.all(AppConstants.spacingMd + 2),
      borderRadius: AppConstants.radiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceElevated
                      : AppColors.forestSoft,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  size: 16,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Instructions & Case Deliverables',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingSm + 4),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkBackground
                  : AppColors.warmCreamLight,
              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
                width: 0.8,
              ),
            ),
            child: Text(
              assignment.description.isNotEmpty ? assignment.description : 'Follow clinical case study guidelines provided during emergency department ward rounds. Prepare your findings and submit your case synthesis below.',
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                fontSize: 13,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
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
        ? DateFormat('EEEE, d MMMM yyyy • h:mm a')
              .format(assignment.submittedAt!)
        : 'Submitted';

    return AppCard(
      padding: const EdgeInsets.all(AppConstants.spacingMd + 2),
      borderRadius: AppConstants.radiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: assignment.isGraded
                      ? (assignment.isPassed == true
                            ? (isDark
                                  ? AppColors.success.withValues(alpha: 0.15)
                                  : AppColors.successSoft)
                            : (isDark
                                  ? AppColors.error.withValues(alpha: 0.15)
                                  : AppColors.errorSoft))
                      : (isDark
                            ? AppColors.info.withValues(alpha: 0.15)
                            : AppColors.infoSoft),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  assignment.isGraded
                      ? Icons.verified_rounded
                      : Icons.pending_actions_rounded,
                  size: 16,
                  color: assignment.isGraded
                      ? (assignment.isPassed == true
                            ? AppColors.success
                            : AppColors.error)
                      : AppColors.info,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                assignment.isGraded ? 'Evaluation Result' : 'Submission Status',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: assignment.isGraded
                      ? (assignment.isPassed == true
                            ? (isDark
                                  ? AppColors.success.withValues(alpha: 0.15)
                                  : AppColors.successSoft)
                            : (isDark
                                  ? AppColors.error.withValues(alpha: 0.15)
                                  : AppColors.errorSoft))
                      : (isDark
                            ? AppColors.info.withValues(alpha: 0.15)
                            : AppColors.infoSoft),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                  border: Border.all(
                    color: assignment.isGraded
                        ? (assignment.isPassed == true
                              ? AppColors.success.withValues(alpha: 0.3)
                              : AppColors.error.withValues(alpha: 0.3))
                        : AppColors.info.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  assignment.isGraded
                      ? (assignment.isPassed == true
                            ? 'PASSED'
                            : 'NEEDS REVISION')
                      : 'PENDING REVIEW',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: assignment.isGraded
                        ? (assignment.isPassed == true
                              ? (isDark
                                    ? const Color(0xFF6EE7B7)
                                    : AppColors.success)
                              : (isDark
                                    ? const Color(0xFFFCA5A5)
                                    : AppColors.error))
                        : (isDark
                              ? AppColors.accentOrangeLight
                              : AppColors.info),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingSm + 2),

          Text(
            'Submitted on $submittedFormatted',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),

          // Graded Evaluation Score Details
          if (assignment.isGraded) ...[
            const SizedBox(height: AppConstants.spacingMd),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceElevated
                    : AppColors.warmCreamLight,
                borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
                  width: 0.8,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Score Awarded:',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${assignment.score?.toStringAsFixed(1) ?? "0"} / ${assignment.totalMarks} (${assignment.percentage?.toStringAsFixed(0) ?? "0"}%)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: assignment.isPassed == true
                              ? (isDark
                                    ? const Color(0xFF6EE7B7)
                                    : AppColors.success)
                              : (isDark
                                    ? const Color(0xFFFCA5A5)
                                    : AppColors.error),
                        ),
                      ),
                    ],
                  ),
                  if (assignment.feedback != null &&
                      assignment.feedback!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Divider(
                      height: 1,
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.borderSubtle,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Faculty Feedback:',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.accentOrangeLight
                            : AppColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      assignment.feedback!,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontStyle: FontStyle.italic,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // Submitted Solution Notes Box
          if (assignment.submissionNotes != null &&
              assignment.submissionNotes!.isNotEmpty) ...[
            const SizedBox(height: AppConstants.spacingMd),
            Text(
              'Your Submitted Solution:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBackground : AppColors.warmCream,
                borderRadius: BorderRadius.circular(AppConstants.radiusSm + 2),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                  width: 0.8,
                ),
              ),
              child: Text(
                assignment.submissionNotes!,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.45,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
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
      padding: const EdgeInsets.all(AppConstants.spacingMd + 2),
      borderRadius: AppConstants.radiusLg,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceElevated
                        : AppColors.forestSoft,
                    borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                  ),
                  child: const Icon(
                    Icons.drive_file_rename_outline_rounded,
                    size: 16,
                    color: AppColors.primaryNavy,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  assignment.isSubmitted
                      ? 'Update Submission'
                      : 'Submit Clinical Deliverable',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingSm),

            Text(
              assignment.isSubmitted
                  ? 'You can revise your case response before final faculty evaluation:'
                  : 'Provide your clinical case summary, discussion, and solutions below:',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppConstants.spacingMd),

            TextFormField(
              controller: _submissionController,
              maxLines: 6,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please write your case response or findings before submitting.';
                }
                return null;
              },
              decoration: InputDecoration(
                hintText: 'Enter clinical observations, patient care analysis, or assignment write-up...',
                hintStyle: TextStyle(
                  fontSize: 12.5,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textMuted,
                ),
                filled: true,
                fillColor: isDark
                    ? AppColors.darkSurfaceElevated
                    : AppColors.white,
                contentPadding: const EdgeInsets.all(14),
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
                    color: AppColors.primaryNavy,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spacingMd),

            TextFormField(
              controller: _attachmentUrlController,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                labelText: 'External Document Link / Reference (Optional)',
                labelStyle: TextStyle(
                  fontSize: 12.5,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
                hintText:
                    'e.g. Google Drive, hospital protocol link, or PDF URL',
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textMuted,
                ),
                prefixIcon: Icon(
                  Icons.link_rounded,
                  size: 20,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.primaryNavy,
                ),
                filled: true,
                fillColor: isDark
                    ? AppColors.darkSurfaceElevated
                    : AppColors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
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
                    color: AppColors.primaryNavy,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spacingLg),

            AppButton(
              label: assignment.isSubmitted
                  ? 'Update Submission'
                  : 'Submit Assignment',
              icon: Icons.check_circle_outline_rounded,
              isLoading: state.isSubmitting,
              onPressed: () => _showSubmitConfirmation(notifier),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(StudentAssignment assignment) {
    if (assignment.isGraded) {
      return assignment.isPassed == true ? AppColors.success : AppColors.error;
    }
    if (assignment.isSubmitted) {
      return AppColors.info;
    }
    if (assignment.isOverdue) {
      return AppColors.error;
    }
    return AppColors.warning;
  }

  Color _getStatusBackgroundColor(StudentAssignment assignment, bool isDark) {
    if (assignment.isGraded) {
      return assignment.isPassed == true
          ? (isDark
                ? AppColors.success.withValues(alpha: 0.15)
                : AppColors.successSoft)
          : (isDark
                ? AppColors.error.withValues(alpha: 0.15)
                : AppColors.errorSoft);
    }
    if (assignment.isSubmitted) {
      return isDark
          ? AppColors.info.withValues(alpha: 0.18)
          : AppColors.infoSoft;
    }
    if (assignment.isOverdue) {
      return isDark
          ? AppColors.error.withValues(alpha: 0.15)
          : AppColors.errorSoft;
    }
    return isDark
        ? AppColors.warning.withValues(alpha: 0.15)
        : AppColors.warningSoft;
  }

  Color _getStatusBorderColor(StudentAssignment assignment, bool isDark) {
    final baseColor = _getStatusColor(assignment);
    return baseColor.withValues(alpha: isDark ? 0.35 : 0.25);
  }

  IconData _getStatusIcon(StudentAssignment assignment) {
    if (assignment.isGraded) {
      return assignment.isPassed == true
          ? Icons.check_circle_rounded
          : Icons.warning_amber_rounded;
    }
    if (assignment.isSubmitted) {
      return Icons.task_alt_rounded;
    }
    if (assignment.isOverdue) {
      return Icons.error_outline_rounded;
    }
    return Icons.pending_actions_rounded;
  }
}
