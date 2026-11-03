import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/responsive_layout.dart';

class MoreHubsScreen extends StatelessWidget {
  const MoreHubsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      appBar: AppBar(
        title: const Text('Operational Suites'),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.warmCream,
      ),
      body: SafeArea(
        child: ResponsiveLayout(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Central Curriculum Categories Management Suite
                _buildSuiteCard(
                  context,
                  title: 'Course Categories',
                  description: 'Institutional taxonomy, academic subject streams & curriculum organization',
                  icon: Icons.category_rounded,
                  route: '/categories',
                  theme: theme,
                  isDark: isDark,
                  buttonLabel: 'Manage Categories',
                  buttonIcon: Icons.list_alt_rounded,
                ),
                const SizedBox(height: 16),

                // 2. Faculty & Instructors Directory Suite
                _buildSuiteCard(
                  context,
                  title: 'Faculty & Instructors',
                  description: 'Academic staff directory, teaching certifications, workload & course assignments',
                  icon: Icons.school_rounded,
                  route: '/faculty',
                  theme: theme,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),

                // 3. Class Scheduling & Timetable Suite
                _buildSuiteCard(
                  context,
                  title: 'Class Scheduling & Timetable',
                  description: 'Live interactive class scheduling, conflict overlap detection & broadcast alerts',
                  icon: Icons.calendar_month_rounded,
                  route: '/classes',
                  theme: theme,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),

                // 4. Assignments & Case Studies Suite
                _buildSuiteCard(
                  context,
                  title: 'Assignments & Case Studies',
                  description: 'Clinical deliverable prompts, student submissions tracking & grading workflow',
                  icon: Icons.assignment_outlined,
                  route: '/assignments',
                  theme: theme,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),

                // 5. Assessments & Question Bank Suite
                _buildSuiteCard(
                  context,
                  title: 'Assessments & Question Bank',
                  description: 'MCQ exams, modular quizzes, question bank builder & score analytics',
                  icon: Icons.quiz_outlined,
                  route: '/assessments',
                  theme: theme,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),

                // 6. Fee Reconciliation & Payments Suite
                _buildSuiteCard(
                  context,
                  title: 'Fee Payments & Invoices',
                  description: 'Financial ledger, transaction receipts, bank UTR verification, refund audits & reports',
                  icon: Icons.payments_rounded,
                  route: '/payments',
                  theme: theme,
                  isDark: isDark,
                  buttonLabel: 'Open Financial Suite',
                  buttonIcon: Icons.receipt_long_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuiteCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required String route,
    required ThemeData theme,
    required bool isDark,
    String? buttonLabel,
    IconData? buttonIcon,
  }) {
    return AppCard(
      child: InkWell(
        onTap: () => context.push(route),
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryForest.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primaryForest, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.forestSoft,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Active Feature',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryForest,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(route),
                    icon: Icon(
                      buttonIcon ?? Icons.open_in_new_rounded,
                      size: 16,
                    ),
                    label: Text(buttonLabel ?? 'Open $title'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
