# Enhanced Flutter Project Tools

## Overview

This directory contains enhanced build and configuration tools for Flutter projects with **centralized configuration management**. All project-specific values are now stored in the `.info/` directory, making it easy to adapt these tools to new projects.

## 🎯 Key Benefits

- **🔧 Zero Hardcoded Values**: All configuration is centralized in `.info/` directory
- **🚀 Quick Project Setup**: Simply edit configuration files and run setup script
- **📱 Multi-Platform Support**: Android APK, App Bundle, iOS, and IPA builds
- **🔥 Firebase Integration**: Automatic Firebase configuration and symbol upload
- **🎨 Enhanced UX**: Colored output, progress indicators, and comprehensive logging
- **⚡ Developer Friendly**: Consistent command interface across all scripts

## 📁 Directory Structure

```
tools/macos/
├── build/                    # Build scripts
│   ├── build_apk.sh         # Android APK build
│   ├── build_appbundle.sh   # Android App Bundle build
│   ├── build_ios.sh         # iOS app build
│   └── build_ipa.sh         # iOS IPA build
├── config/                   # Configuration scripts
│   ├── flutterfire_config.sh # Firebase configuration
│   └── setup_project.sh     # Project setup automation
├── distribution/            # Distribution scripts
│   ├── distribute_android.sh
│   ├── distribute_ios.sh
│   └── setup_firebase.sh
├── key/                     # Key generation scripts
└── common/                  # Shared utilities
    └── paths.sh            # Path configurations
```

## 🔧 Configuration Files (.info/)

The `.info/` directory contains all project-specific configurations:

### app.json
Main application configuration including:
- App name and display names
- Android package names and bundle IDs
- iOS team information and certificates
- Flavor-specific configurations

### firebase.json
Firebase project configuration:
- Project ID and app IDs
- Distribution settings (testers, groups)
- Release notes templates

### build.json
Build-specific settings:
- Flutter command preferences (fvm vs flutter)
- Build arguments and optimization settings
- Output path configurations

### paths.json
Project path configurations:
- Directory structure definitions
- Environment file locations
- Firebase output paths

### common.sh
Helper functions library providing:
- Configuration reading functions
- Validation utilities
- Logging and display functions

## 🚀 Quick Start

### 1. Configure Your Project

Edit the configuration files in `.info/` directory:

```bash
# Edit main app configuration
nano .info/app/app.json

# Edit Firebase settings
nano .info/app/firebase.json

# Review build settings
nano .info/app/build.json
```

### 2. Run Project Setup

```bash
# Interactive setup (recommended for first time)
./tools/macos/config/setup_project.sh

# Non-interactive setup (for CI/CD)
./tools/macos/config/setup_project.sh --non-interactive
```

### 3. Start Building

```bash
# Build Android APK
./tools/macos/build/build_apk.sh dev

# Build Android App Bundle
./tools/macos/build/build_appbundle.sh prod

# Build iOS
./tools/macos/build/build_ios.sh stg

# Configure Firebase
./tools/macos/config/flutterfire_config.sh dev
```

## 📱 Available Commands

### Build Commands

| Command | Description | Usage |
|---------|-------------|-------|
| `build_apk.sh` | Build Android APK | `./build_apk.sh [dev\|stg\|prod] [--no-tree-shake-icons]` |
| `build_appbundle.sh` | Build Android App Bundle | `./build_appbundle.sh [dev\|stg\|prod] [--no-tree-shake-icons]` |
| `build_ios.sh` | Build iOS app | `./build_ios.sh [dev\|stg\|prod]` |
| `build_ipa.sh` | Build iOS IPA | `./build_ipa.sh [dev\|stg\|prod]` |

### Configuration Commands

| Command | Description | Usage |
|---------|-------------|-------|
| `setup_project.sh` | Complete project setup | `./setup_project.sh [--non-interactive]` |
| `flutterfire_config.sh` | Configure Firebase | `./flutterfire_config.sh [dev\|stg\|prod]` |

### Utility Commands

All scripts support `-h` or `--help` for detailed usage information.

## 🔄 Migrating to New Project

### Step 1: Copy Tools Directory
```bash
# Copy the entire tools directory to your new project
cp -r /path/to/artlexis-flutter/tools /path/to/new-project/
cp -r /path/to/artlexis-flutter/.info /path/to/new-project/
```

### Step 2: Update Configuration
Edit the configuration files in `.info/`:

```json
// .info/app/app.json
{
  "appName": "YourNewApp",
  "appDisplayName": "Your New App",
  "android": {
    "packageName": "com.yourcompany.yournewapp"
  },
  "ios": {
    "bundleId": "com.yourcompany.yournewapp",
    "teamId": "YOUR_TEAM_ID"
  },
  "flavors": {
    "dev": {
      "displayName": "Your New App Dev",
      "android": {
        "packageName": "com.yourcompany.yournewapp.dev"
      }
    }
    // ... other flavors
  }
}
```

```json
// .info/app/firebase.json
{
  "projectId": "your-new-firebase-project",
  // ... update app IDs and package names
}
```

### Step 3: Update Environment Files
Create/update your environment files in `.env/`:
- `.env/.env.dev`
- `.env/.env.stg` 
- `.env/.env.prod`

### Step 4: Run Setup
```bash
./tools/macos/config/setup_project.sh
```

## 🎨 Features

### Enhanced User Experience
- **Colored Output**: Clear visual feedback with emojis and colors
- **Progress Indicators**: Step-by-step progress tracking
- **Configuration Summary**: Display current settings before build
- **Error Handling**: Comprehensive error messages and suggestions

### Automatic Integrations
- **Firebase Crashlytics**: Automatic debug symbol upload
- **Environment Validation**: Pre-build configuration validation
- **Output Management**: Organized build outputs with automatic folder opening

### Developer Productivity
- **Help System**: Comprehensive help for all commands
- **Validation**: Pre-flight checks for all requirements
- **Logging**: Detailed logging for debugging build issues

## 🛠️ Prerequisites

Ensure you have the following tools installed:

```bash
# Required tools
flutter          # Flutter SDK
jq              # JSON processor
firebase        # Firebase CLI (for Firebase features)

# Optional but recommended
fvm             # Flutter Version Management
```

### macOS Installation
```bash
# Install jq
brew install jq

# Install Firebase CLI
npm install -g firebase-tools

# Install FVM (optional)
dart pub global activate fvm
```

## 🧪 Testing Your Setup

### Basic Validation
```bash
# Test configuration loading
source tools/macos/common/common.sh
validate_environment

# Show current configuration
show_config_summary dev
```

### Build Testing
```bash
# Test build scripts
./tools/macos/build/build_apk.sh dev --help
./tools/macos/config/flutterfire_config.sh --help
```

## 🔍 Troubleshooting

### Common Issues

**Missing jq command**
```bash
brew install jq
```

**Permission denied**
```bash
chmod +x tools/macos/**/*.sh
```

**Configuration not found**
```bash
# Ensure .info/ directory exists and contains required files
ls -la .info/
```

**Environment file missing**
```bash
# Check environment files exist
ls -la .env/
```

### Debug Mode

For detailed debugging, you can examine the configuration loading:

```bash
# Test configuration functions
source tools/macos/common/common.sh
get_app_name
get_android_package_name dev
get_firebase_project_id
```

## 📚 Advanced Usage

### Custom Build Arguments
You can customize build arguments by editing `.info/app/build.json`:

```json
{
  "flutter": {
    "buildArgs": {
      "android": {
        "apk": [
          "--release",
          "--obfuscate",
          "--split-debug-info=.obfuscation",
          "--custom-flag"
        ]
      }
    }
  }
}
```

### Environment-Specific Settings
Each flavor can have unique settings in `.info/app/app.json`:

```json
{
  "flavors": {
    "dev": {
      "displayName": "App Dev",
      "android": {
        "packageName": "com.example.app.dev"
      }
    }
  }
}
```

## 🤝 Contributing

When adding new scripts or features:

1. Use the centralized configuration from `tools/macos/common/common.sh`
2. Follow the established logging patterns (`log_info`, `log_error`, etc.)
3. Include help text with `-h/--help` flag
4. Validate inputs and environment before execution
5. Update this documentation

## 📄 License

This tool collection is part of the Artlexis Flutter project and follows the same license terms.

---

For questions or issues, please refer to the project documentation or create an issue in the project repository.