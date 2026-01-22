# Code Standards & Conventions

**Last Updated:** Jan 22, 2026
**Applies To:** All Dart/Flutter code in Meup project

---

## 1. Architecture Pattern: Clean Architecture + BLoC

### Layer Separation (Mandatory)
```
Presentation Layer (Pages, Widgets, Cubits)
         ↓
Domain Layer (Entities, Repository Interfaces, Use Cases)
         ↓
Data Layer (Models, APIs, Repository Implementations, Data Sources)
```

### Rules
- **Never** import data types in presentation (no Dio, Retrofit, or Models)
- **Never** import presentation types in domain/data
- Domain layer must be **platform-agnostic** (no Flutter imports except for value types)
- Repository interface lives in domain, implementation in data

---

## 2. State Management: BLoC/Cubit Pattern

### Cubit Structure
```dart
class CourseCubit extends Cubit<CourseState> with CubitUseCaseHandlerMixin {
  final GetCoursesUseCase _getCoursesUseCase;

  CourseCubit(this._getCoursesUseCase) : super(const CourseState.initial());

  void loadCourses() {
    runUseCase<List<CourseEntity>>(
      useCase: () => _getCoursesUseCase(const PageBreakRequest()),
      onSuccess: (courses) => emit(CourseState.success(courses: courses)),
    );
  }
}
```

### State Definition with Freezed
```dart
@freezed
class CourseState with _$CourseState {
  const factory CourseState.initial() = _Initial;
  const factory CourseState.loading() = _Loading;
  const factory CourseState.success({required List<CourseEntity> courses}) = _Success;
  const factory CourseState.failure({required String errorMessage}) = _Failure;
}
```

### Cubit vs BLoC
- **Use Cubit:** Simple states, single source of truth, function-driven
- **Use BLoC:** Complex multi-event flows, multiple listeners (e.g., AuthBloc)
- Prefer Cubits for new features

### HydratedCubit (Persistence)
```dart
class ThemeCubit extends HydratedCubit<ThemeMode> {
  @override
  ThemeMode get initialState => ThemeMode.light;

  @override
  ThemeMode? fromJson(Map<String, dynamic> json) {
    return ThemeMode.values[json['index'] as int];
  }

  @override
  Map<String, dynamic>? toJson(ThemeMode state) {
    return {'index': state.index};
  }
}
```

---

## 3. Error Handling: Functional with TaskEither

### Use Case Pattern
```dart
abstract class UseCase<Type, Params> {
  TaskEither<AppException, Type> call(Params params);
}

class GetUserUseCase extends UseCase<UserEntity, String> {
  final UserRepository _repository;

  GetUserUseCase(this._repository);

  @override
  TaskEither<AppException, UserEntity> call(String userId) {
    return _repository.getUserById(userId);
  }
}
```

### AppException Sealed Class
```dart
sealed class AppException {
  // Generic errors
  factory AppException.generic({String? message}) = _Generic;
  factory AppException.server({String? statusCode}) = _Server;
  factory AppException.connection() = _Connection;
  factory AppException.database() = _Database;

  // HTTP errors
  factory AppException.notFound() = _NotFound;
  factory AppException.unauthorized() = _Unauthorized;
  factory AppException.invalidInput({String? field}) = _InvalidInput;

  String get message; // Raw error message
  String get displayMessage; // User-friendly message
}
```

### Repository Implementation
```dart
class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource _remoteDataSource;

  @override
  TaskEither<AppException, UserEntity> getUserById(String userId) {
    return TaskEither.tryCatch(
      () async => (await _remoteDataSource.getUserById(userId)).toEntity(),
      (error, stackTrace) => AppException.server(statusCode: '500'),
    );
  }
}
```

### In Cubits (Using Mixin)
```dart
void loadUser(String userId) {
  runUseCase<UserEntity>(
    useCase: () => _getUserUseCase(userId),
    onSuccess: (user) {
      emit(UserState.success(user: user));
    },
  );
  // Mixin handles loading state, error display automatically
}
```

---

## 4. Naming Conventions

### Files
| Item | Convention | Example |
|------|-----------|---------|
| Dart file | `snake_case` | `auth_bloc.dart`, `user_entity.dart` |
| Page | `{name}_page.dart` | `login_page.dart`, `course_page.dart` |
| Widget | `{name}_widget.dart` | `course_card.dart`, `lesson_item.dart` |
| Service | `{name}_service.dart` | `auth_service.dart`, `tracking_service.dart` |
| Use Case | `{name}_use_case.dart` | `login_use_case.dart`, `get_courses_use_case.dart` |
| Repository | `{name}_repository_impl.dart` | `user_repository_impl.dart` |
| Data Source | `{name}_data_source.dart` | `user_remote_data_source.dart` |

### Classes & Types
| Item | Convention | Example |
|------|-----------|---------|
| Class | `PascalCase` | `LoginPage`, `CourseEntity`, `UserCubit` |
| Enum | `PascalCase` | `ExerciseType`, `UserRole` |
| Typedef | `PascalCase` | `UserCallback`, `ResultHandler` |
| Constant | `SCREAMING_SNAKE_CASE` | `API_BASE_URL`, `CACHE_KEY_USER` |

### Cubit/BLoC
| Item | Convention | Example |
|------|-----------|---------|
| Cubit | `{Name}Cubit` | `AuthCubit`, `CourseCubit` |
| BLoC | `{Name}Bloc` | `AuthBloc` |
| State | `{Name}State` | `AuthState`, `CourseState` |
| Event | `{Name}Event` | `AuthEvent`, `CourseEvent` |

### API & Endpoints
| Item | Convention | Example |
|------|-----------|---------|
| API Class | `{Name}Api` | `UserApi`, `CourseApi` |
| Endpoint | `/path/to/resource` | `/users/{id}`, `/courses?page=1` |
| Model (API) | `{Name}Model` | `UserModel`, `CourseModel` |
| Entity (Domain) | `{Name}Entity` | `UserEntity`, `CourseEntity` |

### Variables & Functions
```dart
// Local variables: camelCase
String firstName;
int itemCount;

// Private members: _camelCase prefix
String _privateField;
void _privateMethod() {}

// Function/Method: camelCase
void loadCourses() {}
Future<UserEntity> fetchUserById(String id) {}

// Callbacks: camelCase with Action/Callback suffix
Function onSuccess;
void Function(String) onError;
VoidCallback onTap;
```

---

## 5. Code Organization & File Structure

### Feature Module Structure (Mandatory)
```
lib/src/feature_name/
├── domain/
│   ├── entities/
│   │   ├── {entity}_entity.dart
│   │   └── ...
│   ├── repositories/
│   │   └── {repository}_repository.dart
│   └── use_cases/
│       ├── {use_case}_use_case.dart
│       └── ...
├── data/
│   ├── datasources/
│   │   ├── apis/
│   │   │   └── {name}_api.dart (Retrofit)
│   │   ├── local/
│   │   │   └── {name}_local_data_source.dart
│   │   └── remote/
│   │       └── {name}_remote_data_source.dart
│   ├── models/
│   │   ├── {model}_model.dart
│   │   └── ...
│   └── repositories/
│       └── {repository}_repository_impl.dart
└── presentation/
    ├── cubits/
    │   ├── {cubit}_cubit.dart
    │   └── ...
    ├── pages/
    │   ├── {page}_page.dart
    │   └── ...
    └── widgets/
        ├── {widget}_widget.dart
        └── ...
```

### Maximums Per File (IMPORTANT)
- **Max 200 lines per code file** (excluding generated code)
- **Split when approaching limit:** Create focused sub-widgets or services
- **Use composition over inheritance** for widgets
- **Extract utilities into separate files** for reusability

### Part File Usage (When Necessary)
```dart
// main_file.dart
library auth;

part 'auth_bloc.dart';
part 'auth_state.dart';
part 'auth_event.dart';
```

---

## 6. Code Generation Workflow

### Freezed (Immutable Classes)
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_entity.freezed.dart';
part 'user_entity.g.dart';

@freezed
class UserEntity with _$UserEntity {
  const factory UserEntity({
    required String id,
    required String name,
    String? email,
  }) = _UserEntity;

  factory UserEntity.fromJson(Map<String, dynamic> json) =>
      _$UserEntityFromJson(json);
}
```

**Usage:** Immutable, auto-equality, copyWith, pattern matching

### Retrofit (REST API)
```dart
import 'package:retrofit/retrofit.dart';
import 'package:dio/dio.dart';

part 'user_api.g.dart';

@RestApi(baseUrl: 'https://api.meup.com')
abstract class UserApi {
  factory UserApi(Dio dio, {String baseUrl}) = _UserApi;

  @GET('/users/{id}')
  Future<UserModel> getUser(@Path('id') String id);

  @POST('/users')
  Future<UserModel> createUser(@Body() UserModel user);

  @GET('/users')
  Future<List<UserModel>> listUsers(
    @Query('page') int page,
    @Query('limit') int limit,
  );
}
```

### Injectable (Dependency Injection)
```dart
@LazySingleton()
class UserService {
  final UserRepository _repository;

  UserService(this._repository);
}

@factoryMethod
Future<DatabaseConnection> provideDatabaseConnection() async {
  return DatabaseConnection();
}
```

### Go Router (Type-Safe Navigation)
```dart
@TypedGoRoute<CourseRoute>(
  path: '/course/:id',
  name: 'course',
  routes: [
    TypedGoRoute<LessonRoute>(
      path: 'lesson/:lessonId',
      name: 'lesson',
    ),
  ],
)
class CourseRoute extends GoRouteData {
  final String id;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return CupertinoPage(
      child: CoursePage(courseId: id),
    );
  }
}
```

**Command to regenerate all:**
```bash
dart run build_runner build --delete-conflicting-outputs
dart run build_runner watch --delete-conflicting-outputs  # Development
```

---

## 7. Testing Patterns

### Unit Test Structure
```dart
void main() {
  group('GetUserUseCase', () {
    late GetUserUseCase useCase;
    late MockUserRepository mockRepository;

    setUp(() {
      mockRepository = MockUserRepository();
      useCase = GetUserUseCase(mockRepository);
    });

    test('returns UserEntity when repository succeeds', () async {
      // Arrange
      final user = UserEntity(id: '1', name: 'John');
      when(mockRepository.getUserById('1'))
          .thenAnswer((_) => TaskEither.right(user));

      // Act
      final result = await useCase('1').run();

      // Assert
      expect(result.isRight(), true);
      expect(result.getOrElse((_) => null), user);
    });

    test('returns AppException on failure', () async {
      // Arrange
      when(mockRepository.getUserById('1'))
          .thenAnswer((_) => TaskEither.left(AppException.notFound()));

      // Act
      final result = await useCase('1').run();

      // Assert
      expect(result.isLeft(), true);
    });
  });
}
```

### Cubit Test Structure
```dart
void main() {
  group('CourseCubit', () {
    late CourseCubit cubit;
    late MockGetCoursesUseCase mockUseCase;

    setUp(() {
      mockUseCase = MockGetCoursesUseCase();
      cubit = CourseCubit(mockUseCase);
    });

    blocTest<CourseCubit, CourseState>(
      'emits loading then success when courses loaded',
      build: () {
        final courses = [CourseEntity(id: '1', title: 'English')];
        when(mockUseCase(...)).thenAnswer(
          (_) => TaskEither.right(courses),
        );
        return cubit;
      },
      act: (cubit) => cubit.loadCourses(),
      expect: () => [
        isA<CourseState>().having(...),  // loading
        isA<CourseState>().having(...),  // success
      ],
    );
  });
}
```

### Mock Creation
```dart
import 'package:mockito/mockito.dart';

class MockUserRepository extends Mock implements UserRepository {}
class MockGetUserUseCase extends Mock implements GetUserUseCase {}

// Or using Mockito generators (requires build_runner)
```

---

## 8. Commit Message Format

### Convention (Conventional Commits)
```
type-TICKET-ID: subject
```

### Structure
- **Type:** `feature`, `fix`, `refactor`, `style`, `docs`, `test`, `chore`, `perf`
- **TICKET-ID:** Extracted from branch (e.g., `MEUP-123`)
- **Subject:** Imperative, lowercase, no period, max 50 chars

### Examples
```
feature-MEUP-123: add course roadmap visualization
fix-MEUP-456: resolve lesson loading timeout
refactor-MEUP-789: simplify exercise state management
docs-MEUP-101: update authentication guide
test-MEUP-202: add unit tests for progress tracking
```

### Extraction
From branch `feature/MEUP-123-add-login`:
- Type: `feature`
- Ticket ID: `MEUP-123`
- Subject: Commit description

---

## 9. Code Quality Standards

### Analyzer Configuration
**File:** `analysis_options.yaml`

```yaml
linter:
  rules:
    - avoid_empty_else
    - avoid_null_checks_in_equality_operators
    - prefer_final_in_for_each
    - prefer_single_quotes
    - unnecessary_const
    - unnecessary_constructor_name
```

**Excluded files (auto-generated):**
```yaml
exclude:
  - '**/*.g.dart'
  - '**/*.freezed.dart'
  - '**/*.graphql.dart'
  - '**/config/routes/routes.g.dart'
```

### Running Analysis
```bash
flutter analyze                     # Static analysis
dart format lib/ test/              # Auto-format (180 char width)
flutter test                        # Run all tests
flutter test test/unit/             # Specific test directory
```

### Pre-Commit Checks (MANDATORY)
1. Run `flutter analyze` - Fix linter warnings
2. Run `dart format lib/ test/` - Auto-format code
3. Run `flutter test` - Ensure all tests pass
4. Verify no secrets in .env files (.gitignored)
5. Commit with conventional message format

---

## 10. Anti-Patterns & Forbidden Practices

### ❌ NEVER
```dart
// 1. Import data types in presentation
import 'package:dio/dio.dart';  // ❌ FORBIDDEN in presentation layer
import 'package:retrofit/retrofit.dart';  // ❌ FORBIDDEN

// 2. Use try-catch in domain layer
try {
  return repository.getData();  // ❌ Should use TaskEither
} catch (e) {
  // ...
}

// 3. Hardcode strings in widgets
Text('Hello World');  // ❌ Should use localization

// 4. Large files (> 200 LOC)
class MegaWidget extends StatefulWidget {
  // ... 500 lines of code  // ❌ Split into smaller widgets
}

// 5. Widget state mutation
_courses = courses;  // ❌ In immutable state, use freezed

// 6. Bypass DI container
final service = UserService();  // ❌ Use getIt<UserService>()

// 7. Direct Dio/GraphQL in presentation
final response = await dio.get('/users');  // ❌ Use repository

// 8. Circular module imports
// auth imports course, course imports auth  // ❌ Refactor

// 9. Multiple responsibilities per Cubit
// CourseCubit handles loading + filtering + sorting  // ❌ Create separate cubits

// 10. Ignored test failures
// flutter test  // Output: 3 tests failed  // ❌ ALWAYS fix
```

### ✅ DO

```dart
// 1. Proper layer separation
// Presentation imports domain, domain stands alone
import 'package:meup/src/course/domain/repositories/course_repository.dart';

// 2. Use TaskEither in domain
TaskEither<AppException, CourseEntity> getCourse(String id) {
  return repository.getCourseById(id);
}

// 3. Use localization
Text(context.l10n.courseTitle)

// 4. Keep files under 200 LOC
// Split large widgets into smaller, focused components

// 5. Immutable states with freezed
@freezed
class CourseState with _$CourseState {
  const factory CourseState.success({required List<CourseEntity> courses}) = _Success;
}

// 6. Use DI container
final cubit = getIt<CourseCubit>();

// 7. Access data via repository
final course = await _courseRepository.getCourseById(id);

// 8. Avoid circular dependencies
// Use dependency injection to break cycles

// 9. Single responsibility per Cubit
// CourseCubit: loads & selects course
// CourseFilterCubit: manages filters separately

// 10. Fix all test failures before commit
flutter test  // Must pass 100%
```

---

## 11. Documentation Comments

### Class Documentation
```dart
/// Manages user authentication and session lifecycle.
///
/// Handles login, logout, token refresh, and OAuth flows.
/// Persists auth state via HydratedCubit for app restarts.
class AuthCubit extends HydratedCubit<AuthState> {
  // ...
}
```

### Function Documentation
```dart
/// Loads courses from the backend with pagination.
///
/// Parameters:
/// - [page] - Page number (1-indexed)
/// - [limit] - Items per page
///
/// Returns:
/// - Success: List of [CourseEntity] objects
/// - Failure: [AppException] with error details
///
/// Throws:
/// - No exceptions (uses TaskEither for error handling)
Future<TaskEither<AppException, List<CourseEntity>>> loadCourses(
  int page,
  int limit,
) async {
  // ...
}
```

### Complex Logic Comments
```dart
// Calculate completion percentage based on attempts and passes
// Formula: (totalCorrectAnswers / totalAttempts) * 100
final completionPercentage = (correctAnswers / totalAttempts) * 100;
```

---

## 12. Localization Standards

### Key Naming (camelCase, module as namespace)
```yaml
# assets/i18n/en/course.yaml
courseCatalog: "Course Catalog"
courseTitle: "Course Title"
startLearning: "Start Learning"
completeLesson: "Complete Lesson"
```

### In Code (NEVER hardcode)
```dart
// ✅ CORRECT
Text(context.l10n.courseCatalog)

// ❌ WRONG
Text('Course Catalog')
```

### Workflow
```bash
# 1. Pull from Google Sheets
tools/macos/localization/localization.sh pull

# 2. Generate Dart code
dart run slang

# 3. Use in widgets
Text(context.l10n.keyName)
```

---

## 13. Security Standards

### Secrets Management
- **NEVER** commit `.env` files, API keys, keystores
- **ALWAYS** use `.gitignore` for sensitive files
- **USE** environment variables with `--dart-define-from-file`
- **Store** secrets in `.info/key/` (git-ignored)

### Data Protection
- Encrypt sensitive data in local storage
- Use HTTPS for all API calls
- Enable code obfuscation in release builds (`--obfuscate`)
- Use secure token storage (system keychain when possible)

### Error Handling
- Never expose sensitive info in error messages
- Log errors to Crashlytics (stripped of PII)
- Use generic error messages for users

---

## 14. Performance Guidelines

### Widget Optimization
```dart
// ❌ INEFFICIENT: Rebuilds entire tree
class CourseListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CourseCubit, CourseState>(
      builder: (context, state) {
        return ListView.builder(
          itemCount: courses.length,
          itemBuilder: (context, index) => CourseCard(...),  // Rebuilds all
        );
      },
    );
  }
}

// ✅ EFFICIENT: Individual items rebuild on change
class CourseCard extends StatelessWidget {
  final CourseEntity course;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CourseCardCubit, CourseCardState>(
      builder: (context, state) {
        return Card(child: ...);  // Only this item rebuilds
      },
    );
  }
}
```

### Memory Management
- Dispose controllers and listeners properly
- Use `late` for lazy initialization
- Avoid circular references in cubits
- Profile with DevTools before claiming performance

---

## 15. Service Patterns: Tracking & Remote Config

### Tracking Service (ITrackingService)
- **170+ event types** categorized: onboarding, course, lesson, roleplay, progress, payments
- Helper methods: `_courseParams()`, `_courseLessonParams()`, `_roleplayParams()` reduce parameter duplication
- Events sent to Firebase Analytics, Sentry, custom backends
- See `lib/core/constants/manual/tracking_key.dart` for complete event catalog

### Remote Config Service (IRemoteConfigService)
- **AppVersionConfigEntity** - forceUserUpdate, latestAndroidVersion, latestIosVersion
- **CourseConfigEntity** - enable, finishOptionalKp toggles
- **PaywallConfigEntity** - enableLessonLock, lessonLock threshold
- Auto-fetched on app launch from Firebase Remote Config

### Entity Extensions
Use for computed properties (avoid extra fields). Example:
```dart
extension QuestionExtension on QuestionEntity {
  bool get hasExplanation => explanation != null && explanation!.text.isNotEmpty;
}
```

---

## 16. Branch Naming Conventions

### Format
```
type/TICKET-ID-description
```

### Examples
```
feature/MEUP-123-add-course-roadmap
fix/MEUP-456-lesson-loading-timeout
refactor/MEUP-789-exercise-state
docs/MEUP-101-update-readme
```

---

**Enforcement:** Code review process validates adherence to standards.
**Questions:** Refer to architecture team or review recent merged PRs for examples.

Last updated: Jan 22, 2026
