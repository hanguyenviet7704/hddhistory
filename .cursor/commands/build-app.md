# Build App

## Overview
Build the Meup Flutter application for different platforms and flavors, with proper code obfuscation and distribution-ready artifacts.

## Quick Build Commands

### Android Builds

#### APK (Development/Testing):
```bash
# Development APK
./tools/macos/build/build_apk.sh dev

# Staging APK
./tools/macos/build/build_apk.sh stg

# Production APK
./tools/macos/build/build_apk.sh prod
```

#### App Bundle (Play Store):
```bash
# Development Bundle
./tools/macos/build/build_appbundle.sh dev

# Staging Bundle
./tools/macos/build/build_appbundle.sh stg

# Production Bundle
./tools/macos/build/build_appbundle.sh prod
```

### iOS Builds

#### Development/Testing:
```bash
# Development iOS
./tools/macos/build/build_ios.sh dev

# Staging iOS
./tools/macos/build/build_ios.sh stg

# Production iOS
./tools/macos/build/build_ios.sh prod
```

#### App Store (IPA):
```bash
# Development IPA
./tools/macos/build/build_ipa.sh dev

# Staging IPA
./tools/macos/build/build_ipa.sh stg

# Production IPA
./tools/macos/build/build_ipa.sh prod
```

## Manual Build Commands

### Android Manual Builds:

#### APK:
```bash
# Development
flutter build apk --flavor dev --dart-define-from-file=.env/.env.dev -t lib/main_dev.dart --obfuscate --split-debug-info=.obfuscation/dev/

# Staging
flutter build apk --flavor stg --dart-define-from-file=.env/.env.stg -t lib/main_stg.dart --obfuscate --split-debug-info=.obfuscation/stg/

# Production
flutter build apk --flavor prod --dart-define-from-file=.env/.env.prod -t lib/main_prod.dart --obfuscate --split-debug-info=.obfuscation/prod/
```

#### App Bundle:
```bash
# Development
flutter build appbundle --flavor dev --dart-define-from-file=.env/.env.dev -t lib/main_dev.dart --obfuscate --split-debug-info=.obfuscation/dev/

# Staging
flutter build appbundle --flavor stg --dart-define-from-file=.env/.env.stg -t lib/main_stg.dart --obfuscate --split-debug-info=.obfuscation/stg/

# Production
flutter build appbundle --flavor prod --dart-define-from-file=.env/.env.prod -t lib/main_prod.dart --obfuscate --split-debug-info=.obfuscation/prod/
```

### iOS Manual Builds:

#### iOS App:
```bash
# Development
flutter build ios --flavor dev --dart-define-from-file=.env/.env.dev -t lib/main_dev.dart --obfuscate --split-debug-info=.obfuscation/dev/

# Staging
flutter build ios --flavor stg --dart-define-from-file=.env/.env.stg -t lib/main_stg.dart --obfuscate --split-debug-info=.obfuscation/stg/

# Production
flutter build ios --flavor prod --dart-define-from-file=.env/.env.prod -t lib/main_prod.dart --obfuscate --split-debug-info=.obfuscation/prod/
```

#### IPA:
```bash
# Development
flutter build ipa --flavor dev --dart-define-from-file=.env/.env.dev -t lib/main_dev.dart --obfuscate --split-debug-info=.obfuscation/dev/

# Staging
flutter build ipa --flavor stg --dart-define-from-file=.env/.env.stg -t lib/main_stg.dart --obfuscate --split-debug-info=.obfuscation/stg/

# Production
flutter build ipa --flavor prod --dart-define-from-file=.env/.env.prod -t lib/main_prod.dart --obfuscate --split-debug-info=.obfuscation/prod/
```

## Build Configuration

### Flavors Available:
- **dev**: Development environment with debug features
- **stg**: Staging environment mirroring production
- **prod**: Production environment for live deployment

### Build Features:
- **Code Obfuscation**: All release builds use `--obfuscate` for security
- **Split Debug Info**: Debug symbols separated for crash reporting
- **Environment Variables**: Flavor-specific configuration from `.env/` files
- **Target Files**: Flavor-specific entry points (`main_dev.dart`, etc.)

## Build Outputs

### Android:
- **APK**: `build/app/outputs/flutter-apk/`
- **App Bundle**: `build/app/outputs/bundle/`
- **Debug Symbols**: `.obfuscation/[flavor]/`

### iOS:
- **iOS App**: `build/ios/iphoneos/`
- **IPA**: `build/ios/ipa/`
- **Debug Symbols**: `.obfuscation/[flavor]/`

## Pre-Build Checklist

### Before Building:
- [ ] All dependencies updated (`flutter pub get`)
- [ ] Code generation completed (`dart run build_runner build --delete-conflicting-outputs`)
- [ ] Localization updated (`./tools/macos/localization/generate_localization.sh`)
- [ ] Tests passing (`flutter test`)
- [ ] Code analysis clean (`flutter analyze`)
- [ ] Environment files configured (`.env/`)

### Version Management:
- [ ] Version updated in `pubspec.yaml`
- [ ] Build number incremented
- [ ] Changelog updated

## Build Optimization

### Performance Builds:
```bash
# Build with performance optimization
flutter build apk --release --target-platform android-arm64

# Build with tree shaking disabled (for icons)
flutter build apk --no-tree-shake-icons --flavor prod -t lib/main_prod.dart
```

### Size Optimization:
```bash
# Analyze app size
flutter build apk --analyze-size

# Build with specific architectures
flutter build apk --target-platform android-arm,android-arm64
```

## Debug Builds

### Development Testing:
```bash
# Debug APK for testing
flutter build apk --debug --flavor dev -t lib/main_dev.dart

# Profile build for performance testing
flutter build apk --profile --flavor dev -t lib/main_dev.dart
```

## Build Troubleshooting

### Common Issues:

#### Android Build Issues:
```bash
# Clean Android build
cd android && ./gradlew clean && cd ..
flutter clean
flutter pub get

# Update Android dependencies
cd android && ./gradlew dependencies && cd ..
```

#### iOS Build Issues:
```bash
# Clean iOS build
cd ios && xcodebuild clean && cd ..
flutter clean
flutter pub get

# Update CocoaPods
cd ios && pod install --repo-update && cd ..
```

#### Code Obfuscation Issues:
```bash
# If obfuscation causes issues, build without it temporarily
flutter build apk --flavor dev -t lib/main_dev.dart --dart-define-from-file=.env/.env.dev
```

### Build Script Issues:
```bash
# Make scripts executable
chmod +x tools/macos/build/*.sh

# Check script paths
ls -la tools/macos/build/
```

## Release Build Process

### Production Release Steps:
1. **Pre-release checks**:
   ```bash
   flutter analyze
   flutter test --coverage
   flutter build apk --flavor prod -t lib/main_prod.dart --obfuscate --split-debug-info=.obfuscation/prod/
   ```

2. **Build all flavors**:
   ```bash
   ./tools/macos/build/build_appbundle.sh dev
   ./tools/macos/build/build_appbundle.sh stg
   ./tools/macos/build/build_appbundle.sh prod
   ```

3. **Upload debug symbols**:
   ```bash
   # Debug symbols are automatically uploaded to Firebase Crashlytics
   ```

## CI/CD Integration

### GitHub Actions Build:
```yaml
build:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v3
    - uses: subosito/flutter-action@v2
    - run: flutter pub get
    - run: dart run build_runner build --delete-conflicting-outputs
    - run: ./tools/macos/localization/generate_localization.sh
    - run: flutter test
    - run: ./tools/macos/build/build_appbundle.sh prod
```

## Build Artifacts

### Artifact Management:
- Keep debug symbols for crash analysis
- Archive build artifacts with version tags
- Maintain build logs for troubleshooting

### Distribution:
- **Internal Testing**: Use dev/stg flavors
- **Beta Testing**: Use stg flavor
- **Production**: Use prod flavor only

## Security Considerations

### Code Protection:
- All release builds use obfuscation
- Debug symbols are separated and secured
- Environment variables are properly isolated

### Build Environment:
- Use secure CI/CD environments
- Protect signing keys and certificates
- Validate build integrity before distribution

## Performance Monitoring

### Build Performance:
```bash
# Monitor build times
time flutter build appbundle --flavor prod -t lib/main_prod.dart

# Analyze build size
flutter build apk --analyze-size --flavor prod -t lib/main_prod.dart
```

### App Performance:
- Use profile builds for performance testing
- Monitor app size and startup time
- Analyze memory usage and rendering performance