# Generate Code

## Overview
Run code generation for the Meup Flutter project, including models, dependency injection, routes, localization, and other generated code.

## Quick Commands

### Full Code Generation
```bash
# Complete code generation workflow
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
./tools/macos/localization/generate_localization.sh
flutter gen-l10n
```

### Specific Generation Tasks

#### 1. **Build Runner Generation**
Generates models, DI, routes, and API clients:
```bash
# Clean previous generated files
dart run build_runner clean

# Generate all code
dart run build_runner build --delete-conflicting-outputs

# Watch mode for development (auto-regenerates on changes)
dart run build_runner watch --delete-conflicting-outputs
```

#### 2. **Localization Generation**
Generates ARB files from Google Sheets and Dart localization classes:
```bash
# Generate from Google Sheets and create Dart files
./tools/macos/localization/generate_localization.sh

# Only generate Dart files from existing ARB files
flutter gen-l10n
```

#### 3. **Firebase Configuration**
Generate Firebase configuration for all flavors:
```bash
./tools/macos/config/flutterfire_config.sh
```

#### 4. **App Icons**
Generate app icons for all flavors:
```bash
flutter pub run flutter_launcher_icons
```

#### 5. **Flavor Configuration**
Regenerate flavor-specific configurations:
```bash
dart run flutter_flavorizr
```

## What Gets Generated

### Build Runner Generates:
- **Models**: JSON serialization (`*.g.dart`)
- **Freezed Classes**: Immutable classes and unions (`*.freezed.dart`)
- **Dependency Injection**: Service registration (`*.config.dart`)
- **Routes**: Navigation and routing (`*.gr.dart`)
- **Retrofit APIs**: HTTP client interfaces (`*.g.dart`)

### Files That Trigger Regeneration:

#### Models (JSON Serialization):
```dart
// Requires regeneration when changed
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

#### Dependency Injection:
```dart
// Requires regeneration when @injectable/@lazySingleton added
@lazySingleton
class UserRepository { }

@injectable  
class UserCubit { }
```

#### Routes:
```dart
// Requires regeneration when routes added/changed
@TypedGoRoute<UserRoute>(path: '/user/:id')
class UserRoute extends GoRouteData { }
```

#### API Clients:
```dart
// Requires regeneration when API methods added/changed
@RestApi()
abstract class UserApiClient {
  @GET('/users/{id}')
  Future<UserModel> getUser(@Path('id') String id);
}
```

## Generation Checklist

### Before Generation:
- [ ] All dependencies are up to date (`flutter pub get`)
- [ ] No syntax errors in code
- [ ] All required annotations are present
- [ ] Build conflicts resolved

### After Generation:
- [ ] No generation errors
- [ ] Generated files compile without errors
- [ ] All imports are resolved
- [ ] App builds successfully

## Common Generation Issues

### Build Runner Issues:
```bash
# If generation fails, try:
flutter clean
flutter pub get
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

### Dependency Injection Issues:
```bash
# If DI registration fails:
# 1. Check all @injectable/@lazySingleton annotations
# 2. Ensure dependencies are properly injected
# 3. Run generation again
dart run build_runner build --delete-conflicting-outputs
```

### Localization Issues:
```bash
# If localization fails:
# 1. Check Google Sheets connection
# 2. Verify ARB file format
# 3. Run manual generation
flutter gen-l10n
```

## Development Workflow

### During Active Development:
```bash
# Use watch mode for automatic regeneration
dart run build_runner watch --delete-conflicting-outputs
```

### Before Committing:
```bash
# Full generation to ensure everything is up to date
dart run build_runner build --delete-conflicting-outputs
./tools/macos/localization/generate_localization.sh
flutter analyze
flutter test
```

### After Pulling Changes:
```bash
# Regenerate after pulling changes from others
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

## Generated File Patterns

### Naming Conventions:
- **JSON Serialization**: `*.g.dart`
- **Freezed Classes**: `*.freezed.dart`
- **DI Configuration**: `*.config.dart`
- **Routes**: `*.gr.dart`
- **Localization**: `app_localizations*.dart`

### Import Patterns:
```dart
// Always import the main file, not generated files
import 'user_model.dart'; // ✅ Correct
// import 'user_model.g.dart'; // ❌ Wrong

// Generated files are imported automatically by the main file
```

## Troubleshooting

### Common Errors:

#### "Conflicting outputs detected":
```bash
dart run build_runner build --delete-conflicting-outputs
```

#### "Could not find a file named pubspec.yaml":
```bash
# Ensure you're in the project root directory
cd /path/to/meup-flutter
dart run build_runner build --delete-conflicting-outputs
```

#### Localization script permission denied:
```bash
chmod +x ./tools/macos/localization/generate_localization.sh
./tools/macos/localization/generate_localization.sh
```

### When Generation Fails:
1. Check for syntax errors in your code
2. Ensure all required dependencies are in `pubspec.yaml`
3. Verify annotation usage is correct
4. Try clean and rebuild
5. Check build_runner logs for specific errors

## Performance Tips

### Faster Generation:
- Use `--delete-conflicting-outputs` to avoid conflicts
- Use watch mode during development
- Only run full generation when necessary
- Keep generated files in version control for faster builds

### Avoiding Unnecessary Regeneration:
- Don't modify generated files manually
- Use `part` directives correctly
- Keep annotations consistent