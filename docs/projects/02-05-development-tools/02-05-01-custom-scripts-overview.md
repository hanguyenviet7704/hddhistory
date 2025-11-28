# Custom Scripts Overview

This document provides an overview of the custom development tools and scripts available in Dcore projects.

## Platform Support Status

- ✅ **macOS**: Full toolset, including iOS/IPA/distribution (Xcode required)
- ✅ **Linux**: Same commands/flags for Android build, config, localization, Firebase
- ✅ **Windows**: Same commands/flags via `.bat`/PowerShell (no iOS)

Scripts stay aligned across platforms; after any change run `tools/smoke.sh` (macOS/Linux) or `tools\\windows\\smoke.bat` (Windows).

## Tools Directory Structure

```
tools/<platform>/
├── build/          # build_apk, build_appbundle, build_ios/build_ipa (macOS), install_app
├── config/         # setup_project, flutterfire_config, icon helpers
├── distribution/   # distribute_android, distribute_ios (macOS), tester/group helpers
├── git/            # gitflow helpers (where present)
├── key/            # keystore/cert generation
├── localization/   # localization.(sh|bat) + shared CLI
└── resource/       # generate_file, reset_app
```

The interface (flags, outputs, expected files) is shared; only iOS/IPA/distribution scripts live in `tools/macos/`.

## macOS Tools Categories

### Build Scripts (`tools/macos/build/`)
**Purpose**: Automate the building process for different platforms and environments

#### Key Scripts:
- `build_apk.sh` - Build Android APK files
- `build_appbundle.sh` - Build Android App Bundles
- `build_ios.sh` - Build iOS applications
- `reset_app.sh` - Clean and reset project state

#### Features:
- Multi-environment support (dev, stg, prod)
- Automatic obfuscation and debug symbol generation
- Firebase Crashlytics integration
- Automatic file opening after build completion

### Resource Management (`tools/macos/resource/`)
**Purpose**: Generate code files and manage project resources

#### Key Scripts:
- `generate_file.sh` - Generate all code files (.g.dart, .freezed.dart, etc.)

#### Generated Files:
- JSON serialization code
- Immutable class definitions
- Dependency injection configurations
- API client code
- Route definitions

### Localization Tools (`tools/<platform>/localization/`)
**Purpose**: Manage multi-language support and translations (Google Sheets ⇄ slang modules)

#### Key Scripts:
- `localization.sh` (Linux/macOS) / `localization.bat` (Windows) - pull/push/migrate/validate
- `localization_cli.py` - shared Python engine

#### Features:
- Google Sheets integration with per-module tabs
- Automatic Python virtual environment setup (`.venv_localization`)
- Migration from legacy sheet/ARB, zh fallback to en
- Slang-ready YAML generation and sheet push with dry-run

### Configuration Management (`tools/macos/config/`)
**Purpose**: Manage project configuration and external service setup

#### Key Scripts:
- `firebase_setup.sh` - Configure Firebase services
- Various configuration utilities

### Distribution Tools (`tools/macos/distribution/`)
**Purpose**: Handle app distribution and deployment

#### Features:
- App Store Connect integration
- TestFlight deployment
- Play Store publishing preparation

### Key Management (`tools/macos/key/`)
**Purpose**: Manage signing keys and certificates

#### Features:
- iOS certificate management
- Android keystore handling
- Secure key storage practices

### Git Integration (`tools/macos/git/`)
**Purpose**: Enhance Git workflow with project-specific utilities

#### Features:
- Branch management helpers
- Commit message validation
- GitFlow integration utilities

## Tool Usage Patterns

### Standard Workflow Commands

#### First-Time Setup
```bash
# 1. Generate all code files
sh tools/macos/resource/generate_file.sh

# 2. Clean and reset project
sh tools/macos/build/reset_app.sh

# 3. Pull/migrate localizations (Linux/macOS)
tools/<platform>/localization/localization.sh pull
```

#### Daily Development
```bash
# Regenerate code after model changes
sh tools/macos/resource/generate_file.sh

# Build for testing
sh tools/macos/build/build_apk.sh dev
```

#### Release Preparation
```bash
# Build all environments
sh tools/macos/build/build_apk.sh stg
sh tools/macos/build/build_apk.sh prod

# Build iOS
sh tools/macos/build/build_ios.sh prod
```

### Script Parameters and Options

#### Build Scripts
```bash
# Basic usage
sh tools/macos/build/build_apk.sh [dev|stg|prod]

# With options
sh tools/macos/build/build_apk.sh dev --no-tree-shake-icons

# Help information
sh tools/macos/build/build_apk.sh --help
```

#### Resource Generation
```bash
# Standard generation
sh tools/macos/resource/generate_file.sh

# The script automatically handles all build_runner tasks
```

#### Localization Generation
```bash
# Complete localization workflow
sh tools/macos/localization/generate_localization.sh

# The script handles Python environment setup automatically
```

## Key Features

### Environment-Aware Building
All build scripts automatically:
- Select correct environment file based on flavor
- Apply appropriate build configurations
- Use correct target files (main_dev.dart, main_stg.dart, main_prod.dart)
- Display environment configuration before building

### Obfuscation and Debug Symbols
Build scripts automatically:
- Enable code obfuscation for release builds
- Generate debug symbol files
- Upload symbols to Firebase Crashlytics
- Store obfuscation maps for crash analysis

### Firebase Integration
- Automatic Crashlytics symbol upload
- Environment-specific Firebase project selection
- Proper configuration for each build environment

### User-Friendly Features
- Colored output and progress indicators
- Automatic file/folder opening after completion
- Comprehensive error messages and validation
- Help documentation within scripts

## Error Handling and Validation

### Input Validation
Scripts validate:
- Required parameters are provided
- Environment files exist and are readable
- Flutter SDK is available and configured
- Project structure is correct

### Error Recovery
Scripts provide:
- Clear error messages with suggested solutions
- Graceful failure handling
- Cleanup of temporary files on errors
- Help information for troubleshooting

### Logging and Debug Information
Scripts output:
- Current configuration being used
- Environment file contents (for verification)
- Build progress and timing information
- Success/failure status with details

## Cross-Platform Considerations

- **Parity-first**: Commands/flags are kept identical across `macos`, `linux`, and `windows` directories.
- **macOS-only flows**: iOS build/IPA/distribution scripts run only on macOS because they need Xcode; Android/localization/Firebase scripts run everywhere.
- **Smoke checks**: Run `tools/smoke.sh` (macOS/Linux) or `tools\\windows\\smoke.bat` after editing any script to verify the interface.
- **Manual fallback**: When debugging CI or experimenting, you can always use raw `flutter build ... --dart-define-from-file=.env/.env.<flavor>` commands instead of the wrappers.

## Maintenance and Updates

### Script Maintenance
Regular tasks include:
- Updating Flutter build parameters
- Maintaining Firebase integration
- Adding new environment support
- Improving error handling and user experience

### Version Compatibility
Scripts are designed to work with:
- Current Flutter stable channel
- FVM (Flutter Version Management)
- Latest Firebase CLI tools
- Current project dependencies

### Contributing to Tools
When modifying or extending tools:
1. Test thoroughly on macOS
2. Consider cross-platform implications
3. Update documentation
4. Maintain backward compatibility
5. Follow existing script patterns and conventions

## Best Practices

### Using the Tools
- Always run scripts from the project root directory
- Use the scripts rather than manual commands for consistency
- Check script output for errors or warnings
- Keep tools updated with project requirements

### Troubleshooting
- Run `flutter doctor` to verify Flutter setup
- Check file permissions on script files
- Verify environment files are properly configured
- Review script output for specific error messages

### Integration with IDE
- Use IDE run configurations for daily development
- Use scripts for release builds and distribution
- Combine IDE debugging with script-based building as needed
