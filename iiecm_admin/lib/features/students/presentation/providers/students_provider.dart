import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../data/repositories/supabase_student_repository.dart';
import '../../domain/models/student.dart';
import '../../domain/repositories/student_repository.dart';

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  return SupabaseStudentRepository();
});

class StudentsState {
  final List<Student> students;
  final bool isLoading;
  final String? errorMessage;
  final String selectedCategoryId; // 'all' or category UUID
  final String statusFilter; // 'all', 'active', 'inactive', 'suspended'
  final String searchQuery;

  const StudentsState({
    this.students = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedCategoryId = 'all',
    this.statusFilter = 'all',
    this.searchQuery = '',
  });

  List<Student> get filteredStudents {
    return students.where((s) {
      final matchesCategory =
          selectedCategoryId == 'all' ||
          s.assignedCategories.any((c) => c.id == selectedCategoryId);
      final matchesStatus =
          statusFilter == 'all' || s.accountStatus == statusFilter;
      final matchesSearch =
          searchQuery.isEmpty ||
          s.fullName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          s.studentId.toLowerCase().contains(searchQuery.toLowerCase()) ||
          s.email.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCategory && matchesStatus && matchesSearch;
    }).toList();
  }

  StudentsState copyWith({
    List<Student>? students,
    bool? isLoading,
    String? errorMessage,
    String? selectedCategoryId,
    String? statusFilter,
    String? searchQuery,
  }) {
    return StudentsState(
      students: students ?? this.students,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      statusFilter: statusFilter ?? this.statusFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class StudentsNotifier extends StateNotifier<StudentsState> {
  final StudentRepository _repository;
  final Ref? _ref;
  final Set<String> _pendingDeletionIds = {};

  StudentsNotifier(this._repository, [this._ref])
    : super(const StudentsState()) {
    loadStudents();
  }

  Future<void> loadStudents() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final items = await _repository.getStudents();
      state = state.copyWith(students: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void setSelectedCategory(String categoryId) {
    state = state.copyWith(selectedCategoryId: categoryId);
  }

  void setStatusFilter(String status) {
    state = state.copyWith(statusFilter: status);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<StudentRegistrationResult?> registerStudent({
    required String fullName,
    required String email,
    required String phone,
    required String educationLevel,
    required String qualification,
    required List<String> categoryIds,
    required List<String> courseIds,
    String? city,
    String subscriptionPlan = 'basic',
    String? learningFormat,
    String? preferredSlot,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await _repository.registerStudent(
        fullName: fullName,
        email: email,
        phone: phone,
        educationLevel: educationLevel,
        qualification: qualification,
        categoryIds: categoryIds,
        courseIds: courseIds,
        city: city,
        subscriptionPlan: subscriptionPlan,
        learningFormat: learningFormat,
        preferredSlot: preferredSlot,
      );
      state = state.copyWith(
        students: [result.student, ...state.students],
        isLoading: false,
      );
      return result;
    } catch (e) {
      final displayError = e is StudentProvisioningException
          ? e.message
          : e.toString();
      state = state.copyWith(isLoading: false, errorMessage: displayError);
      return null;
    }
  }

  Future<bool> updateStudent(
    String id, {
    String? fullName,
    String? email,
    String? phone,
    String? educationLevel,
    String? qualification,
    String? city,
    String? accountStatus,
  }) async {
    try {
      final updated = await _repository.updateStudent(
        id,
        fullName: fullName,
        email: email,
        phone: phone,
        educationLevel: educationLevel,
        qualification: qualification,
        city: city,
        accountStatus: accountStatus,
      );
      state = state.copyWith(
        students: state.students.map((s) => s.id == id ? updated : s).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<void> updateStudentCategories(
    String studentId,
    List<String> categoryIds,
  ) async {
    try {
      await _repository.updateStudentCategories(studentId, categoryIds);
      if (_ref != null) {
        _ref.invalidate(studentDetailFamily(studentId));
        _ref.invalidate(studentLmsDetailsFamily(studentId));
      }
      await loadStudents();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> unenrollCourse(String studentId, String courseId) async {
    try {
      await _repository.unenrollStudentCourse(studentId, courseId);
      if (_ref != null) {
        _ref.invalidate(studentDetailFamily(studentId));
        _ref.invalidate(studentLmsDetailsFamily(studentId));
      }
      await loadStudents();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> updateStudentStreamsAndCourses(
    String studentId,
    List<String> categoryIds,
    List<String> courseIds,
  ) async {
    try {
      await _repository.updateStudentStreamsAndCourses(
        studentId,
        categoryIds: categoryIds,
        courseIds: courseIds,
      );
      if (_ref != null) {
        _ref.invalidate(studentDetailFamily(studentId));
        _ref.invalidate(studentLmsDetailsFamily(studentId));
      }
      await loadStudents();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    }
  }

  /// Permanently deletes an eligible student via the Super Admin Edge Function.
  /// Enforces concurrency prevention, removes the record locally upon DB deletion,
  /// and invalidates related metrics and family caches.
  Future<StudentDeletionResult> deleteStudent(String studentId) async {
    final normalizedId = studentId.trim();
    if (_pendingDeletionIds.contains(normalizedId)) {
      throw StudentDeletionException(
        message: 'A deletion request is already in progress for this student.',
        statusCode: 409,
        code: 'CONCURRENT_REQUEST',
        studentId: studentId,
      );
    }

    _pendingDeletionIds.add(normalizedId);

    try {
      final result = await _repository.deleteStudent(normalizedId);

      // Both 'completed' and 'failed_auth' signify that public.students was permanently
      // deleted in PostgreSQL.
      if (result.isCompleted || result.isFailedAuth) {
        state = state.copyWith(
          students: state.students.where((s) => s.id != normalizedId).toList(),
        );

        // Invalidate detail families and dashboard metrics
        if (_ref != null) {
          _ref.invalidate(studentDetailFamily(normalizedId));
          _ref.invalidate(studentLmsDetailsFamily(normalizedId));
          _ref.invalidate(dashboardStatsProvider);
        }
      }

      return result;
    } catch (e) {
      // On error, do not modify state; rethrow for UI handling
      rethrow;
    } finally {
      _pendingDeletionIds.remove(normalizedId);
    }
  }
}

final studentsNotifierProvider =
    StateNotifierProvider<StudentsNotifier, StudentsState>((ref) {
      final repo = ref.watch(studentRepositoryProvider);
      return StudentsNotifier(repo, ref);
    });

final studentLmsDetailsFamily =
    FutureProvider.family<List<StudentCategoryLmsGroup>, String>((
      ref,
      studentId,
    ) async {
      final repo = ref.watch(studentRepositoryProvider);
      return repo.getStudentCategoryLmsDetails(studentId);
    });

final studentDetailFamily = FutureProvider.family<Student?, String>((
  ref,
  studentId,
) async {
  final repo = ref.watch(studentRepositoryProvider);
  return repo.getStudentById(studentId);
});
