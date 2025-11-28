# macOS Development Tools

This document provides detailed information about the fully functional development tools available for macOS in Dcore projects.

## Overview

The `tools/macos/` directory contains a comprehensive suite of development tools that are **fully functional and up-to-date** for macOS development environments. These tools automate common development tasks and provide a streamlined workflow.

> **Note**: Command interfaces are shared with the Linux/Windows scripts for Android/localization/Firebase. iOS/IPA/distribution flows remain macOS-only because they require Xcode.

## Tool Categories

### Build Tools (`tools/macos/build/`)

#### build_apk.sh
**Purpose**: Build Android APK files for all environments

**Usage**:
```bash
# Basic usage
sh tools/macos/build/build_apk.sh [dev|stg|prod]

# With options
sh tools/macos/build/build_apk.sh dev --no-tree-shake-icons

# Help
sh tools/macos/build/build_apk.sh --help
```

**Features**:
- Automatic environment file selection
- Code obfuscation enabled
- Debug symbol generation and Firebase upload
- Output directory automatic opening
- Comprehensive error handling and validation

**Output**: APK files in `build/app/outputs/flutter-apk/`

#### build_appbundle.sh
**Purpose**: Build Android App Bundles for Google Play Store

**Usage**:
```bash
sh tools/macos/build/build_appbundle.sh [dev|stg|prod]
```

**Features**:
- Google Play Store optimized builds
- Dynamic delivery support
- Automatic obfuscation and symbol upload
- Multi-architecture support

**Output**: AAB files in `build/app/outputs/bundle/`

#### build_ios.sh
**Purpose**: Build iOS applications for all environments

**Usage**:
```bash
sh tools/macos/build/build_ios.sh [dev|stg|prod]
```

**Features**:
- iOS-specific build optimizations
- Automatic code signing (if configured)
- TestFlight preparation
- Debug symbol management

**Output**: iOS builds in `build/ios/iphoneos/`

#### reset_app.sh
**Purpose**: Clean and reset project state

**Usage**:
```bash
sh tools/macos/build/reset_app.sh
```

**Features**:
- Flutter clean execution
- Build directory removal
- Dependency refresh (flutter pub get)
- Project state reset

### Resource Management (`tools/macos/resource/`)

#### generate_file.sh
**Purpose**: Generate all code files using build_runner

**Usage**:
```bash
sh tools/macos/resource/generate_file.sh
```

**Generated Files**:
- JSON serialization (`.g.dart`)
- Immutable classes (`.freezed.dart`)
- Dependency injection (`injection.config.dart`)
- API clients (retrofit generated)
- Route definitions (`app_router.gr.dart`)
- Asset references (`gen/` directory)

**Process**:
```bash
# Executes internally:
fvm dart run build_runner build --delete-conflicting-outputs
```

### Localization Tools (`tools/macos/localization/`)

#### generate_localization.sh
**Purpose**: Complete localization workflow from Google Sheets to Flutter

**Usage**:
```bash
sh tools/macos/localization/generate_localization.sh
```

**Workflow**:
1. **Python Environment Setup**: Creates virtual environment if needed
2. **Google Sheets Integration**: Downloads translations from Google Sheets
3. **ARB File Generation**: Creates module-specific ARB files
4. **ARB File Merging**: Combines modules into app-level ARB files
5. **Flutter Generation**: Runs `flutter gen-l10n` to create Dart files

**Dependencies**:
- Python 3 (automatically detected)
- Requests library (automatically installed)
- Virtual environment (automatically created)

**Output**:
- Module ARB files: `assets/arb/module/`
- App ARB files: `assets/arb/app/`
- Dart localization: `lib/config/l10n/`

#### generate_arb_from_sheets.py
**Purpose**: Extract translations from Google Sheets

**Features**:
- Google Sheets API integration
- Multi-language support
- Module-based organization
- Error handling and validation

#### merge_arb_files.py
**Purpose**: Merge module ARB files into application ARB files

**Features**:
- Namespace management
- Conflict resolution
- Metadata preservation
- Validation and error reporting

### Configuration Management (`tools/macos/config/`)

#### firebase_setup.sh
**Purpose**: Configure Firebase services and upload debug symbols

**Usage**:
```bash
# Called automatically by build scripts
sh tools/macos/config/firebase_setup.sh [dev|stg|prod] [android|ios]
```

**Features**:
- Environment-specific Firebase project selection
- Crashlytics symbol upload
- Build artifact integration
- Error handling and retry logic

### Distribution Tools (`tools/macos/distribution/`)

#### upload_appstore.sh
**Purpose**: Upload iOS builds to App Store Connect

**Usage**:
```bash
sh tools/macos/distribution/upload_appstore.sh [dev|stg|prod]
```

**Features**:
- App Store Connect API integration
- Automatic metadata upload
- TestFlight preparation
- Build validation

**Requirements**:
- Apple Developer account
- App Store Connect API key
- Proper code signing certificates

### Key Management (`tools/macos/key/`)

**Purpose**: Manage development certificates and signing keys

**Features**:
- iOS certificate management
- Android keystore handling
- Secure key storage recommendations
- Key rotation procedures

### Git Integration (`tools/macos/git/`)

**Purpose**: Enhanced Git workflow integration

**Features**:
- Branch management utilities
- Commit message validation
- GitFlow workflow helpers
- Release preparation tools

## Common Tool Features

### Environment Awareness
All build tools automatically:
- Detect and validate flavor parameters
- Select appropriate environment files
- Display configuration before execution
- Validate prerequisites

### Error Handling
Comprehensive error handling includes:
- Parameter validation
- File existence checks
- Command execution verification
- Clear error messages with solutions
- Safe cleanup on failures

### User Experience
Tools provide:
- Colored output for better readability
- Progress indicators for long operations
- Success/failure status messages
- Automatic file/directory opening
- Help documentation

### Integration Features
- **FVM Support**: All Flutter commands use FVM
- **Firebase Integration**: Automatic Crashlytics symbol upload
- **IDE Compatibility**: Output formats compatible with IDE error parsing
- **CI/CD Ready**: Non-interactive execution support

## Tool Configuration

### Prerequisites
Tools require:
- macOS operating system
- Flutter SDK (via FVM recommended)
- Xcode (for iOS builds)
- Android SDK (for Android builds)
- Python 3 (for localization tools)

### Environment Setup
Ensure the following are configured:
- Flutter in PATH or FVM installed
- Android SDK path set
- Xcode command line tools installed
- Python 3 available

### Script Permissions
Make scripts executable:
```bash
chmod +x tools/macos/build/*.sh
chmod +x tools/macos/resource/*.sh
chmod +x tools/macos/localization/*.sh
chmod +x tools/macos/config/*.sh
```

## Advanced Usage

### Custom Build Options
Many scripts support additional options:

```bash
# Disable tree shaking for icons
sh tools/macos/build/build_apk.sh dev --no-tree-shake-icons

# View help for any script
sh tools/macos/build/build_apk.sh --help
```

### Pipeline Integration
Tools can be integrated into CI/CD pipelines:

```yaml
# Example CI configuration
build:
  script:
    - sh tools/macos/build/reset_app.sh
    - sh tools/macos/resource/generate_file.sh
    - sh tools/macos/localization/generate_localization.sh
    - sh tools/macos/build/build_apk.sh prod
```

### Parallel Execution
Some operations can be parallelized:

```bash
# Build multiple platforms simultaneously
sh tools/macos/build/build_apk.sh prod &
sh tools/macos/build/build_ios.sh prod &
wait
```

## Monitoring and Debugging

### Log Files
Tools generate logs in various locations:
- Build logs: Console output
- Firebase upload logs: Script output
- Localization logs: Python script output

### Debug Mode
Enable verbose output:
```bash
# Set debug mode for detailed output
export DEBUG=1
sh tools/macos/build/build_apk.sh dev
```

### Performance Monitoring
Tools provide timing information:
- Build duration reporting
- Operation progress indicators
- Bottleneck identification

## Maintenance and Updates

### Tool Updates
Regularly update tools by:
- Reviewing Flutter version compatibility
- Updating Firebase CLI tools
- Testing with latest Xcode versions
- Validating Python dependencies

### Customization
Tools can be customized by:
- Modifying script parameters
- Adding project-specific logic
- Integrating additional services
- Extending error handling

### Version Control
Tool configurations are tracked in:
- Script files in `tools/macos/`
- Configuration files in `.info/`
- Environment files in `.env/`

## Troubleshooting

### Common Issues

#### Permission Denied
```bash
# Fix script permissions
chmod +x tools/macos/build/build_apk.sh
```

#### Flutter Not Found
```bash
# Install FVM or add Flutter to PATH
export PATH="$PATH:/path/to/flutter/bin"
```

#### Python Environment Issues
```bash
# Reset Python environment
rm -rf .venv_localization
sh tools/macos/localization/generate_localization.sh
```

#### Firebase Upload Failures
```bash
# Check Firebase CLI authentication
firebase login
firebase projects:list
```

### Debug Commands
```bash
# Verify Flutter installation
flutter doctor -v

# Check script syntax
bash -n tools/macos/build/build_apk.sh

# Test environment files
cat .env/.env.dev

# Verify Firebase configuration
firebase use --list
```

## Best Practices

### Development Workflow
1. **Start with setup scripts**:
   ```bash
   sh tools/macos/resource/generate_file.sh
   sh tools/macos/build/reset_app.sh
   sh tools/macos/localization/generate_localization.sh
   ```

2. **Use appropriate build tools**:
   - Development: APK builds for testing
   - Staging: App Bundle builds for internal testing
   - Production: App Bundle builds for release

3. **Regular maintenance**:
   - Keep tools updated
   - Test scripts with new Flutter versions
   - Validate Firebase integration

### Performance Optimization
- Use build scripts for release builds
- Use IDE configurations for development
- Cache dependencies when possible
- Parallelize independent operations

### Security Considerations
- Protect signing keys and certificates
- Use secure storage for sensitive configuration
- Regular security audits of scripts
- Validate all inputs and parameters
