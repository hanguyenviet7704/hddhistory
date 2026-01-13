---
trigger: model_decision
description: Data models and code generation rules using Freezed and JSON serialization
---

# Data Models and Code Generation Rules

## Freezed for Immutable Classes

### Entity Models (Domain Layer)
```dart
@freezed
class User with _$User {
  const factory User({
    required String id,
    required String name,
    required String email,
    DateTime? lastLoginAt,
    @Default([]) List<String> permissions,
  }) = _User;
  
  // Add business logic methods
  const User._();
  
  bool get isAdmin => permissions.contains('admin');
  bool get isActive => lastLoginAt != null;
}
```

### Data Models (Data Layer)
```dart
@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String name,
    required String email,
    @JsonKey(name: 'last_login_at') DateTime? lastLoginAt,
    @Default([]) List<String> permissions,
  }) = _UserModel;
  
  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
  
  // Conversion methods
  const UserModel._();
  
  User toEntity() => User(
    id: id,
    name: name,
    email: email,
    lastLoginAt: lastLoginAt,
    permissions: permissions,
  );
}
```

### Use Case Parameters
```dart
@freezed
class GetUserParams with _$GetUserParams {
  const factory GetUserParams({
    required String userId,
    @Default(false) bool includePermissions,
  }) = _GetUserParams;
}

@freezed  
class LoginParams with _$LoginParams {
  const factory LoginParams({
    required String email,
    required String password,
    @Default(false) bool rememberMe,
  }) = _LoginParams;
}
```

### API Response Models
```dart
@freezed
class ApiResponse<T> with _$ApiResponse<T> {
  const factory ApiResponse({
    required bool success,
    required T data,
    String? message,
    @JsonKey(name: 'error_code') String? errorCode,
  }) = _ApiResponse<T>;
  
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) => _$ApiResponseFromJson(json, fromJsonT);
}
```

## JSON Serialization Rules

### Basic Serialization
```dart
@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String name,
  }) = _UserModel;
  
  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}
```

### Custom Field Names
```dart
@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    @JsonKey(name: 'full_name') required String fullName,
    @JsonKey(name: 'email_address') required String email,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _UserModel;
  
  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}
```

### Nullable and Default Values
```dart
@freezed
class UserSettings with _$UserSettings {
  const factory UserSettings({
    @Default(true) bool notificationsEnabled,
    @Default('light') String theme,
    @JsonKey(name: 'last_sync') DateTime? lastSyncAt,
    String? deviceToken,
  }) = _UserSettings;
  
  factory UserSettings.fromJson(Map<String, dynamic> json) =>
      _$UserSettingsFromJson(json);
}
```

### Enum Serialization
```dart
enum UserRole {
  @JsonValue('admin')
  admin,
  @JsonValue('user')
  user,
  @JsonValue('guest')
  guest,
}

@freezed
class User with _$User {
  const factory User({
    required String id,
    required String name,
    @Default(UserRole.user) UserRole role,
  }) = _User;
  
  factory User.fromJson(Map<String, dynamic> json) =>
      _$UserFromJson(json);
}
```

## API Client Models

### Retrofit Integration
```dart
@RestApi()
abstract class UserApiClient {
  factory UserApiClient(Dio dio) = _UserApiClient;
  
  @GET('/users/{id}')
  Future<ApiResponse<UserModel>> getUser(@Path('id') String id);
  
  @POST('/users')
  Future<ApiResponse<UserModel>> createUser(@Body CreateUserRequest request);
  
  @PUT('/users/{id}')  
  Future<ApiResponse<UserModel>> updateUser(
    @Path('id') String id,
    @Body UpdateUserRequest request,
  );
  
  @DELETE('/users/{id}')
  Future<ApiResponse<void>> deleteUser(@Path('id') String id);
}
```

### Request Models
```dart
@freezed
class CreateUserRequest with _$CreateUserRequest {
  const factory CreateUserRequest({
    required String name,
    required String email,
    required String password,
    @Default(UserRole.user) UserRole role,
  }) = _CreateUserRequest;
  
  factory CreateUserRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateUserRequestFromJson(json);
}
```

## Union Types for Complex States

### Result Types
```dart
@freezed
class LoadUserResult with _$LoadUserResult {
  const factory LoadUserResult.success(User user) = _Success;
  const factory LoadUserResult.notFound() = _NotFound;  
  const factory LoadUserResult.networkError(String message) = _NetworkError;
  const factory LoadUserResult.serverError(String message) = _ServerError;
}
```

### Validation Results
```dart
@freezed
class ValidationResult with _$ValidationResult {
  const factory ValidationResult.valid() = _Valid;
  const factory ValidationResult.invalid(List<String> errors) = _Invalid;
}
```

## Code Generation Commands

### After Model Changes
```bash
# Generate freezed and json_serializable code
dart run build_runner build --delete-conflicting-outputs

# Clean and regenerate if needed
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

## Model Testing

### Testing Data Models
```dart
group('UserModel', () {
  test('should serialize to/from JSON correctly', () {
    final user = UserModel(
      id: '123',
      name: 'John Doe',
      email: 'john@example.com',
    );
    
    final json = user.toJson();
    final fromJson = UserModel.fromJson(json);
    
    expect(fromJson, equals(user));
  });
  
  test('should convert to entity correctly', () {
    final model = UserModel(
      id: '123', 
      name: 'John Doe',
      email: 'john@example.com',
    );
    
    final entity = model.toEntity();
    
    expect(entity.id, equals(model.id));
    expect(entity.name, equals(model.name));
    expect(entity.email, equals(model.email));
  });
});
```

## Model Validation

### Built-in Validation
```dart
@freezed
class User with _$User {
  const factory User({
    required String id,
    required String name, 
    required String email,
  }) = _User;
  
  const User._();
  
  factory User.fromJson(Map<String, dynamic> json) =>
      _$UserFromJson(json);
      
  // Validation methods
  bool get isValidEmail => RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
      .hasMatch(email);
      
  bool get isValidName => name.isNotEmpty && name.length >= 2;
  
  ValidationResult validate() {
    final errors = <String>[];
    
    if (!isValidEmail) errors.add('Invalid email format');
    if (!isValidName) errors.add('Name must be at least 2 characters');
    
    return errors.isEmpty
        ? const ValidationResult.valid()
        : ValidationResult.invalid(errors);
  }
}