Testing: test_product

## Architecture Updates

### TaskEither Migration (✅ Completed)
The entire codebase has been updated to use `TaskEither` from fpdart instead of `Future<Either>`:

**Benefits:**
- **Better composition**: Chain operations with `flatMap`, `map`, `fold`
- **Lazy evaluation**: TaskEither doesn't execute until `.run()` is called
- **More functional**: Follows functional programming principles
- **Type-safe**: Stronger type guarantees

**Usage Pattern:**
```dart
// Repository returns TaskEither
TaskEither<AppException, Product> getProduct(String id) {
  return TaskEither.tryCatch(...);
}

// UseCase returns TaskEither
TaskEither<AppException, Product> call(String params) {
  return _repository.getProduct(params);
}

// BLoC/Cubit runs it
final result = await _useCase(id).run();
result.fold(onError, onSuccess);
```

## Mason (Code Generation with Templates)
```bash
# List available bricks
mason list

# Generate a new feature using feature_clean brick
mason make feature_clean

# Generate feature_clean with specific name
mason make feature_clean --feature_name test_product

# Get mason brick info
mason get

# Check mason version
mason --version

# Update mason bricks
mason upgrade
```

## Code Generation (Run First)
```bash
# Generate required code files
dart run build_runner build --delete-conflicting-outputs

# Clean and regenerate if needed
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

## Code Analysis
```bash
# Analyze all code
flutter analyze

# Analyze specific file
dart analyze lib/src/test_product/data/models/product_model.dart

# Format code
dart format lib/src/test_product/
```

## Run Tests
```bash
# Run all tests
flutter test

# Run all unit tests
flutter test test/unit/

# Run specific test file (if exists)
flutter test test/unit/domain/usecases/test_product/

# Run tests with coverage
flutter test --coverage

# Run tests with verbose output
flutter test --verbose
```

## Build & Run
```bash
# Run app with dev flavor
flutter run --flavor dev -t lib/main_dev.dart

# Build APK for testing
./tools/macos/build/build_apk.sh dev

# Build with no tree shaking (for debugging)
./tools/macos/build/build_apk.sh dev --no-tree-shake-icons
```

## Quick Test Workflow
```bash
# 1. Generate code
dart run build_runner build --delete-conflicting-outputs

# 2. Analyze code
flutter analyze

# 3. Run tests
flutter test

# 4. Test run the app
flutter run --flavor dev -t lib/main_dev.dart
```

## Debugging
```bash
# Check diagnostics
dart analyze lib/src/test_product/

# View build_runner output
dart run build_runner build --verbose

# Clean everything
flutter clean && flutter pub get
```
