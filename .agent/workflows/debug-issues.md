---
trigger: model_decision
description: Workflow for /debug-issues (Debug Issues)
---

# Debug Issues

## Invocation
Use only when the user explicitly requests `/debug-issues` or asks to run this workflow.
Ask the listed questions first, then execute the steps.

## Overview
Comprehensive guide for debugging common issues in the Meup Flutter project, including development environment problems, build failures, and runtime errors.

## Quick Debugging Commands

### Clean Project
```bash
# Full project clean
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
tools/<os>/localization/localization.sh pull
```

### Check Project Health
```bash
# Analyze code issues
flutter analyze

# Run tests to identify broken functionality
flutter test

# Check dependencies
flutter pub deps
```

## Common Issues and Solutions

### 1. **Build Runner Issues**

#### Problem: Code generation fails
```
Could not find a file named pubspec.yaml
```
**Solution:**
```bash
# Ensure you're in the project root
cd /path/to/meup
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

#### Problem: Conflicting outputs
```
Conflicting outputs were detected and the build is unable to proceed
```
**Solution:**
```bash
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

#### Problem: Generated files not found
```
Target of URI doesn't exist: 'user_model.g.dart'
```
**Solution:**
```bash
# Ensure all required annotations are present
// Add missing annotations
@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String name,
  }) = _UserModel;
  
  factory UserModel.fromJson(Map<String, dynamic> json) => 
      _$UserModelFromJson(json);
}

# Regenerate code
dart run build_runner build --delete-conflicting-outputs
```

### 2. **Dependency Injection Issues**

#### Problem: GetIt registration error
```
Object/factory with type X is not registered inside GetIt
```
**Solution:**
```bash
# Check if class has proper annotation
@lazySingleton  // ✅ Correct
class UserRepository { }

# Not @injectable unless specifically needed
# @injectable  // ❌ Usually wrong for this project

# Regenerate DI code
dart run build_runner build --delete-conflicting-outputs
```

#### Problem: Circular dependency
```
Circular dependency detected
```
**Solution:**
```dart
// Break circular dependency by using interfaces
abstract class IUserRepository { }

@LazySingleton(as: IUserRepository)
class UserRepository implements IUserRepository {
  // Implementation depends on interfaces, not concrete classes
}
```

### 3. **Flutter/Dart Issues**

#### Problem: Flutter command not found
```
flutter: command not found
```
**Solution:**
```bash
# Add Flutter to PATH in shell profile
echo 'export PATH="$PATH:/path/to/flutter/bin"' >> ~/.zshrc
source ~/.zshrc

# Or use FVM if installed
fvm flutter pub get
```

#### Problem: Dart version mismatch
```
The current Dart SDK version is X.X.X
```
**Solution:**
```bash
# Update Flutter (includes Dart)
flutter upgrade

# Check versions
flutter doctor -v
dart --version
```

### 4. **Android Build Issues**

#### Problem: Gradle build failure
```
FAILURE: Build failed with an exception
```
**Solution:**
```bash
# Clean Android build
cd android && ./gradlew clean && cd ..
flutter clean
flutter pub get

# Update Gradle wrapper
cd android && ./gradlew wrapper --gradle-version=8.3 && cd ..
```

#### Problem: Flavor configuration not found
```
Could not find flavor 'dev' in project
```
**Solution:**
```bash
# Regenerate flavors
dart run flutter_flavorizr
flutter clean
flutter pub get
```

#### Problem: Signing issues
```
Keystore was tampered with, or password was incorrect
```
**Solution:**
```bash
# Check keystore configuration in android/app/build.gradle
# Verify key.properties file exists and has correct values
```

### 5. **iOS Build Issues**

#### Problem: CocoaPods issues
```
CocoaPods not installed or not in valid state
```
**Solution:**
```bash
# Install/update CocoaPods
sudo gem install cocoapods

# Update pods
cd ios && pod install --repo-update && cd ..
```

#### Problem: Xcode build failures
```
Build input file cannot be found
```
**Solution:**
```bash
# Clean iOS build
cd ios && xcodebuild clean && cd ..
flutter clean
flutter pub get
cd ios && pod install && cd ..
```

### 6. **Localization Issues**

#### Problem: Localization script fails
```
Permission denied: tools/macos/localization/localization.sh
```
**Solution:**
```bash
# Make script executable
chmod +x tools/macos/localization/localization.sh
tools/macos/localization/localization.sh pull
```

#### Problem: YAML localization parsing error
```
FormatException: Invalid JSON
```
**Solution:**
```bash
# Validate YAML file format
# Check Google Sheets connection
# Run manual generation
tools/<os>/localization/localization.sh slang
```

### 7. **State Management Issues**

#### Problem: BLoC state not updating
```dart
// Check if state is properly emitted
void loadUser() {
  emit(const UserState.loading()); // ✅ Emit loading state
  // ... async operation
  emit(UserState.success(user)); // ✅ Emit success state
}
```

#### Problem: HydratedBloc persistence issues
```dart
// Ensure proper serialization
@override
Map<String, dynamic>? toJson(UserState state) {
  return state.when(
    initial: () => null,
    loading: () => null,
    success: (user) => {'user': user.toJson()},
    error: (_) => null,
  );
}
```

### 8. **Network Issues**

#### Problem: API connection fails
```
SocketException: Failed host lookup
```
**Solution:**
```dart
// Check flavor-specific API URLs
String get apiBaseUrl {
  return switch (F.appFlavor) {
    Flavor.dev => EnvConfig.devBaseUrl, // from .env.dev
    Flavor.stg => EnvConfig.stgBaseUrl, // from .env.stg
    Flavor.prod => EnvConfig.prodBaseUrl, // from .env.prod
    _ => EnvConfig.prodBaseUrl,
  };
}
```

## Debugging Tools

### Flutter Inspector
```bash
# Open Flutter Inspector
flutter inspector

# Widget tree debugging
flutter run --debug
# Then use IDE's Flutter Inspector
```

### Network Debugging
```dart
// Enable Dio logging in debug mode
if (F.appFlavor == Flavor.dev) {
  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
  ));
}
```

### State Debugging
```dart
// Add BLoC observer for debugging
class AppBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    print('${bloc.runtimeType} $change');
  }
}

// In main.dart
Bloc.observer = AppBlocObserver();
```

## Performance Debugging

### Memory Leaks
```bash
# Use Flutter's memory tools
flutter run --profile
# Use IDE's memory profiler
```

### Widget Rebuild Issues
```dart
// Add debug print to identify rebuilds
@override
Widget build(BuildContext context) {
  print('${runtimeType} rebuilt');
  return Container(/* ... */);
}
```

### App Size Analysis
```bash
# Analyze app size
flutter build apk --analyze-size

# Check bundle size
flutter build appbundle --analyze-size
```

## Logging and Monitoring

### Debug Logging
```dart
// Use proper logging levels
final logger = Logger('ClassName');

logger.fine('Debug info');     // Dev only
logger.info('General info');   // Stg/Prod
logger.warning('Warning');     // All environments
logger.severe('Error');        // All environments
```

### Crash Reporting
```dart
// Ensure Firebase Crashlytics is configured
FirebaseCrashlytics.instance.recordError(
  error,
  stackTrace,
  fatal: false,
);
```

## Environment-Specific Debugging

### Debug by Flavor
```dart
if (F.appFlavor == Flavor.dev) {
  // Development-only debugging code
  print('Debug info: $data');
}
```

### Feature Flags for Debugging
```dart
bool get enableDebugPanel => F.appFlavor == Flavor.dev;

if (enableDebugPanel) {
  // Show debug UI
}
```

## IDE-Specific Debugging

### VS Code
- Use launch.json configurations for different flavors
- Enable Flutter hot reload
- Use breakpoints and debugger

### Android Studio
- Use Flutter Inspector
- Set breakpoints in Dart code
- Use Android profiler for performance

## Emergency Debugging

### When Nothing Works
1. **Nuclear option**:
   ```bash
   flutter clean
   rm -rf build/
   rm pubspec.lock
   flutter pub get
   dart run build_runner build --delete-conflicting-outputs
   ```

2. **Check Flutter Doctor**:
   ```bash
   flutter doctor -v
   # Fix any issues shown
   ```

3. **Update everything**:
   ```bash
   flutter upgrade
   flutter pub upgrade
   ```

4. **Verify project integrity**:
   ```bash
   git status
   git diff
   # Check for uncommitted changes that might cause issues
   ```
