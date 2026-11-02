import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../domain/models/faculty.dart';
import '../providers/faculty_provider.dart';
import '../widgets/add_edit_faculty_sheet.dart';

class FacultyProfileScreen extends ConsumerStatefulWidget {
  final String facultyId;

  const FacultyProfileScreen({super.key, required this.facultyId});

  @override
  ConsumerState<FacultyProfileScreen> createState() => _FacultyProfileScreenState();
}

class _FacultyProfileScreenState extends ConsumerState<FacultyProfileScreen> {
  List<Map<String, dynamic>> _scheduledClasses = [];
  bool _isLoadingClasses = false;

  @override
  void initState() {
    super.initState();
    _loadFacultyClasses();
  }

  Future<void> _loadFacultyClasses() async {
    setState(() => _isLoadingClasses = true);
    try {
      final rows = await AppSupabase.client
          .from('live_classes')
          .select('*')
          .eq('instructor_id', widget.facultyId)
          .order('scheduled_at', ascending: false)
          .limit(10);

      if (mounted) {
        setState(() {
          _scheduledClasses = List<Map<String, dynamic>>.from(rows);
          _isLoadingClasses = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingClasses = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final facultyAsync = ref.watch(facultyDetailProvider(widget.facultyId));

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      appBar: AppBar(
        title: const Text('Faculty Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Faculty',
            onPressed: () {
              facultyAsync.whenData((faculty) {
                if (faculty != null) {
                  AddEditFacultySheet.show(context, faculty: faculty).then((updated) {
                    if (updated == true) {
                      ref.invalidate(facultyDetailProvider(widget.facultyId));
                      ref.read(facultyNotifierProvider.notifier).loadFaculty();
                    }
                  });
                }
              });
            },
          ),
        ],
      ),
      body: facultyAsync.when(
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
                Text('Failed to load faculty: $err', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(facultyDetailProvider(widget.facultyId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (faculty) {
          if (faculty == null) {
            return const Center(child: Text('Faculty member not found.'));
          }

          final isActive = faculty.isActive;

          return ResponsiveLayout(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Top Profile Card
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: AppColors.primaryForest.withValues(alpha: 0.15),
                              child: Text(
                                faculty.fullName.isNotEmpty
                                    ? faculty.fullName.substring(0, 1).toUpperCase()
                                    : 'F',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryForest,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          faculty.fullName,
                                          style: theme.textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isActive
                                              ? AppColors.forestSoft
                                              : AppColors.error.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          faculty.accountStatus.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: isActive ? AppColors.primaryForest : AppColors.error,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    faculty.qualifications,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    faculty.specialization,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.terracotta,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                                      const SizedBox(width: 4),
                                      Text(
                                        faculty.rating.toStringAsFixed(1),
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                                      ),
                                      const SizedBox(width: 12),
                                      const Icon(Icons.work_history_outlined, size: 14, color: AppColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${faculty.experienceYears} Years Exp',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 16),

                        // Contact info
                        Row(
                          children: [
                            const Icon(Icons.email_outlined, size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                faculty.email,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.phone_outlined, size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                faculty.phone,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),

                        if (faculty.bio != null && faculty.bio!.trim().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            faculty.bio!,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2. Metrics Workload Row
                  Row(
                    children: [
                      Expanded(
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.people_outline_rounded, color: AppColors.primaryForest, size: 22),
                              const SizedBox(height: 8),
                              Text(
                                '${faculty.totalStudents}',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryForest,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text('Students Mentored', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.class_outlined, color: AppColors.terracotta, size: 22),
                              const SizedBox(height: 8),
                              Text(
                                '${faculty.assignedCourses.length}',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.terracotta,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text('Courses Assigned', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.video_camera_front_outlined, color: Colors.blueAccent, size: 22),
                              const SizedBox(height: 8),
                              Text(
                                '${faculty.totalClasses}',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.blueAccent,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text('Live Classes', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 3. Certified Categories
                  Text(
                    'Certified Curriculum Categories',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (faculty.assignedCategories.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.surface,
                        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                      ),
                      child: const Text('No specific categories mapped to this instructor.'),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: faculty.assignedCategories.map((c) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.forestSoft,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primaryForest.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.school_rounded, size: 14, color: AppColors.primaryForest),
                              const SizedBox(width: 6),
                              Text(
                                c.name,
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

                  const SizedBox(height: 20),

                  // 4. Assigned Courses Catalog
                  Text(
                    'Assigned Courses',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (faculty.assignedCourses.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.surface,
                        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                      ),
                      child: const Text('No courses currently assigned.'),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: faculty.assignedCourses.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final cr = faculty.assignedCourses[index];
                        return AppCard(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryForest.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.menu_book_rounded, color: AppColors.primaryForest, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cr.title,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      cr.categoryName,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              OutlinedButton(
                                onPressed: () => context.push('/courses'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  visualDensity: VisualDensity.compact,
                                ),
                                child: const Text('View', style: TextStyle(fontSize: 11)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 20),

                  // 5. Timetable / Recent Live Classes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Class Schedule & Timetable',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => context.push('/classes'),
                        icon: const Icon(Icons.calendar_month_outlined, size: 16),
                        label: const Text('View All Classes', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_isLoadingClasses)
                    const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                  else if (_scheduledClasses.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.surface,
                        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                      ),
                      child: const Text('No classes scheduled for this faculty member.'),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _scheduledClasses.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final cls = _scheduledClasses[index];
                        final title = cls['title']?.toString() ?? 'Class';
                        final courseName = cls['course_name']?.toString() ?? 'Course';
                        final scheduledStr = cls['scheduled_at']?.toString();
                        final scheduledAt = scheduledStr != null ? DateTime.tryParse(scheduledStr) : null;
                        final duration = cls['duration_minutes']?.toString() ?? '60';
                        final status = cls['status']?.toString() ?? 'upcoming';

                        return AppCard(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: status == 'upcoming'
                                      ? Colors.blue.withValues(alpha: 0.1)
                                      : (status == 'completed'
                                          ? AppColors.primaryForest.withValues(alpha: 0.1)
                                          : AppColors.error.withValues(alpha: 0.1)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.live_tv_rounded,
                                  color: status == 'upcoming'
                                      ? Colors.blueAccent
                                      : (status == 'completed' ? AppColors.primaryForest : AppColors.error),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$courseName • ${scheduledAt != null ? DateFormatter.formatDateTime(scheduledAt) : 'N/A'} ($duration mins)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.forestSoft,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryForest,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

