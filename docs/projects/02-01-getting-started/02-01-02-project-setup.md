# Project Setup Guide

This document provides step-by-step instructions for setting up Dcore Flutter projects on your development machine.

## Quick Setup (Experienced Developers)

For developers familiar with Flutter projects, follow these essential steps:

```bash
# 1. Clone the repository
git clone [repository-url]
cd meup-flutter

# 2. Generate project resources
sh tools/macos/resource/generate_file.sh

# 3. Reset and clean project
sh tools/macos/build/reset_app.sh

# 4. Generate localization files
sh tools/macos/localization/generate_localization.sh

# 5. Run the application using IDE configurations
```

## Detailed Setup Process

### Step 1: Repository Setup

#### Clone the Repository
```bash
git clone [repository-url]
cd meup-flutter
```

#### Verify Repository Structure
```bash
ls -la
```

You should see the following key directories and files:
- `.env/` - Environment configuration files
- `.info/` - Project metadata
- `tools/` - Custom development scripts
- `lib/` - Flutter application source code
- `pubspec.yaml` - Project dependencies
- `CLAUDE.md` - AI assistant guidance

### Step 2: Environment Configuration

#### Check Environment Files
```bash
ls -la .env/
```

Expected files:
- `.env.dev` - Development environment
- `.env.stg` - Staging environment
- `.env.prod` - Production environment

#### Verify Environment File Contents
```bash
cat .env/.env.dev
```

The file should contain environment-specific configuration such as:
- API endpoints
- Firebase configuration keys
- Feature flags
- Environment identifiers

> **Important**: If environment files are missing or incomplete, contact the project team for proper configuration.

### Step 3: Project Dependencies

#### Install Flutter Dependencies
```bash
flutter pub get
```

This command will:
- Download all required packages
- Resolve dependency conflicts
- Prepare the project for development

#### Verify Dependencies
```bash
flutter pub deps
```

### Step 4: Resource Generation (Critical)

This step is **mandatory** and must be completed before running the application.

#### Generate Code Files
```bash
sh tools/macos/resource/generate_file.sh
```

This script generates:
- `.g.dart` files (JSON serialization)
- `.freezed.dart` files (immutable classes)
- Dependency injection code
- API client code
- Route definitions

#### What This Script Does
The script runs:
```bash
fvm dart run build_runner build --delete-conflicting-outputs
```

**Expected Output**:
```
Running build_runner to generate api files...
Running build_runner to generate models files...
Running build_runner to generate resources files...
[INFO] Generating build script...
[INFO] Building new asset graph...
[INFO] Running build...
[INFO] Succeeded after XXXXms with XXX outputs
```

### Step 5: Project Reset and Cleanup

#### Clean and Reset Project
```bash
sh tools/macos/build/reset_app.sh
```

This script:
- Removes build artifacts (`build/` directory)
- Runs `flutter clean`
- Fetches fresh dependencies with `flutter pub get`

**Expected Output**:
```
Cleaning Flutter project...
Fetching Flutter packages...
Flutter project reset successfully: cleaned and packages fetched.
```

### Step 6: Localization Setup

#### Generate Localization Files
```bash
sh tools/macos/localization/generate_localization.sh
```

This script:
1. Creates Python virtual environment (first run only)
2. Generates module ARB files from Google Sheets
3. Merges module ARB files into app ARB files
4. Runs `flutter gen-l10n` to generate Dart localization code

**Expected Output**:
```
Flutter Localization Generator
================================
Step 1: Generating module ARB files from Google Sheets...
Step 2: Merging module ARB files...
Step 3: Running Flutter localization generation...
✓ Localization generation completed successfully!
```

### Step 7: Verify Setup

#### Check Generated Files
```bash
# Check if code generation worked
find lib -name "*.g.dart" | head -5
find lib -name "*.freezed.dart" | head -5

# Check localization files
ls -la lib/config/l10n/
ls -la assets/arb/app/
```

#### Run Flutter Doctor
```bash
flutter doctor -v
```

Ensure all checks pass, especially:
- Flutter installation
- Android toolchain (if targeting Android)
- iOS toolchain (if targeting iOS)
- IDE setup

### Step 8: Test the Setup

#### Option 1: Using VS Code
1. Open the project in VS Code
2. Go to Run and Debug (Ctrl/Cmd + Shift + D)
3. Select "dev Debug" configuration
4. Press F5 or click the run button

#### Option 2: Using IntelliJ/Android Studio
1. Open the project
2. Look for run configurations in the toolbar
3. Select "main_dev_dart" configuration
4. Click the run button

#### Option 3: Command Line
```bash
flutter run --flavor dev --dart-define-from-file=.env/.env.dev -t lib/main_dev.dart
```

## Platform-Specific Setup

### Android Setup

#### Verify Android Configuration
```bash
flutter doctor android
```

#### Build APK (Optional Test)
```bash
sh tools/macos/build/build_apk.sh dev
```

### iOS Setup (macOS only)

#### Pod Installation
```bash
cd ios
pod install
cd ..
```

#### Build iOS (Optional Test)
```bash
sh tools/macos/build/build_ios.sh dev
```

## Common Setup Issues

### Build Runner Issues

#### Clear Cache and Regenerate
```bash
flutter packages pub run build_runner clean
sh tools/macos/resource/generate_file.sh
```

#### Manual Build Runner Command
```bash
fvm dart run build_runner build --delete-conflicting-outputs
```

### Permission Issues (macOS)

#### Make Scripts Executable
```bash
chmod +x tools/macos/resource/generate_file.sh
chmod +x tools/macos/build/reset_app.sh
chmod +x tools/macos/localization/generate_localization.sh
```

### Environment File Issues

#### Check File Encoding
Environment files should be UTF-8 encoded without BOM.

#### Verify File Format
Each line should be in format: `KEY=value`

### Dependency Conflicts

#### Clear Pub Cache
```bash
flutter pub cache clean
flutter pub get
```

#### Update Dependencies
```bash
flutter pub upgrade
```

## Project Structure Verification

After setup, your project should have:

```
lib/
├── config/
│   ├── di/
│   │   └── injection.config.dart    # Generated DI config
│   ├── l10n/
│   │   ├── app_localizations.dart   # Generated localizations
│   │   └── ...
│   └── routes/
│       └── app_router.gr.dart       # Generated routes
├── core/
│   └── constants/
│       └── gen/                     # Generated assets
└── src/
    ├── data/
    │   └── models/
    │       └── *.g.dart            # Generated JSON models
    └── domain/
        └── entities/
            └── *.freezed.dart      # Generated immutable classes
```

## Next Steps

After successful setup:
1. Read [First-Time Developer Setup](02-01-03-first-time-setup.md) for IDE configuration
2. Explore [Project Architecture](../02-02-project-architecture/) documentation
3. Review [Development Tools](../02-05-development-tools/) for available scripts
4. Start development with your preferred IDE configuration

## Troubleshooting Resources

### Common Commands for Issues
```bash
# Complete project reset
flutter clean
rm -rf build/
flutter pub get
sh tools/macos/resource/generate_file.sh

# Clear all caches
flutter pub cache clean
flutter clean

# Regenerate everything
sh tools/macos/build/reset_app.sh
sh tools/macos/resource/generate_file.sh
sh tools/macos/localization/generate_localization.sh
```

### Getting Help
1. Check the troubleshooting section in each script's README
2. Review Flutter doctor output for system issues
3. Consult team members for project-specific problems
4. Check project issues/documentation for known problems