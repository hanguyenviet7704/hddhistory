# Firebase Remote Config Implementation Guide for Force Update

## Setup Instructions

### 1. Add Firebase Remote Config to your project

Add these dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  firebase_remote_config: ^5.1.3  # Check for latest version
  package_info_plus: ^8.0.3       # Already in your project
  url_launcher: ^6.3.1            # Already in your project
```

Run `flutter pub get` after adding the dependencies.

### 2. Firebase Console Configuration

1. Go to your Firebase Console (https://console.firebase.google.com)
2. Select your project
3. Navigate to "Remote Config" in the left sidebar
4. Click "Add parameter" and add these parameters:

   - **Parameter key**: `minimum_app_version`
     - **Default value**: `1.0.0` (or your current minimum version)
     - **Description**: Minimum required app version
   
   - **Parameter key**: `force_update_enabled`
     - **Default value**: `false`
     - **Data type**: Boolean
     - **Description**: Enable/disable force update feature

5. Click "Publish changes" to make the parameters available

### 3. Update the Firebase Remote Config Service

Replace the mock service in `lib/config/services/firebase/firebase_remote_config_service.dart` with the actual implementation once you've added the firebase_remote_config package.

### 4. Register the Service in DI

Add this to your DI configuration file (e.g., `lib/config/di/di.dart`):

```dart
import 'package:your_app/config/services/firebase/firebase_remote_config_service.dart';

// In your DI configuration
@module
abstract class FirebaseModule {
  @lazySingleton
  FirebaseRemoteConfigService get remoteConfigService => FirebaseRemoteConfigService();
}
```

### 5. Update the Splash Page

In `splash_page.dart`, replace the mock implementation with the actual Firebase Remote Config service:

```dart
Future<void> _checkForUpdate() async {
  try {
    final remoteConfigService = AppDI.injector.get<FirebaseRemoteConfigService>();
    await remoteConfigService.initialize();
    final shouldUpdate = await remoteConfigService.shouldForceUpdate();
    
    if (mounted) {
      setState(() {
        _needsUpdate = shouldUpdate;
        _isCheckingUpdate = false;
      });
      
      if (!shouldUpdate) {
        // Only proceed with normal flow if no update is needed
        WidgetsBinding.instance.addPostFrameCallback(_initScreen);
      }
    }
  } catch (e) {
    print('Error checking for update: $e');
    // On error, proceed with normal flow
    if (mounted) {
      setState(() {
        _isCheckingUpdate = false;
      });
      WidgetsBinding.instance.addPostFrameCallback(_initScreen);
    }
  }
}
```

### 6. Update App Store URLs

In the `_handleUpdatePressed` method, replace the placeholder URLs with your actual app store URLs:

```dart
final String appStoreUrl = Platform.isIOS
    ? 'https://apps.apple.com/app/id123456789' // Your actual App Store ID
    : 'https://play.google.com/store/apps/details?id=com.yourcompany.yourapp'; // Your actual package name
```

## Testing

### Local Testing
1. Set `force_update_enabled` to `true` in Firebase Console
2. Set `minimum_app_version` to a version higher than your current app version (e.g., if your app is 1.0.0, set it to 2.0.0)
3. Publish the changes in Firebase Console
4. Run your app - you should see the force update dialog

### Production Deployment
1. Only enable force update when you have a critical update
2. Make sure the new version is available in both App Store and Google Play Store before enabling
3. Consider gradual rollout using Firebase Remote Config conditions

## Best Practices

1. **Version Format**: Always use semantic versioning (MAJOR.MINOR.PATCH)
2. **Grace Period**: Consider showing the update dialog after a grace period for better UX
3. **Error Handling**: Always have fallback behavior if Remote Config fails
4. **Analytics**: Track force update events for monitoring
5. **Testing**: Test thoroughly on both iOS and Android before enabling in production

## Monitoring

Add analytics tracking to monitor the force update feature:

```dart
// When force update is shown
AppDI.injector.get<AppTrackingService>(instanceName: DIKey.firebaseAnalyticsService)
  .trackEvent('force_update_shown', parameters: {
    'current_version': currentVersion,
    'minimum_version': minimumVersion,
  });

// When user taps update
AppDI.injector.get<AppTrackingService>(instanceName: DIKey.firebaseAnalyticsService)
  .trackEvent('force_update_tapped');
``` 