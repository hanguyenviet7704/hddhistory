# Code Obfuscation

This document explains the code obfuscation implementation and configuration in Dcore project build processes.

## Overview

Code obfuscation is a security technique used to protect Flutter applications from reverse engineering by making the compiled code difficult to understand. The Dcore project implements comprehensive obfuscation for all release builds while maintaining debug symbols for crash analysis.

## Obfuscation Implementation

### Build Script Integration
All build scripts in `tools/macos/build/` automatically enable obfuscation for release builds:

```bash
# Example from build_apk.sh
fvm flutter build apk \
    --release \
    --obfuscate \
    --split-debug-info=".obfuscation" \
    --flavor "$FLAVOR" \
    --dart-define-from-file="$ENV_FILE" \
    -t "lib/main_$FLAVOR.dart"
```

### Key Obfuscation Parameters
- **`--obfuscate`**: Enables code obfuscation
- **`--split-debug-info=".obfuscation"`**: Separates debug symbols for crash analysis
- **`--release`**: Uses release build optimizations

## How Obfuscation Works

### Dart Code Obfuscation
Flutter's obfuscation process transforms:
- **Class names**: `UserRepository` → `a`
- **Method names**: `getUserData()` → `b()`
- **Variable names**: `emailAddress` → `c`
- **Property names**: `user.name` → `d.e`

### Example Transformation
**Original Code:**
```dart
class UserRepository {
  final String apiEndpoint;
  
  Future<User> fetchUser(String userId) async {
    final response = await http.get('$apiEndpoint/users/$userId');
    return User.fromJson(response.data);
  }
}
```

**Obfuscated Code:**
```dart
class a {
  final String b;
  
  Future<c> d(String e) async {
    final f = await g.h('$b/users/$e');
    return c.i(f.j);
  }
}
```

## Build Configuration

### Android Obfuscation
Additional obfuscation through ProGuard/R8 in `android/app/build.gradle`:

```gradle
android {
    buildTypes {
        release {
            signingConfig signingConfigs.release
            
            // Enable code shrinking and obfuscation
            minifyEnabled true
            shrinkResources true
            
            // ProGuard configuration
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
            
            // Additional optimizations
            zipAlignEnabled true
            debuggable false
        }
    }
}
```

### ProGuard Rules
```proguard
# android/app/proguard-rules.pro

# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Gson (if used)
-keepattributes Signature
-keepattributes *Annotation*
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.stream.** { *; }

# Project specific - keep model classes for JSON serialization
-keep class com.eup.meup.data.models.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep crashlytics
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
```

### iOS Obfuscation
iOS builds benefit from Flutter's Dart obfuscation and additional Xcode optimizations:

```bash
# iOS build with obfuscation
fvm flutter build ios \
    --release \
    --obfuscate \
    --split-debug-info=".obfuscation" \
    --flavor "$FLAVOR" \
    --dart-define-from-file="$ENV_FILE" \
    -t "lib/main_$FLAVOR.dart"
```

## Debug Symbol Management

### Symbol File Structure
Obfuscated builds generate debug symbol files:

```
.obfuscation/
├── app.android-arm.symbols         # ARM Android symbols
├── app.android-arm64.symbols       # ARM64 Android symbols
├── app.android-x64.symbols         # x64 Android symbols
├── app.ios-arm64.symbols          # ARM64 iOS symbols
└── mapping.txt                    # Symbol mapping file
```

### Symbol File Contents
```
# Example from mapping.txt
com.example.UserRepository -> a:
    java.lang.String apiEndpoint -> b
    User fetchUser(java.lang.String) -> c
    void setApiEndpoint(java.lang.String) -> d

com.example.User -> e:
    java.lang.String name -> f
    java.lang.String email -> g
    User fromJson(java.util.Map) -> h
```

### Firebase Crashlytics Integration
Debug symbols are automatically uploaded to Firebase Crashlytics:

```bash
# Automatic upload in build scripts
echo "🔥 Uploading debug symbols to Firebase Crashlytics..."
FIREBASE_SETUP_SCRIPT="tools/macos/config/firebase_setup.sh"

if [[ -f "$FIREBASE_SETUP_SCRIPT" ]]; then
    "$FIREBASE_SETUP_SCRIPT" "$FLAVOR" "android"
fi
```

### Manual Symbol Upload
```bash
# Upload symbols manually
firebase crashlytics:symbols:upload \
  --app=1:your-project-id:android:app-id \
  .obfuscation/

# Verify uploaded symbols
firebase crashlytics:symbols:list \
  --app=1:your-project-id:android:app-id
```

## Crash Report Analysis

### Reading Obfuscated Stack Traces
**Raw Crash Report:**
```
Exception: StateError: Bad state: No element
    at a.b (Unknown Source:2)
    at c.d (Unknown Source:15)
    at e.f (Unknown Source:8)
    at g.h (Unknown Source:12)
```

**Deobfuscated Report (with symbols):**
```
Exception: StateError: Bad state: No element
    at UserRepository.fetchUser (user_repository.dart:45)
    at UserCubit.loadUser (user_cubit.dart:28)
    at LoginBloc._onLoginRequested (login_bloc.dart:67)
    at AuthenticationService.authenticate (auth_service.dart:123)
```

### Local Deobfuscation
```bash
# Using Flutter tools for local analysis
flutter symbolize \
  --input=crash-report.txt \
  --debug-info=.obfuscation/ \
  --output=deobfuscated-report.txt
```

## Obfuscation Levels

### Standard Obfuscation (Default)
Enabled with `--obfuscate` flag:
- Renames classes, methods, and variables
- Preserves essential functionality
- Maintains compatibility with reflection

### Aggressive Obfuscation
Additional ProGuard optimizations:

```proguard
# Aggressive optimization (use with caution)
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification
-repackageclasses ''
-dontusemixedcaseclassnames
```

### Custom Obfuscation Rules
```proguard
# Keep specific classes from obfuscation
-keep class com.eup.meup.models.** { *; }

# Keep methods with specific annotations
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep enum values
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
```

## Performance Impact

### Build Time Impact
- **Increased Build Time**: 10-20% longer build times
- **Symbol Generation**: Additional time for debug info creation
- **ProGuard Processing**: Android-specific processing time

### Runtime Performance
- **Improved Performance**: Smaller binary size
- **Faster Loading**: Reduced method count
- **Memory Efficiency**: Optimized code paths

### App Size Reduction
```bash
# Example size comparison
# Without obfuscation: app-release.apk (45.2 MB)
# With obfuscation:    app-release.apk (38.7 MB)
# Size reduction:      ~14%
```

## Security Considerations

### What Obfuscation Protects
- **Source Code Logic**: Makes reverse engineering difficult
- **API Endpoints**: Harder to extract hardcoded URLs
- **Business Logic**: Protects proprietary algorithms
- **String Constants**: Obfuscates sensitive strings

### What Obfuscation Doesn't Protect
- **Network Traffic**: Use HTTPS and certificate pinning
- **Stored Data**: Encrypt sensitive local data
- **API Keys**: Use server-side validation
- **Root/Jailbreak**: Implement runtime checks

### Additional Security Measures
```dart
// Runtime security checks
class SecurityUtils {
  static bool isDeviceSecure() {
    // Check for root/jailbreak
    // Verify app integrity
    // Check for debugging tools
    return true; // Implement actual checks
  }
  
  static void obfuscateStrings() {
    // Additional string obfuscation
    const apiKey = 'QUl6YVN5RXhhbXBsZQ=='; // Base64 encoded
  }
}
```

## Testing Obfuscated Builds

### Local Testing
```bash
# Build obfuscated version for testing
sh tools/macos/build/build_apk.sh prod

# Install and test functionality
adb install build/app/outputs/flutter-apk/app-prod-release.apk

# Test crash reporting
# Trigger crashes and verify Firebase receives deobfuscated reports
```

### Automated Testing
```yaml
# CI/CD pipeline testing
test_obfuscated_build:
  runs-on: ubuntu-latest
  steps:
    - name: Build obfuscated APK
      run: sh tools/macos/build/build_apk.sh prod
      
    - name: Run integration tests
      run: flutter test integration_test/
      
    - name: Verify symbol upload
      run: firebase crashlytics:symbols:list
```

### Manual Verification
1. **Functionality Testing**: Ensure all features work correctly
2. **Crash Reporting**: Verify crashes are properly reported
3. **Performance Testing**: Check for performance regressions
4. **Security Analysis**: Reverse engineer to verify obfuscation

## Troubleshooting

### Common Obfuscation Issues

#### Reflection Problems
```dart
// Problem: Reflection fails with obfuscation
Type userType = User; // Fails in obfuscated build

// Solution: Use proper annotations or avoid reflection
@JsonSerializable()
class User {
  // Proper JSON serialization without reflection
}
```

#### Missing Debug Symbols
```bash
# Problem: Crashes show obfuscated stack traces
# Solution: Ensure symbols are uploaded
firebase crashlytics:symbols:upload .obfuscation/

# Verify upload
firebase crashlytics:symbols:list
```

#### ProGuard Issues
```proguard
# Problem: Specific classes being over-obfuscated
# Solution: Add keep rules
-keep class com.eup.meup.important.** { *; }

# Problem: Gson serialization fails
# Solution: Keep Gson-related classes
-keep class com.google.gson.** { *; }
-keepattributes Signature
```

### Debug Commands
```bash
# Check obfuscation is enabled
flutter build apk --release --obfuscate --analyze-size

# Verify symbol files exist
ls -la .obfuscation/

# Test Firebase symbol upload
firebase crashlytics:symbols:upload .obfuscation/ --dry-run

# Check ProGuard mapping
cat android/app/build/outputs/mapping/release/mapping.txt | head -20
```

### Performance Analysis
```bash
# Compare build sizes
du -h build/app/outputs/flutter-apk/app-*-release.apk

# Analyze APK content
aapt dump badging build/app/outputs/flutter-apk/app-prod-release.apk

# Method count analysis
dexdump -f build/app/intermediates/dex/release/minifyReleaseWithR8/classes.dex | grep "method_ids_size"
```

## Best Practices

### Development Workflow
- **Test Early**: Regularly test obfuscated builds
- **Symbol Management**: Always upload debug symbols
- **Version Control**: Don't commit symbol files
- **Documentation**: Document any obfuscation exclusions

### Security Practices
- **Layer Defense**: Combine multiple security techniques
- **Regular Updates**: Keep obfuscation tools updated
- **Threat Modeling**: Understand specific security risks
- **Monitoring**: Monitor for reverse engineering attempts

### Performance Optimization
- **Measure Impact**: Profile obfuscated vs non-obfuscated builds
- **Selective Obfuscation**: Exclude performance-critical code if needed
- **Build Optimization**: Optimize build pipeline for obfuscation
- **Size Monitoring**: Track app size impact over time

### Maintenance
- **Regular Testing**: Test obfuscated builds in CI/CD
- **Symbol Cleanup**: Clean old symbol files periodically
- **Rule Updates**: Update ProGuard rules as needed
- **Documentation**: Keep obfuscation documentation current