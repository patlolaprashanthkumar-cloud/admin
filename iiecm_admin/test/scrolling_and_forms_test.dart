import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iiecm_admin/app/theme/app_theme.dart';
import 'package:iiecm_admin/features/categories/domain/models/course_category.dart';
import 'package:iiecm_admin/features/categories/domain/repositories/category_repository.dart';
import 'package:iiecm_admin/features/categories/presentation/providers/category_provider.dart';
import 'package:iiecm_admin/features/categories/presentation/widgets/category_form_sheet.dart';
import 'package:iiecm_admin/features/courses/domain/models/course.dart';
import 'package:iiecm_admin/features/courses/domain/models/course_lesson.dart';
import 'package:iiecm_admin/features/courses/domain/models/course_module.dart';
import 'package:iiecm_admin/features/courses/domain/repositories/course_repository.dart';
import 'package:iiecm_admin/features/courses/presentation/providers/courses_provider.dart';
import 'package:iiecm_admin/features/courses/presentation/widgets/course_form_sheet.dart';
import 'package:iiecm_admin/features/students/domain/models/student.dart';
import 'package:iiecm_admin/features/students/domain/repositories/student_repository.dart';
import 'package:iiecm_admin/features/students/presentation/providers/students_provider.dart';
import 'package:iiecm_admin/features/students/presentation/screens/add_student_wizard.dart';

class MockTestCategoryRepo implements CategoryRepository {
  List<CourseCategory> list = [];
  MockTestCategoryRepo(this.list);

  @override
  Future<List<CourseCategory>> getCategories({bool? onlyActive}) async => list;
  @override
  Future<CourseCategory?> getCategoryById(String id) async =>
      list.firstWhere((c) => c.id == id);
  @override
  Future<CourseCategory> createCategory({
    required String name,
    required String description,
    required String color,
    String? iconName,
    bool isActive = true,
  }) async {
    final cat = CourseCategory(
      id: 'c-new',
      name: name,
      description: description,
      color: color,
      iconName: iconName,
      isActive: isActive,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    list.add(cat);
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
  }) async => list.first;
  @override
  Future<void> toggleCategoryActive(String id, bool isActive) async {}
  @override
  Future<void> deleteCategory(String id) async {}
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
  @override
  Future<List<CourseCategory>> getCategoriesForStudent(
    String studentId,
  ) async => [];
  @override
  Future<void> assignCategoriesToStudent(
    String studentId,
    List<String> categoryIds,
  ) async {}
  @override
  Future<void> removeCategoryFromStudent(
    String studentId,
    String categoryId,
  ) async {}
  @override
  Future<List<CourseCategory>> getCategoriesForInstructor(
    String instructorId,
  ) async => [];
  @override
  Future<void> assignCategoriesToInstructor(
    String instructorId,
    List<String> categoryIds,
  ) async {}
  @override
  Future<void> removeCategoryFromInstructor(
    String instructorId,
    String categoryId,
  ) async {}
}

class MockTestCourseRepo implements CourseRepository {
  List<Course> list = [];
  MockTestCourseRepo(this.list);

  @override
  Future<List<Course>> getCourses({
    String? categoryId,
    String? status,
    String? searchQuery,
  }) async => list;
  @override
  Future<Course?> getCourseById(String id) async => list.first;
  @override
  Future<Course> createCourse({
    required String title,
    required String description,
    required String categoryId,
    required String categoryName,
    String? instructorId,
    int durationWeeks = 8,
    double fee = 0.0,
    String format = 'hybrid',
    String status = 'draft',
  }) async {
    final crs = Course(
      id: 'crs-new',
      title: title,
      description: description,
      categoryId: categoryId,
      categoryName: categoryName,
      durationWeeks: durationWeeks,
      fee: fee,
      format: format,
      status: status,
      createdAt: DateTime.now(),
    );
    list.add(crs);
    return crs;
  }

  @override
  Future<Course> updateCourse(
    String id, {
    String? title,
    String? description,
    String? categoryId,
    String? categoryName,
    String? instructorId,
    int? durationWeeks,
    double? fee,
    String? format,
    String? status,
  }) async => list.first;
  @override
  Future<void> deleteCourse(String id) async {}

  @override
  Future<List<CourseModule>> getModules(String courseId) async => [];
  @override
  Future<CourseModule> createModule(CourseModule module) async => module;
  @override
  Future<CourseModule> updateModule(CourseModule module) async => module;
  @override
  Future<void> deleteModule(String moduleId) async {}
  @override
  Future<CourseLesson> createLesson(CourseLesson lesson) async => lesson;
  @override
  Future<CourseLesson> updateLesson(CourseLesson lesson) async => lesson;
  @override
  Future<void> deleteLesson(String lessonId) async {}
}

class MockTestStudentRepo implements StudentRepository {
  List<Student> list = [];
  MockTestStudentRepo(this.list);

  @override
  Future<List<Student>> getStudents({
    String? categoryId,
    String? searchQuery,
    String? status,
  }) async => list;
  @override
  Future<Student?> getStudentById(String id) async => list.first;
  @override
  Future<StudentRegistrationResult> registerStudent({
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
    final s = Student(
      id: 'std-new',
      studentId: 'IIECM-NEW',
      fullName: fullName,
      email: email,
      phone: phone,
      educationLevel: educationLevel,
      qualification: qualification,
      preferredCategory: 'Test',
      createdAt: DateTime.now(),
    );
    list.add(s);
    return StudentRegistrationResult(
      student: s,
      statusCode: 201,
      isExistingUser: false,
      invitationSent: true,
      message: 'Student registered successfully',
    );
  }

  @override
  Future<Student> updateStudent(
    String id, {
    String? fullName,
    String? email,
    String? phone,
    String? educationLevel,
    String? qualification,
    String? city,
    String? accountStatus,
  }) async => list.first;
  @override
  Future<void> updateStudentCategories(
    String studentId,
    List<String> categoryIds,
  ) async {}
  @override
  Future<List<StudentCategoryLmsGroup>> getStudentCategoryLmsDetails(
    String studentId,
  ) async => [];
}

void main() {
  final sampleCategory = CourseCategory(
    id: 'cat-1',
    name: 'Emergency Medicine',
    description: 'Comprehensive trauma and emergency resuscitation protocols.',
    color: '#245B43',
    iconName: 'emergency',
    isActive: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final sampleCourse = Course(
    id: 'crs-1',
    title: 'Advanced Airway Protocol',
    description: 'Rapid sequence intubation and surgical airway management.',
    categoryId: 'cat-1',
    categoryName: 'Emergency Medicine',
    durationWeeks: 8,
    fee: 12000.0,
    format: 'hybrid',
    status: 'published',
    createdAt: DateTime.now(),
  );

  group('CategoryFormSheet Scrolling & Button Accessibility', () {
    testWidgets(
      'Add Category shows docked Create Category button on small screen without scrolling',
      (tester) async {
        // Simulate compact phone screen: 360 x 640
        tester.view.physicalSize = const Size(360 * 2, 640 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: CategoryFormSheet(
                onSave: ({
                  required name,
                  required description,
                  required color,
                  iconName,
                  isActive = true,
                }) async => true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // "Create Category" and "Cancel" buttons must be visible immediately
        expect(find.text('Create Category'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);

        // The form body is scrollable
        final scrollableFinder = find.byType(SingleChildScrollView);
        expect(scrollableFinder, findsOneWidget);

        // Scroll form body down
        await tester.drag(scrollableFinder, const Offset(0, -300));
        await tester.pumpAndSettle();

        // Buttons are still visible and docked
        expect(find.text('Create Category'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
      },
    );

    testWidgets(
      'Edit Category shows docked Save Changes button with keyboard visible',
      (tester) async {
        // Simulate keyboard opening: 300dp bottom inset
        tester.view.physicalSize = const Size(400 * 2, 750 * 2);
        tester.view.devicePixelRatio = 2.0;
        tester.view.viewInsets = const FakeViewPadding(bottom: 300 * 2);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: CategoryFormSheet(
                initialCategory: sampleCategory,
                onSave: ({
                  required name,
                  required description,
                  required color,
                  iconName,
                  isActive = true,
                }) async => true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify "Save Changes" is docked above the keyboard and accessible
        expect(find.text('Save Changes'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);

        // Verify form is scrollable above keyboard
        final scrollableFinder = find.byType(SingleChildScrollView);
        expect(scrollableFinder, findsOneWidget);
        await tester.drag(scrollableFinder, const Offset(0, -200));
        await tester.pumpAndSettle();

        expect(find.text('Save Changes'), findsOneWidget);
      },
    );
  });

  group('CourseFormSheet Scrolling & Button Accessibility', () {
    testWidgets(
      'CourseFormSheet has accessible Create Course button and scrollable fields',
      (tester) async {
        tester.view.physicalSize = const Size(360 * 2, 640 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: CourseFormSheet(
                  onSave: ({
                    required title,
                    required description,
                    required categoryId,
                    required categoryName,
                    durationWeeks = 8,
                    fee = 0.0,
                    format = 'hybrid',
                    instructorId,
                    status = 'draft',
                  }) async => true,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Create Course'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);

        final scrollableFinder = find.byType(SingleChildScrollView);
        expect(scrollableFinder, findsOneWidget);
        await tester.drag(scrollableFinder, const Offset(0, -250));
        await tester.pumpAndSettle();

        expect(find.text('Create Course'), findsOneWidget);
      },
    );
  });

  group('AddStudentWizard Scrolling & Navigation Controls', () {
    testWidgets(
      'Wizard displays Step 1 with scrollable inputs and docked Continue button',
      (tester) async {
        final catRepo = MockTestCategoryRepo([sampleCategory]);
        final crsRepo = MockTestCourseRepo([sampleCourse]);
        final stdRepo = MockTestStudentRepo([]);

        // Small screen
        tester.view.physicalSize = const Size(360 * 2, 600 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              categoryRepositoryProvider.overrideWithValue(catRepo),
              courseRepositoryProvider.overrideWithValue(crsRepo),
              studentRepositoryProvider.overrideWithValue(stdRepo),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const AddStudentWizard(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Header, Step, and docked Continue button must be visible
        expect(find.text('Step 1 of 6'), findsOneWidget);
        expect(find.text('Continue'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);

        // Verify scroll view exists and scrolls
        final scrollable = find.byType(SingleChildScrollView);
        expect(scrollable, findsOneWidget);

        await tester.drag(scrollable, const Offset(0, -300));
        await tester.pumpAndSettle();

        // Navigation buttons remain docked and visible
        expect(find.text('Continue'), findsOneWidget);
      },
    );

    testWidgets(
      'Step 1 validates required fields and advances to Step 2 when filled',
      (tester) async {
        final catRepo = MockTestCategoryRepo([sampleCategory]);
        final crsRepo = MockTestCourseRepo([sampleCourse]);
        final stdRepo = MockTestStudentRepo([]);

        tester.view.physicalSize = const Size(400 * 2, 800 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              categoryRepositoryProvider.overrideWithValue(catRepo),
              courseRepositoryProvider.overrideWithValue(crsRepo),
              studentRepositoryProvider.overrideWithValue(stdRepo),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const AddStudentWizard(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Enter Name, Email, Phone, City, Qualification
        final textFields = find.byType(TextFormField);
        await tester.enterText(textFields.at(0), 'Dr. Rajesh Khanna');
        await tester.enterText(textFields.at(1), 'rajesh@hospital.org');
        await tester.enterText(textFields.at(2), '9876543210');
        await tester.enterText(textFields.at(3), 'Mumbai');
        await tester.enterText(textFields.at(4), 'MBBS, MD');

        // Tap Continue
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Must be on Step 2
        expect(find.text('Step 2 of 6'), findsOneWidget);
        expect(find.text('Previous'), findsOneWidget);
        expect(find.text('Continue'), findsOneWidget);
      },
    );
  });
}
