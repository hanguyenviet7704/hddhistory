# Build Process Overview

This document provides a comprehensive overview of the build process in Dcore Flutter projects.

## Build System Architecture

The Dcore project uses a sophisticated build system that supports:
- Multiple environments (dev, stg, prod)
- Multiple platforms (Android, iOS)
- Multiple build types (debug, profile, release)
- Code obfuscation and debug symbol generation
- Automatic Firebase Crashlytics integration

## Key Build Components

### Environment Configuration
The build system uses `--dart-define-from-file` to load environment-specific configuration:

```bash
--dart-define-from-file=.env/.env.dev    # Development
--dart-define-from-file=.env/.env.stg    # Staging
--dart-define-from-file=.env/.env.prod   # Production
```

### Multi-Flavor Support
Each environment corresponds to a Flutter flavor:

| Environment | Flavor | Target File | Environment File |
|-------------|--------|-------------|------------------|
| Development | `dev` | `lib/main_dev.dart` | `.env/.env.dev` |
| Staging | `stg` | `lib/main_stg.dart` | `.env/.env.stg` |
| Production | `prod` | `lib/main_prod.dart` | `.env/.env.prod` |

### Build Script Integration
Custom build scripts in `tools/macos/build/` automate the entire build process:

```bash
# Build Android APK
sh tools/macos/build/build_apk.sh [dev|stg|prod]

# Build Android App Bundle
sh tools/macos/build/build_appbundle.sh [dev|stg|prod]

# Build iOS App
sh tools/macos/build/build_ios.sh [dev|stg|prod]
```

## Build Process Flow

### 1. Pre-Build Validation
All build scripts perform validation before starting:

```bash
# Check flavor parameter
if [[ -z "$FLAVOR" ]]; then
    echo "Usage: $(basename "$0") [dev|stg|prod]"
    exit 1
fi

# Validate environment file exists
if [[ ! -f "$ENV_FILE" ]]; then
    echo "Error: Environment file $ENV_FILE not found"
    exit 1
fi

# Check Flutter availability
if ! command -v flutter &> /dev/null; then
    echo "Flutter is not installed or not in PATH"
    exit 1
fi
```

### 2. Environment Configuration Display
Scripts display the environment configuration being used:

```bash
echo "Building APK for $FLAVOR flavor..."
echo "Using environment variables from file: $ENV_FILE"
echo "Contents of $ENV_FILE:"
cat "$ENV_FILE"
echo ""
```

### 3. Build Execution
The actual Flutter build command with all necessary parameters:

```bash
fvm flutter build apk \
    --release \
    --obfuscate \
    --split-debug-info="$DEBUG_INFO_OUTPUT_PATH" \
    --flavor "$FLAVOR" \
    --dart-define-from-file="$ENV_FILE" \
    -t "lib/main_$FLAVOR.dart"
```

### 4. Post-Build Processing
After successful build:

#### Debug Symbol Upload
Automatic upload to Firebase Crashlytics:
```bash
echo "🔥 Uploading debug symbols to Firebase Crashlytics..."
FIREBASE_SETUP_SCRIPT="tools/macos/config/firebase_setup.sh"

if [[ -f "$FIREBASE_SETUP_SCRIPT" ]]; then
    "$FIREBASE_SETUP_SCRIPT" "$FLAVOR" "android"
fi
```

#### File Management
- Open build output directory
- Display success message
- Provide build artifact locations

## Build Configurations

### Release Configuration
All production builds use release configuration:
- Code obfuscation enabled
- Debug information stripped
- Performance optimizations applied
- Smaller app size

### Debug Information Management
Debug symbols are separated for crash analysis:
```bash
--split-debug-info=".obfuscation"
```

This creates:
- Obfuscated release build
- Separate debug symbol files
- Mapping files for crash analysis

### Obfuscation Settings
Code obfuscation is enabled for all release builds:
```bash
--obfuscate
```

Benefits:
- Protects intellectual property
- Reduces reverse engineering risk
- Smaller binary size
- Still allows crash analysis with proper symbols

## Platform-Specific Builds

### Android Builds

#### APK Generation
```bash
flutter build apk \
    --release \
    --obfuscate \
    --split-debug-info=".obfuscation" \
    --flavor "$FLAVOR" \
    --dart-define-from-file="$ENV_FILE" \
    -t "lib/main_$FLAVOR.dart"
```

Output location: `build/app/outputs/flutter-apk/`

#### App Bundle Generation
```bash
flutter build appbundle \
    --release \
    --obfuscate \
    --split-debug-info=".obfuscation" \
    --flavor "$FLAVOR" \
    --dart-define-from-file="$ENV_FILE" \
    -t "lib/main_$FLAVOR.dart"
```

Output location: `build/app/outputs/bundle/`

### iOS Builds

#### iOS App Generation
```bash
flutter build ios \
    --release \
    --obfuscate \
    --split-debug-info=".obfuscation" \
    --flavor "$FLAVOR" \
    --dart-define-from-file="$ENV_FILE" \
    -t "lib/main_$FLAVOR.dart"
```

Output location: `build/ios/iphoneos/`

## Build Optimization Features

### Tree Shaking Options
Optional tree shaking control:
```bash
# Disable tree shaking for icons (if needed)
sh tools/macos/build/build_apk.sh dev --no-tree-shake-icons
```

### FVM Integration
All builds use FVM (Flutter Version Management):
```bash
fvm flutter build ...
```

Benefits:
- Consistent Flutter version across team
- Project-specific Flutter SDK
- Version isolation

### Parallel Processing
Build scripts support background execution and monitoring:
- Real-time progress feedback
- Error handling and recovery
- Parallel Firebase symbol upload

## Build Artifacts

### Generated Files Structure
```
build/
├── app/
│   ├── outputs/
│   │   ├── flutter-apk/        # Android APK files
│   │   └── bundle/             # Android App Bundles
├── ios/
│   └── iphoneos/               # iOS build artifacts
└── ...

.obfuscation/                   # Debug symbol files
├── app.android-arm.symbols
├── app.android-arm64.symbols
├── app.android-x64.symbols
└── ...
```

### Artifact Naming Convention
Build artifacts follow consistent naming:
- `app-dev-release.apk` - Development APK
- `app-stg-release.apk` - Staging APK  
- `app-prod-release.apk` - Production APK
- Similar naming for App Bundles and iOS builds

## Build Script Features

### User Experience Enhancements
- Colored output for better readability
- Progress indicators during long operations
- Clear error messages with suggested solutions
- Automatic file/folder opening after completion

### Error Handling
Comprehensive error handling:
```bash
if [[ $? -ne 0 ]]; then
    echo "APK build failed for $FLAVOR flavor."
    exit 1
fi
```

### Help Documentation
Built-in help for all scripts:
```bash
sh tools/macos/build/build_apk.sh --help
```

### Validation and Safety
- Parameter validation
- File existence checks
- Environment verification
- Safe failure modes

## Integration with Development Workflow

### IDE Integration
Build process integrates with IDE run configurations:
- VS Code launch configurations use same parameter format
- IntelliJ run configurations mirror build script behavior
- Consistent environment loading across all tools

### Continuous Integration Support
Build scripts designed for CI/CD:
- Non-interactive execution
- Clear exit codes
- Comprehensive logging
- Artifact management

### Local Development
Optimized for local development:
- Fast feedback cycles
- Development-friendly defaults
- Easy troubleshooting
- Minimal setup requirements

## Monitoring and Debugging

### Build Logging
Comprehensive logging throughout build process:
- Environment configuration display
- Build progress indicators
- Error messages with context
- Success/failure status

### Performance Monitoring
Build time tracking and optimization:
- FVM for consistent performance
- Parallel processing where possible
- Efficient artifact management
- Cache utilization

### Troubleshooting Support
Built-in troubleshooting features:
- Verbose error messages
- Common issue detection
- Recovery suggestions
- Debug information collection

## Best Practices

### Build Environment
- Use consistent Flutter versions (FVM)
- Maintain clean build environment
- Regular dependency updates
- Environment file validation

### Security Considerations
- Secure handling of signing keys
- Environment variable protection
- Debug symbol management
- Build artifact security

### Performance Optimization
- Parallel build processes
- Efficient caching strategies
- Optimal obfuscation settings
- Resource management

### Team Collaboration
- Consistent build procedures
- Shared build configurations  
- Clear documentation
- Error reporting processes