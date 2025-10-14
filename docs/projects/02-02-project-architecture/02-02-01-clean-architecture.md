# Clean Architecture Implementation

This document explains the Clean Architecture implementation in Dcore Flutter projects.

## Architecture Overview

The Dcore project follows Clean Architecture principles with a clear separation of concerns across three main layers:

```
lib/
├── config/           # App-level configuration
├── core/             # Shared utilities and constants  
└── src/              # Clean Architecture layers
    ├── domain/       # Business Logic Layer
    ├── data/         # Data Access Layer
    └── presentation/ # User Interface Layer
```

## Layer Responsibilities

### Domain Layer (`src/domain/`)
The innermost layer containing business logic and rules.

#### Components:
- **Entities**: Core business objects
- **Use Cases**: Application-specific business rules
- **Repository Interfaces**: Contracts for data access

#### Structure:
```
src/domain/
├── entities/
│   ├── user_entity.dart
│   ├── product_entity.dart
│   └── ...
├── repositories/
│   ├── user_repository.dart
│   ├── product_repository.dart
│   └── ...
└── usecases/
    ├── auth/
    │   ├── login_usecase.dart
    │   └── logout_usecase.dart
    └── user/
        ├── get_user_usecase.dart
        └── update_user_usecase.dart
```

#### Example Entity:
```dart
@freezed
class UserEntity with _$UserEntity {
  const factory UserEntity({
    required String id,
    required String name,
    required String email,
    String? profileImageUrl,
    @Default(false) bool isVerified,
  }) = _UserEntity;
}
```

#### Example Repository Interface:
```dart
abstract class UserRepository {
  TaskEither<AppException, UserEntity> getUser(String id);
  TaskEither<AppException, UserEntity> updateUser(UserEntity user);
  TaskEither<AppException, void> deleteUser(String id);
}
```

#### Example Use Case:
```dart
@injectable
class GetUserUseCase {
  const GetUserUseCase(this._userRepository);
  
  final UserRepository _userRepository;
  
  TaskEither<AppException, UserEntity> call(String userId) {
    return _userRepository.getUser(userId);
  }
}
```

### Data Layer (`src/data/`)
The outermost layer handling data sources and external communications.

#### Components:
- **Models**: Data representations with JSON serialization
- **Data Sources**: Remote and local data access
- **Repository Implementations**: Concrete implementations of domain contracts

#### Structure:
```
src/data/
├── datasources/
│   ├── local/
│   │   ├── user_local_datasource.dart
│   │   └── cache_datasource.dart
│   └── remote/
│       ├── user_remote_datasource.dart
│       └── api_datasource.dart
├── models/
│   ├── user_model.dart
│   ├── product_model.dart
│   └── ...
└── repositories/
    ├── user_repository_impl.dart
    ├── product_repository_impl.dart
    └── ...
```

#### Example Model:
```dart
@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String name,
    required String email,
    String? profileImageUrl,
    @Default(false) bool isVerified,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}

extension UserModelX on UserModel {
  UserEntity toEntity() => UserEntity(
    id: id,
    name: name,
    email: email,
    profileImageUrl: profileImageUrl,
    isVerified: isVerified,
  );
}
```

#### Example Data Source:
```dart
@injectable
class UserRemoteDataSource {
  const UserRemoteDataSource(this._apiClient);
  
  final ApiClient _apiClient;
  
  Future<UserModel> getUser(String id) async {
    final response = await _apiClient.getUser(id);
    return UserModel.fromJson(response.data);
  }
  
  Future<UserModel> updateUser(UserModel user) async {
    final response = await _apiClient.updateUser(
      user.id, 
      user.toJson(),
    );
    return UserModel.fromJson(response.data);
  }
}
```

#### Example Repository Implementation:
```dart
@Injectable(as: UserRepository)
class UserRepositoryImpl implements UserRepository {
  const UserRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
  );
  
  final UserRemoteDataSource _remoteDataSource;
  final UserLocalDataSource _localDataSource;
  
  @override
  TaskEither<AppException, UserEntity> getUser(String id) async {
    try {
      // Try to get from cache first
      final cachedUser = await _localDataSource.getUser(id);
      if (cachedUser != null) {
        return Right(cachedUser.toEntity());
      }
      
      // Fetch from remote
      final remoteUser = await _remoteDataSource.getUser(id);
      
      // Cache the result
      await _localDataSource.saveUser(remoteUser);
      
      return Right(remoteUser.toEntity());
    } on NetworkException catch (e) {
      return Left(NetworkException(e.message));
    } catch (e) {
      return Left(AppException('Failed to get user: $e'));
    }
  }
}
```

### Presentation Layer (`src/presentation/`)
The UI layer handling user interactions and state management.

#### Components:
- **Pages**: Full screen widgets
- **Widgets**: Reusable UI components  
- **BLoCs/Cubits**: State management
- **Models**: UI-specific data representations

#### Structure:
```
src/presentation/
├── blocs/
│   ├── auth/
│   │   ├── auth_bloc.dart
│   │   ├── auth_event.dart
│   │   └── auth_state.dart
│   └── user/
│       ├── user_cubit.dart
│       └── user_state.dart
├── pages/
│   ├── auth/
│   │   ├── login_page.dart
│   │   └── register_page.dart
│   └── user/
│       ├── user_profile_page.dart
│       └── user_settings_page.dart
└── widgets/
    ├── common/
    │   ├── custom_button.dart
    │   └── loading_indicator.dart
    └── user/
        ├── user_avatar.dart
        └── user_info_card.dart
```

#### Example BLoC:
```dart
@injectable
class UserCubit extends Cubit<UserState> {
  UserCubit(this._getUserUseCase) : super(const UserState.initial());
  
  final GetUserUseCase _getUserUseCase;
  
  Future<void> loadUser(String userId) async {
    emit(const UserState.loading());
    
    final result = await _getUserUseCase(userId);
    
    result.fold(
      (error) => emit(UserState.error(error.message)),
      (user) => emit(UserState.loaded(user)),
    );
  }
}

@freezed
class UserState with _$UserState {
  const factory UserState.initial() = _Initial;
  const factory UserState.loading() = _Loading;
  const factory UserState.loaded(UserEntity user) = _Loaded;
  const factory UserState.error(String message) = _Error;
}
```

#### Example Page:
```dart
class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key, required this.userId});
  
  final String userId;
  
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<UserCubit>()..loadUser(userId),
      child: Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: BlocBuilder<UserCubit, UserState>(
          builder: (context, state) {
            return state.when(
              initial: () => const SizedBox.shrink(),
              loading: () => const Center(child: CircularProgressIndicator()),
              loaded: (user) => UserProfileView(user: user),
              error: (message) => Center(child: Text(message)),
            );
          },
        ),
      ),
    );
  }
}
```

## Dependency Flow

### Dependency Rule
Dependencies point inward toward the domain layer:

```
Presentation → Domain ← Data
```

- **Presentation** depends on **Domain**
- **Data** depends on **Domain**
- **Domain** depends on nothing (except core utilities)

### Interface Implementation
The domain layer defines interfaces that the data layer implements:

```dart
// Domain layer defines the contract
abstract class UserRepository {
  TaskEither<AppException, UserEntity> getUser(String id);
}

// Data layer implements the contract
@Injectable(as: UserRepository)
class UserRepositoryImpl implements UserRepository {
  // Implementation details
}

// Presentation layer uses the contract
class UserCubit {
  UserCubit(this._userRepository); // Depends on interface, not implementation
  final UserRepository _userRepository;
}
```

## Error Handling

### Functional Error Handling
Using `Either` type for error handling:

```dart
// Success or failure result
TaskEither<AppException, UserEntity> getUser(String id);

// Usage in BLoC
final result = await _getUserUseCase(userId);
result.fold(
  (error) => emit(UserState.error(error.message)),
  (user) => emit(UserState.loaded(user)),
);
```

### Exception Hierarchy
```dart
abstract class AppException implements Exception {
  const AppException(this.message);
  final String message;
}

class NetworkException extends AppException {
  const NetworkException(super.message);
}

class ValidationException extends AppException {
  const ValidationException(super.message);
}
```

## Dependency Injection

### Service Registration
```dart
// Domain layer
@injectable
class GetUserUseCase { /* ... */ }

// Data layer  
@Injectable(as: UserRepository)
class UserRepositoryImpl implements UserRepository { /* ... */ }

// Presentation layer
@injectable
class UserCubit extends Cubit<UserState> { /* ... */ }
```

### Usage in Widgets
```dart
class UserProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<UserCubit>(), // Dependency injection
      child: /* ... */,
    );
  }
}
```

## Testing Strategy

### Unit Testing by Layer

#### Domain Layer Testing
```dart
group('GetUserUseCase', () {
  test('should return user when repository returns user', () async {
    // Arrange
    when(() => mockUserRepository.getUser(any()))
        .thenAnswer((_) async => Right(userEntity));
    
    // Act
    final result = await getUserUseCase('user-id');
    
    // Assert
    expect(result, equals(Right(userEntity)));
  });
});
```

#### Data Layer Testing
```dart
group('UserRepositoryImpl', () {
  test('should return user from remote when cache is empty', () async {
    // Arrange
    when(() => mockLocalDataSource.getUser(any()))
        .thenAnswer((_) async => null);
    when(() => mockRemoteDataSource.getUser(any()))
        .thenAnswer((_) async => userModel);
    
    // Act
    final result = await userRepository.getUser('user-id');
    
    // Assert
    expect(result, equals(Right(userEntity)));
  });
});
```

#### Presentation Layer Testing
```dart
group('UserCubit', () {
  blocTest<UserCubit, UserState>(
    'should emit loading then loaded when loadUser succeeds',
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

## Benefits of Clean Architecture

### Maintainability
- Clear separation of concerns
- Easy to understand and modify
- Reduced coupling between layers

### Testability
- Each layer can be tested independently
- Easy to mock dependencies
- High test coverage possible

### Scalability
- New features follow established patterns
- Easy to add new data sources or UI components
- Consistent architecture across the app

### Platform Independence
- Business logic is independent of Flutter
- Can be reused across different platforms
- Easy to change external dependencies