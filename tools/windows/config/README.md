# Firebase Configuration Scripts (Windows)

This directory contains Windows batch scripts for configuring and setting up Firebase services for the Artlexis Flutter project.

## Scripts Overview

### 1. `flutterfire_config.bat` - FlutterFire Configuration

Configures Firebase project settings for different environments using the FlutterFire CLI.

**Usage:**

```cmd
flutterfire_config.bat [dev|stg|prod]
```

**What it does:**

- Generates environment-specific Firebase configuration files
- Creates `firebase_options_[env].dart` files
- Sets up platform-specific Firebase configuration files
- Configures iOS bundle IDs and Android package names

### 2. `firebase_setup.bat` - Firebase Crashlytics Setup

Uploads debug symbols to Firebase Crashlytics for crash reporting with readable stack traces.

**Usage:**

```cmd
firebase_setup.bat [dev|stg|prod]
```

**Prerequisites:**

- Firebase CLI must be installed: `npm install -g firebase-tools`
- Must be logged in: `firebase login`
- Debug symbols must exist (generated during obfuscated builds)
- PowerShell must be available (included with Windows)

**What it does:**

- Extracts the correct Firebase App ID from `google-services.json`
- Uploads debug symbols from `.obfuscation` directory to Firebase Crashlytics
- Enables readable stack traces in crash reports

### 3. `verify_symbols.bat` - Verify Debug Symbols

Helps verify uploaded debug symbols in Firebase Console and provides useful information about the current state.

**Usage:**

```cmd
verify_symbols.bat [dev|stg|prod]
```

**What it does:**

- Shows environment-specific configuration details
- Provides Firebase Console links for easy access
- Lists local debug symbols status
- Opens Firebase Console in the default browser

### 4. `generate_app_icon.bat` - App Icon Generation

Generates app icons for different environments and platforms.

**Usage:**

```cmd
generate_app_icon.bat [dev|stg|prod]
```

## Environment Configuration

The scripts support three environments:

| Environment | iOS Bundle ID      | Android Package    | Firebase Config File                        |
| ----------- | ------------------ | ------------------ | ------------------------------------------- |
| **dev**     | `com.eup.meup.dev` | `com.eup.meup.dev` | `android\app\src\dev\google-services.json`  |
| **stg**     | `com.eup.meup.stg` | `com.eup.meup.stg` | `android\app\src\stg\google-services.json`  |
| **prod**    | `com.eup.meup`     | `com.eup.meup`     | `android\app\src\prod\google-services.json` |

## Typical Workflow

### Initial Setup (First Time)

1. **Configure FlutterFire for all environments:**
   ```cmd
   flutterfire_config.bat dev
   flutterfire_config.bat stg
   flutterfire_config.bat prod
   ```

## 🚀 Automated Workflow (Recommended)

The build scripts now automatically handle debug symbol uploads! Here's what happens:

1. **Run a build script:**

   ```cmd
   ..\..\build\build_apk.bat prod
   ```

2. **Automatic process:**
   - ✅ App builds with obfuscation
   - ✅ Debug symbols generated in `.obfuscation`
   - ✅ Firebase setup script automatically called
   - ✅ Debug symbols uploaded to Crashlytics
   - ✅ Console opens to show results

3. **What you'll see:**
   ```
   🔥 Uploading debug symbols to Firebase Crashlytics...
   ✅ Debug symbols uploaded successfully!
   ```

**Error Handling:** If upload fails, the build still succeeds and you'll get manual instructions.

### After Each Obfuscated Build

1. **Build your app with obfuscation** (this automatically uploads debug symbols):

   ```cmd
   REM Using the build scripts - these now automatically upload debug symbols!
   ..\..\build\build_apk.bat [env]
   REM or
   ..\..\build\build_appbundle.bat [env]
   ```

   The build scripts now automatically call `firebase_setup.bat` after a successful build.

2. **Manual upload** (only if automatic upload failed):

   ```cmd
   firebase_setup.bat [env]
   ```

3. **Verify upload** (optional):
   ```cmd
   verify_symbols.bat [env]
   ```

## Firebase App IDs

The script automatically extracts these Firebase App IDs from your `google-services.json` files:

- **prod**: `1:997620226708:android:29479ac03ab356b6be3281`
- **dev**: `1:997620226708:android:38274b8c641cd955be3281`
- **stg**: `1:997620226708:android:1186c4d20d3bc822be3281`

## Troubleshooting

### Common Issues

1. **"Firebase CLI is not installed"**

   ```cmd
   npm install -g firebase-tools
   ```

2. **"Not logged in to Firebase CLI"**

   ```cmd
   firebase login
   ```

3. **"Debug symbols directory not found"**
   - Run a build with obfuscation first
   - Ensure the build completed successfully
   - Check that `.obfuscation` directory exists in project root

4. **"Could not extract Firebase App ID"**
   - Verify the `google-services.json` file exists for the environment
   - Check that the package name matches the expected value
   - Re-run `flutterfire_config.bat` if needed

5. **"PowerShell execution policy restrictions"**
   - Run as Administrator: `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`
   - Or use: `powershell -ExecutionPolicy Bypass -File script.ps1`

6. **"Script cannot be loaded"**
   - Ensure you're running from Command Prompt or PowerShell
   - Check that the script files have proper Windows line endings

### Windows-Specific Notes

- **PowerShell**: The scripts use PowerShell for JSON parsing, which is included with Windows 10+ by default
- **Path Separators**: Uses Windows-style backslashes (`\`) for paths
- **Command Prompt**: Scripts are designed to work with both Command Prompt and PowerShell
- **Browser Opening**: Uses `start` command to open Firebase Console in default browser

### Firebase Console Links

- **Project Overview**: https://console.firebase.google.com/project/meup-bf64f
- **Crashlytics Dashboard**: https://console.firebase.google.com/project/meup-bf64f/crashlytics

## Dependencies

- **FlutterFire CLI**: For Firebase configuration
- **Firebase CLI**: For uploading debug symbols
- **PowerShell**: For JSON parsing (included with Windows)
- **Node.js & npm**: For installing Firebase CLI

## Installation Commands (Windows)

```cmd
REM Install Node.js from https://nodejs.org/ first, then:
npm install -g firebase-tools
npm install -g flutterfire-cli

REM Login to Firebase
firebase login

REM Verify installation
firebase --version
flutterfire --version
```

## Related Documentation

- [Firebase Crashlytics Flutter Documentation](https://firebase.google.com/docs/crashlytics/get-started?platform=flutter)
- [FlutterFire Configuration](https://firebase.flutter.dev/docs/cli/)
- [Windows Command Line Reference](https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/windows-commands)
