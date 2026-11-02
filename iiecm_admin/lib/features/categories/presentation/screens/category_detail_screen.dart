import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../providers/category_provider.dart';
import '../widgets/category_form_sheet.dart';

class CategoryDetailScreen extends ConsumerStatefulWidget {
  final String categoryId;

  const CategoryDetailScreen({
    super.key,
    required this.categoryId,
  });

  @override
  ConsumerState<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends ConsumerState<CategoryDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final detailAsync = ref.watch(categoryDetailFamily(widget.categoryId));

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      appBar: AppBar(
        title: const Text('Category Overview'),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.warmCream,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(categoryDetailFamily(widget.categoryId)),
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () {
              final cat = detailAsync.value?.category;
              if (cat == null) return;
              final allCategories = ref.read(categoryNotifierProvider).categories;
              CategoryFormSheet.show(
                context,
                initialCategory: cat,
                existingCategories: allCategories,
                onSave: ({
                  required String name,
                  required String description,
                  required String color,
                  String? iconName,
                  bool isActive = true,
                }) async {
                  final notifier = ref.read(categoryNotifierProvider.notifier);
                  final ok = await notifier.updateCategory(
                    cat.id,
                    name: name,
                    description: description,
                    color: color,
                    iconName: iconName,
                    isActive: isActive,
                  );
                  if (ok) {
                    ref.invalidate(categoryDetailFamily(widget.categoryId));
                    return null;
                  }
                  return notifier.errorMessage ?? 'Failed to update category.';
                },
              );
            },
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryForest),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text('Failed to load category', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(err.toString(), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(categoryDetailFamily(widget.categoryId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (data) {
          final cat = data.category;
          if (cat == null) {
            return const Center(child: Text('Category not found'));
          }
          final catColor = _parseHex(cat.color);

          return ResponsiveLayout(
            child: Column(
              children: [
                // Category Header Banner
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: catColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(Icons.category_rounded, color: catColor, size: 28),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cat.name,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: cat.isActive
                                              ? AppColors.forestSoft
                                              : Colors.grey.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          cat.isActive ? 'Active Stream' : 'Inactive Stream',
                                          style: TextStyle(
                                            color: cat.isActive
                                                ? AppColors.primaryForest
                                                : AppColors.textSecondary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          cat.description,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Quick Stats Row
                        Row(
                          children: [
                            _HeaderStat(
                              count: data.courses.length,
                              label: 'Courses',
                              color: AppColors.primaryForest,
                            ),
                            const SizedBox(width: 10),
                            _HeaderStat(
                              count: data.instructors.length,
                              label: 'Faculty',
                              color: AppColors.accentTerracotta,
                            ),
                            const SizedBox(width: 10),
                            _HeaderStat(
                              count: data.students.length,
                              label: 'Enrolled',
                              color: AppColors.forestLight,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Tabs
                Container(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primaryForest,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: AppColors.primaryForest,
                    indicatorWeight: 3,
                    tabs: [
                      Tab(text: 'Courses (${data.courses.length})'),
                      Tab(text: 'Instructors (${data.instructors.length})'),
                      Tab(text: 'Students (${data.students.length})'),
                    ],
                  ),
                ),

                // Tab Views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Courses List
                      data.courses.isEmpty
                          ? const Center(child: Text('No courses mapped to this category'))
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: data.courses.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final course = data.courses[index];
                                return AppCard(
                                  child: ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.forestSoft,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.book_rounded, color: AppColors.primaryForest),
                                    ),
                                    title: Text(
                                      course['title']?.toString() ?? 'Course',
                                      style: const TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                    subtitle: Text(
                                      '${course['duration_weeks'] ?? 8} weeks · Fee: ${CurrencyFormatter.format((course['fee'] as num?)?.toDouble() ?? 0)}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: course['status'] == 'published'
                                            ? AppColors.forestSoft
                                            : Colors.grey.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        course['status']?.toString() ?? 'draft',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: course['status'] == 'published'
                                              ? AppColors.primaryForest
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                      // Instructors List
                      data.instructors.isEmpty
                          ? const Center(child: Text('No faculty instructors teaching in this category'))
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: data.instructors.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final ins = data.instructors[index];
                                return AppCard(
                                  child: ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      backgroundColor: AppColors.terracottaSoft,
                                      child: Text(
                                        (ins['full_name']?.toString() ?? 'I').substring(0, 1),
                                        style: const TextStyle(
                                          color: AppColors.accentTerracotta,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      ins['full_name']?.toString() ?? 'Faculty Member',
                                      style: const TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                    subtitle: Text(
                                      ins['specialization']?.toString() ?? ins['email']?.toString() ?? '',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                );
                              },
                            ),

                      // Students List
                      data.students.isEmpty
                          ? const Center(child: Text('No students enrolled in this category'))
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: data.students.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final stu = data.students[index];
                                return AppCard(
                                  child: ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      backgroundColor: AppColors.forestSoft,
                                      child: Text(
                                        (stu['full_name']?.toString() ?? 'S').substring(0, 1),
                                        style: const TextStyle(
                                          color: AppColors.primaryForest,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      stu['full_name']?.toString() ?? 'Student',
                                      style: const TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                    subtitle: Text(
                                      '${stu['student_id'] ?? ''} · ${stu['email'] ?? ''}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: stu['account_status'] == 'active'
                                            ? AppColors.forestSoft
                                            : Colors.grey.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        stu['account_status']?.toString() ?? 'active',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: stu['account_status'] == 'active'
                                              ? AppColors.primaryForest
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _HeaderStat({
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
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
      ),
    );
  }
}
