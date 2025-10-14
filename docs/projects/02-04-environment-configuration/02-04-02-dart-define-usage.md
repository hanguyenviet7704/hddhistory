# Using --dart-define-from-file

This document explains the usage of `--dart-define-from-file` in Dcore project build processes, which is the **preferred method** for environment configuration.

## Overview

The Dcore project uses `--dart-define-from-file` (NOT `--dart-define`) to load environment variables from configuration files during the build process. This approach provides better organization, maintainability, and security for environment-specific settings.

## Why --dart-define-from-file?

### Advantages over --dart-define
- **File-based Configuration**: All environment variables in organized files
- **Better Security**: Sensitive values can be managed separately
- **Easier Maintenance**: Single source of truth for environment settings
- **Version Control Friendly**: Template files can be committed, actual values managed separately
- **Reduced Command Line Complexity**: No need for multiple --dart-define flags

### Comparison

#### OLD WAY (--dart-define) - NOT USED
```bash
flutter build apk \
  --dart-define=API_BASE_URL=https://api.example.com \
  --dart-define=ENVIRONMENT=dev \
  --dart-define=ENABLE_DEBUG=true \
  --dart-define=FIREBASE_PROJECT_ID=meup-dev
```

#### NEW WAY (--dart-define-from-file) - USED IN PROJECT
```bash
flutter build apk --dart-define-from-file=.env/.env.dev
```

## Implementation in Build Scripts

### Build Script Integration

All build scripts in the `tools/macos/build/` directory use `--dart-define-from-file`:

#### APK Build Script
```bash
# File: tools/macos/build/build_apk.sh
# Automatically selects correct environment file based on flavor
ENV_FILE=""
if [[ "$FLAVOR" == "dev" ]]; then
    ENV_FILE=".env/.env.dev"
elif [[ "$FLAVOR" == "stg" ]]; then
    ENV_FILE=".env/.env.stg"
elif [[ "$FLAVOR" == "prod" ]]; then
    ENV_FILE=".env/.env.prod"
fi

# Build with environment file
fvm flutter build apk \
    --release \
    --obfuscate \
    --split-debug-info="$DEBUG_INFO_OUTPUT_PATH" \
    --flavor "$FLAVOR" \
    --dart-define-from-file="$ENV_FILE" \
    -t "lib/main_$FLAVOR.dart"
```

#### App Bundle Build Script
```bash
# File: tools/macos/build/build_appbundle.sh
fvm flutter build appbundle \
    --release \
    --obfuscate \
    --split-debug-info="$DEBUG_INFO_OUTPUT_PATH" \
    --flavor "$FLAVOR" \
    --dart-define-from-file="$ENV_FILE" \
    -t "lib/main_$FLAVOR.dart"
```

#### iOS Build Script
```bash
# File: tools/macos/build/build_ios.sh
fvm flutter build ios \
    --release \
    --obfuscate \
    --split-debug-info="$DEBUG_INFO_OUTPUT_PATH" \
    --flavor "$FLAVOR" \
    --dart-define-from-file="$ENV_FILE" \
    -t "lib/main_$FLAVOR.dart"
```

### Environment File Mapping

The build scripts automatically map flavors to environment files:

| Flavor | Environment File | Purpose |
|--------|------------------|---------|
| `dev` | `.env/.env.dev` | Development builds |
| `stg` | `.env/.env.stg` | Staging builds |
| `prod` | `.env/.env.prod` | Production builds |

## Usage Examples

### Command Line Usage

#### Direct Flutter Commands
```bash
# Development build
flutter run --flavor dev --dart-define-from-file=.env/.env.dev -t lib/main_dev.dart

# Staging build
flutter run --flavor stg --dart-define-from-file=.env/.env.stg -t lib/main_stg.dart

# Production build
flutter run --flavor prod --dart-define-from-file=.env/.env.prod -t lib/main_prod.dart
```

#### Using Build Scripts (Recommended)
```bash
# Build APK for development
sh tools/macos/build/build_apk.sh dev

# Build APK for staging
sh tools/macos/build/build_apk.sh stg

# Build APK for production
sh tools/macos/build/build_apk.sh prod
```

### IDE Integration

#### VS Code Launch Configurations
The `.vscode/launch.json` file includes `--dart-define-from-file` in all configurations:

```json
{
  "name": "dev Debug",
  "request": "launch",
  "type": "dart",
  "flutterMode": "debug",
  "args": [
    "--flavor",
    "dev",
    "--dart-define-from-file",
    ".env/.env.dev"
  ],
  "program": "lib/main_dev.dart"
}
```

#### IntelliJ Run Configurations
The `.idea/runConfigurations/` files include `--dart-define-from-file` parameters:

```xml
<!-- main_dev_dart.xml -->
<component name="ProjectRunConfigurationManager">
  <configuration name="main_dev.dart" type="FlutterRunConfigurationType">
    <option name="additionalArgs" value="--flavor dev --dart-define-from-file .env/.env.dev" />
    <option name="filePath" value="$PROJECT_DIR$/lib/main_dev.dart" />
  </configuration>
</component>
```

## Environment File Structure

### Required Format
Environment files must follow the standard `.env` format:

```env
# .env/.env.dev example
API_BASE_URL=https://dev-api.meup.com
ENVIRONMENT=dev
ENABLE_DEBUG=true
FIREBASE_PROJECT_ID=meup-dev
FIREBASE_API_KEY=AIzaSyExample123...
```

### File Validation
Before builds, the scripts display environment file contents:

```bash
echo "Building APK for $FLAVOR flavor..."
echo "Using environment variables from file: $ENV_FILE"
echo "Contents of $ENV_FILE:"
cat "$ENV_FILE"
```

## Accessing Environment Variables in Code

### String Values
```dart
class EnvironmentConfig {
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String environment = String.fromEnvironment('ENVIRONMENT');
  static const String firebaseProjectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
}
```

### Boolean Values
```dart
class EnvironmentConfig {
  static const bool enableDebug = bool.fromEnvironment('ENABLE_DEBUG');
  static const bool enableCrashlytics = bool.fromEnvironment('ENABLE_CRASHLYTICS');
}
```

### Integer Values
```dart
class EnvironmentConfig {
  static const int apiTimeout = int.fromEnvironment('API_TIMEOUT', defaultValue: 30000);
  static const int maxRetries = int.fromEnvironment('MAX_RETRIES', defaultValue: 3);
}
```

### Default Values
Always provide default values for optional configuration:

```dart
class EnvironmentConfig {
  // Required values (no default)
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  
  // Optional values with defaults
  static const int apiTimeout = int.fromEnvironment('API_TIMEOUT', defaultValue: 30000);
  static const bool enableLogging = bool.fromEnvironment('ENABLE_LOGGING', defaultValue: false);
}
```

## Build Process Integration

### Automatic Environment Selection

The build scripts automatically select the correct environment file based on the flavor parameter:

```bash
# build_apk.sh logic
case $FLAVOR in
    dev)
        ENV_FILE=".env/.env.dev"
        ;;
    stg)
        ENV_FILE=".env/.env.stg"
        ;;
    prod)
        ENV_FILE=".env/.env.prod"
        ;;
esac
```

### Validation and Error Handling

Build scripts include validation:

```bash
# Check if environment file exists
if [[ ! -f "$ENV_FILE" ]]; then
    echo "Error: Environment file $ENV_FILE not found"
    exit 1
fi

# Validate flavor selection
if [[ -z "$FLAVOR" ]]; then
    echo "Usage: $(basename "$0") [dev|stg|prod]"
    exit 1
fi
```

## Troubleshooting

### Common Issues

#### Environment File Not Found
**Error**: `Error: Environment file .env/.env.dev not found`
**Solution**:
1. Verify environment files exist in `.env/` directory
2. Check file permissions
3. Ensure correct working directory

#### Variables Not Loading
**Error**: `String.fromEnvironment` returns empty values
**Solution**:
1. Verify file format (key=value with no spaces around =)
2. Check for typos in variable names
3. Ensure file encoding is UTF-8
4. Verify build command uses correct `--dart-define-from-file` path

#### Build Script Issues
**Error**: Build script doesn't recognize flavor
**Solution**:
1. Use correct flavor names: `dev`, `stg`, or `prod`
2. Ensure build script has execute permissions
3. Run from project root directory

### Debug Commands

#### Verify Environment File Content
```bash
# Check file exists and show content
ls -la .env/.env.dev
cat .env/.env.dev
```

#### Test Build Command
```bash
# Test with verbose output
flutter build apk --flavor dev --dart-define-from-file=.env/.env.dev --verbose
```

#### Validate Environment Variables in App
Add debug code to verify variables are loaded:

```dart
void debugPrintEnvironment() {
  print('API URL: ${EnvironmentConfig.apiBaseUrl}');
  print('Environment: ${EnvironmentConfig.environment}');
  print('Debug Enabled: ${EnvironmentConfig.enableDebug}');
}
```

## Best Practices

### File Management
- Keep environment files in `.env/` directory
- Use consistent naming: `.env.dev`, `.env.stg`, `.env.prod`
- Provide template files for required variables
- Document all required environment variables

### Security
- Never commit sensitive values to version control
- Use placeholder values in committed files
- Provide actual values through secure channels
- Implement proper CI/CD integration for sensitive configuration

### Development Workflow
- Always test builds with all three environments
- Verify configuration changes across all environments
- Use IDE configurations for daily development
- Use build scripts for release builds

### Variable Naming
- Use UPPER_CASE with underscores
- Use descriptive, clear names
- Group related variables with prefixes
- Document complex or non-obvious variables

## Migration Notes

If migrating from `--dart-define` to `--dart-define-from-file`:

1. **Collect Current Variables**: List all current `--dart-define` variables
2. **Create Environment Files**: Move variables to appropriate `.env` files
3. **Update Build Scripts**: Replace `--dart-define` with `--dart-define-from-file`
4. **Update IDE Configurations**: Modify launch/run configurations
5. **Test All Environments**: Verify builds work with all environment files
6. **Update Documentation**: Document the new process for team members