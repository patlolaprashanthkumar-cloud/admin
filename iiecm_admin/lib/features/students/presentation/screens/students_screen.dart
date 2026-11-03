import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../domain/models/student.dart';
import '../providers/students_provider.dart';

class StudentsScreen extends ConsumerWidget {
  const StudentsScreen({super.key});

  Color _parseHex(String hex) {
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return AppColors.primaryForest;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(studentsNotifierProvider);
    final notifier = ref.read(studentsNotifierProvider.notifier);
    final categoriesState = ref.watch(categoryNotifierProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      appBar: AppBar(
        title: const Text('Students & Admissions'),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.warmCream,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => notifier.loadStudents(),
          ),
          FilledButton.icon(
            onPressed: () => context.push('/students/add'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryForest,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            icon: const Icon(Icons.person_add_rounded, size: 18),
            label: const Text('Add Student'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: ResponsiveLayout(
          child: RefreshIndicator(
            onRefresh: () => notifier.loadStudents(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Search and Filters Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search bar
                        TextField(
                          onChanged: notifier.setSearchQuery,
                          decoration: InputDecoration(
                            hintText: 'Search by name, student ID, email, or stream...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: state.searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear_rounded,
                                      size: 18,
                                    ),
                                    onPressed: () =>
                                        notifier.setSearchQuery(''),
                                  )
                                : null,
                            filled: true,
                            fillColor: isDark
                                ? AppColors.darkSurface
                                : Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppConstants.radiusMedium,
                              ),
                              borderSide: BorderSide(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : AppColors.borderNeutral,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Dynamic Multi-Category Filter Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              FilterChip(
                                label: const Text('All Categories'),
                                selected: state.selectedCategoryId == 'all',
                                onSelected: (_) =>
                                    notifier.setSelectedCategory('all'),
                              ),
                              const SizedBox(width: 8),
                              ...categoriesState.categories.map((cat) {
                                final isSelected =
                                    state.selectedCategoryId == cat.id;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    avatar: Icon(
                                      Icons.category_rounded,
                                      size: 14,
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.primaryForest,
                                    ),
                                    label: Text(cat.name),
                                    selected: isSelected,
                                    onSelected: (_) =>
                                        notifier.setSelectedCategory(
                                          isSelected ? 'all' : cat.id,
                                        ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Error State
                if (state.errorMessage != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusMedium,
                          ),
                        ),
                        child: Text(
                          state.errorMessage!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Loading
                if (state.isLoading && state.students.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryForest,
                      ),
                    ),
                  )
                // Empty State
                else if (state.filteredStudents.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: const BoxDecoration(
                                color: AppColors.forestSoft,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.people_alt_rounded,
                                size: 40,
                                color: AppColors.primaryForest,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              state.searchQuery.isNotEmpty
                                  ? 'No students matching filter'
                                  : 'No student candidates enrolled',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Register new student admissions and assign multiple academic categories.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              onPressed: () => context.push('/students/add'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primaryForest,
                              ),
                              icon: const Icon(Icons.person_add_rounded),
                              label: const Text('Add Student'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                // Students List
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final student = state.filteredStudents[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _StudentCard(
                            student: student,
                            parseHex: _parseHex,
                            onTap: () =>
                                context.push('/students/${student.id}'),
                          ),
                        );
                      }, childCount: state.filteredStudents.length),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final Student student;
  final Color Function(String hex) parseHex;
  final VoidCallback onTap;

  const _StudentCard({
    required this.student,
    required this.parseHex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.forestSoft,
                  child: Text(
                    student.fullName.isNotEmpty
                        ? student.fullName.substring(0, 1)
                        : 'S',
                    style: const TextStyle(
                      color: AppColors.primaryForest,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              student.fullName,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: student.accountStatus == 'active'
                                  ? AppColors.forestSoft
                                  : Colors.grey.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              student.accountStatus,
                              style: TextStyle(
                                color: student.accountStatus == 'active'
                                    ? AppColors.primaryForest
                                    : AppColors.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${student.studentId} · ${student.qualification} · ${student.educationLevel}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${student.email} · ${student.phone}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Multi-Category Badges
            Row(
              children: [
                const Icon(
                  Icons.school_rounded,
                  size: 14,
                  color: AppColors.primaryForest,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: student.assignedCategories.isEmpty
                      ? Text(
                          'Category: ${student.preferredCategory}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: student.assignedCategories.map((c) {
                            final col = parseHex(c.color);
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: col.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                c.name,
                                style: TextStyle(
                                  color: col,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                ),
                Text(
                  '${student.enrolledCourseIds.length} Courses',
                  style: const TextStyle(
                    color: AppColors.accentTerracotta,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
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
