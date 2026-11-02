import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../core/widgets/stat_kpi_card.dart';
import '../../../courses/presentation/providers/courses_provider.dart';
import '../../../faculty/presentation/providers/faculty_provider.dart';
import '../../domain/models/live_class.dart';
import '../providers/class_provider.dart';
import '../widgets/create_class_sheet.dart';

class ClassesScreen extends ConsumerStatefulWidget {
  const ClassesScreen({super.key});

  @override
  ConsumerState<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends ConsumerState<ClassesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showStatusDialog(LiveClass liveClass) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Update Status: ${liveClass.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Upcoming'),
              leading: const Icon(Icons.schedule_rounded, color: Colors.blueAccent),
              onTap: () {
                Navigator.of(ctx).pop();
                ref.read(classNotifierProvider.notifier).updateStatus(liveClass.id, 'upcoming');
              },
            ),
            ListTile(
              title: const Text('Live Now'),
              leading: const Icon(Icons.fiber_manual_record_rounded, color: Colors.red),
              onTap: () {
                Navigator.of(ctx).pop();
                ref.read(classNotifierProvider.notifier).updateStatus(liveClass.id, 'live');
              },
            ),
            ListTile(
              title: const Text('Completed'),
              leading: const Icon(Icons.check_circle_outline_rounded, color: AppColors.primaryForest),
              onTap: () {
                Navigator.of(ctx).pop();
                ref.read(classNotifierProvider.notifier).updateStatus(liveClass.id, 'completed');
              },
            ),
            ListTile(
              title: const Text('Cancelled'),
              leading: const Icon(Icons.cancel_outlined, color: AppColors.error),
              onTap: () {
                Navigator.of(ctx).pop();
                ref.read(classNotifierProvider.notifier).updateStatus(liveClass.id, 'cancelled');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(LiveClass liveClass) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Live Class?'),
        content: Text('Are you sure you want to delete "${liveClass.title}" from the timetable?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(classNotifierProvider.notifier).deleteClass(liveClass.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _copyMeetingLink(String? link) {
    if (link == null || link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No meeting link assigned to this session.')),
      );
      return;
    }
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Meeting link copied to clipboard'),
        backgroundColor: AppColors.primaryForest,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(classNotifierProvider);
    final notifier = ref.read(classNotifierProvider.notifier);
    final facultyState = ref.watch(facultyNotifierProvider);
    final coursesState = ref.watch(coursesNotifierProvider);

    final totalClasses = state.classList.length;
    final upcomingCount = state.classList.where((c) => c.isUpcoming).length;
    final liveCount = state.classList.where((c) => c.isLive).length;
    final completedCount = state.classList.where((c) => c.isCompleted).length;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      appBar: AppBar(
        title: const Text('Class Timetable & Scheduling'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => notifier.loadClasses(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryForest,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Schedule Class'),
        onPressed: () => CreateClassSheet.show(context),
      ),
      body: SafeArea(
        child: ResponsiveLayout(
          child: RefreshIndicator(
            onRefresh: () => notifier.loadClasses(),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // 1. KPI Telemetry
                Row(
                  children: [
                    Expanded(
                      child: StatKpiCard(
                        label: 'Total Sessions',
                        value: '$totalClasses',
                        icon: Icons.calendar_today_rounded,
                        accentColor: AppColors.primaryForest,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatKpiCard(
                        label: 'Upcoming',
                        value: '$upcomingCount',
                        icon: Icons.schedule_rounded,
                        accentColor: Colors.blueAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: StatKpiCard(
                        label: 'Live Now',
                        value: '$liveCount',
                        icon: Icons.fiber_manual_record_rounded,
                        accentColor: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatKpiCard(
                        label: 'Completed',
                        value: '$completedCount',
                        icon: Icons.check_circle_rounded,
                        accentColor: AppColors.primaryForest,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 2. View Mode Selector (List, Daily, Weekly)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      _buildViewModeTab('List View', ClassViewMode.list, state.viewMode, (m) {
                        notifier.setViewMode(m);
                      }),
                      _buildViewModeTab('Today / Daily', ClassViewMode.daily, state.viewMode, (m) {
                        notifier.setViewMode(m);
                      }),
                      _buildViewModeTab('Weekly View', ClassViewMode.weekly, state.viewMode, (m) {
                        notifier.setViewMode(m);
                      }),
                    ],
                  ),
                ),

                if (state.viewMode == ClassViewMode.daily) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded),
                        onPressed: () {
                          notifier.setSelectedDate(state.selectedDate.subtract(const Duration(days: 1)));
                        },
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.calendar_month_rounded, size: 16),
                        label: Text(
                          DateFormatter.formatDate(state.selectedDate),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: state.selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) notifier.setSelectedDate(picked);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded),
                        onPressed: () {
                          notifier.setSelectedDate(state.selectedDate.add(const Duration(days: 1)));
                        },
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),

                // 3. Search Field
                TextField(
                  controller: _searchController,
                  onChanged: (val) => notifier.setSearchQuery(val),
                  decoration: InputDecoration(
                    hintText: 'Search sessions by title, course, or instructor...',
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

                // 4. Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All Status', 'all', state.selectedStatus, (s) {
                        notifier.setStatusFilter(s);
                      }),
                      const SizedBox(width: 8),
                      _buildFilterChip('Upcoming', 'upcoming', state.selectedStatus, (s) {
                        notifier.setStatusFilter(s);
                      }),
                      const SizedBox(width: 8),
                      _buildFilterChip('Live', 'live', state.selectedStatus, (s) {
                        notifier.setStatusFilter(s);
                      }),
                      const SizedBox(width: 8),
                      _buildFilterChip('Completed', 'completed', state.selectedStatus, (s) {
                        notifier.setStatusFilter(s);
                      }),
                      const SizedBox(width: 8),
                      _buildFilterChip('Cancelled', 'cancelled', state.selectedStatus, (s) {
                        notifier.setStatusFilter(s);
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // 5. Instructor & Course Filters
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: state.selectedInstructorId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          labelText: 'Filter Instructor',
                          prefixIcon: Icon(Icons.person_search_outlined, size: 18),
                        ),
                        items: [
                          const DropdownMenuItem(value: 'all', child: Text('All Faculty')),
                          ...facultyState.facultyList.map((f) {
                            return DropdownMenuItem(
                              value: f.id,
                              child: Text(f.fullName, overflow: TextOverflow.ellipsis),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          if (val != null) notifier.setInstructorFilter(val);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: state.selectedCourseId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          labelText: 'Filter Course',
                          prefixIcon: Icon(Icons.menu_book_outlined, size: 18),
                        ),
                        items: [
                          const DropdownMenuItem(value: 'all', child: Text('All Courses')),
                          ...coursesState.courses.map((c) {
                            return DropdownMenuItem(
                              value: c.id,
                              child: Text(c.title, overflow: TextOverflow.ellipsis),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          if (val != null) notifier.setCourseFilter(val);
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 6. Live Class Cards
                if (state.isLoading && state.classList.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(color: AppColors.primaryForest),
                    ),
                  )
                else if (state.filteredClasses.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_busy_rounded,
                          size: 56,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No scheduled classes found',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Try selecting a different date or filter option',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.filteredClasses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final c = state.filteredClasses[index];

                      Color badgeColor;
                      Color badgeText;
                      if (c.isLive) {
                        badgeColor = Colors.red.withValues(alpha: 0.15);
                        badgeText = Colors.red;
                      } else if (c.isUpcoming) {
                        badgeColor = Colors.blue.withValues(alpha: 0.15);
                        badgeText = Colors.blueAccent;
                      } else if (c.isCompleted) {
                        badgeColor = AppColors.forestSoft;
                        badgeText = AppColors.primaryForest;
                      } else {
                        badgeColor = AppColors.error.withValues(alpha: 0.1);
                        badgeText = AppColors.error;
                      }

                      return AppCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: badgeColor,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    c.isLive ? Icons.sensors_rounded : Icons.video_camera_front_rounded,
                                    color: badgeText,
                                    size: 22,
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
                                              c.title,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: badgeColor,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (c.isLive) ...[
                                                  Container(
                                                    width: 6,
                                                    height: 6,
                                                    decoration: const BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                ],
                                                Text(
                                                  c.status.toUpperCase(),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w800,
                                                    color: badgeText,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        c.courseName,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primaryForest,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.person_outline_rounded, size: 14, color: AppColors.textSecondary),
                                          const SizedBox(width: 4),
                                          Text(
                                            c.instructorName,
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                          ),
                                          const SizedBox(width: 12),
                                          const Icon(Icons.timer_outlined, size: 14, color: AppColors.textSecondary),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${c.durationMinutes} mins',
                                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert_rounded, size: 20),
                                  onSelected: (val) {
                                    switch (val) {
                                      case 'reschedule':
                                        CreateClassSheet.show(context, existingClass: c);
                                        break;
                                      case 'status':
                                        _showStatusDialog(c);
                                        break;
                                      case 'delete':
                                        _confirmDelete(c);
                                        break;
                                    }
                                  },
                                  itemBuilder: (ctx) => [
                                    const PopupMenuItem(
                                      value: 'reschedule',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_calendar_rounded, size: 18),
                                          SizedBox(width: 8),
                                          Text('Reschedule'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'status',
                                      child: Row(
                                        children: [
                                          Icon(Icons.toggle_on_outlined, size: 18),
                                          SizedBox(width: 8),
                                          Text('Change Status'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                                          SizedBox(width: 8),
                                          Text('Delete Class', style: TextStyle(color: AppColors.error)),
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

                            // Date/Time badge & Action buttons
                            Row(
                              children: [
                                const Icon(Icons.calendar_month_rounded, size: 14, color: AppColors.textSecondary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    DateFormatter.formatDateTime(c.scheduledAt),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                if (c.meetingLink != null && c.meetingLink!.isNotEmpty) ...[
                                  OutlinedButton.icon(
                                    onPressed: () => _copyMeetingLink(c.meetingLink),
                                    icon: const Icon(Icons.copy_rounded, size: 14),
                                    label: const Text('Copy Link', style: TextStyle(fontSize: 11)),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViewModeTab(
    String label,
    ClassViewMode mode,
    ClassViewMode currentMode,
    ValueChanged<ClassViewMode> onSelect,
  ) {
    final isSelected = mode == currentMode;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryForest : Colors.transparent,
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium - 2),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textSecondary,
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
