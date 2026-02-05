---
trigger: model_decision
description: Dependency injection patterns and rules using get_it + injectable
---

# Dependency Injection Rules

## Core DI Principles
This project uses `get_it` + `injectable` with a centralized `AppDI` pattern.

## Registration Patterns

### Default Registration: @lazySingleton
**Use @lazySingleton for 99% of cases:**
```dart
@lazySingleton
class UserRepository implements IUserRepository {
  final ApiClient apiClient;
  UserRepository(this.apiClient);
}

@lazySingleton  
class GetUserUseCase extends UseCaseWithParams<User, GetUserParams> {
  final IUserRepository repository;
  GetUserUseCase(this.repository);
}
```

### Interface Binding
```dart
@LazySingleton(as: IUserRepository)
class UserRepository implements IUserRepository {
  // implementation
}
```

### Named Dependencies
```dart
@lazySingleton
@Named(DIKey.devApiClient)
class DevApiClient implements ApiClient {
  // implementation
}

// Usage in constructor
class UserRepository {
  final ApiClient apiClient;
  
  UserRepository(@Named(DIKey.devApiClient) this.apiClient);
}
```

### Module Organization
```dart
@module
abstract class NetworkModule {
  @lazySingleton
  Dio get dio => Dio();
  
  @lazySingleton
  ApiClient apiClient(Dio dio) => ApiClient(dio);
}
```

## Dependency Resolution

### Always Use AppDI.injector Pattern
```dart
// CORRECT ✅
final repository = AppDI.injector.get<IUserRepository>();
final useCase = AppDI.injector.get<GetUserUseCase>();

// WRONG ❌ - Never use these patterns
final repository = getIt<IUserRepository>();
final repository = sl<IUserRepository>();
```

### In BLoC/Cubit Providers
```dart
BlocProvider(
  create: (context) => AppDI.injector.get<UserCubit>(),
  child: UserPage(),
)
```

### In Use Cases and Repositories
Dependencies are automatically injected via constructor:
```dart
@lazySingleton
class GetUserUseCase {
  final IUserRepository repository; // Auto-injected
  
  GetUserUseCase(this.repository);
}
```

## Code Generation
After adding @injectable annotations:
```bash
dart run build_runner build --delete-conflicting-outputs
```

## DI File Organization
- `lib/config/di/di.dart` - Main DI setup
- `lib/config/di/app_di_config.dart` - AppDI mixin
- `lib/config/di/di.config.dart` - Generated file

## Common DI Patterns

### Repository Registration
```dart
@LazySingleton(as: IUserRepository)
class UserRepository implements IUserRepository {
  // Auto-injected dependencies
  final ApiClient apiClient;
  final UserLocalDataSource localSource;
  
  UserRepository(this.apiClient, this.localSource);
}
```

### UseCase Registration
```dart
@lazySingleton
class LoginUseCase extends UseCaseWithParams<User, LoginParams> {
  final IAuthRepository authRepository;
  
  LoginUseCase(this.authRepository);
}
```

### BLoC/Cubit Registration
```dart
@injectable
class UserCubit extends HydratedCubit<UserState> {
  final GetUserUseCase getUserUseCase;
  final UpdateUserUseCase updateUserUseCase;
  
  UserCubit(this.getUserUseCase, this.updateUserUseCase) 
    : super(const UserState.initial());
}
```

### Data Source Registration
```dart
@lazySingleton
class UserLocalDataSource {
  final FlutterSecureStorage secureStorage;
  
  UserLocalDataSource(this.secureStorage);
}
```

## Testing with DI
```dart
setUp(() {
  // Reset injector for tests
  AppDI.injector.reset();
  
  // Register test doubles
  AppDI.injector.registerLazySingleton<IUserRepository>(
    () => MockUserRepository(),
  );
});
```