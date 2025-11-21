# State Management with BLoC

This document explains the state management implementation using the BLoC pattern in Dcore projects.

## Overview

The Dcore project uses the BLoC (Business Logic Component) pattern for state management, providing a predictable and testable approach to managing application state. The implementation uses `flutter_bloc` and `hydrated_bloc` for state persistence.

> **Note**: The Clean Architecture flow in this project is not yet 100% standardized but follows the established patterns shown in this documentation. The project includes custom UseCase handler mixins to reduce boilerplate code and ensure consistent error handling across all state management implementations.

## BLoC Architecture

### Core Components
- **BLoC/Cubit**: Business logic containers
- **Events**: User actions and external triggers (for BLoC)
- **States**: UI representations of application state
- **Repositories**: Data access abstraction
- **Use Cases**: Business logic operations

### State Flow
```
UI Widget → Event → BLoC → Use Case → Repository → Data Source
    ↑               ↑       ↑         ↑            ↑         ↓
    ←─── State ←─── BLoC ←─ Result ←─ Repository ←─────────┘
```

## BLoC Implementation

### BLoC Structure
```dart
// Example: Authentication BLoC
@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(
    this._loginUseCase,
    this._logoutUseCase,
    this._getCurrentUserUseCase,
  ) : super(const AuthState.initial()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthUserRequested>(_onUserRequested);
  }

  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    
    final result = await _loginUseCase(LoginParams(
      email: event.email,
      password: event.password,
    ));

    result.fold(
      (failure) => emit(AuthState.error(failure.message)),
      (user) => emit(AuthState.authenticated(user)),
    );
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    
    final result = await _logoutUseCase(NoParams());
    
    result.fold(
      (failure) => emit(AuthState.error(failure.message)),
      (_) => emit(const AuthState.unauthenticated()),
    );
  }
}
```

### Events Definition
```dart
// auth_event.dart
@freezed
class AuthEvent with _$AuthEvent {
  const factory AuthEvent.loginRequested({
    required String email,
    required String password,
  }) = AuthLoginRequested;
  
  const factory AuthEvent.logoutRequested() = AuthLogoutRequested;
  
  const factory AuthEvent.userRequested() = AuthUserRequested;
}
```

### States Definition
```dart
// auth_state.dart
@freezed
class AuthState with _$AuthState {
  const factory AuthState.initial() = _Initial;
  const factory AuthState.loading() = _Loading;
  const factory AuthState.authenticated(UserEntity user) = _Authenticated;
  const factory AuthState.unauthenticated() = _Unauthenticated;
  const factory AuthState.error(String message) = _Error;
}
```

## UseCase Handler Mixins

To avoid code duplication and standardize use case handling, the project provides custom handler mixins that automatically manage loading states and error handling.

### CubitUseCaseHandlerMixin

**File**: `lib/core/base/bloc/cubit_usecase_handler.dart`

This mixin provides standardized methods for executing use cases within Cubit classes:

```dart
mixin CubitUseCaseHandlerMixin<State> on Cubit<State> {
  // Execute use case returning BaseResponse<T>
  Future<void> executeUseCase<T>({
    required TaskEither<AppException, BaseResponse<T>> Function() usecase,
    State Function(State currentState, {required bool isLoading})? setLoadingState,
    Function(BaseResponse<T>)? onSuccess,
    Function(AppException)? onFailure,
  });

  // Execute use case returning BaseResponse (no data)
  Future<void> executeEmptyUseCase({
    required TaskEither<AppException, BaseResponse> Function() usecase,
    State Function(State currentState, {required bool isLoading})? setLoadingState,
    Function(BaseResponse)? onSuccess,
    Function(AppException)? onFailure,
  });

  // Execute use case returning BaseResponseList<T>
  Future<void> executeListUseCase<T>({
    required TaskEither<AppException, BaseResponseList<T>> Function() usecase,
    State Function(State currentState, {required bool isLoading})? setLoadingState,
    Function(BaseResponseList<T>)? onSuccess,
    Function(AppException)? onFailure,
  });

  // Execute paginated use case with automatic data merging
  Future<void> executePageBreakUseCase<T>({
    required TaskEither<AppException, BaseResponse<BasePageBreak<T>>> Function() usecase,
    required BasePageBreak<T> currentPageData,
    required bool isInit,
    required State Function(State currentState, {required BasePageBreak<T> mergedPageBreakData}) setPageBreakState,
    Function(BaseResponse<BasePageBreak<T>>)? onSuccess,
    Function(AppException)? onFailure,
    State Function(State currentState, {required bool isLoading})? setLoadingState,
  });

  // Execute custom use case returning any type T
  Future<void> executeCustomUseCase<T>({
    required TaskEither<AppException, T> Function() usecase,
    State Function(State currentState, {required bool isLoading})? setLoadingState,
    Function(T)? onSuccess,
    Function(AppException)? onFailure,
  });
}
```

### BlocUseCaseHandlerMixin

**File**: `lib/core/base/bloc/bloc_usecase_handler.dart`

Similar to the Cubit handler, but for BLoC classes:

```dart
mixin BlocUseCaseHandlerMixin<Event, State> on BlocBase<State> {
  // Same method signatures as CubitUseCaseHandlerMixin
}
```

## Cubit Implementation

### Simple State Management
For simpler state management, use Cubit with the handler mixin:

```dart
@injectable
class UserCubit extends Cubit<UserState> with CubitUseCaseHandlerMixin<UserState> {
  UserCubit(
    this._getUserUseCase,
    this._updateUserUseCase,
  ) : super(const UserState.initial());

  final GetUserUseCase _getUserUseCase;
  final UpdateUserUseCase _updateUserUseCase;

  Future<void> loadUser(String userId) async {
    await executeUseCase(
      usecase: () => _getUserUseCase(GetUserParams(userId: userId)),
      setLoadingState: (currentState, {required bool isLoading}) => 
          isLoading ? const UserState.loading() : currentState,
      onSuccess: (response) => emit(UserState.loaded(response.data!)),
      onFailure: (error) => emit(UserState.error(error.message)),
    );
  }

  Future<void> updateUser(UserEntity user) async {
    await executeUseCase(
      usecase: () => _updateUserUseCase(UpdateUserParams(user: user)),
      setLoadingState: (currentState, {required bool isLoading}) => 
          isLoading ? const UserState.loading() : currentState,
      onSuccess: (response) => emit(UserState.loaded(response.data!)),
      onFailure: (error) => emit(UserState.error(error.message)),
    );
  }
}
```

### Cubit States
```dart
@freezed
class UserState with _$UserState {
  const factory UserState.initial() = _Initial;
  const factory UserState.loading() = _Loading;
  const factory UserState.loaded(UserEntity user) = _Loaded;
  const factory UserState.error(String message) = _Error;
}
```

### Real-World Example: IAPCubit

**File**: `lib/src/presentation/blocs/paywall/iap/iap_cubit.dart`

Here's a practical example showing different handler methods in use:

```dart
@lazySingleton
class IAPCubit extends Cubit<IAPState> with CubitUseCaseHandlerMixin<IAPState> {
  final GetPackagesUsecase _getPackagesUsecase;
  final PurchaseUsecase _purchaseUsecase;
  final RestoreUsecase _restoreUsecase;

  IAPCubit(
    this._getPackagesUsecase,
    this._purchaseUsecase,
    this._restoreUsecase,
  ) : super(IAPState.initial());

  // Using executeListUseCase for loading products
  void loadIapProducts() async {
    await executeListUseCase(
      usecase: _getPackagesUsecase.call,
      onSuccess: (products) {
        if (products.data.isEmpty) return;
        String largestProductPriceId = products.data
            .reduce((a, b) => a.rawPrice > b.rawPrice ? a : b).id;
        emit(state.copyWith(
          iapProducts: products.data, 
          selectedProductId: largestProductPriceId,
        ));
      },
      onFailure: (error) => emit(state.copyWith(error: error.toString())),
    );
  }

  // Using executeUseCase for purchase
  Future<void> purchaseProduct({PurchaseType type = PurchaseType.subscription}) async {
    await executeUseCase(
      usecase: () => _purchaseUsecase.call(
        PurchaseParams(productId: state.selectedProductId, type: type)
      ),
      onSuccess: (verify) => emit(state.copyWith(isLoading: false)),
      onFailure: (error) => emit(state.copyWith(error: error.toString())),
    );
  }

  // Using executeUseCase for restore
  Future<void> restorePurchases() async {
    await executeUseCase(
      usecase: () => _restoreUsecase.call(),
      onSuccess: (verify) => emit(state.copyWith(isLoading: false)),
      onFailure: (error) => emit(state.copyWith(error: error.toString())),
    );
  }
}
```

### Benefits of UseCase Handler Mixins

The custom handler mixins provide several advantages:

1. **Automatic Loading State Management**: No need to manually emit loading states before and after use case execution
2. **Consistent Error Handling**: Standardized error handling across all BLoCs/Cubits
3. **Reduced Boilerplate**: Less repetitive code in each state management class
4. **Type Safety**: Generic type support for different response types
5. **Pagination Support**: Built-in support for paginated data with automatic merging
6. **Flexible State Updates**: Optional loading state management for cases where it's not needed

### Handler Method Types

- **`executeUseCase`**: For standard API calls returning `BaseResponse<T>`
- **`executeEmptyUseCase`**: For API calls that don't return data
- **`executeListUseCase`**: For API calls returning `BaseResponseList<T>`
- **`executePageBreakUseCase`**: For paginated data with automatic merging
- **`executeCustomUseCase`**: For use cases returning custom types

## Hydrated BLoC (State Persistence)

### Persistent State Management
For state that needs to persist across app restarts:

```dart
@injectable
class SettingsCubit extends HydratedCubit<SettingsState> {
  SettingsCubit() : super(const SettingsState.initial());

  void updateThemeMode(ThemeMode themeMode) {
    state.maybeWhen(
      loaded: (settings) => emit(SettingsState.loaded(
        settings.copyWith(themeMode: themeMode),
      )),
      orElse: () => emit(SettingsState.loaded(
        SettingsEntity(themeMode: themeMode),
      )),
    );
  }

  void updateLanguage(String languageCode) {
    state.maybeWhen(
      loaded: (settings) => emit(SettingsState.loaded(
        settings.copyWith(languageCode: languageCode),
      )),
      orElse: () => emit(SettingsState.loaded(
        SettingsEntity(languageCode: languageCode),
      )),
    );
  }

  @override
  SettingsState? fromJson(Map<String, dynamic> json) {
    try {
      final settings = SettingsEntity.fromJson(json);
      return SettingsState.loaded(settings);
    } catch (_) {
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(SettingsState state) {
    return state.maybeWhen(
      loaded: (settings) => settings.toJson(),
      orElse: () => null,
    );
  }
}
```

## UI Integration

### BlocProvider Integration
```dart
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<AuthBloc>(),
      child: const LoginView(),
    );
  }
}
```

### BlocBuilder Usage
```dart
class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          return state.when(
            initial: () => const LoginForm(),
            loading: () => const Center(child: CircularProgressIndicator()),
            authenticated: (user) => const HomePage(),
            unauthenticated: () => const LoginForm(),
            error: (message) => LoginForm(errorMessage: message),
          );
        },
      ),
    );
  }
}
```

### BlocListener for Side Effects
```dart
class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        state.maybeWhen(
          authenticated: (user) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Welcome, ${user.name}!')),
            );
            context.go('/home');
          },
          error: (message) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: Colors.red,
              ),
            );
          },
          orElse: () {},
        );
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          // UI building logic
        },
      ),
    );
  }
}
```

### BlocConsumer (Builder + Listener)
```dart
BlocConsumer<AuthBloc, AuthState>(
  listener: (context, state) {
    // Handle side effects
  },
  builder: (context, state) {
    // Build UI based on state
  },
)
```

## Global State Management

### App-Level BLoCs/Cubits

Global state management is handled through the `AppProviders` class which provides all application-wide BLoCs and Cubits to the widget tree.

**File**: `lib/core/helpers/provider/app_providers.dart`

```dart
class AppProviders extends StatelessWidget {
  final Widget _child;
  const AppProviders({super.key, required Widget child}) : _child = child;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Theme and UI State Management
        BlocProvider<ThemeCubit>(create: (_) => AppDI.injector.get<ThemeCubit>()),
        BlocProvider<LocaleCubit>(create: (_) => AppDI.injector.get<LocaleCubit>()),
        BlocProvider<ThemeModeCubit>(create: (_) => AppDI.injector.get<ThemeModeCubit>()),
        
        // App Navigation and Connectivity
        BlocProvider<HomeCubit>(create: (_) => AppDI.injector.get<HomeCubit>()),
        BlocProvider<ConnectivityCubit>(create: (_) => AppDI.injector.get<ConnectivityCubit>()),
        BlocProvider<DeeplinkCubit>(create: (_) => AppDI.injector.get<DeeplinkCubit>()),
        
        // User Management (Only BLoC used for Auth)
        BlocProvider<UserCubit>(create: (_) => AppDI.injector.get<UserCubit>()),
        BlocProvider<AuthBloc>(create: (_) => AppDI.injector.get<AuthBloc>()),
        
        // Feature-Specific Cubits
        BlocProvider<IAPCubit>(create: (_) => AppDI.injector.get<IAPCubit>()),      
      ],
      child: ScreenUtilInit(
        designSize: AppGlobalValue.designSize,
        minTextAdapt: true,
        splitScreenMode: true,
        child: _child,
      ),
    );
  }
}
```

### Main App Integration

**File**: `lib/main.dart`

The `AppProviders` is integrated at the root level in `main.dart`:

```dart
void main() {
  AppService.instance.init(() => runApp(const AppProviders(child: DMainApp())));
}

class DMainApp extends StatelessWidget {
  const DMainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return TranslationProvider(
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        onGenerateTitle: (context) => context.text.common.appTitle,
        onNavigationNotification: (notification) =>
            AppService.instance.onNavigationNotification(notification),
        routeInformationParser: AppPages.routes.routeInformationParser,
        routerDelegate: AppPages.routes.routerDelegate,
        routeInformationProvider: AppPages.routes.routeInformationProvider,
        
        // Theme management through Cubit selectors
        theme: context.select((ThemeCubit theme) => theme.state.themeMaterial),
        darkTheme: AppThemeMaterial.darkTheme,
        themeMode: context.select((ThemeModeCubit themeMode) => themeMode.state.themeModeData),
        
        // Localization management through Cubit selector
        locale: context.select((LocaleCubit locale) => locale.state.localeData),
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        
        builder: EasyLoading.init(),
      ),
    );
  }
}
```

### Global State Architecture

The global state management follows this pattern:

1. **AppProviders Wrapper**: Contains all global BLoCs/Cubits using `MultiBlocProvider`
2. **Dependency Injection**: All state managers are resolved through `AppDI.injector.get<T>()`
3. **Cubit Selectors**: UI reacts to state changes through `context.select()` for performance
4. **Single AuthBloc**: Only authentication uses BLoC pattern, all others use Cubit

### State Categories

- **UI State**: `ThemeCubit`, `LocaleCubit`, `ThemeModeCubit` for appearance and localization
- **App State**: `HomeCubit`, `DeeplinkCubit`, `ConnectivityCubit` for navigation and system state
- **User State**: `UserCubit`, `AuthBloc` for user management and authentication
- **Feature State**: Feature-specific Cubits for different app functionalities

## State Management Patterns

### Loading States
```dart
class DataCubit extends Cubit<DataState> {
  DataCubit(this._repository) : super(const DataState.initial());

  final DataRepository _repository;

  Future<void> loadData({bool forceRefresh = false}) async {
    if (state is _Loading) return; // Prevent multiple concurrent loads

    emit(const DataState.loading());

    try {
      final data = await _repository.getData(forceRefresh: forceRefresh);
      emit(DataState.loaded(data));
    } catch (error) {
      emit(DataState.error(error.toString()));
    }
  }

  void refresh() => loadData(forceRefresh: true);
}
```

### Pagination States
```dart
@freezed
class PaginatedState<T> with _$PaginatedState<T> {
  const factory PaginatedState.initial() = _Initial<T>;
  const factory PaginatedState.loading() = _Loading<T>;
  const factory PaginatedState.loaded({
    required List<T> items,
    required bool hasReachedMax,
    required int currentPage,
  }) = _Loaded<T>;
  const factory PaginatedState.error(String message) = _Error<T>;
}

class PaginatedCubit<T> extends Cubit<PaginatedState<T>> {
  PaginatedCubit(this._repository) : super(const PaginatedState.initial());

  final PaginatedRepository<T> _repository;

  Future<void> loadInitialPage() async {
    emit(const PaginatedState.loading());
    
    try {
      final result = await _repository.getPage(page: 1);
      emit(PaginatedState.loaded(
        items: result.items,
        hasReachedMax: result.isLastPage,
        currentPage: 1,
      ));
    } catch (error) {
      emit(PaginatedState.error(error.toString()));
    }
  }

  Future<void> loadNextPage() async {
    await state.maybeWhen(
      loaded: (items, hasReachedMax, currentPage) async {
        if (hasReachedMax) return;

        try {
          final result = await _repository.getPage(page: currentPage + 1);
          emit(PaginatedState.loaded(
            items: [...items, ...result.items],
            hasReachedMax: result.isLastPage,
            currentPage: currentPage + 1,
          ));
        } catch (error) {
          emit(PaginatedState.error(error.toString()));
        }
      },
      orElse: () async {},
    );
  }
}
```

## Testing BLoCs

### BLoC Testing
```dart
group('AuthBloc', () {
  late AuthBloc authBloc;
  late MockLoginUseCase mockLoginUseCase;
  late MockLogoutUseCase mockLogoutUseCase;

  setUp(() {
    mockLoginUseCase = MockLoginUseCase();
    mockLogoutUseCase = MockLogoutUseCase();
    authBloc = AuthBloc(mockLoginUseCase, mockLogoutUseCase);
  });

  tearDown(() {
    authBloc.close();
  });

  group('AuthLoginRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [loading, authenticated] when login succeeds',
      build: () {
        when(() => mockLoginUseCase(any()))
            .thenAnswer((_) async => Right(userEntity));
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthEvent.loginRequested(
        email: 'test@test.com',
        password: 'password',
      )),
      expect: () => [
        const AuthState.loading(),
        AuthState.authenticated(userEntity),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [loading, error] when login fails',
      build: () {
        when(() => mockLoginUseCase(any()))
            .thenAnswer((_) async => Left(NetworkFailure('Network error')));
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthEvent.loginRequested(
        email: 'test@test.com',
        password: 'password',
      )),
      expect: () => [
        const AuthState.loading(),
        const AuthState.error('Network error'),
      ],
    );
  });
});
```

### Cubit Testing
```dart
group('UserCubit', () {
  late UserCubit userCubit;
  late MockGetUserUseCase mockGetUserUseCase;

  setUp(() {
    mockGetUserUseCase = MockGetUserUseCase();
    userCubit = UserCubit(mockGetUserUseCase);
  });

  tearDown(() {
    userCubit.close();
  });

  blocTest<UserCubit, UserState>(
    'emits [loading, loaded] when loadUser succeeds',
    build: () {
      when(() => mockGetUserUseCase(any()))
          .thenAnswer((_) async => Right(userEntity));
      return userCubit;
    },
    act: (cubit) => cubit.loadUser('user-id'),
    expect: () => [
      const UserState.loading(),
      UserState.loaded(userEntity),
    ],
  );
});
```

## Best Practices

### State Design
- Keep states immutable using `@freezed`
- Use sealed unions for different state variants
- Include error messages in error states
- Design states to represent UI needs

### Event Design (Auth BLoC only)
- Use descriptive event names
- Include all necessary data in events
- Keep events simple and focused
- Use `@freezed` for immutable events

### BLoC/Cubit Choice
- Use **Cubit** for all state management by default
- Use **BLoC** only for the **auth** feature where complex event handling is needed
- Use **HydratedBloc/Cubit** for persistent state
- Always extend Cubit/BLoC with the appropriate UseCase handler mixin

### UseCase Handler Implementation
- Always use `CubitUseCaseHandlerMixin` or `BlocUseCaseHandlerMixin` to avoid code duplication
- Use the appropriate handler method based on your return type:
  - `executeUseCase` for `BaseResponse<T>`
  - `executeListUseCase` for `BaseResponseList<T>`
  - `executePageBreakUseCase` for paginated data
  - `executeEmptyUseCase` for operations without return data
  - `executeCustomUseCase` for custom return types
- Provide `setLoadingState` function when loading states are needed
- Always handle both `onSuccess` and `onFailure` callbacks

### Performance Optimization
- Avoid creating new BLoCs/Cubits unnecessarily
- Use `BlocBuilder` with `buildWhen` for selective rebuilds
- Dispose of BLoCs/Cubits properly to prevent memory leaks
- Use `BlocListener` for side effects, not UI building

### Error Handling
- Let the UseCase handler mixins manage loading states automatically
- Always handle error states in UI components
- Use the `AppException` class for consistent error handling
- Provide meaningful error messages to users
- Implement retry mechanisms where appropriate

### Testing
- Test all state transitions
- Mock dependencies and use cases properly
- Use `blocTest` package for easier testing
- Test both success and failure scenarios
- Mock the handler mixin methods when necessary
