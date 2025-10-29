Description: Run all code generation tasks (build_runner, localization, Firebase config) with validation

# Generate Code

## What This Does
Runs all code generation tasks in proper sequence:
- **Build runner** - Freezed, JSON serialization, DI, routes
- **Localization** - ARB files from Google Sheets and Dart generation
- **Firebase config** - FlutterFire CLI configuration for all flavors

**Validates** each step and reports any errors.

## When to Use
- After adding/modifying models with Freezed or JSON annotations
- After changing repository registrations (@lazySingleton)
- After adding/modifying routes
- After updating GraphQL schema
- After changing localization in Google Sheets
- After Firebase project changes

**Common triggers:**
- Added new entity or model
- Modified dependency injection
- Changed API contracts
- Updated navigation routes

## Required Context
**None** - Runs on entire project automatically

## Command Flow

### 1. Ask Questions
Uses `AskUserQuestion` to gather:
```
1. What to generate:
   - All (default) - Everything
   - Build runner only
   - Localization only
   - Firebase config only

2. Clean first:
   - Yes - Run build_runner clean first
   - No - Incremental generation
```

### 2. Track Progress
Uses `TodoWrite` to show progress:
```
☐ Clean previous generated files (if requested)
☐ Run build_runner (Freezed, JSON, DI, routes)
☐ Generate localization from Google Sheets
☐ Generate Dart localization files
☐ Configure Firebase (if requested)
☐ Validate generated code
☐ Run flutter analyze
```

### 3. Clean (Optional)
If user selected clean:
```bash
dart run build_runner clean
```

Removes:
- `*.g.dart` files
- `*.freezed.dart` files
- `*.config.dart` files
- `*.gr.dart` files

### 4. Run Build Runner
Executes:
```bash
dart run build_runner build --delete-conflicting-outputs
```

Generates:
- **Freezed**: `*.freezed.dart` for immutable classes
- **JSON**: `*.g.dart` for JSON serialization
- **Injectable**: `*.config.dart` for DI
- **GoRouter**: `*.gr.dart` for routes
- **Retrofit**: API client implementations

Typical time: 30-90 seconds depending on project size

### 5. Generate Localization (If Selected)
#### Step 5a: Fetch from Google Sheets
```bash
./tools/macos/localization/generate_localization.sh
```

Fetches ARB files from Google Sheets and saves to:
- `lib/config/l10n/arb/app_en.arb`
- `lib/config/l10n/arb/app_vi.arb`
- [Other languages]

#### Step 5b: Generate Dart Files
```bash
flutter gen-l10n
```

Generates:
- `lib/config/l10n/generated/app_localizations.dart`
- `lib/config/l10n/generated/app_localizations_en.dart`
- `lib/config/l10n/generated/app_localizations_vi.dart`

### 6. Configure Firebase (If Selected)
```bash
./tools/macos/config/flutterfire_config.sh
```

Configures for all flavors:
- `lib/firebase_options_dev.dart`
- `lib/firebase_options_stg.dart`
- `lib/firebase_options_prod.dart`

Requires Firebase CLI authentication.

### 7. Validate Generated Code
Checks:
- ✅ All expected files generated
- ✅ No generation errors in output
- ✅ Files are not empty
- ✅ Imports resolve correctly

Example validation:
```
Validating generated files...
✓ 47 *.freezed.dart files generated
✓ 52 *.g.dart files generated
✓ 3 *.config.dart files generated
✓ 2 *.gr.dart files generated
✓ Localization: 2 languages generated
✓ Firebase: 3 flavors configured
```

### 8. Run Flutter Analyze
```bash
flutter analyze
```

Checks for:
- Compilation errors
- Linting issues
- Missing imports
- Type errors

Reports any issues found.

## Output Format

```
✅ Code Generation Complete

🔧 Build Runner
✓ Freezed: 47 files generated
✓ JSON serialization: 52 files generated
✓ Injectable DI: 3 config files generated
✓ GoRouter: 2 route files generated
✓ Retrofit: 8 API clients generated
⏱ Time: 45 seconds

🌍 Localization
✓ Fetched from Google Sheets
✓ ARB files: 2 languages (en, vi)
✓ Dart files: app_localizations generated
✓ Keys: 234 total strings

🔥 Firebase Configuration
✓ Dev flavor: firebase_options_dev.dart
✓ Stg flavor: firebase_options_stg.dart
✓ Prod flavor: firebase_options_prod.dart

✅ Validation
✓ All files generated successfully
✓ No generation errors
✓ flutter analyze: 0 issues

🎯 Next Steps
All code generation complete. You can now:
1. Build and run the app
2. Commit the generated files
```

## Example Usage

### Example 1: After Model Changes
```
User: /generate-code
      "Added new NotificationModel with Freezed"

Claude: Questions:
        1. What to generate? → All
        2. Clean first? → Yes

        [Cleans previous generated files]
        [Runs build_runner]
        [Generates localization]
        [Validates everything]

        ✅ Complete in 52 seconds
        - 48 Freezed files (1 new)
        - 53 JSON files (1 new)
        - All validations passed
```

### Example 2: Quick Incremental
```
User: /generate-code
      "Just updated DI registration"

Claude: Questions:
        1. What to generate? → Build runner only
        2. Clean first? → No (incremental)

        [Runs build_runner incrementally]
        [Validates DI config]

        ✅ Complete in 15 seconds
        - DI config updated
        - No errors
```

### Example 3: Localization Update
```
User: /generate-code
      "Updated translations in Google Sheets"

Claude: Questions:
        1. What to generate? → Localization only
        2. Clean first? → N/A

        [Fetches from Google Sheets]
        [Generates Dart files]
        [Validates strings]

        ✅ Complete
        - 12 new keys added
        - 2 languages updated
```

## Common Issues and Solutions

### Issue: Conflicting Outputs
```
Error: Conflicting outputs were detected
```
**Solution:** Automatically uses `--delete-conflicting-outputs`

### Issue: Missing Part Directive
```
Error: 'part of' directive expected
```
**Solution:** Detected and reported:
```
⚠️ Missing part directive in:
- lib/src/data/models/notification_model.dart

Add: part of '../models.dart';
```

### Issue: Google Sheets Access
```
Error: Unable to fetch from Google Sheets
```
**Solution:** Checks and reports:
```
⚠️ Google Sheets authentication failed

Ensure:
1. Script has proper credentials
2. Sheet is shared with service account
3. Internet connection is active
```

### Issue: Firebase CLI Not Authenticated
```
Error: Firebase authentication required
```
**Solution:** Reports and provides instructions:
```
⚠️ Firebase CLI not authenticated

Run: firebase login
Then retry code generation
```

## What Gets Generated

### Freezed (`*.freezed.dart`)
For classes annotated with `@freezed`:
```dart
@freezed
class UserModel with _$UserModel { ... }

// Generates:
// user_model.freezed.dart with:
// - Copyable immutable class
// - Union types support
// - Pattern matching
```

### JSON Serialization (`*.g.dart`)
For classes with `fromJson`/`toJson`:
```dart
factory UserModel.fromJson(Map<String, dynamic> json) =>
    _$UserModelFromJson(json);

// Generates:
// user_model.g.dart with:
// - JSON parsing logic
// - Serialization methods
```

### Injectable DI (`*.config.dart`)
For classes with `@injectable`, `@lazySingleton`:
```dart
@lazySingleton
class UserRepository { ... }

// Generates:
// injection.config.dart with:
// - GetIt registration
// - Dependency resolution
```

### GoRouter Routes (`*.gr.dart`)
For route annotations:
```dart
@TypedGoRoute<UserRoute>(path: '/user/:id')
class UserRoute extends GoRouteData { ... }

// Generates:
// app_router.gr.dart with:
// - Route configuration
// - Type-safe navigation
```

## Best Practices

### When to Generate
- **Always** after model changes
- **Always** after DI changes
- **Always** after route changes
- **Regularly** for localization (weekly)
- **As needed** for Firebase config

### Before Committing
Run full generation:
```bash
/generate-code
→ All
→ Yes (clean)
```

Ensures all generated files are up-to-date.

### In CI/CD
Include in pipeline:
```yaml
- run: flutter pub get
- run: dart run build_runner build --delete-conflicting-outputs
- run: flutter gen-l10n
- run: flutter analyze
```

---

*See CLAUDE.md: Code Generation for detailed build_runner configuration*
*See CLAUDE.md: Localization for Google Sheets integration setup*
