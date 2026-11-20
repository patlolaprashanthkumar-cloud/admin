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
///
/// Follows the IIECM Modern Academic design language with institutional branding,
/// structured tabs, academic metadata metrics, and polished syllabus navigation.
class CourseDetailScreen extends ConsumerStatefulWidget {
  final String courseId;

  const CourseDetailScreen({super.key, required this.courseId});

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
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.backgroundWarmOffWhite,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.darkSurface
            : AppColors.backgroundWarmOffWhite,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(AppConstants.radiusSm),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceElevated
                      : AppColors.white,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 18,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              course?.title ?? 'Course Curriculum',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            Text(
              course?.categoryName != null
                  ? '${course!.categoryName} · Academic Curriculum'
                  : 'Official Medical Training Curriculum',
              style: TextStyle(
                fontSize: 11,
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
            tooltip: 'Refresh Curriculum',
            icon: const Icon(Icons.refresh_rounded),
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            onPressed: () => notifier.refresh(),
          ),
          const SizedBox(width: AppConstants.spacingSm),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: isDark
                  ? AppColors.accentOrangeLight
                  : AppColors.primaryNavy,
              unselectedLabelColor: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
              indicatorColor: AppColors.accentOrange,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
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
          ? _buildErrorState(
              context,
              detailState.errorMessage,
              notifier,
              isDark,
              theme,
            )
          : course == null
          ? _buildNotFoundState(context, isDark, theme)
          : TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Curriculum & Lessons
                _buildCurriculumTab(
                  context,
                  course,
                  detailState,
                  notifier,
                  isDark,
                  theme,
                ),

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
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryNavy),
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Text(
            'Loading course curriculum...',
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
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: AppColors.errorSoft,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.error,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingMd),
              Text(
                'Unable to Load Curriculum',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                errorMessage ??
                    'A network or server error occurred. Please try again.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                  height: 1.4,
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

  Widget _buildNotFoundState(
    BuildContext context,
    bool isDark,
    ThemeData theme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: AppCard(
          padding: const EdgeInsets.all(AppConstants.spacingLg + 4),
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
                      : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppConstants.spacingMd),
              Text(
                'Course Not Found',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'This course either does not exist or you do not have an active enrollment assigned.',
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
                label: 'Back to Courses',
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

  Widget _buildCurriculumTab(
    BuildContext context,
    StudentCourse course,
    CourseDetailState detailState,
    CourseDetailNotifier notifier,
    bool isDark,
    ThemeData theme,
  ) {
    return RefreshIndicator(
      color: AppColors.primaryNavy,
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
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceElevated
                      : AppColors.forestSoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.layers_rounded,
                  size: 16,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Modules & Lessons',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceElevated
                      : AppColors.forestSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryNavy.withValues(alpha: 0.12),
                  ),
                ),
                child: Text(
                  '${detailState.modules.length} Modules · ${detailState.totalLessonsCount} Lessons',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.accentOrangeLight
                        : AppColors.primaryNavy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingSm + 2),

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
    final hasThumbnail =
        course.thumbnailUrl != null && course.thumbnailUrl!.trim().isNotEmpty;

    return AppCard(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Optional Thumbnail Header
          if (hasThumbnail) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
              child: AspectRatio(
                aspectRatio: 16 / 7.5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      course.thumbnailUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: isDark
                            ? AppColors.darkSurfaceElevated
                            : AppColors.forestSoft,
                        child: const Center(
                          child: Icon(
                            Icons.school_outlined,
                            size: 32,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${course.durationWeeks} WEEKS CURRICULUM',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spacingSm + 4),
          ],

          // Taxonomy Badges Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Category Badge
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
                          color: AppColors.primaryNavy.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Text(
                        course.categoryName.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                    ),

                    // Delivery Format Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkBackground
                            : AppColors.warmCreamLight,
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusSm,
                        ),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        course.format.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.accentOrangeLight
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Enrollment Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.successSoft : AppColors.infoSoft,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                  border: Border.all(
                    color: isActive
                        ? AppColors.success.withValues(alpha: 0.28)
                        : AppColors.info.withValues(alpha: 0.28),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isActive
                          ? Icons.check_circle_rounded
                          : Icons.verified_rounded,
                      size: 11,
                      color: isActive ? AppColors.success : AppColors.info,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      course.enrollmentStatus.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: isActive ? AppColors.success : AppColors.info,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingSm + 2),

          // Course Title
          Text(
            course.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              height: 1.25,
            ),
          ),

          if (course.instructorName != null &&
              course.instructorName!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceElevated
                        : AppColors.forestSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    size: 13,
                    color: AppColors.primaryNavy,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Lead Faculty: ${course.instructorName!}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryNavy,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: AppConstants.spacingMd),
          Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
          ),
          const SizedBox(height: AppConstants.spacingMd),

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
              if (detailState.totalDurationMinutes > 0) ...[
                _buildStatDivider(isDark),
                _buildStatColumn(
                  icon: Icons.timelapse_rounded,
                  value: '${detailState.totalDurationMinutes}m',
                  label: 'Content',
                  isDark: isDark,
                ),
              ],
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
        Icon(icon, size: 18, color: AppColors.primaryNavy),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider(bool isDark) {
    return Container(
      height: 24,
      width: 1,
      color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
    );
  }

  Widget _buildModuleExpansionCard(
    CourseModule module,
    bool isDark,
    ThemeData theme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingSm + 2),
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
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceElevated
                  : AppColors.forestSoft,
              borderRadius: BorderRadius.circular(AppConstants.radiusSm),
              border: Border.all(
                color: AppColors.primaryNavy.withValues(alpha: 0.15),
              ),
            ),
            child: Center(
              child: Text(
                '${module.orderIndex}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: AppColors.primaryNavy,
                ),
              ),
            ),
          ),
          title: Text(
            module.title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Row(
              children: [
                Text(
                  '${module.lessons.length} Lessons${module.totalDurationMinutes > 0 ? " · ${module.totalDurationMinutes} min" : ""}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
                if (module.videoCount > 0) ...[
                  const SizedBox(width: 6),
                  _buildMiniTypePill(
                    Icons.play_circle_filled_rounded,
                    '${module.videoCount}',
                    AppColors.accentOrange,
                    isDark,
                  ),
                ],
                if (module.pdfCount > 0) ...[
                  const SizedBox(width: 4),
                  _buildMiniTypePill(
                    Icons.picture_as_pdf_rounded,
                    '${module.pdfCount}',
                    AppColors.error,
                    isDark,
                  ),
                ],
              ],
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          children: [
            if (module.description != null && module.description!.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceElevated
                      : AppColors.warmCreamLight,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.borderSubtle,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.article_outlined,
                      size: 14,
                      color: AppColors.primaryNavy,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        module.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                          height: 1.35,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (module.lessons.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(
                    'No lessons published for this module yet.',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontStyle: FontStyle.italic,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textMuted,
                    ),
                  ),
                ),
              )
            else
              ...module.lessons.map(
                (lesson) =>
                    LessonTile(lesson: lesson, moduleTitle: module.title),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniTypePill(
    IconData icon,
    String count,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 2.5),
          Text(
            count,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyModulesCard(bool isDark, ThemeData theme) {
    return AppCard(
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      child: Column(
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
            child: const Icon(
              Icons.auto_stories_outlined,
              size: 28,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Text(
            'Curriculum Under Preparation',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'The syllabus modules for this training program are currently being published by the department.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
              height: 1.4,
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
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceElevated
                          : AppColors.forestSoft,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      size: 16,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Program Description',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingSm + 2),
              Text(
                course.description.isNotEmpty ? course.description : 'Comprehensive institutional curriculum tailored for clinical emergency and healthcare management fellows.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  fontSize: 13,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
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
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceElevated
                            : AppColors.forestSoft,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.track_changes_rounded,
                        size: 16,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Learning Objectives & Competencies',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingMd),
                ...course.learningObjectives.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final objective = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurfaceElevated
                                : AppColors.forestSoft,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primaryNavy.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '$index',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryNavy,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            objective,
                            style: theme.textTheme.bodySmall?.copyWith(
                              height: 1.45,
                              fontSize: 12.5,
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
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: AppColors.accentOrangeSoft,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.assignment_turned_in_outlined,
                        size: 16,
                        color: AppColors.accentOrange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Prerequisites & Eligibility',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingSm + 4),
                ...course.prerequisites.map(
                  (prereq) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: AppColors.accentOrange,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            prereq,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 12,
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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceElevated
                      : AppColors.forestSoft,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryNavy.withValues(alpha: 0.15),
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.verified_user_outlined,
                    size: 20,
                    color: AppColors.primaryNavy,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Official Course Enrollment',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your enrollment in this course is officially recorded in the IIECM registry. Lesson completions, clinical ward attendance, and OSCE checkpoints contribute toward your credential certification.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                        height: 1.4,
                        fontSize: 12,
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
