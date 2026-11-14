import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/models/course_module.dart';
import '../../domain/models/student_course.dart';
import '../providers/courses_provider.dart';
import '../providers/courses_state.dart';
import '../widgets/lesson_tile.dart';

/// Full Course Details and Curriculum Screen displaying modules and ordered lessons
class CourseDetailScreen extends ConsumerStatefulWidget {
  final String courseId;

  const CourseDetailScreen({
    super.key,
    required this.courseId,
  });

  @override
  ConsumerState<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final detailState = ref.watch(courseDetailProvider(widget.courseId));
    final notifier = ref.read(courseDetailProvider(widget.courseId).notifier);

    final course = detailState.course;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          course?.title ?? 'Course Curriculum',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Curriculum',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => notifier.refresh(),
          ),
          const SizedBox(width: AppConstants.spacingSm),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: isDark ? AppColors.darkSurface : AppColors.warmCreamLight,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primaryForest,
              unselectedLabelColor:
                  isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              indicatorColor: AppColors.primaryForest,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              tabs: const [
                Tab(
                  icon: Icon(Icons.menu_book_rounded, size: 18),
                  text: 'Curriculum & Lessons',
                ),
                Tab(
                  icon: Icon(Icons.info_outline_rounded, size: 18),
                  text: 'Overview & Syllabus',
                ),
              ],
            ),
          ),
        ),
      ),
      body: detailState.isLoading && course == null
          ? _buildLoadingState(isDark)
          : detailState.hasError && course == null
              ? _buildErrorState(context, detailState.errorMessage, notifier, isDark, theme)
              : course == null
                  ? _buildNotFoundState(context, isDark, theme)
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        // Tab 1: Curriculum & Lessons
                        _buildCurriculumTab(context, course, detailState, notifier, isDark, theme),

                        // Tab 2: Overview & Objectives
                        _buildOverviewTab(context, course, isDark, theme),
                      ],
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
            'Loading course curriculum...',
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
    CourseDetailNotifier notifier,
    bool isDark,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      child: Center(
        child: AppCard(
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 44),
              const SizedBox(height: AppConstants.spacingSm),
              Text(
                'Unable to Load Curriculum',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                errorMessage ?? 'A network or server error occurred. Please try again.',
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
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textMuted,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Text(
              'Course Not Found',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'This course either does not exist or you do not have an active enrollment assigned.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppConstants.spacingLg),
            AppButton(
              label: 'Back to Courses',
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

  Widget _buildCurriculumTab(
    BuildContext context,
    StudentCourse course,
    CourseDetailState detailState,
    CourseDetailNotifier notifier,
    bool isDark,
    ThemeData theme,
  ) {
    return RefreshIndicator(
      color: AppColors.primaryForest,
      onRefresh: () => notifier.refresh(),
      child: ListView(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        children: [
          // Course Header Banner Card
          _buildCourseHeaderCard(course, detailState, isDark, theme),
          const SizedBox(height: AppConstants.spacingMd),

          // Syllabus Section Title
          Row(
            children: [
              const Icon(Icons.format_list_bulleted_rounded,
                  size: 18, color: AppColors.primaryForest),
              const SizedBox(width: 8),
              Text(
                'Modules & Lessons',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${detailState.modules.length} Modules • ${detailState.totalLessonsCount} Lessons',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingSm),

          // Modules Accordion List
          if (detailState.modules.isEmpty)
            _buildEmptyModulesCard(isDark, theme)
          else
            ...detailState.modules.map(
              (module) => _buildModuleExpansionCard(module, isDark, theme),
            ),

          const SizedBox(height: AppConstants.spacingXl),
        ],
      ),
    );
  }

  Widget _buildCourseHeaderCard(
    StudentCourse course,
    CourseDetailState detailState,
    bool isDark,
    ThemeData theme,
  ) {
    final isActive = course.isActive;

    return AppCard(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tags Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceElevated : AppColors.forestSoft,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                ),
                child: Text(
                  course.categoryName.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
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
                  course.format.toUpperCase(),
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
                  color: isActive ? AppColors.successSoft : AppColors.infoSoft,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                ),
                child: Text(
                  course.enrollmentStatus.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isActive ? AppColors.success : AppColors.info,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingSm),

          // Course Title
          Text(
            course.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              height: 1.25,
            ),
          ),

          if (course.instructorName != null && course.instructorName!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.person_outline_rounded,
                    size: 14, color: AppColors.primaryForest),
                const SizedBox(width: 5),
                Text(
                  'Lead Faculty: ${course.instructorName!}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryForest,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: AppConstants.spacingMd),
          const Divider(height: 1),
          const SizedBox(height: AppConstants.spacingSm),

          // Stat Pills Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn(
                icon: Icons.layers_outlined,
                value: '${detailState.modules.length}',
                label: 'Modules',
                isDark: isDark,
              ),
              _buildStatDivider(isDark),
              _buildStatColumn(
                icon: Icons.play_lesson_outlined,
                value: '${detailState.totalLessonsCount}',
                label: 'Lessons',
                isDark: isDark,
              ),
              _buildStatDivider(isDark),
              _buildStatColumn(
                icon: Icons.schedule_rounded,
                value: '${course.durationWeeks} Wks',
                label: 'Duration',
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn({
    required IconData icon,
    required String value,
    required String label,
    required bool isDark,
  }) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryForest),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider(bool isDark) {
    return Container(
      height: 24,
      width: 1,
      color: isDark ? AppColors.darkBorder : AppColors.border,
    );
  }

  Widget _buildModuleExpansionCard(
    CourseModule module,
    bool isDark,
    ThemeData theme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingSm),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: module.orderIndex == 1,
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceElevated : AppColors.forestSoft,
              borderRadius: BorderRadius.circular(AppConstants.radiusSm),
            ),
            child: Center(
              child: Text(
                '${module.orderIndex}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: AppColors.primaryForest,
                ),
              ),
            ),
          ),
          title: Text(
            module.title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '${module.lessons.length} Lessons${module.totalDurationMinutes > 0 ? " • ${module.totalDurationMinutes} min" : ""}',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          children: [
            if (module.description != null && module.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  module.description!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ),

            if (module.lessons.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No lessons published for this module yet.',
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textMuted,
                  ),
                ),
              )
            else
              ...module.lessons.map(
                (lesson) => LessonTile(
                  lesson: lesson,
                  moduleTitle: module.title,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyModulesCard(bool isDark, ThemeData theme) {
    return AppCard(
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      child: Column(
        children: [
          Icon(
            Icons.auto_stories_outlined,
            size: 40,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textMuted,
          ),
          const SizedBox(height: AppConstants.spacingSm),
          const Text(
            'Curriculum Under Preparation',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'The syllabus modules for this training program are currently being published by the department.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(
    BuildContext context,
    StudentCourse course,
    bool isDark,
    ThemeData theme,
  ) {
    return ListView(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      children: [
        // Description Card
        AppCard(
          padding: const EdgeInsets.all(AppConstants.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.description_outlined,
                      size: 18, color: AppColors.primaryForest),
                  const SizedBox(width: 8),
                  Text(
                    'Program Description',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingSm),
              Text(
                course.description.isNotEmpty
                    ? course.description
                    : 'Comprehensive institutional curriculum tailored for clinical emergency and healthcare management fellows.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.45,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppConstants.spacingMd),

        // Learning Objectives Card
        if (course.learningObjectives.isNotEmpty) ...[
          AppCard(
            padding: const EdgeInsets.all(AppConstants.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.track_changes_rounded,
                        size: 18, color: AppColors.primaryForest),
                    const SizedBox(width: 8),
                    Text(
                      'Learning Objectives & Competencies',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingSm),
                ...course.learningObjectives.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final objective = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurfaceElevated
                                : AppColors.forestSoft,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$index',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryForest,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            objective,
                            style: theme.textTheme.bodySmall?.copyWith(
                              height: 1.4,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spacingMd),
        ],

        // Prerequisites Card
        if (course.prerequisites.isNotEmpty) ...[
          AppCard(
            padding: const EdgeInsets.all(AppConstants.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.assignment_turned_in_outlined,
                        size: 18, color: AppColors.terracotta),
                    const SizedBox(width: 8),
                    Text(
                      'Prerequisites & Eligibility',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingSm),
                ...course.prerequisites.map(
                  (prereq) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_rounded,
                            size: 16, color: AppColors.terracotta),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            prereq,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spacingMd),
        ],

        // Academic Standing / Verification Card
        AppCard(
          padding: const EdgeInsets.all(AppConstants.spacingMd),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.verified_user_outlined,
                  size: 22, color: AppColors.primaryForest),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Official Course Enrollment',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your enrollment in this course is officially recorded in the IIECM registry. Lesson completions, clinical ward attendance, and OSCE checkpoints contribute toward your credential certification.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppConstants.spacingXl),
      ],
    );
  }
}

