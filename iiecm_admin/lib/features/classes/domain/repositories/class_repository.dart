import '../models/live_class.dart';

abstract class ClassRepository {
  /// Fetch classes with optional filters
  Future<List<LiveClass>> getClasses({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? instructorId,
    String? courseId,
  });

  /// Get class by ID
  Future<LiveClass?> getClassById(String id);

  /// Check if the instructor has any overlapping classes in the specified window
  Future<List<LiveClass>> checkInstructorConflicts({
    required String instructorId,
    required DateTime scheduledAt,
    required int durationMinutes,
    String? excludeClassId,
  });

  /// Create a new live class
  Future<LiveClass> createClass(LiveClass liveClass, {bool notifyStudents = true});

  /// Update existing class
  Future<LiveClass> updateClass(LiveClass liveClass);

  /// Reschedule class to a new date/time
  Future<LiveClass> rescheduleClass(
    String id,
    DateTime newScheduledAt,
    int newDuration, {
    bool notifyStudents = true,
  });

  /// Update class status ('upcoming', 'live', 'completed', 'cancelled')
  Future<void> updateClassStatus(String id, String status);

  /// Delete class record
  Future<void> deleteClass(String id);
}

