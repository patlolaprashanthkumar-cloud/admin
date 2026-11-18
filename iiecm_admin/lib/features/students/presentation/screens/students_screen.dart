import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../providers/students_provider.dart';
import '../widgets/student_card.dart';

/// Students & Admissions Screen
///
/// Institutional directory and admissions management for IIECM LEARNING HUB.
/// Displays student rosters, academic category filters, search capabilities,
/// and provides rapid access to new candidate registration.
class StudentsScreen extends ConsumerWidget {
  const StudentsScreen({super.key});

  Color _parseHex(String hex) {
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return AppColors.primaryNavy;
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
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.backgroundWarmOffWhite,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.darkSurface
            : AppColors.backgroundWarmOffWhite,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceContainerLow
                    : AppColors.forestSoft,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryNavy.withValues(alpha: 0.15),
                  width: 1.2,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.people_alt_rounded,
                  color: AppColors.primaryNavy,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Students & Admissions',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!state.isLoading) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryNavy.withValues(
                              alpha: isDark ? 0.3 : 0.08,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${state.filteredStudents.length}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? AppColors.accentOrangeLight
                                  : AppColors.primaryNavy,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    'Institutional Roster · Enrollment Management',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Roster',
            icon: Icon(
              Icons.refresh_rounded,
              color: isDark ? Colors.white : AppColors.primaryNavy,
              size: 22,
            ),
            onPressed: () => notifier.loadStudents(),
          ),
          const SizedBox(width: 4),
          FilledButton.icon(
            onPressed: () => context.push('/students/add'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryNavy,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.person_add_rounded, size: 17),
            label: const Text(
              'Add Student',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          const SizedBox(width: 14),
        ],
      ),
      body: SafeArea(
        child: ResponsiveLayout(
          child: RefreshIndicator(
            color: AppColors.primaryNavy,
            onRefresh: () => notifier.loadStudents(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Search and Filters Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search bar with Modern Academic styling
                        Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.2 : 0.03,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            onChanged: notifier.setSearchQuery,
                            decoration: InputDecoration(
                              hintText: 'Search by name, student ID, email, or stream...',
                              hintStyle: TextStyle(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textMuted,
                                fontSize: 13,
                              ),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: isDark
                                    ? AppColors.accentOrangeLight
                                    : AppColors.primaryNavy,
                                size: 20,
                              ),
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
                                  : AppColors.cardWhite,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.borderNeutral,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.borderNeutral,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.primaryNavy,
                                  width: 1.6,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Dynamic Multi-Category Filter Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              FilterChip(
                                label: const Text('All Categories'),
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: state.selectedCategoryId == 'all'
                                      ? Colors.white
                                      : (isDark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.textPrimary),
                                ),
                                selected: state.selectedCategoryId == 'all',
                                selectedColor: AppColors.primaryNavy,
                                backgroundColor: isDark
                                    ? AppColors.darkSurface
                                    : AppColors.cardWhite,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: state.selectedCategoryId == 'all'
                                        ? AppColors.primaryNavy
                                        : (isDark
                                              ? AppColors.darkBorder
                                              : AppColors.borderNeutral),
                                  ),
                                ),
                                showCheckmark: false,
                                onSelected: (_) =>
                                    notifier.setSelectedCategory('all'),
                              ),
                              const SizedBox(width: 8),
                              ...categoriesState.categories.map((cat) {
                                final isSelected =
                                    state.selectedCategoryId == cat.id;
                                final catColor = _parseHex(cat.color);

                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    avatar: Icon(
                                      Icons.category_rounded,
                                      size: 14,
                                      color: isSelected
                                          ? Colors.white
                                          : catColor,
                                    ),
                                    label: Text(cat.name),
                                    labelStyle: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark
                                                ? AppColors.darkTextPrimary
                                                : AppColors.textPrimary),
                                    ),
                                    selected: isSelected,
                                    selectedColor: catColor,
                                    backgroundColor: isDark
                                        ? AppColors.darkSurface
                                        : AppColors.cardWhite,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: BorderSide(
                                        color: isSelected
                                            ? catColor
                                            : (isDark
                                                  ? AppColors.darkBorder
                                                  : AppColors.borderNeutral),
                                      ),
                                    ),
                                    showCheckmark: false,
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
                          color: AppColors.errorSoft,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.error,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                state.errorMessage!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Loading State
                if (state.isLoading && state.students.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: AppColors.primaryNavy,
                          ),
                          SizedBox(height: 14),
                          Text(
                            'Loading institutional student roster...',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
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
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkSurfaceContainerLow
                                    : AppColors.forestSoft,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primaryNavy.withValues(
                                    alpha: 0.15,
                                  ),
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.people_alt_rounded,
                                size: 32,
                                color: AppColors.primaryNavy,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              state.searchQuery.isNotEmpty
                                  ? 'No students matching filter'
                                  : 'No student candidates enrolled',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 360),
                              child: Text(
                                'Register new student admissions and assign multiple academic categories.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textSecondary,
                                  fontSize: 12.5,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),
                            FilledButton.icon(
                              onPressed: () => context.push('/students/add'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primaryNavy,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                              icon: const Icon(
                                Icons.person_add_rounded,
                                size: 18,
                              ),
                              label: const Text(
                                'Add Student',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
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
                          child: StudentCard(
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
