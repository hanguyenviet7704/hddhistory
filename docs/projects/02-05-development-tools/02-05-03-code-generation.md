# Code Generation

This document explains the code generation system used in Dcore projects for automating repetitive code tasks.

## Overview

The Dcore project uses extensive code generation to automate the creation of boilerplate code, ensuring consistency and reducing development time. The code generation is primarily handled by `build_runner` with various packages.

## Code Generation Setup

### Primary Generation Script
**File**: `tools/macos/resource/generate_file.sh`

**Usage**:
```bash
sh tools/macos/resource/generate_file.sh
```

**Process**:
```bash
# The script executes:
fvm dart run build_runner build --delete-conflicting-outputs
```

### Manual Execution
```bash
# Standard generation
dart run build_runner build --delete-conflicting-outputs

# Watch mode for development
dart run build_runner watch --delete-conflicting-outputs

# Clean generated files
dart run build_runner clean
```

## Code Generation Categories

### JSON Serialization (`json_annotation` & `json_serializable`)

#### Purpose
Generate `fromJson()` and `toJson()` methods for model classes.

#### Configuration
Models use `@JsonSerializable()` annotation:

```dart
// user_model.dart
import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.profileImageUrl,
  });

  final String id;
  final String name;
  final String email;
  @JsonKey(name: 'profile_image_url')
  final String? profileImageUrl;

  factory UserModel.fromJson(Map<String, dynamic> json) => 
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}
```

#### Generated Output
Creates `user_model.g.dart`:
```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      profileImageUrl: json['profile_image_url'] as String?,
    );

Map<String, dynamic> _$UserModelToJson(UserModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'profile_image_url': instance.profileImageUrl,
    };
```

### Immutable Classes (`freezed`)

#### Purpose
Generate immutable data classes with copying, equality, and toString methods.

#### Configuration
```dart
// user_entity.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_entity.freezed.dart';
part 'user_entity.g.dart';

@freezed
class UserEntity with _$UserEntity {
  const factory UserEntity({
    required String id,
    required String name,
    required String email,
    String? profileImageUrl,
    @Default(false) bool isVerified,
  }) = _UserEntity;

  factory UserEntity.fromJson(Map<String, dynamic> json) => 
      _$UserEntityFromJson(json);
}
```

#### Generated Output
Creates `user_entity.freezed.dart` with:
- Immutable class implementation
- `copyWith()` method for object copying
- `toString()`, `hashCode`, and `==` implementations
- Union types and pattern matching (when used)

### API Clients (`retrofit`)

#### Purpose
Generate HTTP clients from interface definitions.

#### Configuration
```dart
// user_api_client.dart
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/user_model.dart';

part 'user_api_client.g.dart';

@RestApi(baseUrl: '/api/v1')
abstract class UserApiClient {
  factory UserApiClient(Dio dio) = _UserApiClient;

  @GET('/users/{id}')
  Future<UserModel> getUser(@Path('id') String id);

  @GET('/users')
  Future<List<UserModel>> getUsers(
    @Query('page') int page,
    @Query('limit') int limit,
  );

  @POST('/users')
  Future<UserModel> createUser(@Body() UserModel user);

  @PUT('/users/{id}')
  Future<UserModel> updateUser(
    @Path('id') String id,
    @Body() UserModel user,
  );

  @DELETE('/users/{id}')
  Future<void> deleteUser(@Path('id') String id);
}
```

#### Generated Output
Creates `user_api_client.g.dart` with complete HTTP client implementation.

### Dependency Injection (`injectable` & `get_it`)

#### Purpose
Generate dependency injection configuration.

#### Configuration
Service classes use `@injectable` annotation:
```dart
// user_repository_impl.dart
@Injectable(as: UserRepository)
class UserRepositoryImpl implements UserRepository {
  const UserRepositoryImpl(this._apiClient, this._localDataSource);

  final UserApiClient _apiClient;
  final UserLocalDataSource _localDataSource;

  // Implementation details...
}

// user_cubit.dart
@injectable
class UserCubit extends Cubit<UserState> {
  UserCubit(this._getUserUseCase) : super(const UserState.initial());

  final GetUserUseCase _getUserUseCase;

  // Implementation details...
}
```

Main injection configuration:
```dart
// injection.dart
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injection.config.dart';

final GetIt getIt = GetIt.instance;

@InjectableInit()
void configureDependencies() => getIt.init();
```

#### Generated Output
Creates `injection.config.dart` with complete dependency registration.

### Route Generation (`go_router_builder`)

#### Purpose
Generate type-safe route definitions.

#### Configuration
```dart
// app_router.dart
import 'package:go_router/go_router.dart';
import 'package:go_router_builder/go_router_builder.dart';

part 'app_router.g.dart';

@TypedGoRoute<HomeRoute>(
  path: '/home',
  name: 'home',
)
class HomeRoute extends GoRouteData {
  const HomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const HomePage();
}

@TypedGoRoute<UserProfileRoute>(
  path: '/user/:userId',
  name: 'user-profile',
)
class UserProfileRoute extends GoRouteData {
  const UserProfileRoute({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return UserProfilePage(userId: userId);
  }
}

@TypedStatefulShellRoute<AppShellRouteData>(
  branches: <TypedStatefulShellBranch<StatefulShellBranchData>>[
    TypedStatefulShellBranch<HomeBranchData>(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<HomeRoute>(path: '/home'),
      ],
    ),
  ],
)
class AppShellRouteData extends StatefulShellRouteData {
  const AppShellRouteData();

  @override
  Widget builder(
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell navigationShell,
  ) {
    return AppShell(navigationShell: navigationShell);
  }
}
```

#### Generated Output
Creates `app_router.g.dart` with type-safe routing methods and GoRouter configuration.

### Asset Generation (`flutter_gen`)

#### Purpose
Generate type-safe asset references.

#### Configuration
In `pubspec.yaml`:
```yaml
flutter_gen:
  output: lib/core/constants/gen/
  line_length: 200

  assets:
    enabled: true
    outputs:
      style: dot-delimiter
      class_name: AppAssets
    exclude: []

  fonts:
    enabled: true
    outputs:
      class_name: AppFonts

  colors:
    enabled: true
    outputs:
      class_name: AppColors
```

#### Generated Output
Creates files in `lib/core/constants/gen/`:
- `assets.gen.dart` - Asset references
- `fonts.gen.dart` - Font references  
- `colors.gen.dart` - Color constants

Usage:
```dart
// Type-safe asset references
Image.asset(AppAssets.images.logo.path)
Text('Hello', style: TextStyle(fontFamily: AppFonts.nunito))
Container(color: AppColors.primary)
```

### Localization Generation (`slang`)

#### Purpose
Generate localization classes from module-based YAML files (synced from Google Sheets via tooling).

#### Configuration
- Source YAML per locale/module: `assets/i18n/<locale>/<module>.yaml`
- Config: `slang.yaml`
- Generated output: `lib/config/l10n/strings*.g.dart`

Usage:
```dart
// Access localizations (TranslationProvider wraps the app)
final t = context.text; // shortcut extension
Text(t.common.appTitle)
Text(t.auth.authGreeting(name: 'John'))
```

## Build Configuration

### build.yaml
Configuration for build_runner:
```yaml
targets:
  $default:
    builders:
      json_serializable:
        options:
          explicit_to_json: true
          field_rename: snake
          include_if_null: false

      freezed:
        options:
          map: true
          when: true
          maybe_when: true

      injectable_generator:auto_register:
        options:
          auto_register: true
          class_name_pattern: "^_?[A-Z][a-zA-Z0-9]*Service$|^_?[A-Z][a-zA-Z0-9]*Repository$|^_?[A-Z][a-zA-Z0-9]*DataSource$"

global_options:
  json_serializable:
    runs_before:
      - freezed
```

### Generated File Management

#### .gitignore Configuration
Generated files that should be committed:
```gitignore
# Don't ignore these generated files
!**/*.g.dart
!**/*.freezed.dart
!**/*.gr.dart
!**/*.config.dart
!**/gen/
!**/l10n/
```

Files to ignore:
```gitignore
# Build runner intermediate files
.dart_tool/build/
build/
```

## Development Workflow

### When to Run Code Generation

#### Required Generation
Run code generation when you:
- Add new models with `@JsonSerializable()`
- Create new `@freezed` classes
- Add new services with `@injectable`
- Modify API client interfaces
- Add new routes to router
- Add new assets to pubspec.yaml
- Update ARB translation files

#### Generation Commands
```bash
# Quick generation (recommended)
sh tools/macos/resource/generate_file.sh

# Manual generation
dart run build_runner build --delete-conflicting-outputs

# Watch mode during development
dart run build_runner watch --delete-conflicting-outputs

# Clean and regenerate
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

### IDE Integration

#### VS Code
Add build tasks in `.vscode/tasks.json`:
```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Generate Code",
      "type": "shell",
      "command": "dart",
      "args": ["run", "build_runner", "build", "--delete-conflicting-outputs"],
      "group": "build",
      "presentation": {
        "echo": true,
        "reveal": "always"
      }
    },
    {
      "label": "Watch Code Generation",
      "type": "shell",
      "command": "dart",
      "args": ["run", "build_runner", "watch", "--delete-conflicting-outputs"],
      "group": "build",
      "isBackground": true
    }
  ]
}
```

#### IntelliJ/Android Studio
Configure external tools:
1. Settings > Tools > External Tools
2. Add tools for build_runner commands
3. Assign keyboard shortcuts

## Troubleshooting

### Common Issues

#### Build Conflicts
```bash
# Clean and regenerate
dart run build_runner clean
sh tools/macos/resource/generate_file.sh
```

#### Missing Generated Files
```bash
# Ensure proper annotations are present
# Run generation manually
dart run build_runner build --delete-conflicting-outputs
```

#### Circular Dependencies
```bash
# Check import statements
# Ensure proper part/part of declarations
# Verify dependency injection configuration
```

#### Performance Issues
```bash
# Use watch mode during development
dart run build_runner watch

# Clean periodically
dart run build_runner clean
```

### Debug Commands
```bash
# Verbose output
dart run build_runner build --verbose --delete-conflicting-outputs

# Check what files will be generated
dart run build_runner build --dry-run

# List available builders
dart run build_runner build --help
```

## Best Practices

### Code Organization
- Keep generated files alongside source files
- Use consistent naming conventions
- Group related annotations together
- Document complex generation configurations

### Performance Optimization
- Use `watch` mode during active development
- Run full generation before commits
- Clean generated files periodically
- Optimize build_runner configuration

### Version Control
- Commit generated files to avoid build issues
- Use `.gitignore` properly for build artifacts
- Document generation requirements
- Test generation on fresh checkouts

### Team Workflow
- Run generation after pulling changes
- Include generation in CI/CD pipelines
- Document generation requirements
- Use consistent build_runner versions

### Maintenance
- Keep generation packages updated
- Monitor generation performance
- Review generated code quality
- Test generation with different configurations
