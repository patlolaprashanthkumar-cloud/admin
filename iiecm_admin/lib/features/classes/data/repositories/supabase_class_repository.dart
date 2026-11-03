import 'dart:developer' as developer;

import '../../../../core/network/supabase_client.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/models/live_class.dart';
import '../../domain/repositories/class_repository.dart';

class SupabaseClassRepository implements ClassRepository {
  @override
  Future<List<LiveClass>> getClasses({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? instructorId,
    String? courseId,
  }) async {
    final client = AppSupabase.client;

    try {
      var query = client.from('live_classes').select('*');

      if (status != null && status.isNotEmpty && status != 'all') {
        query = query.eq('status', status);
      }
      if (instructorId != null &&
          instructorId.isNotEmpty &&
          instructorId != 'all') {
        query = query.eq('instructor_id', instructorId);
      }
      if (courseId != null && courseId.isNotEmpty && courseId != 'all') {
        query = query.eq('course_id', courseId);
      }
      if (startDate != null) {
        query = query.gte('scheduled_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('scheduled_at', endDate.toIso8601String());
      }

      final List<dynamic> rows = await query.order(
        'scheduled_at',
        ascending: true,
      );
      return rows
          .map((r) => LiveClass.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      developer.log('Error in getClasses: $e', name: 'SupabaseClassRepository');
      rethrow;
    }
  }

  @override
  Future<LiveClass?> getClassById(String id) async {
    final client = AppSupabase.client;
    try {
      final List<dynamic> rows = await client
          .from('live_classes')
          .select('*')
          .eq('id', id)
          .limit(1);

      if (rows.isEmpty) return null;
      return LiveClass.fromJson(rows.first as Map<String, dynamic>);
    } catch (e) {
      developer.log(
        'Error in getClassById: $e',
        name: 'SupabaseClassRepository',
      );
      rethrow;
    }
  }

  @override
  Future<List<LiveClass>> checkInstructorConflicts({
    required String instructorId,
    required DateTime scheduledAt,
    required int durationMinutes,
    String? excludeClassId,
  }) async {
    final client = AppSupabase.client;

    try {
      // Query classes for this instructor within +- 24 hours of scheduledAt
      final dayBefore = scheduledAt.subtract(const Duration(hours: 24));
      final dayAfter = scheduledAt.add(const Duration(hours: 24));

      var query = client
          .from('live_classes')
          .select('*')
          .eq('instructor_id', instructorId)
          .neq('status', 'cancelled')
          .gte('scheduled_at', dayBefore.toIso8601String())
          .lte('scheduled_at', dayAfter.toIso8601String());

      if (excludeClassId != null && excludeClassId.isNotEmpty) {
        query = query.neq('id', excludeClassId);
      }

      final List<dynamic> rows = await query;
      final existingClasses = rows
          .map((r) => LiveClass.fromJson(r as Map<String, dynamic>))
          .toList();

      // Detect overlap
      final conflicts = existingClasses.where((c) {
        return c.overlapsWith(scheduledAt, durationMinutes);
      }).toList();

      return conflicts;
    } catch (e) {
      developer.log(
        'Error in checkInstructorConflicts: $e',
        name: 'SupabaseClassRepository',
      );
      return [];
    }
  }

  @override
  Future<LiveClass> createClass(
    LiveClass liveClass, {
    bool notifyStudents = true,
  }) async {
    final client = AppSupabase.client;

    try {
      final payload = liveClass.toJson();
      final List<dynamic> inserted = await client
          .from('live_classes')
          .insert(payload)
          .select('*');

      if (inserted.isEmpty) {
        throw Exception('Failed to insert live class.');
      }

      final created = LiveClass.fromJson(
        inserted.first as Map<String, dynamic>,
      );

      // Increment total_classes for instructor if present
      if (created.instructorId.isNotEmpty) {
        try {
          await client.rpc(
            'increment_instructor_classes',
            params: {'inst_id': created.instructorId},
          );
        } catch (_) {
          // If RPC is absent, update directly
          try {
            final inst = await client
                .from('instructors')
                .select('total_classes')
                .eq('id', created.instructorId)
                .maybeSingle();
            if (inst != null) {
              final current = (inst['total_classes'] as int?) ?? 0;
              await client
                  .from('instructors')
                  .update({'total_classes': current + 1})
                  .eq('id', created.instructorId);
            }
          } catch (_) {}
        }
      }

      // Notify students if enabled
      if (notifyStudents) {
        try {
          await client.from('notifications').insert({
            'title': 'New Class Scheduled: ${created.title}',
            'message':
                'Live session for ${created.courseName} scheduled on ${DateFormatter.formatDateTime(created.scheduledAt)} with ${created.instructorName}.',
            'type': 'class',
            'priority': 'high',
            'read': false,
            'action_url': created.meetingLink,
          });
        } catch (e) {
          developer.log(
            'Failed to dispatch notification: $e',
            name: 'SupabaseClassRepository',
          );
        }
      }

      return created;
    } catch (e) {
      developer.log(
        'Error in createClass: $e',
        name: 'SupabaseClassRepository',
      );
      rethrow;
    }
  }

  @override
  Future<LiveClass> updateClass(LiveClass liveClass) async {
    final client = AppSupabase.client;

    try {
      final payload = liveClass.toJson();
      await client.from('live_classes').update(payload).eq('id', liveClass.id);
      return (await getClassById(liveClass.id)) ?? liveClass;
    } catch (e) {
      developer.log(
        'Error in updateClass: $e',
        name: 'SupabaseClassRepository',
      );
      rethrow;
    }
  }

  @override
  Future<LiveClass> rescheduleClass(
    String id,
    DateTime newScheduledAt,
    int newDuration, {
    bool notifyStudents = true,
  }) async {
    final client = AppSupabase.client;

    try {
      await client
          .from('live_classes')
          .update({
            'scheduled_at': newScheduledAt.toIso8601String(),
            'duration_minutes': newDuration,
            'status': 'upcoming',
          })
          .eq('id', id);

      final updated = await getClassById(id);
      if (updated == null) {
        throw Exception('Class not found after reschedule.');
      }

      if (notifyStudents) {
        try {
          await client.from('notifications').insert({
            'title': 'Class Rescheduled: ${updated.title}',
            'message':
                'Live session for ${updated.courseName} has been rescheduled to ${DateFormatter.formatDateTime(newScheduledAt)}.',
            'type': 'class',
            'priority': 'high',
            'read': false,
            'action_url': updated.meetingLink,
          });
        } catch (_) {}
      }

      return updated;
    } catch (e) {
      developer.log(
        'Error in rescheduleClass: $e',
        name: 'SupabaseClassRepository',
      );
      rethrow;
    }
  }

  @override
  Future<void> updateClassStatus(String id, String status) async {
    final client = AppSupabase.client;
    try {
      await client.from('live_classes').update({'status': status}).eq('id', id);
    } catch (e) {
      developer.log(
        'Error in updateClassStatus: $e',
        name: 'SupabaseClassRepository',
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteClass(String id) async {
    final client = AppSupabase.client;
    try {
      await client.from('live_classes').delete().eq('id', id);
    } catch (e) {
      developer.log(
        'Error in deleteClass: $e',
        name: 'SupabaseClassRepository',
      );
      rethrow;
    }
  }
}
