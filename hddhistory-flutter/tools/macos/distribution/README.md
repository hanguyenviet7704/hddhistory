# Firebase App Distribution Tools

Comprehensive tools for managing Firebase App Distribution including building, distributing, and managing testers and groups.

## 📋 Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Available Tools](#available-tools)
- [Usage Examples](#usage-examples)
- [Configuration](#configuration)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## 🎯 Overview

This directory contains enhanced Firebase App Distribution tools that:

- **Dynamic Configuration**: All settings pulled from centralized `.info/` configuration
- **Command Visibility**: All Firebase commands are printed before execution
- **Automated Workflows**: Build and distribute in one command
- **Tester Management**: Add, remove, import/export testers
- **Group Management**: Create, sync, and manage distribution groups
- **Cross-Platform**: Support for both Android (APK/AAB) and iOS (IPA)

## 📦 Prerequisites

### Required Tools

```bash
# Firebase CLI
npm install -g firebase-tools

# jq (JSON processor)
brew install jq

# Flutter/FVM (if using)
# Already configured in your project
```

### Firebase Setup

1. **Install Firebase CLI** and login:
   ```bash
   firebase login
   ```

2. **Configure Firebase project** in `.info/firebase.json`:
   ```json
   {
     "projects": {
       "dev": "your-project-dev",
       "stg": "your-project-stg",
       "prod": "your-project-prod"
     },
     "apps": {
       "android": {
         "dev": { "appId": "1:xxx:android:xxx" },
         "stg": { "appId": "1:xxx:android:xxx" },
         "prod": { "appId": "1:xxx:android:xxx" }
       },
       "ios": {
         "dev": { "appId": "1:xxx:ios:xxx" },
         "stg": { "appId": "1:xxx:ios:xxx" },
         "prod": { "appId": "1:xxx:ios:xxx" }
       }
     },
     "distribution": {
       "testers": {
         "dev": ["tester1@example.com", "tester2@example.com"],
         "stg": ["qa@example.com"],
         "prod": ["beta@example.com"]
       },
       "groups": {
         "dev": ["dev-team", "qa-team"],
         "stg": ["qa-team"],
         "prod": ["beta-testers"]
       },
       "releaseNotes": {
         "template": "Version {{version}} - {{flavor}} build\\n\\nReleased on {{date}}"
       }
     }
   }
   ```

## 🚀 Quick Start

### 1. Distribute Android APK

```bash
# Build and distribute in one command
./tools/macos/build/build_apk.sh dev --distribute

# Or distribute existing build
./tools/macos/distribution/distribute_android.sh apk dev
```

### 2. Distribute iOS IPA

```bash
# Build and distribute
./tools/macos/distribution/distribute_ios.sh dev --build-first

# Or distribute existing build
./tools/macos/distribution/distribute_ios.sh prod
```

### 3. Manage Testers

```bash
# List testers
./tools/macos/distribution/manage_testers.sh list

# Add testers
./tools/macos/distribution/manage_testers.sh add user1@example.com user2@example.com

# Add testers to group
./tools/macos/distribution/manage_testers.sh add-to-group --group qa-team user@example.com
```

### 4. Manage Groups

```bash
# List groups
./tools/macos/distribution/manage_groups.sh list

# Create group
./tools/macos/distribution/manage_groups.sh create "QA Team" qa-team

# Sync groups from config
./tools/macos/distribution/manage_groups.sh sync --flavor dev
```

## 🛠️ Available Tools

### Distribution Scripts

All distribution tools use centralized configuration and print commands before execution.

#### `distribute_android.sh`
```bash
./distribute_android.sh [apk|appbundle] [dev|stg|prod] [--build-first] [--dry-run]
```

#### `distribute_ios.sh`
```bash
./distribute_ios.sh [dev|stg|prod] [--build-first] [--ipa <path>] [--dry-run]
```

### Fastlane Wrappers (Android + iOS)

Fastlane wrappers are available at:

```bash
tools/macos/distribution/fastlane/android_fastlane.sh
tools/macos/distribution/fastlane/ios_fastlane.sh
```

Both wrappers support:
- lane aliases for all current lanes
- `lane <lane_name>` generic execution
- `raw <fastlane args...>` passthrough for any Fastlane command/action
- global flags: `--dry-run`, `--verbose`, `--ci`, `--help`

Examples:

```bash
# Android
bash tools/macos/distribution/fastlane/android_fastlane.sh lanes --ci
bash tools/macos/distribution/fastlane/android_fastlane.sh build_apk flavor:dev
bash tools/macos/distribution/fastlane/android_fastlane.sh deploy --dry-run flavor:prod track:internal
bash tools/macos/distribution/fastlane/android_fastlane.sh deploy track:production
bash tools/macos/distribution/fastlane/android_fastlane.sh lane deploy flavor:prod track:production
bash tools/macos/distribution/fastlane/android_fastlane.sh raw deploy flavor:prod track:production
bash tools/macos/distribution/fastlane/android_fastlane.sh raw supply init --package_name com.hddhistory.app

# iOS
bash tools/macos/distribution/fastlane/ios_fastlane.sh lanes --ci
bash tools/macos/distribution/fastlane/ios_fastlane.sh beta_ipa flavor:stg changelog:"Build notes"
bash tools/macos/distribution/fastlane/ios_fastlane.sh deploy --dry-run flavor:prod track:production
bash tools/macos/distribution/fastlane/ios_fastlane.sh deploy flavor:prod track:production upload_metadata:true
bash tools/macos/distribution/fastlane/ios_fastlane.sh lane deploy flavor:prod track:production upload_metadata:true
bash tools/macos/distribution/fastlane/ios_fastlane.sh raw deploy flavor:prod track:production upload_metadata:true
bash tools/macos/distribution/fastlane/ios_fastlane.sh raw deliver download_metadata --app_identifier com.hddhistory.app --metadata_path fastlane/metadata
```

Notes:
- Default flavor in deploy lanes is `prod`.
- For iOS metadata flags (`upload_metadata`, `upload_screenshots`), use `deploy ...` / `lane deploy ...` / `raw deploy ...`.
- `deploy_production` is a shortcut lane and not the best choice when you need metadata flags.

### Tester Management

#### `manage_testers.sh`
```bash
./manage_testers.sh <command> [options]

Commands:
  list, add, remove, add-to-group, remove-from-group, import, export
```

### Group Management

#### `manage_groups.sh`
```bash
./manage_groups.sh <command> [options]

Commands:
  list, create, delete, show, sync
```

### Enhanced Build Tools

```bash
# Build with distribution
./tools/macos/build/build_apk.sh dev --distribute
./tools/macos/build/build_apk.sh prod --distribute --group beta-testers
```

## 📖 Usage Examples

See the detailed examples in the full documentation sections above.

## ⚙️ Configuration

All configuration is centralized in `.info/firebase.json`. Environment variables can override settings:

```bash
export FIREBASE_DISTRIBUTION_TESTERS="custom@example.com"
export FIREBASE_DISTRIBUTION_GROUP="custom-group"
```

## 🎯 Best Practices

1. **Always test with --dry-run first**
2. **Organize testers with groups**  
3. **Regular backups of tester lists**
4. **Sync groups regularly**
5. **Automate distribution in CI/CD**

## 🔍 Troubleshooting

Common issues and solutions:

1. **Firebase CLI Not Authenticated**: `firebase login`
2. **App ID Not Found**: Verify `.info/firebase.json`
3. **Distribution Fails**: Update Firebase CLI
4. **Tester Not Receiving**: Re-add to group
5. **Group Not Found**: Run sync command

## 📚 Resources

- [Firebase App Distribution Docs](https://firebase.google.com/docs/app-distribution)
- [Firebase CLI Reference](https://firebase.google.com/docs/cli)

---

For detailed usage, run any script with `--help` flag.
