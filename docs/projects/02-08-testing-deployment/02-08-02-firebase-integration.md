# Firebase Integration

This document explains the Firebase integration and configuration in Dcore projects.

## Overview

The Dcore project integrates with multiple Firebase services across different environments, providing analytics, crash reporting, authentication, and more. Each environment (dev, stg, prod) uses its own Firebase project for proper separation and testing.

## Firebase Services Used

### Core Services
- **Firebase Analytics**: User behavior tracking and insights
- **Firebase Crashlytics**: Crash reporting and performance monitoring
- **Firebase Authentication**: User authentication and management
- **Firebase Remote Config**: Feature flags and configuration management
- **Firebase Messaging**: Push notifications

### Additional Services
- **Firebase Performance Monitoring**: App performance insights
- **Firebase App Check**: App attestation and abuse protection

## Project Structure

### Multi-Environment Setup
Each environment uses a separate Firebase project:

| Environment | Firebase Project ID | Purpose |
|-------------|-------------------|---------|
| Development | `meup-dev` | Development and testing |
| Staging | `meup-stg` | Pre-production testing |
| Production | `meup-prod` | Live production app |

### Configuration Files

#### Project Root
- `firebase.json`: Main Firebase configuration
- `.info/firebase_info.json`: Project metadata and configuration

#### Android Configuration
```
android/app/src/
├── dev/
│   └── google-services.json     # Development Firebase config
├── stg/
│   └── google-services.json     # Staging Firebase config
└── prod/
    └── google-services.json     # Production Firebase config
```

#### iOS Configuration
```
ios/Runner/
├── GoogleService-Info-dev.plist     # Development Firebase config
├── GoogleService-Info-stg.plist     # Staging Firebase config
└── GoogleService-Info-prod.plist    # Production Firebase config
```

## Firebase Configuration

### firebase.json
Main Firebase configuration file:

```json
{
  "flutter": {
    "platforms": {
      "dart": {
        "lib/firebase_options_dev.dart": {
          "projectId": "meup-dev",
          "configurations": {
            "android": "android/app/src/dev/google-services.json",
            "ios": "ios/Runner/GoogleService-Info-dev.plist"
          }
        },
        "lib/firebase_options_stg.dart": {
          "projectId": "meup-stg", 
          "configurations": {
            "android": "android/app/src/stg/google-services.json",
            "ios": "ios/Runner/GoogleService-Info-stg.plist"
          }
        },
        "lib/firebase_options_prod.dart": {
          "projectId": "meup-prod",
          "configurations": {
            "android": "android/app/src/prod/google-services.json",
            "ios": "ios/Runner/GoogleService-Info-prod.plist"
          }
        }
      }
    }
  },
  "functions": {
    "source": "functions",
    "predeploy": [
      "npm --prefix \"$RESOURCE_DIR\" run lint",
      "npm --prefix \"$RESOURCE_DIR\" run build"
    ]
  }
}
```

### Environment-Specific Initialization
Firebase is initialized based on the current environment:

```dart
// lib/config/firebase/firebase_config.dart
import 'package:firebase_core/firebase_core.dart';
import '../../../firebase_options_dev.dart' as dev;
import '../../../firebase_options_stg.dart' as stg;
import '../../../firebase_options_prod.dart' as prod;

class FirebaseConfig {
  static const String environment = String.fromEnvironment('ENVIRONMENT');
  
  static FirebaseOptions get currentPlatform {
    switch (environment) {
      case 'dev':
        return dev.DefaultFirebaseOptions.currentPlatform;
      case 'stg':
        return stg.DefaultFirebaseOptions.currentPlatform;
      case 'prod':
        return prod.DefaultFirebaseOptions.currentPlatform;
      default:
        return dev.DefaultFirebaseOptions.currentPlatform;
    }
  }
  
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: currentPlatform,
    );
  }
}
```

### Application Initialization
Firebase initialization in main entry points:

```dart
// lib/main_dev.dart, lib/main_stg.dart, lib/main_prod.dart
import 'package:flutter/material.dart';
import 'config/firebase/firebase_config.dart';
import 'config/di/injection.dart';
import 'src/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase for current environment
  await FirebaseConfig.initialize();
  
  // Configure dependencies
  configureDependencies();
  
  runApp(const App());
}
```

## Service Configuration

### Firebase Analytics
Track user events and behavior:

```dart
// lib/config/services/analytics_service.dart
@singleton
class AnalyticsService {
  AnalyticsService() : _analytics = FirebaseAnalytics.instance;
  
  final FirebaseAnalytics _analytics;
  
  Future<void> logEvent(String name, Map<String, dynamic> parameters) async {
    await _analytics.logEvent(
      name: name,
      parameters: parameters,
    );
  }
  
  Future<void> setUserId(String userId) async {
    await _analytics.setUserId(id: userId);
  }
  
  Future<void> setUserProperty(String name, String value) async {
    await _analytics.setUserProperty(name: name, value: value);
  }
}
```

### Firebase Crashlytics
Crash reporting and performance monitoring:

```dart
// lib/config/services/crashlytics_service.dart
@singleton
class CrashlyticsService {
  CrashlyticsService() : _crashlytics = FirebaseCrashlytics.instance;
  
  final FirebaseCrashlytics _crashlytics;
  
  Future<void> initialize() async {
    // Enable Crashlytics collection
    await _crashlytics.setCrashlyticsCollectionEnabled(true);
    
    // Set up Flutter error handling
    FlutterError.onError = _crashlytics.recordFlutterFatalError;
    
    // Set up Dart error handling
    PlatformDispatcher.instance.onError = (error, stack) {
      _crashlytics.recordError(error, stack, fatal: true);
      return true;
    };
  }
  
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    bool fatal = false,
  }) async {
    await _crashlytics.recordError(
      exception,
      stack,
      fatal: fatal,
    );
  }
  
  Future<void> setUserId(String userId) async {
    await _crashlytics.setUserId(userId);
  }
  
  Future<void> setCustomKey(String key, Object value) async {
    await _crashlytics.setCustomKey(key, value);
  }
}
```

### Firebase Authentication
User authentication management:

```dart
// lib/config/services/auth_service.dart
@singleton
class AuthService {
  AuthService() : _auth = FirebaseAuth.instance;
  
  final FirebaseAuth _auth;
  
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  User? get currentUser => _auth.currentUser;
  
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }
  
  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }
  
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
```

### Firebase Remote Config
Feature flags and remote configuration:

```dart
// lib/config/services/remote_config_service.dart
@singleton
class RemoteConfigService {
  RemoteConfigService() : _remoteConfig = FirebaseRemoteConfig.instance;
  
  final FirebaseRemoteConfig _remoteConfig;
  
  Future<void> initialize() async {
    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ),
    );
    
    // Set default values
    await _remoteConfig.setDefaults({
      'feature_new_ui': false,
      'api_timeout_seconds': 30,
      'max_retry_attempts': 3,
    });
    
    // Fetch and activate
    await _remoteConfig.fetchAndActivate();
  }
  
  bool getBool(String key) => _remoteConfig.getBool(key);
  int getInt(String key) => _remoteConfig.getInt(key);
  String getString(String key) => _remoteConfig.getString(key);
  double getDouble(String key) => _remoteConfig.getDouble(key);
}
```

## Debug Symbol Upload

### Automatic Upload Process
Build scripts automatically upload debug symbols to Firebase Crashlytics:

```bash
# In build scripts (build_apk.sh, build_appbundle.sh, build_ios.sh)
echo "🔥 Uploading debug symbols to Firebase Crashlytics..."
FIREBASE_SETUP_SCRIPT="tools/macos/config/firebase_setup.sh"

if [[ -f "$FIREBASE_SETUP_SCRIPT" ]]; then
    "$FIREBASE_SETUP_SCRIPT" "$FLAVOR" "android"
    
    if [[ $? -eq 0 ]]; then
        echo "✅ Debug symbols uploaded successfully!"
    else
        echo "⚠️  Debug symbols upload failed, but build was successful."
    fi
fi
```

### Firebase Setup Script
The Firebase setup script handles symbol upload:

```bash
#!/bin/bash
# tools/macos/config/firebase_setup.sh

FLAVOR=$1      # dev, stg, or prod
PLATFORM=$2    # android or ios

# Map flavor to Firebase project
case $FLAVOR in
    dev)
        FIREBASE_PROJECT="meup-dev"
        ;;
    stg)
        FIREBASE_PROJECT="meup-stg"
        ;;
    prod)
        FIREBASE_PROJECT="meup-prod"
        ;;
esac

# Upload debug symbols
firebase use $FIREBASE_PROJECT
firebase crashlytics:symbols:upload .obfuscation/

echo "Debug symbols uploaded to $FIREBASE_PROJECT"
```

### Manual Symbol Upload
If automatic upload fails:

```bash
# Set Firebase project
firebase use meup-prod

# Upload symbols manually
firebase crashlytics:symbols:upload .obfuscation/

# Verify upload
firebase crashlytics:symbols:list
```

## Environment Variables

### Firebase Configuration Variables
Environment files contain Firebase-specific configuration:

```env
# .env/.env.dev
FIREBASE_PROJECT_ID=meup-dev
FIREBASE_API_KEY=AIzaSyExample123Dev
FIREBASE_APP_ID=1:123456789:android:abcd1234dev
ENABLE_CRASHLYTICS=true
ENABLE_ANALYTICS=true
ENABLE_REMOTE_CONFIG=true

# .env/.env.stg  
FIREBASE_PROJECT_ID=meup-stg
FIREBASE_API_KEY=AIzaSyExample123Stg
FIREBASE_APP_ID=1:987654321:android:efgh5678stg
ENABLE_CRASHLYTICS=true
ENABLE_ANALYTICS=true
ENABLE_REMOTE_CONFIG=true

# .env/.env.prod
FIREBASE_PROJECT_ID=meup-prod
FIREBASE_API_KEY=AIzaSyExample123Prod
FIREBASE_APP_ID=1:111222333:android:ijkl9012prod
ENABLE_CRASHLYTICS=true
ENABLE_ANALYTICS=false  # May disable in prod for privacy
ENABLE_REMOTE_CONFIG=true
```

### Service Activation
Services are activated based on environment variables:

```dart
class FirebaseServiceConfig {
  static const bool enableCrashlytics = 
      bool.fromEnvironment('ENABLE_CRASHLYTICS', defaultValue: true);
  static const bool enableAnalytics = 
      bool.fromEnvironment('ENABLE_ANALYTICS', defaultValue: true);
  static const bool enableRemoteConfig = 
      bool.fromEnvironment('ENABLE_REMOTE_CONFIG', defaultValue: true);
}
```

## Integration Testing

### Firebase Test Configuration
Test Firebase integration across environments:

```dart
// test/integration/firebase_integration_test.dart
void main() {
  group('Firebase Integration', () {
    testWidgets('should initialize Firebase correctly', (tester) async {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      expect(Firebase.apps.isNotEmpty, true);
    });
    
    testWidgets('should record analytics events', (tester) async {
      final analytics = getIt<AnalyticsService>();
      
      await analytics.logEvent('test_event', {'test_key': 'test_value'});
      
      // Verify event was recorded (integration test)
    });
  });
}
```

### Environment Validation
Validate Firebase configuration for each environment:

```bash
# Validate development environment
flutter test integration_test/firebase_dev_test.dart --flavor dev

# Validate staging environment
flutter test integration_test/firebase_stg_test.dart --flavor stg

# Validate production environment
flutter test integration_test/firebase_prod_test.dart --flavor prod
```

## Monitoring and Analytics

### Custom Event Tracking
Track app-specific events:

```dart
class AppAnalytics {
  static final _analytics = getIt<AnalyticsService>();
  
  static Future<void> trackUserLogin(String method) async {
    await _analytics.logEvent('user_login', {
      'login_method': method,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  static Future<void> trackFeatureUsage(String feature) async {
    await _analytics.logEvent('feature_used', {
      'feature_name': feature,
      'environment': EnvironmentConfig.environment,
    });
  }
  
  static Future<void> trackError(String error, String context) async {
    await _analytics.logEvent('app_error', {
      'error_message': error,
      'error_context': context,
      'app_version': AppInfo.version,
    });
  }
}
```

### Performance Monitoring
Monitor app performance:

```dart
class PerformanceMonitoring {
  static final _performance = FirebasePerformance.instance;
  
  static Trace startTrace(String name) {
    return _performance.newTrace(name);
  }
  
  static Future<T> measureAsync<T>(
    String traceName,
    Future<T> Function() operation,
  ) async {
    final trace = startTrace(traceName);
    await trace.start();
    
    try {
      final result = await operation();
      return result;
    } finally {
      await trace.stop();
    }
  }
}
```

## Security and Privacy

### Data Collection Policies
Configure data collection based on environment:

```dart
class FirebasePrivacySettings {
  static Future<void> configureDataCollection() async {
    // Disable analytics in development if needed
    if (EnvironmentConfig.isDevelopment && !enableAnalytics) {
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(false);
    }
    
    // Configure crash reporting
    if (enableCrashlytics) {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    }
  }
}
```

### User Consent Management
Handle user consent for data collection:

```dart
class ConsentManager {
  static Future<void> handleUserConsent(bool granted) async {
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(granted);
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(granted);
  }
}
```

## Troubleshooting

### Common Issues

#### Configuration File Issues
```bash
# Verify Firebase configuration
firebase projects:list
firebase use meup-dev
firebase apps:list
```

#### Symbol Upload Failures
```bash
# Check Firebase CLI authentication
firebase login
firebase projects:list

# Manual symbol upload
firebase crashlytics:symbols:upload .obfuscation/
```

#### Service Initialization Errors
```dart
// Add proper error handling
try {
  await FirebaseConfig.initialize();
} catch (e) {
  print('Firebase initialization failed: $e');
  // Handle gracefully or show error to user
}
```

### Debug Commands
```bash
# Verify Firebase project
firebase use --list

# Check symbol files
ls -la .obfuscation/

# Test Firebase connection
firebase projects:list

# View crashlytics symbols
firebase crashlytics:symbols:list
```

## Best Practices

### Environment Management
- Use separate Firebase projects for each environment
- Keep configuration files secure and up-to-date
- Test Firebase services in staging before production

### Performance Optimization
- Enable only necessary Firebase services
- Configure appropriate data retention policies
- Monitor quota usage and costs

### Security
- Implement proper user consent mechanisms
- Protect Firebase configuration files
- Regular security audits and updates
- Use Firebase Security Rules where applicable