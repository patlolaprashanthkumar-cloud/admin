import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../core/widgets/stat_kpi_card.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../domain/models/faculty.dart';
import '../providers/faculty_provider.dart';
import '../widgets/add_edit_faculty_sheet.dart';

class FacultyScreen extends ConsumerStatefulWidget {
  const FacultyScreen({super.key});

  @override
  ConsumerState<FacultyScreen> createState() => _FacultyScreenState();
}

class _FacultyScreenState extends ConsumerState<FacultyScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showStatusDialog(Faculty faculty) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Update Status: ${faculty.fullName}'),
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
                    .read(facultyNotifierProvider.notifier)
                    .updateStatus(faculty.id, 'active');
              },
            ),
            ListTile(
              title: const Text('Suspended'),
              leading: const Icon(
                Icons.pause_circle_outline,
                color: Colors.orange,
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                ref
                    .read(facultyNotifierProvider.notifier)
                    .updateStatus(faculty.id, 'suspended');
              },
            ),
            ListTile(
              title: const Text('Inactive'),
              leading: const Icon(
                Icons.cancel_outlined,
                color: AppColors.error,
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                ref
                    .read(facultyNotifierProvider.notifier)
                    .updateStatus(faculty.id, 'inactive');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Faculty faculty) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Faculty Member?'),
        content: Text(
          'Are you sure you want to remove ${faculty.fullName}? This will unassign any courses mapped to this instructor.',
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
                  .read(facultyNotifierProvider.notifier)
                  .deleteFaculty(faculty.id);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(facultyNotifierProvider);
    final notifier = ref.read(facultyNotifierProvider.notifier);
    final categoriesState = ref.watch(categoryNotifierProvider);

    final totalCount = state.facultyList.length;
    final activeCount = state.facultyList.where((f) => f.isActive).length;
    final totalClasses = state.facultyList.fold<int>(
      0,
      (sum, f) => sum + f.totalClasses,
    );
    final avgRating = totalCount > 0
        ? state.facultyList.fold<double>(0.0, (sum, f) => sum + f.rating) /
              totalCount
        : 0.0;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      appBar: AppBar(
        title: const Text('Faculty & Instructors'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => notifier.loadFaculty(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryForest,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Faculty'),
        onPressed: () => AddEditFacultySheet.show(context),
      ),
      body: SafeArea(
        child: ResponsiveLayout(
          child: RefreshIndicator(
            onRefresh: () => notifier.loadFaculty(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. KPI Telemetry Metrics
                        Row(
                          children: [
                            Expanded(
                              child: StatKpiCard(
                                label: 'Total Faculty',
                                value: '$totalCount',
                                icon: Icons.school_rounded,
                                accentColor: AppColors.primaryForest,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StatKpiCard(
                                label: 'Active Faculty',
                                value: '$activeCount',
                                icon: Icons.check_circle_rounded,
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
                                label: 'Avg Rating',
                                value: avgRating > 0
                                    ? avgRating.toStringAsFixed(1)
                                    : '5.0',
                                icon: Icons.star_rounded,
                                accentColor: Colors.amber,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StatKpiCard(
                                label: 'Total Classes',
                                value: '$totalClasses',
                                icon: Icons.video_camera_front_rounded,
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
                            hintText: 'Search faculty by name, specialization, email...',
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
                                'Suspended',
                                'suspended',
                                state.selectedStatus,
                                (s) {
                                  notifier.setStatusFilter(s);
                                },
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                'Inactive',
                                'inactive',
                                state.selectedStatus,
                                (s) {
                                  notifier.setStatusFilter(s);
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        // 4. Category Filter Chips
                        if (categoriesState.categories.isNotEmpty)
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildFilterChip(
                                  'All Categories',
                                  'all',
                                  state.selectedCategoryId,
                                  (c) {
                                    notifier.setCategoryFilter(c);
                                  },
                                ),
                                ...categoriesState.categories.map((c) {
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: _buildFilterChip(
                                      c.name,
                                      c.id,
                                      state.selectedCategoryId,
                                      (id) {
                                        notifier.setCategoryFilter(id);
                                      },
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

                // 5. Faculty Cards List
                if (state.isLoading && state.facultyList.isEmpty)
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
                else if (state.filteredFaculty.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_search_rounded,
                            size: 56,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No faculty found',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Try adjusting your search query or filters',
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
                      itemCount: state.filteredFaculty.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final faculty = state.filteredFaculty[index];
                        final isActive = faculty.isActive;

                        return AppCard(
                          padding: const EdgeInsets.all(16),
                          child: InkWell(
                            onTap: () => context.push('/faculty/${faculty.id}'),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: AppColors.primaryForest
                                          .withValues(alpha: 0.15),
                                      child: Text(
                                        faculty.fullName.isNotEmpty
                                            ? faculty.fullName
                                                  .substring(0, 1)
                                                  .toUpperCase()
                                            : 'F',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primaryForest,
                                        ),
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
                                                  faculty.fullName,
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
                                                  color: isActive
                                                      ? AppColors.forestSoft
                                                      : AppColors.error
                                                            .withValues(
                                                              alpha: 0.1,
                                                            ),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  faculty.accountStatus
                                                      .toUpperCase(),
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w800,
                                                    color: isActive
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
                                            '${faculty.specialization} • ${faculty.qualifications}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.accentTerracotta,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.work_history_outlined,
                                                size: 13,
                                                color: AppColors.textSecondary,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${faculty.experienceYears} yrs exp',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              const Icon(
                                                Icons.star_rounded,
                                                size: 14,
                                                color: Colors.amber,
                                              ),
                                              const SizedBox(width: 2),
                                              Text(
                                                faculty.rating.toStringAsFixed(
                                                  1,
                                                ),
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
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
                                          case 'profile':
                                            context.push(
                                              '/faculty/${faculty.id}',
                                            );
                                            break;
                                          case 'edit':
                                            AddEditFacultySheet.show(
                                              context,
                                              faculty: faculty,
                                            );
                                            break;
                                          case 'status':
                                            _showStatusDialog(faculty);
                                            break;
                                          case 'delete':
                                            _confirmDelete(faculty);
                                            break;
                                        }
                                      },
                                      itemBuilder: (ctx) => [
                                        const PopupMenuItem(
                                          value: 'profile',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.person_outline_rounded,
                                                size: 18,
                                              ),
                                              SizedBox(width: 8),
                                              Text('View Profile'),
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
                                              Text('Edit Faculty'),
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
                                                'Remove Faculty',
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
                                const SizedBox(height: 10),

                                // Contact & Category tags
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.email_outlined,
                                      size: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        faculty.email,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.phone_outlined,
                                      size: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      faculty.phone,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),

                                if (faculty.assignedCategories.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: faculty.assignedCategories
                                        .take(3)
                                        .map((c) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.forestSoft,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              c.name,
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
