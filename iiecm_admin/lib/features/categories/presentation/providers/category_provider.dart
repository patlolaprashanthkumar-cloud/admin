import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../data/repositories/supabase_category_repository.dart';
import '../../domain/models/course_category.dart';
import '../../domain/repositories/category_repository.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return SupabaseCategoryRepository();
});

class CategoryState {
  final List<CourseCategory> categories;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;
  final String statusFilter; // 'all', 'active', 'inactive'

  const CategoryState({
    this.categories = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
    this.statusFilter = 'all',
  });

  List<CourseCategory> get filteredCategories {
    return categories.where((c) {
      final matchesSearch =
          searchQuery.isEmpty ||
          c.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          c.description.toLowerCase().contains(searchQuery.toLowerCase());

      final matchesStatus =
          statusFilter == 'all' ||
          (statusFilter == 'active' && c.isActive) ||
          (statusFilter == 'inactive' && !c.isActive);

      return matchesSearch && matchesStatus;
    }).toList();
  }

  int get activeCount => categories.where((c) => c.isActive).length;

  CategoryState copyWith({
    List<CourseCategory>? categories,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    String? statusFilter,
  }) {
    return CategoryState(
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }
}

class CategoryNotifier extends StateNotifier<CategoryState> {
  final CategoryRepository _repository;
  final Ref? _ref;

  CategoryNotifier(this._repository, [this._ref])
    : super(const CategoryState()) {
    loadCategories();
  }

  String? get errorMessage => state.errorMessage;

  Future<void> loadCategories() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final items = await _repository.getCategories();
      state = state.copyWith(categories: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setStatusFilter(String filter) {
    state = state.copyWith(statusFilter: filter);
  }

  /// Checks whether a category name is already registered (case-insensitive, trimmed).
  /// [excludeCategoryId] allows editing a category without flagging its own name as a duplicate.
  bool isNameDuplicate(String name, {String? excludeCategoryId}) {
    final trimmed = name.trim().toLowerCase();
    if (trimmed.isEmpty) return false;
    return state.categories.any((c) {
      if (excludeCategoryId != null && c.id == excludeCategoryId) {
        return false;
      }
      return c.name.trim().toLowerCase() == trimmed;
    });
  }

  String _formatErrorMessage(dynamic e) {
    final str = e.toString();
    if (str.contains('updated_at') ||
        str.contains('has no field "updated_at"')) {
      return 'Database schema missing "updated_at" on course_categories. Please execute migration 20261102000001.';
    }
    if (str.contains('23505') ||
        str.toLowerCase().contains('unique') ||
        str.toLowerCase().contains('duplicate')) {
      return 'A category with this name already exists. Please choose a unique name.';
    }
    if (str.contains('42501') ||
        str.toLowerCase().contains('permission') ||
        str.toLowerCase().contains('policy') ||
        str.toLowerCase().contains('row-level security')) {
      return 'Administrative privileges required to modify categories.';
    }
    if (str.startsWith('PostgrestException(')) {
      final match = RegExp(r'message:\s*([^,]+)').firstMatch(str);
      if (match != null && match.group(1) != null) {
        return match.group(1)!.trim();
      }
    }
    return str;
  }

  Future<bool> createCategory({
    required String name,
    required String description,
    required String color,
    String? iconName,
    bool isActive = true,
  }) async {
    final trimmedName = name.trim();
    final trimmedDesc = description.trim();
    final trimmedColor = color.trim();

    if (trimmedName.isEmpty) {
      state = state.copyWith(errorMessage: 'Please enter category name');
      return false;
    }

    if (isNameDuplicate(trimmedName)) {
      state = state.copyWith(
        errorMessage:
            'A category named "$trimmedName" already exists. Please choose a unique name.',
      );
      return false;
    }

    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      final created = await _repository.createCategory(
        name: trimmedName,
        description: trimmedDesc,
        color: trimmedColor,
        iconName: iconName,
        isActive: isActive,
      );
      state = state.copyWith(
        categories: [
          ...state.categories.where((c) => c.id != created.id),
          created,
        ],
        isLoading: false,
        errorMessage: null,
      );
      _ref?.invalidate(dashboardStatsProvider);
      await loadCategories(); // Refresh telemetry counts
      return true;
    } catch (e) {
      final msg = _formatErrorMessage(e);
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    }
  }

  Future<bool> updateCategory(
    String id, {
    String? name,
    String? description,
    String? color,
    String? iconName,
    bool? isActive,
  }) async {
    final trimmedName = name?.trim();
    final trimmedDesc = description?.trim();
    final trimmedColor = color?.trim();

    if (trimmedName != null && trimmedName.isEmpty) {
      state = state.copyWith(errorMessage: 'Category name cannot be empty');
      return false;
    }

    // Do not flag the category currently being edited as a duplicate
    if (trimmedName != null &&
        isNameDuplicate(trimmedName, excludeCategoryId: id)) {
      state = state.copyWith(
        errorMessage:
            'A category named "$trimmedName" already exists. Please choose a unique name.',
      );
      return false;
    }

    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      final updated = await _repository.updateCategory(
        id,
        name: trimmedName,
        description: trimmedDesc,
        color: trimmedColor,
        iconName: iconName,
        isActive: isActive,
      );
      // Immediately reflect updated category in state
      state = state.copyWith(
        categories: state.categories
            .map((c) => c.id == id ? updated : c)
            .toList(),
        isLoading: false,
        errorMessage: null,
      );
      _ref?.invalidate(dashboardStatsProvider);
      await loadCategories();
      return true;
    } catch (e) {
      final msg = _formatErrorMessage(e);
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    }
  }

  Future<void> toggleActive(String id, bool currentStatus) async {
    try {
      await _repository.toggleCategoryActive(id, !currentStatus);
      _ref?.invalidate(dashboardStatsProvider);
      await loadCategories();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await _repository.deleteCategory(id);
      state = state.copyWith(
        categories: state.categories.where((c) => c.id != id).toList(),
      );
      _ref?.invalidate(dashboardStatsProvider);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }
}

final categoryNotifierProvider =
    StateNotifierProvider<CategoryNotifier, CategoryState>((ref) {
      final repo = ref.watch(categoryRepositoryProvider);
      return CategoryNotifier(repo, ref);
    });

final categoryDetailFamily =
    FutureProvider.family<
      ({
        CourseCategory? category,
        List<Map<String, dynamic>> courses,
        List<Map<String, dynamic>> instructors,
        List<Map<String, dynamic>> students,
      }),
      String
    >((ref, categoryId) async {
      final repo = ref.watch(categoryRepositoryProvider);
      final cat = await repo.getCategoryById(categoryId);
      final courses = await repo.getCoursesForCategory(categoryId);
      final instructors = await repo.getInstructorsForCategory(categoryId);
      final students = await repo.getStudentsForCategory(categoryId);

      return (
        category: cat,
        courses: courses,
        instructors: instructors,
        students: students,
      );
    });

final studentCategoriesFamily =
    FutureProvider.family<List<CourseCategory>, String>((ref, studentId) async {
      final repo = ref.watch(categoryRepositoryProvider);
      return repo.getCategoriesForStudent(studentId);
    });

final instructorCategoriesFamily =
    FutureProvider.family<List<CourseCategory>, String>((
      ref,
      instructorId,
    ) async {
      final repo = ref.watch(categoryRepositoryProvider);
      return repo.getCategoriesForInstructor(instructorId);
    });
