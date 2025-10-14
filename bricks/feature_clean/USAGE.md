# Quick Start Guide

## Installation

```bash
# If you haven't installed Mason CLI yet
dart pub global activate mason_cli

# Add the brick from local path
mason add feature_clean --path bricks/feature_clean

# Or add from current directory if you're in the bricks folder
cd bricks/feature_clean
mason add -g feature_clean
```

## Generate a Feature

```bash
mason make feature_clean
```

### Example Session

```
$ mason make feature_clean
? What is the feature name? user_profile
? What is the entity name? UserProfile
? Use BLoC instead of Cubit? (y/N) N

✓ Made brick feature_clean (0.1s)
  21 files created
```

## After Generation

### 1. Run Code Generation

```bash
# Generate all code (freezed, retrofit, injectable, etc.)
dart run build_runner build --delete-conflicting-outputs
```

### 2. Update API Endpoints

Edit `lib/core/constants/manual/endpoint.dart`:

```dart
mixin AppEndpoint {
  // ... existing endpoints

  // Add your new feature endpoints
  static const String getUserProfile = '/user/profile/{id}';
  static const String getAllUserProfiles = '/user/profiles';
  static const String createUserProfile = '/user/profile';
  static const String updateUserProfile = '/user/profile/{id}';
  static const String deleteUserProfile = '/user/profile/{id}';
}
```

### 3. Update Retrofit API

Edit the generated `data/datasources/user_profile_api.dart` to match your API:

```dart
@RestApi()
@lazySingleton
abstract class UserProfileApi {
  @factoryMethod
  factory UserProfileApi(@Named(DIKey.mainDio) Dio dio) = _UserProfileApi;

  @GET(AppEndpoint.getUserProfile)  // Update to use your endpoint
  Future<UserProfileModel> getUserProfile(@Path('id') String id);

  // ... rest of the methods
}
```

### 4. Run Tests

```bash
# Generate test mocks first
dart run build_runner build --delete-conflicting-outputs

# Run tests
flutter test test/src/user_profile/
```

### 5. Use in Your App

```dart
import 'package:meup/src/user_profile/user_profile.dart';

// In your navigation
class AppRoutes {
  static final userProfile = GoRoute(
    path: '/user-profile',
    builder: (context, state) => const UserProfilePage(),
  );
}
```

## Common Patterns

### Adding a New Use Case

1. Create the use case file:
```dart
// lib/src/user_profile/domain/usecases/search_user_profile_usecase.dart
part of '../../user_profile.dart';

@injectable
class SearchUserProfileUsecase extends UseCaseWithParams<List<UserProfileEntity>, String> {
  SearchUserProfileUsecase(this._repository);

  final IUserProfileRepository _repository;

  @override
  TaskEither<AppException, List<UserProfileEntity>> call(String params) {
    return _repository.searchUserProfile(params);
  }
}
```

2. Add to repository interface:
```dart
// In i_user_profile_repository.dart
abstract class IUserProfileRepository {
  // ... existing methods
  TaskEither<AppException, List<UserProfileEntity>> searchUserProfile(String query);
}
```

3. Implement in repository:
```dart
// In user_profile_repository.dart
@override
TaskEither<AppException, List<UserProfileEntity>> searchUserProfile(String query) {
  return TaskEither.tryCatch(
    () async {
      final models = await _api.searchUserProfile(query);
      return models.map((model) => model.toEntity()).toList();
    },
    (error, stackTrace) => AppException.fromDioException(error as DioException),
  );
}
```

4. Add to main feature file:
```dart
// In user_profile.dart
part 'domain/usecases/search_user_profile_usecase.dart';
```

5. Inject into Cubit/BLoC and use it

### Customizing Entity Fields

Edit both entity and model files:

```dart
// user_profile_entity.dart
@freezed
class UserProfileEntity with _$UserProfileEntity {
  const factory UserProfileEntity({
    required String id,
    required String name,
    required String email,      // Added
    required String avatarUrl,  // Added
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _UserProfileEntity;
}

// user_profile_model.dart
@freezed
class UserProfileModel with _$UserProfileModel {
  const UserProfileModel._();

  const factory UserProfileModel({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'name') required String name,
    @JsonKey(name: 'email') required String email,           // Added
    @JsonKey(name: 'avatar_url') required String avatarUrl,  // Added
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _UserProfileModel;

  UserProfileEntity toEntity() {
    return UserProfileEntity(
      id: id,
      name: name,
      email: email,           // Added
      avatarUrl: avatarUrl,  // Added
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
```

## Troubleshooting

### Build Runner Issues

```bash
# Clean and rebuild
flutter packages pub run build_runner clean
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### Import Errors

Make sure the hub file (`user_profile.dart`) has the correct imports and part directives.

### DI Issues

Regenerate the DI configuration:
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Test Failures

Ensure mocks are generated:
```bash
# This generates the .mocks.dart file
dart run build_runner build --delete-conflicting-outputs
```

## Tips

1. **Always run build_runner** after generating a new feature
2. **Update API endpoints** to match your backend
3. **Customize entity/model fields** to match your data structure
4. **Write tests** as you implement features
5. **Use the hub file** for clean imports (just import the feature, not individual files)
6. **Follow the pattern** for consistency across features

## Need Help?

Check the main README.md for more detailed information about the architecture and best practices.
