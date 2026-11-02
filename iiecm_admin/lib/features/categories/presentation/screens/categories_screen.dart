import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../domain/models/course_category.dart';
import '../providers/category_provider.dart';
import '../widgets/category_form_sheet.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

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

  IconData _getIconData(String? iconName) {
    switch (iconName?.toLowerCase()) {
      case 'medical':
        return Icons.medical_services_rounded;
      case 'school':
        return Icons.school_rounded;
      case 'emergency':
        return Icons.emergency_rounded;
      case 'science':
        return Icons.science_rounded;
      case 'psychology':
        return Icons.psychology_rounded;
      case 'analytics':
        return Icons.analytics_rounded;
      case 'terminal':
        return Icons.terminal_rounded;
      case 'biotech':
        return Icons.biotech_rounded;
      case 'health':
        return Icons.health_and_safety_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    CourseCategory category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${category.name}"?'),
        content: Text(
          category.courseCount > 0
              ? 'This category has ${category.courseCount} associated courses. Deleting it will detach the category reference from those courses.'
              : 'Are you sure you want to permanently delete this category?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(categoryNotifierProvider.notifier).deleteCategory(category.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(categoryNotifierProvider);
    final notifier = ref.read(categoryNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      appBar: AppBar(
        title: const Text('Course Categories'),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.warmCream,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => notifier.loadCategories(),
          ),
          FilledButton.icon(
            onPressed: () {
              CategoryFormSheet.show(
                context,
                existingCategories: state.categories,
                onSave: ({
                  required String name,
                  required String description,
                  required String color,
                  String? iconName,
                  bool isActive = true,
                }) async {
                  final ok = await notifier.createCategory(
                    name: name,
                    description: description,
                    color: color,
                    iconName: iconName,
                    isActive: isActive,
                  );
                  if (!ok) {
                    return notifier.errorMessage ?? 'Failed to save category. Ensure name is unique.';
                  }
                  return null;
                },
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryForest,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: ResponsiveLayout(
          child: RefreshIndicator(
            onRefresh: () => notifier.loadCategories(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Search and Filters Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search field
                        TextField(
                          onChanged: notifier.setSearchQuery,
                          decoration: InputDecoration(
                            hintText: 'Search categories...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: state.searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    onPressed: () => notifier.setSearchQuery(''),
                                  )
                                : null,
                            filled: true,
                            fillColor: isDark ? AppColors.darkSurface : Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                              borderSide: BorderSide(
                                color: isDark ? AppColors.darkBorder : AppColors.borderNeutral,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Filter row
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              FilterChip(
                                label: Text('All (${state.categories.length})'),
                                selected: state.statusFilter == 'all',
                                onSelected: (_) => notifier.setStatusFilter('all'),
                              ),
                              const SizedBox(width: 8),
                              FilterChip(
                                label: Text('Active (${state.activeCount})'),
                                selected: state.statusFilter == 'active',
                                onSelected: (_) => notifier.setStatusFilter('active'),
                              ),
                              const SizedBox(width: 8),
                              FilterChip(
                                label: Text(
                                  'Inactive (${state.categories.length - state.activeCount})',
                                ),
                                selected: state.statusFilter == 'inactive',
                                onSelected: (_) => notifier.setStatusFilter('inactive'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Error Banner
                if (state.errorMessage != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                state.errorMessage!,
                                style: const TextStyle(color: AppColors.error, fontSize: 12),
                              ),
                            ),
                            TextButton(
                              onPressed: () => notifier.loadCategories(),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Loading State
                if (state.isLoading && state.categories.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primaryForest),
                    ),
                  )
                // Empty State
                else if (state.filteredCategories.isEmpty)
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
                              decoration: BoxDecoration(
                                color: AppColors.forestSoft,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.category_rounded,
                                size: 40,
                                color: AppColors.primaryForest,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              state.searchQuery.isNotEmpty
                                  ? 'No matching categories found'
                                  : 'No course categories registered',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              state.searchQuery.isNotEmpty
                                  ? 'Try adjusting your search terms or filters'
                                  : 'Configure institutional categories to organize curriculum streams',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              onPressed: () {
                                CategoryFormSheet.show(
                                  context,
                                  existingCategories: state.categories,
                                  onSave: ({
                                    required String name,
                                    required String description,
                                    required String color,
                                    String? iconName,
                                    bool isActive = true,
                                  }) async {
                                    final ok = await notifier.createCategory(
                                      name: name,
                                      description: description,
                                      color: color,
                                      iconName: iconName,
                                      isActive: isActive,
                                    );
                                    if (!ok) {
                                      return notifier.errorMessage ?? 'Failed to save category. Ensure name is unique.';
                                    }
                                    return null;
                                  },
                                );
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primaryForest,
                              ),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Add First Category'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                // Categories List
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final category = state.filteredCategories[index];
                          final catColor = _parseHex(category.color);
                          final catIcon = _getIconData(category.iconName);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: AppCard(
                              child: InkWell(
                                onTap: () => context.push('/categories/${category.id}'),
                                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header row: Color icon, Name, Status Badge, Actions Menu
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: catColor.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(catIcon, color: catColor, size: 22),
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
                                                      category.name,
                                                      style: theme.textTheme.titleMedium?.copyWith(
                                                        fontWeight: FontWeight.w800,
                                                        color: AppColors.textPrimary,
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: category.isActive
                                                          ? AppColors.forestSoft
                                                          : Colors.grey.withValues(alpha: 0.15),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      category.isActive ? 'Active' : 'Inactive',
                                                      style: TextStyle(
                                                        color: category.isActive
                                                            ? AppColors.primaryForest
                                                            : AppColors.textSecondary,
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                category.description,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: AppColors.textSecondary,
                                                  fontSize: 12,
                                                  height: 1.3,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        PopupMenuButton<String>(
                                          icon: const Icon(
                                            Icons.more_vert_rounded,
                                            color: AppColors.textSecondary,
                                            size: 20,
                                          ),
                                          onSelected: (action) {
                                            if (action == 'details') {
                                              context.push('/categories/${category.id}');
                                            } else if (action == 'edit') {
                                              CategoryFormSheet.show(
                                                context,
                                                initialCategory: category,
                                                existingCategories: state.categories,
                                                onSave: ({
                                                  required String name,
                                                  required String description,
                                                  required String color,
                                                  String? iconName,
                                                  bool isActive = true,
                                                }) async {
                                                  final ok = await notifier.updateCategory(
                                                    category.id,
                                                    name: name,
                                                    description: description,
                                                    color: color,
                                                    iconName: iconName,
                                                    isActive: isActive,
                                                  );
                                                  if (!ok) {
                                                    return notifier.errorMessage ?? 'Failed to update category.';
                                                  }
                                                  return null;
                                                },
                                              );
                                            } else if (action == 'toggle') {
                                              notifier.toggleActive(category.id, category.isActive);
                                            } else if (action == 'delete') {
                                              _confirmDelete(context, ref, category);
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(
                                              value: 'details',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.visibility_rounded, size: 18),
                                                  SizedBox(width: 8),
                                                  Text('View Details'),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 'edit',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit_rounded, size: 18),
                                                  SizedBox(width: 8),
                                                  Text('Edit Category'),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 'toggle',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    category.isActive
                                                        ? Icons.visibility_off_rounded
                                                        : Icons.visibility_rounded,
                                                    size: 18,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(category.isActive ? 'Deactivate' : 'Activate'),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuDivider(),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.delete_outline_rounded,
                                                      size: 18, color: AppColors.error),
                                                  SizedBox(width: 8),
                                                  Text('Delete', style: TextStyle(color: AppColors.error)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 14),
                                    const Divider(height: 1),
                                    const SizedBox(height: 12),

                                    // Metrics counters
                                    Row(
                                      children: [
                                        _MetricChip(
                                          icon: Icons.book_rounded,
                                          label: '${category.courseCount} Courses',
                                          color: AppColors.primaryForest,
                                        ),
                                        const SizedBox(width: 8),
                                        _MetricChip(
                                          icon: Icons.school_rounded,
                                          label: '${category.instructorCount} Faculty',
                                          color: AppColors.accentTerracotta,
                                        ),
                                        const SizedBox(width: 8),
                                        _MetricChip(
                                          icon: Icons.people_alt_rounded,
                                          label: '${category.studentCount} Students',
                                          color: AppColors.forestLight,
                                        ),
                                        const Spacer(),
                                        const Icon(
                                          Icons.chevron_right_rounded,
                                          size: 18,
                                          color: AppColors.textSecondary,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: state.filteredCategories.length,
                      ),
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

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetricChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
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
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

