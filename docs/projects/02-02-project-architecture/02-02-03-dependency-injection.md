# Dependency Injection

This document explains the dependency injection implementation using `get_it` and `injectable` in the DCore Flutter project.

## Overview

The DCore project uses dependency injection to manage object creation and dependencies, promoting loose coupling, testability, and maintainability. The implementation combines `get_it` as the service locator with `injectable` for code generation and uses a centralized `AppDI` mixin pattern for dependency access.

## Architecture

### Core Components
- **GetIt**: Service locator for dependency resolution
- **Injectable**: Annotations for automatic registration
- **Code Generation**: Automatic dependency graph creation

### Dependency Flow
```
Application Startup → configureDependencies() → Generated Registration → GetIt Service Locator → Dependency Resolution
```

## Setup and Configuration

### Main Dependency Injection File
```dart
// lib/config/di/di.dart
library;

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get_it/get_it.dart';
import 'package:graphql_flutter/graphql_flutter.dart' show GraphQLClient;
import 'package:injectable/injectable.dart';

import '../../core/constants/constants.dart';
import '../../core/helpers/helpers.dart';
import '../services/services.dart';
import 'di.config.dart';

// Import all di files here
part 'app_di_config.dart';
part 'cache_di.dart';
part 'network_di.dart';
part 'route_observer_di.dart';
part 'supabase_di.dart';
part 'tracking_di.dart';

// Service Locator instance
final GetIt sl = GetIt.instance;
```

### AppDI Configuration
```dart
// lib/config/di/app_di_config.dart (part of di.dart)
@InjectableInit(
  generateForDir: [
    'lib/config/di',
    'lib/config/services',
    'lib/src/data/datasources/apis',
    'lib/src/data/datasources/sockets',
    'lib/src/data/repositories',
    'lib/src/domain/repositories',
    'lib/src/domain/usecases',
    'lib/src/presentation/blocs',
  ],
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
void configureDependencies() => AppDI.injector.init();

mixin AppDI {
  static GetIt injector = GetIt.instance;

  static Future<void> initializeDependencies() async {
    injector.allowReassignment = true;
    configureDependencies();

    LogDev.data('APP DI CONFIG INITIALIZED!');
  }

  static Future<void> resetDependencies() async {
    await injector.reset();
    configureDependencies();
  }
}
```

### Application Initialization
```dart
// lib/main_dev.dart, lib/main_stg.dart, lib/main_prod.dart
import 'package:flutter/material.dart';
import 'config/di/di.dart';
import 'src/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure dependency injection
  await AppDI.initializeDependencies();
  
  runApp(const App());
}
```

### Generated Configuration
The `di.config.dart` file is automatically generated and contains all dependency registrations:

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

import 'package:get_it/get_it.dart' as _i1;
import 'package:injectable/injectable.dart' as _i2;

import '../../src/data/datasources/local/user_local_datasource.dart' as _i3;
import '../../src/data/datasources/remote/user_remote_datasource.dart' as _i4;
import '../../src/data/repositories/user_repository_impl.dart' as _i5;
import '../../src/domain/repositories/user_repository.dart' as _i6;
import '../../src/domain/usecases/get_user_usecase.dart' as _i7;
import '../../src/presentation/blocs/user/user_cubit.dart' as _i8;

extension GetItInjectableX on _i1.GetIt {
  _i1.GetIt init({
    String? environment,
    _i2.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i2.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    
    gh.lazySingleton<_i3.UserLocalDataSource>(() => _i3.UserLocalDataSource());
    gh.lazySingleton<_i4.UserRemoteDataSource>(() => _i4.UserRemoteDataSource());
    gh.lazySingleton<_i6.UserRepository>(() => _i5.UserRepositoryImpl(
      gh<_i4.UserRemoteDataSource>(),
      gh<_i3.UserLocalDataSource>(),
    ));
    gh.lazySingleton<_i7.GetUserUseCase>(() => _i7.GetUserUseCase(gh<_i6.UserRepository>()));
    gh.factory<_i8.UserCubit>(() => _i8.UserCubit(gh<_i7.GetUserUseCase>()));
    
    return this;
  }
}
```

## Dependency Registration

### DIKey Constants
The project uses a centralized `DIKey` class to define named dependency keys:

```dart
// lib/core/constants/di_key.dart
class DIKey {
  // Network keys
  static const String baseUrl = 'baseUrl';
  static const String apiBaseUrl = 'apiBaseUrl';
  static const String appDio = 'appDio';
  static const String aiDio = 'aiDio';
  static const String appInterceptor = 'appInterceptor';
  
  // Cache keys
  static const String defaultCacheManager = 'defaultCacheManager';
  static const String imageCacheManager = 'imageCacheManager';
  static const String videoCacheManager = 'videoCacheManager';
  static const String cacheService = 'cacheService';
  
  // Services keys
  static const String trackingService = 'trackingService';
  static const String firebaseAnalyticsService = 'firebaseAnalyticsService';
  static const String sentryTrackingService = 'sentryTrackingService';
  
  // Supabase keys
  static const String supabaseUrl = 'supabaseUrl';
  static const String supabaseAnonKey = 'supabaseAnonKey';
  static const String googleWebClientId = 'googleWebClientId';
}
```

### Module-Based Registration
The project uses `@module` abstract classes to organize related dependencies:

```dart
@module
abstract class NetworkModule {
  @Named(DIKey.baseUrl)
  @lazySingleton
  String get baseUrl => EnvConstant.baseUrl;

  @Named(DIKey.appDio)
  @lazySingleton
  Dio appDio(RestfulService networkService, @Named(DIKey.appInterceptor) Interceptor interceptor) {
    final dio = networkService.createDio();
    dio.interceptors.add(interceptor);
    return dio;
  }

  @Named(DIKey.appInterceptor)
  @lazySingleton
  Interceptor get appInterceptor => AppInterceptors();
}
```

### Registration Types

#### LazySingleton (Default Pattern)
The project primarily uses `@lazySingleton` for most dependencies. This creates a single instance that is initialized only when first accessed:

```dart
// Standard lazy singleton registration
@lazySingleton
class UserRepository implements IUserRepository {
  UserRepository(this._remoteDataSource, this._localDataSource);
  
  final UserRemoteDataSource _remoteDataSource;
  final UserLocalDataSource _localDataSource;
  
  // Implementation
}

// Lazy singleton with named identifier
@Named(DIKey.imageCacheManager)
@lazySingleton
CacheManager get imageCacheManager => CacheManager(
  Config(
    CacheKey.imageCache,
    stalePeriod: const Duration(days: 7),
    maxNrOfCacheObjects: 500,
  ),
);

// Cubits as lazy singletons (app-wide state)
@lazySingleton
class IAPCubit extends Cubit<IAPState> {
  IAPCubit(this._iapRepository) : super(IAPState.initial());
  
  final IIAPRepository _iapRepository;
  
  // Implementation for app-wide IAP management
}
```

#### Factory Registration (Special Cases Only)
Use `@injectable` only when you specifically need a new instance each time:

```dart
// Factory registration - only when multiple instances are needed
@injectable
class TemporaryTaskCubit extends Cubit<TaskState> {
  TemporaryTaskCubit(this._taskUseCase) : super(const TaskState.initial());
  
  final TaskUseCase _taskUseCase;
  
  // Use factory when you need fresh state for each widget instance
}
```

#### Interface Registration
Register implementations for interfaces:

```dart
@LazySingleton(as: IIAPRepository)
class IAPRepository implements IIAPRepository {
  final IAPApi _iapApi;
  final IIapService _iapService;
  
  IAPRepository(this._iapApi, this._iapService);
  
  // Implementation
}
```

#### API Registration with Named Dependencies
```dart
@RestApi()
@lazySingleton
abstract class IAPApi {
  @factoryMethod
  factory IAPApi(@Named(DIKey.appDio) Dio dio) = _IAPApi;

  @POST(AppEndpoint.packages)
  Future<BaseResponseList<IapProduct>> getPackages();
}
```

### Environment-Specific Registration
Register different implementations for different environments:

```dart
@LazySingleton(as: ApiClient)
@dev
class DevApiClient implements ApiClient {
  // Development implementation with debug logging
}

@LazySingleton(as: ApiClient)
@prod
class ProdApiClient implements ApiClient {
  // Production implementation with optimizations
}
```

## Layer-by-Layer Registration

### Data Layer Registration

#### Data Sources
```dart
// Remote data sources
@lazySingleton
class UserRemoteDataSource {
  UserRemoteDataSource(this._apiClient);
  final ApiClient _apiClient;
  
  Future<UserModel> getUser(String id) async {
    final response = await _apiClient.getUser(id);
    return UserModel.fromJson(response.data);
  }
}

// Local data sources
@lazySingleton
class UserLocalDataSource {
  UserLocalDataSource(this._secureStorage);
  final FlutterSecureStorage _secureStorage;
  
  Future<UserModel?> getCachedUser(String id) async {
    final jsonString = await _secureStorage.read(key: 'user_$id');
    if (jsonString != null) {
      return UserModel.fromJson(jsonDecode(jsonString));
    }
    return null;
  }
}
```

#### Repositories
```dart
@LazySingleton(as: UserRepository)
class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(this._remoteDataSource, this._localDataSource);
  
  final UserRemoteDataSource _remoteDataSource;
  final UserLocalDataSource _localDataSource;
  
  @override
  TaskEither<AppException, UserEntity> getUser(String id) async {
    try {
      // Try cache first
      final cachedUser = await _localDataSource.getCachedUser(id);
      if (cachedUser != null) {
        return Right(cachedUser.toEntity());
      }
      
      // Fetch from remote
      final remoteUser = await _remoteDataSource.getUser(id);
      await _localDataSource.cacheUser(remoteUser);
      
      
      return Right(remoteUser.toEntity());
    } catch (e) {
      return Left(AppException(e.toString()));
    }
  }
}
```

### Domain Layer Registration

#### Use Cases
```dart
// Default pattern: Lazy singleton for use cases
@lazySingleton
class GetUserUseCase {
  GetUserUseCase(this._userRepository);
  final UserRepository _userRepository;
  
  TaskEither<AppException, UserEntity> call(String userId) {
    return _userRepository.getUser(userId);
  }
}

@lazySingleton
class LoginUseCase {
  LoginUseCase(this._authRepository);
  final AuthRepository _authRepository;
  
  TaskEither<AppException, UserEntity> call(LoginParams params) {
    return _authRepository.login(params.email, params.password);
  }
}

@lazySingleton
class GetPackagesUsecase {
  GetPackagesUsecase(this._iapRepository);
  final IIAPRepository _iapRepository;
  
  TaskEither<AppException, BaseResponseList<IapProduct>> call() {
    return _iapRepository.getProducts();
  }
}
```

### Presentation Layer Registration

#### BLoCs and Cubits
```dart
// Default pattern: Lazy singleton for app-wide state management
@lazySingleton
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(
    this._loginUseCase,
    this._logoutUseCase,
  ) : super(const AuthState.initial()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  
  // Event handlers for app-wide authentication
}

@lazySingleton
class UserCubit extends Cubit<UserState> {
  UserCubit(this._getUserUseCase) : super(const UserState.initial());
  
  final GetUserUseCase _getUserUseCase;
  
  Future<void> loadUser(String userId) async {
    emit(const UserState.loading());
    final result = await _getUserUseCase(userId);
    result.fold(
      (failure) => emit(UserState.error(failure.message)),
      (user) => emit(UserState.loaded(user)),
    );
  }
}

@lazySingleton
class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(const HomeState.initial());
  
  // App-wide home state management
}
```

## Third-Party Service Registration

### External Services
```dart
// HTTP client
@module
abstract class NetworkModule {
  @lazySingleton
  Dio get dio => Dio(BaseOptions(
    baseUrl: const String.fromEnvironment('API_BASE_URL'),
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));
  
  @lazySingleton
  ApiClient apiClient(Dio dio) => ApiClient(dio);
}

// Storage
@module
abstract class StorageModule {
  @lazySingleton
  FlutterSecureStorage get secureStorage => const FlutterSecureStorage();
  
  @lazySingleton
  SharedPreferences sharedPreferences() async => 
      await SharedPreferences.getInstance();
}

// Firebase services
@module
abstract class FirebaseModule {
  @lazySingleton
  FirebaseAnalytics get analytics => FirebaseAnalytics.instance;
  
  @lazySingleton
  FirebaseCrashlytics get crashlytics => FirebaseCrashlytics.instance;
  
  @lazySingleton
  FirebaseAuth get auth => FirebaseAuth.instance;
}
```

## Practical Usage Patterns

### Accessing Named Dependencies
When you need to access named dependencies, use the specific key:

```dart
// Get specific Dio instance
final appDio = AppDI.injector.get<Dio>(instanceName: DIKey.appDio);
final aiDio = AppDI.injector.get<Dio>(instanceName: DIKey.aiDio);

// Get specific cache manager
final imageCache = AppDI.injector.get<CacheManager>(instanceName: DIKey.imageCacheManager);
final videoCache = AppDI.injector.get<CacheManager>(instanceName: DIKey.videoCacheManager);

// Get tracking service
final trackingService = AppDI.injector.get<BaseTrackingService>(instanceName: DIKey.trackingService);
```

### Cubit Registration Patterns
Most Cubits are registered as `@lazySingleton` for app-wide state management:

```dart
// Default pattern: Lazy singleton for app-wide state
@lazySingleton
class UserCubit extends Cubit<UserState> {
  UserCubit(this._getUserUseCase) : super(const UserState.initial());
  
  final GetUserUseCase _getUserUseCase;
  
  // App-wide user state management
}

@lazySingleton
class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit() : super(const ThemeState.initial());
  
  // Global theme management
}

@lazySingleton
class PaywallCubit extends Cubit<PaywallState> {
  PaywallCubit(this._paywallRepository) : super(const PaywallState.initial());
  
  final IPaywallRepository _paywallRepository;
  
  // App-wide paywall state
}

// Special case: Factory registration only when needed
@injectable  // Only use when multiple instances are required
class DialogCubit extends Cubit<DialogState> {
  // For temporary dialog states that need fresh instances
}
```

## Usage in Widgets

### BlocProvider Integration
```dart
class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key, required this.userId});
  
  final String userId;
  
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AppDI.injector.get<UserCubit>()..loadUser(userId),
      child: const UserProfileView(),
    );
  }
}
```

### Direct Service Access
```dart
class ApiService {
  static final _apiClient = AppDI.injector.get<ApiClient>();
  static final _analytics = AppDI.injector.get<FirebaseAnalytics>();
  
  static Future<void> trackEvent(String name, Map<String, dynamic> parameters) {
    return _analytics.logEvent(name: name, parameters: parameters);
  }
}
```

### Global App Providers
```dart
// lib/core/helpers/provider/app_providers.dart
class AppProviders extends StatelessWidget {
  final Widget _child;
  const AppProviders({super.key, required Widget child}) : _child = child;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(create: (_) => AppDI.injector.get<ThemeCubit>()),
        BlocProvider<LocaleCubit>(create: (_) => AppDI.injector.get<LocaleCubit>()),
        BlocProvider<UserCubit>(create: (_) => AppDI.injector.get<UserCubit>()),
        BlocProvider<AuthBloc>(create: (_) => AppDI.injector.get<AuthBloc>()),
        BlocProvider<IAPCubit>(create: (_) => AppDI.injector.get<IAPCubit>()),
        BlocProvider<PaywallCubit>(create: (_) => AppDI.injector.get<PaywallCubit>()),
        // Add more providers as needed
      ],
      child: ScreenUtilInit(
        designSize: AppGlobalValue.designSize, 
        minTextAdapt: true, 
        splitScreenMode: true, 
        child: _child
      ),
    );
  }
}
```

## Testing with Dependency Injection

### Mock Registration for Tests
```dart
// test/helpers/test_injection.dart
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';

class MockUserRepository extends Mock implements UserRepository {}
class MockGetUserUseCase extends Mock implements GetUserUseCase {}

void setupTestDependencies() {
  final getIt = GetIt.instance;
  getIt.reset();
  
  // Register mocks
  getIt.registerLazySingleton<UserRepository>(() => MockUserRepository());
  getIt.registerFactory<GetUserUseCase>(() => MockGetUserUseCase());
  getIt.registerFactory<UserCubit>(() => UserCubit(getIt<GetUserUseCase>()));
}
```

### Test Setup
```dart
group('UserCubit', () {
  late UserCubit userCubit;
  late MockGetUserUseCase mockGetUserUseCase;

  setUp(() {
    setupTestDependencies();
    mockGetUserUseCase = AppDI.injector.get<GetUserUseCase>() as MockGetUserUseCase;
    userCubit = AppDI.injector.get<UserCubit>();
  });

  tearDown(() async {
    await AppDI.resetDependencies();
  });

  // Tests
});
```

### Widget Testing with DI
```dart
testWidgets('UserProfilePage should load user data', (tester) async {
  // Setup
  setupTestDependencies();
  const user = UserEntity(id: '1', name: 'Test User', email: 'test@test.com');
  
  when(mockGetUserUseCase(any())).thenAnswer((_) async => Right(user));
  
  // Test
  await tester.pumpWidget(
    MaterialApp(home: UserProfilePage(userId: '1')),
  );
  await tester.pumpAndSettle();
  
  // Verify
  expect(find.text('Test User'), findsOneWidget);
});
```

## Advanced Features

### Conditional Registration
```dart
@LazySingleton(as: Logger)
@Environment(Environment.dev)
class DebugLogger implements Logger {
  @override
  void log(String message) => print('DEBUG: $message');
}

@LazySingleton(as: Logger)
@Environment(Environment.prod)
class ProductionLogger implements Logger {
  @override
  void log(String message) {
    // Send to logging service
  }
}
```

### Async Registration
```dart
@module
abstract class AsyncModule {
  @preResolve
  @lazySingleton
  Future<SharedPreferences> get sharedPreferences => 
      SharedPreferences.getInstance();
      
  @preResolve
  @lazySingleton
  Future<PackageInfo> get packageInfo => 
      PackageInfo.fromPlatform();
}

// Usage in main
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const App());
}
```

### Named Registration
```dart
@Named('dev')
@lazySingleton
class DevApiConfig implements ApiConfig {
  @override
  String get baseUrl => 'https://dev.api.com';
}

@Named('prod')
@lazySingleton
class ProdApiConfig implements ApiConfig {
  @override
  String get baseUrl => 'https://api.com';
}

// Usage
class ApiClient {
  ApiClient(@Named('dev') this.config);
  final ApiConfig config;
}
```

## Code Generation

### Build Configuration
The project uses `@InjectableInit` with specific directory configuration:

```dart
@InjectableInit(
  generateForDir: [
    'lib/config/di',
    'lib/config/services',
    'lib/src/data/datasources/apis',
    'lib/src/data/datasources/sockets',
    'lib/src/data/repositories',
    'lib/src/domain/repositories',
    'lib/src/domain/usecases',
    'lib/src/presentation/blocs',
  ],
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
```

### Generation Commands
```bash
# Generate dependency injection code
flutter pub run build_runner build --delete-conflicting-outputs

# Or use project script
dart run build_runner build --delete-conflicting-outputs

# Clean and regenerate
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

## Registration Decision Guide

### When to Use @lazySingleton (Default Choice)
Use `@lazySingleton` for **99%** of your dependencies:

```dart
// ✅ Repositories
@lazySingleton
class UserRepository implements IUserRepository { }

// ✅ Use Cases  
@lazySingleton
class LoginUseCase { }

// ✅ Services
@lazySingleton
class NetworkService { }

// ✅ Most Cubits (app-wide state)
@lazySingleton
class UserCubit extends Cubit<UserState> { }

// ✅ APIs
@lazySingleton
abstract class UserApi { }

// ✅ Data Sources
@lazySingleton
class UserRemoteDataSource { }
```

### When to Use @injectable (Special Cases Only)
Use `@injectable` only when you specifically need multiple instances:

```dart
// ✅ Temporary/Dialog Cubits that need fresh state
@injectable
class ImagePickerCubit extends Cubit<ImagePickerState> {
  // Each dialog needs its own fresh state
}

// ✅ Task-specific processors that shouldn't be shared
@injectable
class FileProcessorWorker {
  // Each file processing task needs its own instance
}

// ❌ Don't use injectable for regular app state
// @injectable  // Wrong!
// class UserCubit extends Cubit<UserState> { }
```

### Key Rule
- **Default**: `@lazySingleton` for everything
- **Exception**: `@injectable` only when you explicitly need multiple instances
- **Never**: Mix both patterns for the same type of dependency without clear justification

## Best Practices

### Registration Guidelines
- **Default Pattern**: Use `@lazySingleton` for almost all dependencies (repositories, use cases, services, cubits)
- Use `@lazySingleton` with `@Named` for multiple instances of the same type (different Dio clients, cache managers)
- Use `@injectable` (factory) only in special cases where you explicitly need fresh instances
- Register interfaces, not implementations when possible
- Prefer lazy initialization over eager initialization for better app startup performance

### Dependency Management
- **Consistent Registration**: Use `@lazySingleton` as the default pattern across the entire codebase
- Avoid circular dependencies
- Keep dependency graphs shallow
- Use interfaces to decouple layers
- Group related dependencies in `@module` classes (NetworkModule, CacheModule, etc.)
- Use `DIKey` constants for named dependencies to maintain consistency

### Testing
- Always provide mock implementations for tests
- Use `AppDI.resetDependencies()` between tests to clean up lazy singletons
- Mock dependencies should also follow the same registration patterns
- Use dependency injection consistently in tests
- Mock external dependencies properly
- Be aware that `@lazySingleton` instances persist until explicitly reset

### Performance
- Register expensive services as singletons
- Use lazy initialization where appropriate
- Avoid unnecessary dependency creation
- Monitor memory usage of singletons

### Code Organization
- Keep DI configuration centralized
- Use modules for grouping related services
- Document complex dependency relationships
- Use environment-specific registration when needed