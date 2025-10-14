# Flavor Configuration

This document explains the flavor configuration system used in DCore projects for multi-environment support.

## Overview

Flutter flavors allow building different versions of the same app with different configurations, branding, and behavior. The DCore project uses flavors to support three environments: development, staging, and production.

## Flavor Structure

### Supported Flavors
- **dev**: Development environment with debug features
- **stg**: Staging environment that mirrors production
- **prod**: Production environment for live deployment

### Flavor Mapping
| Flavor | Environment | Target File | Environment File |
|--------|-------------|-------------|------------------|
| `dev` | Development | `lib/main_dev.dart` | `.env/.env.dev` |
| `stg` | Staging | `lib/main_stg.dart` | `.env/.env.stg` |
| `prod` | Production | `lib/main_prod.dart` | `.env/.env.prod` |

## Flutter Flavor Configuration

### Main Entry Points
Each flavor has its own main entry point that sets the flavor and delegates to the common main:

#### lib/main_dev.dart
```dart
import 'flavors.dart';
import 'main.dart' as runner;

void main() {
  F.appFlavor = Flavor.dev;
  runner.main();
}
```

#### lib/main_stg.dart
```dart
import 'flavors.dart';
import 'main.dart' as runner;

void main() {
  F.appFlavor = Flavor.stg;
  runner.main();
}
```

#### lib/main_prod.dart
```dart
import 'flavors.dart';
import 'main.dart' as runner;

void main() {
  F.appFlavor = Flavor.prod;
  runner.main();
}
```

#### lib/main.dart (Common Entry Point)
```dart
import 'package:meup/meup.dart';

void main() {
  AppService.instance.init(() => runApp(const AppProviders(child: DMainApp())));
}

class DMainApp extends StatelessWidget {
  const DMainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => context.text.appTitle,
      // ... rest of app configuration
    );
  }
}
```

### Flavor Management
The project uses a centralized flavor management system:

#### lib/flavors.dart
```dart
import 'package:firebase_core/firebase_core.dart';

import 'config/services/firebase/firebase_options_dev.dart' as dev;
import 'config/services/firebase/firebase_options_prod.dart' as prod;
import 'config/services/firebase/firebase_options_stg.dart' as stg;

enum Flavor {
  dev,
  stg,
  prod,
}

class F {
  static Flavor? appFlavor;

  static String get name => appFlavor?.name ?? '';

  static String get title {
    return switch (appFlavor) {
      Flavor.dev => 'DCore Dev',
      Flavor.stg => 'DCore Staging',
      Flavor.prod => 'DCore',
      _ => 'DCore',
    };
  }

  static FirebaseOptions get firebaseOptions {
    return switch (appFlavor) {
      Flavor.dev => dev.DefaultFirebaseOptions.currentPlatform,
      Flavor.stg => stg.DefaultFirebaseOptions.currentPlatform,
      Flavor.prod => prod.DefaultFirebaseOptions.currentPlatform,
      _ => throw UnsupportedError('No Firebase options set for this flavor')
    };
  }
}
```

### Environment Detection
Access current flavor and environment-specific configuration:

```dart
// Get current flavor
String flavorName = F.name; // 'dev', 'stg', or 'prod'
String appTitle = F.title; // 'DCore Dev', 'DCore Staging', or 'DCore'

// Check specific flavor
bool isDev = F.appFlavor == Flavor.dev;
bool isStg = F.appFlavor == Flavor.stg;
bool isProd = F.appFlavor == Flavor.prod;

// Get Firebase configuration
FirebaseOptions options = F.firebaseOptions;
```

## Flavorizr Configuration

The project uses `flutter_flavorizr` for automated flavor generation. Configuration is defined in `flavorizr.yaml`:

### Flavorizr Settings
```yaml
ide: idea

instructions:
  # assets
  - assets:download
  - assets:extract

  # android
  - android:icons

  # ios
  - ios:podfile
  - ios:xcconfig
  - ios:buildTargets
  - ios:schema
  - ios:dummyAssets
  - ios:icons
  - ios:plist
  - ios:launchScreen

  # google
  - google:firebase

  # assets
  - assets:clean

app:
  android:
    flavorDimensions: "flavor-type"
    buildConfigFields:
      APP_ENVIRONMENT:
        type: "String"
        value: "${flavor}"
  
  ios:
    flavorDimensions: "flavor-type"
    schema: true
```

### Flavor Definitions
```yaml
flavors:
  dev:
    app:
      name: "DCore Dev"
      icon: "assets/images/main_icon.png"

    android:
      applicationId: "com.eup.meup.dev"
      firebase:
        config: "android/app/src/dev/google-services.json"
      resValues:
        app_name:
          type: string
          value: "DCore Dev"
        environment:
          type: string
          value: "development"
      buildConfigFields:
        APP_ENVIRONMENT: 
          type: "String"
          value: "dev"
        API_BASE_URL: 
          type: "String"
          value: "https://dev.api.com"
        IS_DEBUG:
          type: "boolean"
          value: "true"

    ios:
      bundleId: "com.eup.meup.dev"
      buildSettings:
        PRODUCT_BUNDLE_IDENTIFIER: "com.eup.meup.dev"
      firebase:
        config: "ios/flavors/dev/GoogleService-Info.plist"
      variables:
        API_BASE_URL:
          value: "https://dev.api.com"

  stg:
    app:
      name: "DCore Staging"
      icon: "assets/images/main_icon.png"

    android:
      applicationId: "com.eup.meup.stg"
      firebase:
        config: "android/app/src/stg/google-services.json"
      resValues:
        app_name:
          type: string
          value: "DCore Staging"
        environment:
          type: string
          value: "staging"
      buildConfigFields:
        APP_ENVIRONMENT: 
          type: "String"
          value: "stg"
        API_BASE_URL: 
          type: "String"
          value: "https://stg.api.com"
        IS_DEBUG:
          type: "boolean"
          value: "true"

    ios:
      bundleId: "com.eup.meup.stg"
      buildSettings:
        PRODUCT_BUNDLE_IDENTIFIER: "com.eup.meup.stg"
      firebase:
        config: "ios/flavors/stg/GoogleService-Info.plist"
      variables:
        API_BASE_URL:
          value: "https://stg.api.com"

  prod:
    app:
      name: "DCore"
      icon: "assets/images/main_icon.png"

    android:
      applicationId: "com.eup.meup"
      firebase:
        config: "android/app/src/prod/google-services.json"
      resValues:
        app_name:
          type: string
          value: "DCore"
        environment:
          type: string
          value: "production"
      buildConfigFields:
        APP_ENVIRONMENT: 
          type: "String"
          value: "prod"
        API_BASE_URL: 
          type: "String"
          value: "https://prod.api.com"
        IS_DEBUG:
          type: "boolean"
          value: "false"

    ios:
      bundleId: "com.eup.meup"
      buildSettings:
        PRODUCT_BUNDLE_IDENTIFIER: "com.eup.meup"
      firebase:
        config: "ios/flavors/prod/GoogleService-Info.plist"
      variables:
        API_BASE_URL:
          value: "https://prod.api.com"
```

## Android Flavor Configuration

### Generated Flavorizr Configuration
After running `dart run flutter_flavorizr`, flavors are automatically configured in `android/app/flavorizr.gradle.kts`:

```kotlin
import com.android.build.gradle.AppExtension

val android = project.extensions.getByType(AppExtension::class.java)

android.apply {
    flavorDimensions("flavor-type")

    productFlavors {
        create("dev") {
            dimension = "flavor-type"
            applicationId = "com.eup.meup.dev"
            resValue(type = "string", name = "app_name", value = "Meup Dev")
            resValue(type = "string", name = "environment", value = "development")
            buildConfigField(type = "String", name = "APP_ENVIRONMENT", value = "\"dev\"")
            buildConfigField(type = "String", name = "API_BASE_URL", value = "\"https://dev.venusshop.top/api/v1\"")
            buildConfigField(type = "boolean", name = "IS_DEBUG", value = "true")
        }
        create("stg") {
            dimension = "flavor-type"
            applicationId = "com.eup.meup.stg"
            resValue(type = "string", name = "app_name", value = "Meup Staging")
            resValue(type = "string", name = "environment", value = "staging")
            buildConfigField(type = "String", name = "APP_ENVIRONMENT", value = "\"stg\"")
            buildConfigField(type = "String", name = "API_BASE_URL", value = "\"https://dev.venusshop.top/api/v1\"")
            buildConfigField(type = "boolean", name = "IS_DEBUG", value = "true")
        }
        create("prod") {
            dimension = "flavor-type"
            applicationId = "com.eup.meup"
            resValue(type = "string", name = "app_name", value = "Meup")
            resValue(type = "string", name = "environment", value = "production")
            buildConfigField(type = "String", name = "APP_ENVIRONMENT", value = "\"prod\"")
            buildConfigField(type = "String", name = "API_BASE_URL", value = "\"https://venusshop.top/api/v1\"")
            buildConfigField(type = "boolean", name = "IS_DEBUG", value = "false")
        }
    }

    buildFeatures.buildConfig = true
}
```

This file is generated by `flutter_flavorizr` and uses Kotlin DSL syntax. The configuration is applied to the main `android/app/build.gradle` file through the `apply from: 'flavorizr.gradle.kts'` statement.

### Flavor-Specific Resources
Each flavor can have its own resources:

```
android/app/src/
├── main/                    # Common resources
│   ├── AndroidManifest.xml
│   └── res/
├── dev/                     # Development-specific
│   ├── res/
│   │   └── mipmap-*/
│   │       └── ic_launcher_dev.png
│   └── google-services.json
├── stg/                     # Staging-specific
│   ├── res/
│   │   └── mipmap-*/
│   │       └── ic_launcher_stg.png
│   └── google-services.json
└── prod/                    # Production-specific
    ├── res/
    │   └── mipmap-*/
    │       └── ic_launcher.png
    └── google-services.json
```

### AndroidManifest.xml Configuration
Use resource values defined in flavors:

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.eup.meup">
    
    <application
        android:label="@string/app_name"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme" />
              
            <intent-filter android:autoVerify="true">
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
```

The `@string/app_name` resolves to flavor-specific values:
- **dev**: "DCore Dev"
- **stg**: "DCore Staging"  
- **prod**: "DCore"

## iOS Flavor Configuration

### Scheme Configuration
iOS flavors are managed through Xcode schemes and configurations:

```
ios/
├── Runner/
│   ├── Info-dev.plist
│   ├── Info-stg.plist
│   ├── Info-prod.plist
│   └── GoogleService-Info-dev.plist
│       GoogleService-Info-stg.plist
│       GoogleService-Info-prod.plist
└── Runner.xcworkspace/
```

### Info.plist Configuration
Flavorizr generates environment-specific Info.plist files:

#### Development Info.plist
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDisplayName</key>
    <string>DCore Dev</string>
    <key>CFBundleIdentifier</key>
    <string>com.eup.meup.dev</string>
    <key>CFBundleName</key>
    <string>artlexis_dev</string>
    <!-- Environment-specific variables -->
    <key>API_BASE_URL</key>
    <string>https://dev.api.com</string>
    <!-- Firebase configuration from ios/flavors/dev/GoogleService-Info.plist -->
</dict>
</plist>
```

#### Staging Info.plist
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDisplayName</key>
    <string>DCore Staging</string>
    <key>CFBundleIdentifier</key>
    <string>com.eup.meup.stg</string>
    <key>CFBundleName</key>
    <string>artlexis_stg</string>
    <!-- Environment-specific variables -->
    <key>API_BASE_URL</key>
    <string>https://stg.api.com</string>
    <!-- Firebase configuration from ios/flavors/stg/GoogleService-Info.plist -->
</dict>
</plist>
```

#### Production Info.plist
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDisplayName</key>
    <string>DCore</string>
    <key>CFBundleIdentifier</key>
    <string>com.eup.meup</string>
    <key>CFBundleName</key>
    <string>meup</string>
    <!-- Environment-specific variables -->
    <key>API_BASE_URL</key>
    <string>https://prod.api.com</string>
    <!-- Firebase configuration from ios/flavors/prod/GoogleService-Info.plist -->
</dict>
</plist>
```

## Build Integration

### Command Line Usage
Build specific flavors using Flutter commands or the provided build scripts:

#### Using Build Scripts (Recommended)
```bash
# Android APK
./tools/macos/build/build_apk.sh dev    # Development
./tools/macos/build/build_apk.sh stg    # Staging
./tools/macos/build/build_apk.sh prod   # Production

# Android App Bundle
./tools/macos/build/build_appbundle.sh dev
./tools/macos/build/build_appbundle.sh stg
./tools/macos/build/build_appbundle.sh prod

# iOS IPA
./tools/macos/build/build_ipa.sh dev
./tools/macos/build/build_ipa.sh stg
./tools/macos/build/build_ipa.sh prod
```

#### Using Flutter Commands Directly
```bash
# Development flavor
flutter build apk --flavor dev --dart-define-from-file=.env/.env.dev -t lib/main_dev.dart

# Staging flavor
flutter build apk --flavor stg --dart-define-from-file=.env/.env.stg -t lib/main_stg.dart

# Production flavor
flutter build apk --flavor prod --dart-define-from-file=.env/.env.prod -t lib/main_prod.dart
```

#### Running in Development
```bash
# Run with specific flavor
flutter run --flavor dev --dart-define-from-file=.env/.env.dev -t lib/main_dev.dart
flutter run --flavor stg --dart-define-from-file=.env/.env.stg -t lib/main_stg.dart
flutter run --flavor prod --dart-define-from-file=.env/.env.prod -t lib/main_prod.dart
```

### Build Script Integration
Custom build scripts automatically handle flavor selection:

```bash
#!/bin/bash
# Automatic flavor to environment mapping
case $FLAVOR in
    dev)
        ENV_FILE=".env/.env.dev"
        TARGET_FILE="lib/main_dev.dart"
        ;;
    stg)
        ENV_FILE=".env/.env.stg"
        TARGET_FILE="lib/main_stg.dart"
        ;;
    prod)
        ENV_FILE=".env/.env.prod"
        TARGET_FILE="lib/main_prod.dart"
        ;;
esac
```

## IDE Configuration

### VS Code Launch Configurations
Flavor-specific launch configurations in `.vscode/launch.json`:

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "dev Debug",
            "request": "launch",
            "type": "dart",
            "flutterMode": "debug",
            "args": [
                "--flavor", "dev",
                "--dart-define-from-file", ".env/.env.dev"
            ],
            "program": "lib/main_dev.dart"
        },
        {
            "name": "stg Debug",
            "request": "launch",
            "type": "dart",
            "flutterMode": "debug",
            "args": [
                "--flavor", "stg",
                "--dart-define-from-file", ".env/.env.stg"
            ],
            "program": "lib/main_stg.dart"
        },
        {
            "name": "prod Debug",
            "request": "launch",
            "type": "dart",
            "flutterMode": "debug",
            "args": [
                "--flavor", "prod",
                "--dart-define-from-file", ".env/.env.prod"
            ],
            "program": "lib/main_prod.dart"
        }
    ]
}
```

### IntelliJ Run Configurations
Flavor-specific run configurations in `.idea/runConfigurations/`:

```xml
<!-- main_dev_dart.xml -->
<component name="ProjectRunConfigurationManager">
  <configuration name="main_dev.dart" type="FlutterRunConfigurationType">
    <option name="filePath" value="$PROJECT_DIR$/lib/main_dev.dart" />
    <option name="additionalArgs" value="--flavor dev --dart-define-from-file .env/.env.dev" />
    <method v="2" />
  </configuration>
</component>
```

## Environment-Specific Behavior

### Feature Flags
Control features based on flavor:

```dart
class FeatureFlags {
  static bool get debugMenu => F.appFlavor == Flavor.dev;
  static bool get verboseLogging => F.appFlavor != Flavor.prod;
  static bool get crashReporting => F.appFlavor == Flavor.prod;
  
  // Environment-specific API endpoints from build configuration
  static String get apiBaseUrl {
    return switch (F.appFlavor) {
      Flavor.dev => 'https://dev.api.com',
      Flavor.stg => 'https://stg.api.com',
      Flavor.prod => 'https://prod.api.com',
      _ => 'https://prod.api.com',
    };
  }
  
  // Firebase configuration handled automatically by F.firebaseOptions
  static FirebaseOptions get firebaseOptions => F.firebaseOptions;
}
```

### UI Customization
Different UI elements per flavor:

```dart
class AppTheme {
  static ThemeData get theme {
    return switch (F.appFlavor) {
      Flavor.dev => _developmentTheme,
      Flavor.stg => _stagingTheme,
      Flavor.prod => _productionTheme,
      _ => _productionTheme,
    };
  }
  
  static ThemeData get _developmentTheme => ThemeData(
    primarySwatch: Colors.green, // Green for dev
    appBarTheme: AppBarTheme(
      title: Text('${F.title} - DEV'),
    ),
  );
  
  static ThemeData get _stagingTheme => ThemeData(
    primarySwatch: Colors.orange, // Orange for staging
    appBarTheme: AppBarTheme(
      title: Text('${F.title} - STAGING'),
    ),
  );
  
  static ThemeData get _productionTheme => ThemeData(
    primarySwatch: Colors.blue, // Blue for production
    appBarTheme: AppBarTheme(
      title: Text(F.title), // "DCore"
    ),
  );
}
```

### Debug Features
Development-only features:

```dart
class DebugPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (F.appFlavor != Flavor.dev) {
      return SizedBox.shrink();
    }
    
    return FloatingActionButton(
      onPressed: () => _showDebugMenu(context),
      child: Icon(Icons.bug_report),
      backgroundColor: Colors.red,
    );
  }
  
  void _showDebugMenu(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Debug Menu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Flavor: ${F.name}'),
            ),
            ListTile(
              title: Text('App Title: ${F.title}'),
            ),
            ListTile(
              title: Text('API URL: ${FeatureFlags.apiBaseUrl}'),
            ),
            ListTile(
              title: Text('Firebase Project: ${F.firebaseOptions.projectId}'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Testing Flavors

### Flavor-Specific Tests
Test flavor-specific behavior:

```dart
group('Flavor Configuration', () {
  testWidgets('should show debug menu only in development', (tester) async {
    // Set flavor for test
    F.appFlavor = Flavor.dev;
    
    await tester.pumpWidget(
      MaterialApp(home: DebugPanel()),
    );
    
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('should not show debug menu in production', (tester) async {
    // Set flavor for test
    F.appFlavor = Flavor.prod;
    
    await tester.pumpWidget(
      MaterialApp(home: DebugPanel()),
    );
    
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  test('should return correct app title for each flavor', () {
    F.appFlavor = Flavor.dev;
    expect(F.title, 'DCore Dev');

    F.appFlavor = Flavor.stg;
    expect(F.title, 'DCore Staging');

    F.appFlavor = Flavor.prod;
    expect(F.title, 'DCore');
  });
});
```

### Integration Testing
Test all flavors:

```bash
# Test all flavors
flutter test integration_test/dev_test.dart --flavor dev
flutter test integration_test/stg_test.dart --flavor stg  
flutter test integration_test/prod_test.dart --flavor prod
```

## Generating Flavors

### Initial Setup
Generate all flavor configurations using flutter_flavorizr:

```bash
# Install flutter_flavorizr globally
dart pub global activate flutter_flavorizr

# Generate flavors based on flavorizr.yaml configuration
dart run flutter_flavorizr
```

### What Gets Generated
The flavorizr tool automatically creates:

1. **Android Configuration**
   - Flavor dimensions in `build.gradle`
   - Application IDs and build config fields
   - Resource values for app names
   - Firebase configuration files

2. **iOS Configuration**
   - Xcode schemes for each flavor
   - Bundle identifiers and build settings
   - Info.plist configurations
   - Firebase configuration files

3. **Assets and Icons**
   - Flavor-specific app icons
   - Launch screen configurations

### Re-generating After Changes
After modifying `flavorizr.yaml`:

```bash
# Clean previous generation
flutter clean

# Regenerate flavors
dart run flutter_flavorizr

# Get dependencies
flutter pub get
```

## Best Practices

### Flavor Management
- Use `flutter_flavorizr` for automated flavor generation
- Keep flavor-specific code minimal using `F` class methods
- Leverage build config fields for environment-specific values
- Maintain consistent naming conventions across platforms

### Security Considerations
- Never expose sensitive data in development builds
- Use different Firebase projects for each environment
- Store API keys in build config fields, not hardcoded
- Regular security audits per environment

### Development Workflow
- Default to development flavor for daily work
- Use build scripts for consistent builds
- Test staging before production releases
- Maintain environment parity where possible

### Maintenance
- Keep all flavors updated simultaneously
- Test configuration changes across all flavors
- Use automated flavor generation to reduce manual errors
- Regular cleanup of unused configurations

### Integration with CI/CD
- Use flavor-specific build scripts in CI pipelines
- Store environment-specific secrets as CI variables
- Automate flavor testing across all environments
- Generate signed builds for each flavor automatically