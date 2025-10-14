# Firebase Configuration Scripts

This directory contains scripts for configuring and setting up Firebase services for the Artlexis Flutter project.

## Scripts Overview

### 1. `flutterfire_config.sh` - FlutterFire Configuration
Configures Firebase project settings for different environments using the FlutterFire CLI.

**Usage:**
```bash
./flutterfire_config.sh [dev|stg|prod]
```

**What it does:**
- Generates environment-specific Firebase configuration files
- Creates `firebase_options_[env].dart` files
- Sets up platform-specific Firebase configuration files
- Configures iOS bundle IDs and Android package names

### 2. `firebase_setup.sh` - Firebase Crashlytics Setup
Uploads debug symbols to Firebase Crashlytics for crash reporting with readable stack traces.

**Usage:**
```bash
./firebase_setup.sh [dev|stg|prod]
```

**Prerequisites:**
- Firebase CLI must be installed: `npm install -g firebase-tools`
- Must be logged in: `firebase login`
- Debug symbols must exist (generated during obfuscated builds)

**What it does:**
- Extracts the correct Firebase App ID from `google-services.json`
- Uploads debug symbols from `.obfuscation` directory to Firebase Crashlytics
- Enables readable stack traces in crash reports

## Environment Configuration

The scripts support three environments:

| Environment | iOS Bundle ID | Android Package | Firebase Config File |
|-------------|---------------|-----------------|---------------------|
| **dev** | `com.eup.artlexis.dev` | `com.eup.artlexis.dev` | `android/app/src/dev/google-services.json` |
| **stg** | `com.eup.artlexis.stg` | `com.eup.artlexis.stg` | `android/app/src/stg/google-services.json` |
| **prod** | `com.eup.artlexis` | `com.eup.artlexis` | `android/app/src/prod/google-services.json` |

## Typical Workflow

### Initial Setup (First Time)
1. **Configure FlutterFire for all environments:**
   ```bash
   ./flutterfire_config.sh dev
   ./flutterfire_config.sh stg
   ./flutterfire_config.sh prod
   ```

## 🚀 Automated Workflow (Recommended)

The build scripts now automatically handle debug symbol uploads! Here's what happens:

1. **Run a build script:**
   ```bash
   ../../build/build_apk.sh prod
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
   ```bash
   # Using the build scripts - these now automatically upload debug symbols!
   ../../build/build_apk.sh [env]
   # or
   ../../build/build_appbundle.sh [env]
   ```

   The build scripts now automatically call `firebase_setup.sh` after a successful build.

2. **Manual upload** (only if automatic upload failed):
   ```bash
   ./firebase_setup.sh [env]
   ```

## Firebase App IDs

The script automatically extracts these Firebase App IDs from your `google-services.json` files:

- **prod**: `1:997620226708:android:29479ac03ab356b6be3281`
- **dev**: `1:997620226708:android:38274b8c641cd955be3281`
- **stg**: `1:997620226708:android:1186c4d20d3bc822be3281`

## Troubleshooting

### Common Issues

1. **"Firebase CLI is not installed"**
   ```bash
   npm install -g firebase-tools
   ```

2. **"Not logged in to Firebase CLI"**
   ```bash
   firebase login
   ```

3. **"Debug symbols directory not found"**
   - Run a build with obfuscation first
   - Ensure the build completed successfully
   - Check that `.obfuscation` directory exists in project root

4. **"Could not extract Firebase App ID"**
   - Verify the `google-services.json` file exists for the environment
   - Check that the package name matches the expected value
   - Re-run `flutterfire_config.sh` if needed

5. **"jq not found"**
   - Install jq: `brew install jq` (macOS)
   - The script has a fallback method, but jq is more reliable

### Firebase Console Links

- **Project Overview**: https://console.firebase.google.com/project/artlexis-4ba70
- **Crashlytics Dashboard**: https://console.firebase.google.com/project/artlexis-4ba70/crashlytics

## Dependencies

- **FlutterFire CLI**: For Firebase configuration
- **Firebase CLI**: For uploading debug symbols
- **jq** (optional but recommended): For JSON parsing

## Related Documentation

- [Firebase Crashlytics Flutter Documentation](https://firebase.google.com/docs/crashlytics/get-started?platform=flutter)
- [FlutterFire Configuration](https://firebase.flutter.dev/docs/cli/) 