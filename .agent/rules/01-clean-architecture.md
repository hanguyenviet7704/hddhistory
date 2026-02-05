---
trigger: model_decision
description: Clean Architecture rules and layer separation guidelines for the Flutter project
---

# Clean Architecture Rules

## Layer Separation
Always maintain strict separation between layers:

### Domain Layer (`lib/src/domain/`)
**What belongs here:**
- Entities (business objects)
- Repository interfaces (abstract contracts)
- Use cases (business logic)
- Domain-specific exceptions

**Rules:**
- NO dependencies on other layers
- NO Flutter/UI dependencies
- NO external service dependencies
- Pure Dart code only

**Example Entity:**
```dart
@freezed
class User with _$User {
  const factory User({
    required String id,
    required String name,
    required String email,
    DateTime? lastLoginAt,
  }) = _User;
}
```

**Example Repository Interface:**
```dart
abstract class IUserRepository {
  TaskEither<AppException, User> getUser(String id);
  TaskEither<AppException, List<User>> getAllUsers();
  TaskEither<AppException, User> updateUser(User user);
}
```

### Data Layer (`lib/src/data/`)
**What belongs here:**
- Repository implementations
- Data sources (API, local storage)
- Data models (DTOs)
- Mappers between models and entities

**Rules:**
- Implements domain repository interfaces
- Handles data transformation
- Manages external service calls
- Converts exceptions to AppException

**Example Repository Implementation:**
```dart
@LazySingleton(as: IUserRepository)
class UserRepository implements IUserRepository {
  final ApiClient apiClient;
  final UserLocalDataSource localDataSource;
  
  UserRepository(this.apiClient, this.localDataSource);
  
  @override
  TaskEither<AppException, User> getUser(String id) async {
    try {
      final userModel = await apiClient.getUser(id);
      final user = userModel.toEntity();
      await localDataSource.cacheUser(userModel);
      return Right(user);
    } catch (e) {
      return Left(AppException.fromException(e));
    }
  }
}
```

### Presentation Layer (`lib/src/presentation/`)
**What belongs here:**
- Pages and screens
- Widgets and UI components
- BLoCs and Cubits
- UI-specific models

**Rules:**
- Only depends on domain layer
- Uses dependency injection for use cases
- Manages UI state with BLoC pattern
- Handles user interactions

## Dependency Rules
```
Presentation → Domain ← Data
```

- Presentation can only import Domain
- Data can only import Domain  
- Domain imports nothing from other layers
- Use dependency inversion for data access