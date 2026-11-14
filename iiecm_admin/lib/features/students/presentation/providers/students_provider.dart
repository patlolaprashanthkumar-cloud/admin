import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  StudentsNotifier(this._repository) : super(const StudentsState()) {
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
      await loadStudents();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }
}

final studentsNotifierProvider =
    StateNotifierProvider<StudentsNotifier, StudentsState>((ref) {
      final repo = ref.watch(studentRepositoryProvider);
      return StudentsNotifier(repo);
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
