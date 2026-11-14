import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../domain/models/student_dashboard_data.dart';

/// Modal dialog displaying authoritative details and teleconference access for a live class
class LiveClassDetailDialog extends StatelessWidget {
  final LiveClassItem session;

  const LiveClassDetailDialog({super.key, required this.session});

  /// Presents the [LiveClassDetailDialog] modally
  static Future<void> show(
    BuildContext context, {
    required LiveClassItem session,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => LiveClassDetailDialog(session: session),
    );
  }

  void _copyMeetingLink(BuildContext context) {
    final link = session.meetingLink?.trim();
    if (link == null || link.isEmpty) return;

    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Meeting link copied to clipboard. Open in your browser or conferencing app.',
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryForest,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '$minutes mins';
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    if (remaining == 0) return '$hours hr${hours > 1 ? 's' : ''}';
    return '$hours hr${hours > 1 ? 's' : ''} $remaining mins';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasMeetingLink =
        session.meetingLink != null && session.meetingLink!.trim().isNotEmpty;

    final dateFormatted = DateFormat('EEEE, d MMMM yyyy')
        .format(session.scheduledAt);
    final startTime = DateFormat('h:mm a').format(session.scheduledAt);
    final endTime = DateFormat('h:mm a').format(session.endsAt);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
      ),
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 720),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Bar: Category / Stream Tag & Close Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
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
                                color: isDark
                                    ? AppColors.darkSurfaceElevated
                                    : (session.isLive
                                          ? AppColors.errorSoft
                                          : AppColors.forestSoft),
                                borderRadius: BorderRadius.circular(
                                  AppConstants.radiusSm,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    session.isLive
                                        ? Icons.fiber_manual_record_rounded
                                        : Icons.schedule_rounded,
                                    size: 11,
                                    color: session.isLive
                                        ? AppColors.error
                                        : AppColors.primaryForest,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    session.isLive
                                        ? 'LIVE SESSION NOW'
                                        : 'UPCOMING CLINICAL CLASS',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                      color: session.isLive
                                          ? AppColors.error
                                          : AppColors.primaryForest,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          session.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          session.courseName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingMd),

              // Badges Row: Status, Duration & Specialization
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _buildPill(
                    icon: Icons.timer_outlined,
                    label: _formatDuration(session.durationMinutes),
                    color: AppColors.primaryForest,
                    isDark: isDark,
                  ),
                  if (session.specialization != null &&
                      session.specialization!.trim().isNotEmpty)
                    _buildPill(
                      icon: Icons.medical_services_outlined,
                      label: session.specialization!.trim(),
                      color: AppColors.terracotta,
                      isDark: isDark,
                    ),
                  _buildPill(
                    icon: Icons.school_outlined,
                    label: 'Academic Session',
                    color: AppColors.textSecondary,
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingMd),

              const Divider(height: 1),
              const SizedBox(height: AppConstants.spacingMd),

              // Core Teleconference / Class Schedule Box
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingMd),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceElevated
                      : AppColors.warmCreamLight,
                  borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.borderSubtle,
                  ),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      icon: Icons.calendar_today_rounded,
                      label: 'Scheduled Date',
                      value: dateFormatted,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.access_time_rounded,
                      label: 'Time Window',
                      value: '$startTime – $endTime (IST)',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.hourglass_bottom_rounded,
                      label: 'Class Duration',
                      value:
                          '${session.durationMinutes} Minutes (${_formatDuration(session.durationMinutes)})',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.person_outline_rounded,
                      label: 'Faculty Consultant',
                      value: session.instructorName,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.menu_book_outlined,
                      label: 'Curriculum Course',
                      value: session.courseName,
                      isDark: isDark,
                    ),
                    if (session.specialization != null &&
                        session.specialization!.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        icon: Icons.local_hospital_outlined,
                        label: 'Specialization Stream',
                        value: session.specialization!.trim(),
                        isDark: isDark,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.spacingMd),

              // Meeting Access Section
              if (hasMeetingLink) ...[
                Text(
                  'Teleconference / Live Class Link',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBackground : AppColors.white,
                    borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.videocam_rounded,
                        color: AppColors.primaryForest,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          session.meetingLink!.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryForest,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Copy Meeting Link',
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        onPressed: () => _copyMeetingLink(context),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Meeting link pending notice
                Container(
                  padding: const EdgeInsets.all(AppConstants.spacingMd),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceElevated
                        : AppColors.warmCream,
                    borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.warning,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Teleconference Access Link Pending',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'The assigned faculty or institutional coordinator will publish the meeting room link before the class commences. Please check back shortly.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppConstants.spacingLg),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                  if (hasMeetingLink) ...[
                    const SizedBox(width: AppConstants.spacingSm),
                    AppButton(
                      label: 'Open Meeting Link',
                      icon: Icons.open_in_new_rounded,
                      variant: AppButtonVariant.primary,
                      isFullWidth: false,
                      height: 40,
                      onPressed: () => _copyMeetingLink(context),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPill({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
