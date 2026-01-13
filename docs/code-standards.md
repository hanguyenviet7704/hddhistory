# Meup Code Standards & Development Guidelines

**Version:** 1.0
**Last Updated:** 2026-01-13
**Applies To:** All Flutter code in Meup project

## Core Principles

**YAGNI (You Aren't Gonna Need It):** Implement only what's required now. Avoid speculative features.

**KISS (Keep It Simple, Stupid):** Favor simple solutions over complex ones. Readable code beats clever code.

**DRY (Don't Repeat Yourself):** Extract common patterns into reusable components, mixins, or functions.

## File Organization

### Directory Structure
```
lib/src/<feature>/
├── <feature>.dart              # Barrel file (library declaration)
├── <feature>.freezed.dart      # Generated Freezed code
├── <feature>.g.dart            # Generated JSON serialization
├── domain/
│   ├── entities/               # Business models (@freezed)
│   ├── repositories/           # Abstract interfaces (I<Name>Repository)
│   └── usecases/               # Business logic (@lazySingleton)
├── data/
│   ├── datasources/
│   │   ├── apis/              # @RestApi or GraphQL APIs
│   │   └── local/             # Local storage/cache
│   ├── models/                # DTOs with toEntity(), fromJson()
│   └── repositories/          # Concrete implementations (@LazySingleton)
└── presentation/
    ├── cubits/ or blocs/      # State management (@lazySingleton)
    ├── pages/                 # Screen widgets
    └── widgets/               # Reusable UI components
        ├── items/             # Small widgets (cards, buttons)
        └── layouts/           # Layout compositions
```

### File Naming
- **Files/directories:** `snake_case.dart`
- **Types:** `PascalCase`
- **Cubit/BLoC:** Suffix with `Cubit` or `Bloc` (e.g., `AuthCubit`, `AuthBloc`)
- **Entities:** Suffix with `Entity` (e.g., `UserEntity`, `CourseEntity`)
- **Models:** Suffix with `Model` (e.g., `UserModel`, `CourseModel`)
- **Repositories:** Prefix interface with `I`, implementation matches (e.g., `IAuthRepository`, `AuthRepository`)
- **Use Cases:** Descriptive name with `UseCase` suffix (e.g., `LoginUseCase`, `GetCoursesUseCase`)

### File Size Management
**Rule:** Keep individual code files under 200 lines.

**Rationale:** Improves context management for LLMs and human developers.

**Strategies:**
- Split large widgets into smaller components
- Extract utility functions into separate modules
- Use composition over inheritance for complex widgets
- Create dedicated service classes for business logic
- Break large Cubits into multiple smaller Cubits

**Example:**
```dart
// Bad: 300-line LessonPage
lib/src/lesson/presentation/pages/lesson_page.dart (300 LOC)

// Good: Split into components
lib/src/lesson/presentation/pages/lesson_page.dart (80 LOC)
lib/src/lesson/presentation/widgets/lesson_header.dart (40 LOC)
lib/src/lesson/presentation/widgets/lesson_content.dart (60 LOC)
lib/src/lesson/presentation/widgets/lesson_footer.dart (40 LOC)
```

## Clean Architecture Layers

### Domain Layer (Business Logic)
**Location:** `lib/src/<feature>/domain/`

**Entities (`entities/`):**
- Pure Dart objects representing business concepts
- Immutable using `@freezed`
- No external dependencies (except freezed_annotation)
- No JSON serialization logic

```dart
@freezed
abstract class UserEntity with _$UserEntity {
  const factory UserEntity({
    @Default('') String id,
    @Default('') String email,
    @Default('') String name,
  }) = _UserEntity;
}
```

**Repository Interfaces (`repositories/`):**
- Abstract interfaces defining data contracts
- All methods return `TaskEither<AppException, T>`
- Prefix with `I` (e.g., `IAuthRepository`)

```dart
abstract interface class IAuthRepository {
  TaskEither<AppException, AuthEntity> login(Map<String, dynamic> body);
  TaskEither<AppException, AuthEntity> register(Map<String, dynamic> body);
  TaskEither<AppException, void> logout();
}
```

**Use Cases (`usecases/`):**
- Single-responsibility business operations
- Implement `UseCaseWithParams<Params, Result>` or `UseCaseWithoutParams<Result>`
- Registered as `@lazySingleton`
- Return `TaskEither<AppException, T>`

```dart
@lazySingleton
class LoginUseCase implements UseCaseWithParams<LoginParams, AuthEntity> {
  final IAuthRepository _repository;

  LoginUseCase(this._repository);

  @override
  TaskEither<AppException, AuthEntity> call(LoginParams params) {
    return _repository.login(params.toJson());
  }
}
```

### Data Layer (Data Sources)
**Location:** `lib/src/<feature>/data/`

**Models (`models/`):**
- Extend or wrap domain entities
- Include JSON serialization (`@JsonSerializable`)
- Provide `toEntity()` method
- Use `@freezed` for immutability

```dart
@freezed
class UserModel with _$UserModel {
  const UserModel._();

  const factory UserModel({
    @Default('') String id,
    @Default('') String email,
    @Default('') String name,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  UserEntity toEntity() => UserEntity(
    id: id,
    email: email,
    name: name,
  );
}
```

**API Clients (`datasources/apis/`):**
- Use `@RestApi` annotation for Retrofit
- Return `Future<T>` (not `TaskEither`)
- Code-generated with `retrofit_generator`

```dart
@RestApi()
abstract class AuthApi {
  factory AuthApi(Dio dio, {String baseUrl}) = _AuthApi;

  @POST('/api/v1/users/login')
  Future<BaseResponse<AuthModel>> login(@Body() Map<String, dynamic> body);
}
```

**Repository Implementations (`repositories/`):**
- Implement domain repository interfaces
- Use `with RestfulRequestHandlerMixin` or `GraphQLRequestHandlerMixin`
- Convert API responses to entities
- Handle errors via mixins
- Registered as `@LazySingleton(as: I<Name>Repository)`

```dart
@LazySingleton(as: IAuthRepository)
class AuthRepository with RestfulRequestHandlerMixin implements IAuthRepository {
  final AuthApi _authApi;

  AuthRepository(this._authApi);

  @override
  TaskEither<AppException, AuthEntity> login(Map<String, dynamic> body) {
    return callApiWithTransform(
      apiCall: () => _authApi.login(body),
      transform: (response) => response.data?.toEntity() ?? AuthEntity(),
    );
  }
}
```

### Presentation Layer (UI)
**Location:** `lib/src/<feature>/presentation/`

**Cubits/Blocs (`cubits/`, `blocs/`):**
- Use `Cubit` for simple state, `Bloc` for complex event-driven flows
- Use `with CubitUseCaseHandlerMixin` or `BlocUseCaseHandlerMixin`
- States are `@freezed` classes
- Registered as `@lazySingleton`

```dart
@lazySingleton
class AuthCubit extends Cubit<AuthState> with CubitUseCaseHandlerMixin<AuthState> {
  final LoginUseCase _loginUseCase;

  AuthCubit(this._loginUseCase) : super(const AuthState.initial());

  Future<void> login(LoginParams params) async {
    await runUseCase<AuthEntity>(
      useCase: () => _loginUseCase(params),
      onSuccess: (auth) => emit(AuthState.authenticated(auth)),
    );
  }
}

@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.initial() = _Initial;
  const factory AuthState.loading() = _Loading;
  const factory AuthState.authenticated(AuthEntity auth) = _Authenticated;
  const factory AuthState.error(AppException error) = _Error;
}
```

**Pages (`pages/`):**
- Stateless widgets when possible
- Use `BlocProvider` for Cubit/BLoC injection
- Extract complex UI to separate widgets
- Name with `Page` suffix (e.g., `LoginPage`)

```dart
class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AuthCubit>(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Login')),
        body: const LoginForm(),
      ),
    );
  }
}
```

**Widgets (`widgets/`):**
- Reusable components
- Organize by feature or type (items/, layouts/)
- Keep under 100 LOC when possible

## Naming Conventions

### Code Naming
| Type | Convention | Example |
|------|------------|---------|
| Classes | PascalCase | `UserEntity`, `AuthCubit` |
| Functions/Methods | lowerCamelCase | `login()`, `getUserById()` |
| Variables | lowerCamelCase | `userId`, `accessToken` |
| Constants | lowerCamelCase | `maxRetries`, `defaultTimeout` |
| Enums | PascalCase | `AuthStatus`, `PageBreakOrder` |
| Enum values | lowerCamelCase | `authenticated`, `loading` |
| Private members | _lowerCamelCase | `_authApi`, `_loginUseCase` |

### Barrel File Pattern
Each feature module has a single library file:

```dart
// lib/src/auth/auth.dart
library auth;

part 'domain/entities/auth_entity.dart';
part 'domain/repositories/i_auth_repository.dart';
part 'domain/usecases/login_usecase.dart';
part 'data/models/auth_model.dart';
part 'data/datasources/apis/auth_api.dart';
part 'data/repositories/auth_repository.dart';
part 'presentation/cubits/auth_cubit.dart';
part 'presentation/pages/login_page.dart';

// Internal files use part of:
// domain/entities/auth_entity.dart
part of '../../auth.dart';
```

**Import from other modules:**
```dart
import 'package:meup/src/auth/auth.dart';
```

## Error Handling

### Functional Error Pattern
**Rule:** All repository methods and use cases MUST return `TaskEither<AppException, T>` from fpdart.

**Rationale:**
- Type-safe error propagation
- Eliminates try-catch boilerplate
- Composable error flows
- Railway-oriented programming

**AppException Hierarchy:**
```dart
@freezed
sealed class AppException with _$AppException {
  const factory AppException.generic([String? message]) = GenericException;
  const factory AppException.server([String? message]) = ServerException;
  const factory AppException.connection([String? message]) = ConnectionException;
  const factory AppException.unauthorized([String? message]) = UnauthorizedException;
  const factory AppException.notFound([String? message]) = NotFoundException;
  // ... 13 total exception types
}
```

**Usage in Repository:**
```dart
TaskEither<AppException, User> getUser(String id) {
  return callApi(
    request: () => userApi.getUser(id),
    fromJson: User.fromJson,
  );
}
```

**Usage in Cubit:**
```dart
await runUseCase<User>(
  useCase: () => getUserUseCase(userId),
  onSuccess: (user) => emit(state.copyWith(user: user)),
  // onError handled automatically by mixin
);
```

### UseCase Handler Mixins
**Preferred Methods (New):**
- `runUseCase<T>()` - Execute UseCase with params
- `runUseCaseList<T>()` - Execute UseCase returning lists
- `runUseCaseVoid()` - Execute UseCase without result
- `runUseCasePageBreak<T>()` - Execute paginated UseCase

**Legacy Methods (Deprecated):**
- `executeUseCase<T>()` - Manual state management
- `executeListUseCase<T>()` - Legacy list execution
- `executePageBreakUseCase<T>()` - Legacy pagination

**Migration:**
```dart
// Old (Deprecated)
await executeUseCase(
  usecase: () => _loginUseCase(params),
  onSuccess: (auth) => emit(state.copyWith(auth: auth)),
  onError: (error) => emit(state.copyWith(error: error)),
);

// New (Preferred)
await runUseCase<AuthEntity>(
  useCase: () => _loginUseCase(params),
  onSuccess: (auth) => emit(state.copyWith(auth: auth)),
);
```

## State Management

### BLoC vs Cubit
**Use Cubit when:**
- Simple state transformations
- Direct state mutation
- No complex event handling

**Use BLoC when:**
- Complex event-driven flows
- Multiple events trigger same state
- Event logging/debugging needed

### State Classes
**Rule:** All states MUST use `@freezed` sealed classes.

```dart
@freezed
sealed class CourseState with _$CourseState {
  const factory CourseState.initial() = _Initial;
  const factory CourseState.loading() = _Loading;
  const factory CourseState.loaded(List<CourseEntity> courses) = _Loaded;
  const factory CourseState.error(AppException error) = _Error;
}
```

**Benefits:**
- Exhaustive pattern matching
- Immutable state with copyWith
- Code generation reduces boilerplate

### HydratedBloc for Persistence
**Use for:**
- Theme preferences (ThemeCubit, ThemeModeCubit)
- Locale selection (LocaleCubit)
- User preferences

```dart
class ThemeModeCubit extends HydratedCubit<ThemeMode> {
  ThemeModeCubit() : super(ThemeMode.system);

  void setThemeMode(ThemeMode mode) => emit(mode);

  @override
  ThemeMode? fromJson(Map<String, dynamic> json) {
    return ThemeMode.values[json['mode'] as int];
  }

  @override
  Map<String, dynamic>? toJson(ThemeMode state) {
    return {'mode': state.index};
  }
}
```

## Dependency Injection

### Registration Annotations
```dart
// Singleton (shared instance)
@lazySingleton
class AuthCubit extends Cubit<AuthState> { ... }

// Factory (new instance per request)
@injectable
class LoginUseCase { ... }

// Named instances
@Named(DIKey.appDio)
Dio appDio;

// Abstract interface implementation
@LazySingleton(as: IAuthRepository)
class AuthRepository implements IAuthRepository { ... }
```

### Module-Based Registration
```dart
@module
abstract class NetworkModule {
  @Named(DIKey.appDio)
  @lazySingleton
  Dio appDio(IRestfulService service) {
    return service.createDio(
      baseUrl: AppConfig.baseUrl,
      interceptors: [AppInterceptor()],
    );
  }
}
```

### Dependency Resolution
```dart
// In widgets
final cubit = getIt<AuthCubit>();

// Named instances
final dio = getIt<Dio>(instanceName: DIKey.appDio);

// Constructor injection
class AuthCubit {
  final LoginUseCase _loginUseCase;

  AuthCubit(this._loginUseCase); // Auto-injected by get_it
}
```

## Code Generation

### When to Run
Run after changes to:
- Freezed classes (entities, models, states)
- JSON serialization annotations
- Retrofit API clients
- Routes (GoRouter)
- GraphQL queries
- DI registrations

### Command
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Watch Mode (Development)
```bash
dart run build_runner watch --delete-conflicting-outputs
```

### Generated Files
**Never edit:**
- `*.g.dart` - JSON serialization
- `*.freezed.dart` - Freezed classes
- `*.config.dart` - DI configuration
- `routes.g.dart` - GoRouter routes
- `*.graphql.dart` - GraphQL queries

## Testing

### Test Structure
```
test/
├── unit/
│   └── <feature>/
│       ├── domain/
│       │   └── usecases/
│       │       └── login_usecase_test.dart
│       ├── data/
│       │   └── repositories/
│       │       └── auth_repository_test.dart
│       └── presentation/
│           └── cubits/
│               └── auth_cubit_test.dart
└── integration/
    └── <feature>/
        └── auth_flow_test.dart
```

### Test Naming
- File: `<target>_test.dart`
- Test group: `describe('<ClassName>')`
- Test case: `it('should <expected behavior>')`

### Mocking
```dart
@GenerateMocks([IAuthRepository, LoginUseCase])
void main() {
  late MockIAuthRepository mockRepository;
  late AuthCubit cubit;

  setUp(() {
    mockRepository = MockIAuthRepository();
    cubit = AuthCubit(LoginUseCase(mockRepository));
  });

  test('should emit authenticated state on successful login', () async {
    when(mockRepository.login(any))
      .thenAnswer((_) => TaskEither.right(AuthEntity()));

    await cubit.login(LoginParams(email: 'test@example.com', password: 'password'));

    expect(cubit.state, isA<_Authenticated>());
  });
}
```

### Coverage Target
- **Business Logic (Use Cases):** 80%+
- **Repositories:** 70%+
- **Cubits/Blocs:** 60%+

## Git Workflow

### Branch Naming
```
<type>/<TICKET-ID>-<description>

Types: feature, fix, hotfix, release
Example: feature/MEUP-123-add-social-login
```

### Creating Branches
```bash
# Feature branch
./tools/macos/git/feature.sh MEUP-123 "add social login"

# Fix branch
./tools/macos/git/fix.sh MEUP-456 "fix login error"

# Hotfix branch
./tools/macos/git/hotfix.sh MEUP-789 "critical auth bug"
```

### Commit Message Format
```
<type>-<TICKET-ID>: <subject>

Types: feature, fix, refactor, style, docs, test, chore, perf
Subject: Imperative mood, no period, max 72 chars

Example: feature-MEUP-123: Add Google social login functionality
```

### Commit Message Validation
Pre-commit hook validates format automatically.

**Valid:**
```
feature-MEUP-123: Add social login
fix-MEUP-456: Fix token refresh bug
refactor-MEUP-789: Extract login form widget
```

**Invalid:**
```
Added social login  // Missing type and ticket
MEUP-123 login      // Wrong format
feature: login      // Missing ticket ID
```

### Pre-Push Hook
Runs `flutter test` before push. Fix failing tests before pushing.

## Coding Conventions

### Key Rules
- Prefer `const` constructors
- Use trailing commas for formatting
- Always use async/await over `.then()`
- Use null-aware operators (`??`, `?.`)
- Use string interpolation over concatenation
- Use collection if/for for conditional/loop elements

## Localization

### Key Naming
- Use lowerCamelCase
- Organize by module (auth, course, lesson, etc.)
- No module prefix (module is namespace)

```yaml
# assets/i18n/en/auth.yaml
login: Login
email: Email
password: Password
forgotPassword: Forgot Password?
loginButton: Sign In
```

**Usage:**
```dart
import 'package:meup/config/l10n/l10n.dart';

Text(t.auth.loginButton);
```

### Workflow
1. Edit YAML files in `assets/i18n/<locale>/<module>.yaml`
2. Push to Google Sheets: `tools/macos/localization/localization.sh push`
3. Pull from Google Sheets: `tools/macos/localization/localization.sh pull`
4. Regenerate: `dart run slang`

## Performance Guidelines

Use `const` constructors, `ListView.builder` for long lists, `CachedNetworkImage` for remote images, pagination for large datasets, and dispose controllers/streams in `dispose()`.

## Security Best Practices

Never commit `.env` files or hardcode secrets. Use `flutter_secure_storage` for tokens. Always use HTTPS, validate inputs, and clear sensitive data on logout.

## Documentation

Use doc comments (`///`) for public APIs. Update comments when code changes. Explain "why" not "what". Keep project README under 300 LOC and link to `docs/` for details.

## Linting & Formatting

### Analysis Options
- Base: `flutter_lints/flutter.yaml`
- Line length: 180 characters (for LLM context)
- Trailing commas: preserve

### Pre-Commit Checks
1. Run `flutter analyze` (no errors allowed)
2. Run `flutter test` (all tests pass)
3. Format code: `dart format lib/ test/`

### Ignored Lints
- `invalid_annotation_target` (Freezed/JSON serialization)
- `annotate_overrides` (code generation conflicts)

## Anti-Patterns to Avoid

### DON'T
- ❌ Expose Dio/GraphQL types beyond data layer
- ❌ Use `try-catch` instead of `TaskEither` in repositories
- ❌ Put business logic in widgets or Cubits
- ❌ Create "god" classes (large files with multiple responsibilities)
- ❌ Ignore failing tests
- ❌ Use `dynamic` types without documentation
- ❌ Create circular dependencies between modules
- ❌ Hardcode strings (use localization)
- ❌ Commit generated files (exclude in .gitignore)
- ❌ Skip code generation after schema changes

### DO
- ✅ Use mixins for cross-cutting concerns
- ✅ Keep files under 200 LOC
- ✅ Write tests for business logic
- ✅ Use sealed classes for states and errors
- ✅ Follow Clean Architecture layers
- ✅ Use const constructors
- ✅ Document public APIs
- ✅ Run code generation after changes
- ✅ Use TaskEither for error handling
- ✅ Extract reusable widgets

## Checklist for New Features

- [ ] Create feature branch with correct naming
- [ ] Implement domain layer (entities, repository interface, use cases)
- [ ] Implement data layer (models, API clients, repository)
- [ ] Implement presentation layer (Cubit/BLoC, pages, widgets)
- [ ] Register all classes in DI (`@lazySingleton`, `@injectable`)
- [ ] Add routes in `lib/config/routes/data/`
- [ ] Run code generation (`dart run build_runner build --delete-conflicting-outputs`)
- [ ] Write unit tests (80%+ coverage for use cases)
- [ ] Write integration tests for critical flows
- [ ] Update localization files (`assets/i18n/<locale>/<module>.yaml`)
- [ ] Run `flutter analyze` (zero errors)
- [ ] Run `flutter test` (all pass)
- [ ] Format code (`dart format lib/ test/`)
- [ ] Commit with conventional format (`feature-MEUP-XXX: description`)
- [ ] Create MR/PR with description and screenshots

## Summary

Following these standards ensures:
- **Consistency:** Predictable code structure across features
- **Maintainability:** Easy to understand and modify
- **Testability:** Clean boundaries enable comprehensive testing
- **Scalability:** Modular architecture supports growth
- **Quality:** Automated checks catch issues early
- **Collaboration:** Clear conventions reduce merge conflicts
