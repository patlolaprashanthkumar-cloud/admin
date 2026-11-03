import 'package:flutter_test/flutter_test.dart';
import 'package:iiecm_admin/features/categories/domain/models/course_category.dart';
import 'package:iiecm_admin/features/categories/domain/repositories/category_repository.dart';
import 'package:iiecm_admin/features/categories/presentation/providers/category_provider.dart';

class MockCategoryRepository implements CategoryRepository {
  List<CourseCategory> store = [];

  MockCategoryRepository([List<CourseCategory>? initial]) {
    store = initial ?? [];
  }

  @override
  Future<List<CourseCategory>> getCategories({bool? onlyActive}) async {
    if (onlyActive == true) {
      return store.where((c) => c.isActive).toList();
    }
    return List.from(store);
  }

  @override
  Future<CourseCategory?> getCategoryById(String id) async {
    try {
      return store.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<CourseCategory> createCategory({
    required String name,
    required String description,
    required String color,
    String? iconName,
    bool isActive = true,
  }) async {
    final cat = CourseCategory(
      id: 'cat-${store.length + 1}',
      name: name,
      description: description,
      color: color,
      iconName: iconName,
      isActive: isActive,
      courseCount: 0,
      instructorCount: 0,
      studentCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    store.add(cat);
    return cat;
  }

  @override
  Future<CourseCategory> updateCategory(
    String id, {
    String? name,
    String? description,
    String? color,
    String? iconName,
    bool? isActive,
  }) async {
    final index = store.indexWhere((c) => c.id == id);
    final current = store[index];
    final updated = current.copyWith(
      name: name,
      description: description,
      color: color,
      iconName: iconName,
      isActive: isActive,
    );
    store[index] = updated;
    return updated;
  }

  @override
  Future<void> toggleCategoryActive(String id, bool isActive) async {
    final index = store.indexWhere((c) => c.id == id);
    if (index != -1) {
      store[index] = store[index].copyWith(isActive: isActive);
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    store.removeWhere((c) => c.id == id);
  }

  @override
  Future<List<Map<String, dynamic>>> getCoursesForCategory(
    String categoryId,
  ) async => [];

  @override
  Future<List<Map<String, dynamic>>> getInstructorsForCategory(
    String categoryId,
  ) async => [];

  @override
  Future<List<Map<String, dynamic>>> getStudentsForCategory(
    String categoryId,
  ) async => [];

  final Map<String, List<String>> _studentCats = {};
  final Map<String, List<String>> _instructorCats = {};

  @override
  Future<List<CourseCategory>> getCategoriesForStudent(String studentId) async {
    final ids = _studentCats[studentId] ?? [];
    return store.where((c) => ids.contains(c.id)).toList();
  }

  @override
  Future<void> assignCategoriesToStudent(
    String studentId,
    List<String> categoryIds,
  ) async {
    _studentCats.putIfAbsent(studentId, () => []).addAll(categoryIds);
  }

  @override
  Future<void> removeCategoryFromStudent(
    String studentId,
    String categoryId,
  ) async {
    _studentCats[studentId]?.remove(categoryId);
  }

  @override
  Future<List<CourseCategory>> getCategoriesForInstructor(
    String instructorId,
  ) async {
    final ids = _instructorCats[instructorId] ?? [];
    return store.where((c) => ids.contains(c.id)).toList();
  }

  @override
  Future<void> assignCategoriesToInstructor(
    String instructorId,
    List<String> categoryIds,
  ) async {
    _instructorCats.putIfAbsent(instructorId, () => []).addAll(categoryIds);
  }

  @override
  Future<void> removeCategoryFromInstructor(
    String instructorId,
    String categoryId,
  ) async {
    _instructorCats[instructorId]?.remove(categoryId);
  }
}

void main() {
  group('CourseCategory Model Tests', () {
    test('Constructs CourseCategory correctly from JSON map', () {
      final json = {
        'id': 'cat-123',
        'name': 'Emergency Critical Care',
        'description': 'Advanced life support and resuscitation algorithms',
        'color': '#245B43',
        'is_active': true,
        'icon_name': 'emergency',
        'created_at': '2026-10-28T12:00:00Z',
        'updated_at': '2026-10-28T12:00:00Z',
      };

      final cat = CourseCategory.fromJson(
        json,
        courseCount: 4,
        instructorCount: 2,
        studentCount: 35,
      );

      expect(cat.id, 'cat-123');
      expect(cat.name, 'Emergency Critical Care');
      expect(
        cat.description,
        'Advanced life support and resuscitation algorithms',
      );
      expect(cat.color, '#245B43');
      expect(cat.isActive, true);
      expect(cat.iconName, 'emergency');
      expect(cat.courseCount, 4);
      expect(cat.instructorCount, 2);
      expect(cat.studentCount, 35);
    });

    test('CourseCategory copyWith updates selected fields immutably', () {
      final original = CourseCategory(
        id: 'cat-1',
        name: 'Surgery',
        description: 'Surgical foundations',
        color: '#1A4331',
        isActive: true,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final updated = original.copyWith(
        name: 'Trauma Surgery',
        isActive: false,
      );

      expect(updated.id, 'cat-1');
      expect(updated.name, 'Trauma Surgery');
      expect(updated.description, 'Surgical foundations');
      expect(updated.isActive, false);
      expect(original.name, 'Surgery');
      expect(original.isActive, true);
    });
  });

  group('CategoryState and Notifier Tests', () {
    test('Filters categories by search query and active status', () {
      final list = [
        CourseCategory(
          id: '1',
          name: 'Pediatric Care',
          description: 'Child medicine',
          color: '#245B43',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        CourseCategory(
          id: '2',
          name: 'Adult Resuscitation',
          description: 'Emergency response protocols',
          color: '#C87552',
          isActive: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        CourseCategory(
          id: '3',
          name: 'Disaster Management',
          description: 'Mass casualty and triage protocols',
          color: '#1E3A8A',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      var state = CategoryState(categories: list);
      expect(state.filteredCategories.length, 3);
      expect(state.activeCount, 2);

      // Search
      state = state.copyWith(searchQuery: 'protocols');
      expect(state.filteredCategories.length, 2);

      // Status filter
      state = state.copyWith(statusFilter: 'active');
      expect(state.filteredCategories.length, 1);
      expect(state.filteredCategories.first.name, 'Disaster Management');
    });

    test('CategoryNotifier performs CRUD operations seamlessly', () async {
      final repo = MockCategoryRepository();
      final notifier = CategoryNotifier(repo);

      // Wait initial load
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(notifier.state.categories.isEmpty, true);

      // Create
      final ok = await notifier.createCategory(
        name: 'Critical Diagnostics',
        description: 'ECG and point of care ultrasound',
        color: '#245B43',
        iconName: 'analytics',
        isActive: true,
      );

      expect(ok, true);
      expect(notifier.state.categories.length, 1);
      expect(notifier.state.categories.first.name, 'Critical Diagnostics');

      final catId = notifier.state.categories.first.id;

      // Toggle Active
      await notifier.toggleActive(catId, true);
      expect(notifier.state.categories.first.isActive, false);

      // Update
      await notifier.updateCategory(
        catId,
        name: 'Advanced Ultrasound & Diagnostics',
      );
      expect(
        notifier.state.categories.first.name,
        'Advanced Ultrasound & Diagnostics',
      );

      // Delete
      await notifier.deleteCategory(catId);
      expect(notifier.state.categories.isEmpty, true);
    });

    test('Category uniqueness validation handles create, edit, whitespace and case-insensitivity', () async {
      final repo = MockCategoryRepository();
      final notifier = CategoryNotifier(repo);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // 1. Create initial category
      final ok1 = await notifier.createCategory(
        name: 'Emergency Medicine',
        description: 'First response emergency care',
        color: '#245B43',
      );
      expect(ok1, true);
      expect(notifier.state.categories.length, 1);
      final firstCatId = notifier.state.categories.first.id;

      // 2. Create second category
      final ok2 = await notifier.createCategory(
        name: 'Pediatric Care',
        description: 'Child healthcare and resuscitation',
        color: '#C87552',
      );
      expect(ok2, true);
      expect(notifier.state.categories.length, 2);

      // 3. Attempt to create exact duplicate
      final dup1 = await notifier.createCategory(
        name: 'Emergency Medicine',
        description: 'Duplicate attempt',
        color: '#123456',
      );
      expect(dup1, false);
      expect(notifier.state.errorMessage, contains('already exists'));

      // 4. Attempt to create case-insensitive and trimmed duplicate
      final dup2 = await notifier.createCategory(
        name: '  emergency medicine  ',
        description: 'Case-insensitive duplicate',
        color: '#123456',
      );
      expect(dup2, false);
      expect(notifier.state.errorMessage, contains('already exists'));

      // 5. Edit existing category WITHOUT changing name (must SUCCEED)
      final editSameName = await notifier.updateCategory(
        firstCatId,
        name: 'Emergency Medicine',
        description: 'Updated description for emergency care',
      );
      expect(editSameName, true);
      expect(
        notifier.state.categories
            .firstWhere((c) => c.id == firstCatId)
            .description,
        'Updated description for emergency care',
      );

      // 6. Edit existing category with case/trimmed variation of its own name (must SUCCEED)
      final editOwnTrimmed = await notifier.updateCategory(
        firstCatId,
        name: '  Emergency Medicine  ',
      );
      expect(editOwnTrimmed, true);

      // 7. Edit existing category to another category's name (must FAIL)
      final editToOtherCat = await notifier.updateCategory(
        firstCatId,
        name: 'Pediatric Care',
      );
      expect(editToOtherCat, false);
      expect(notifier.state.errorMessage, contains('already exists'));

      // 8. Edit existing category to a brand new unused name (must SUCCEED)
      final editNewName = await notifier.updateCategory(
        firstCatId,
        name: 'Trauma & Emergency Medicine',
      );
      expect(editNewName, true);
      expect(
        notifier.state.categories.firstWhere((c) => c.id == firstCatId).name,
        'Trauma & Emergency Medicine',
      );
    });
  });
}
