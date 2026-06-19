part of '../services.dart';

@Named(DIKey.facebookAppEventsService)
@LazySingleton(as: IAppEventService)
class FacebookAppEventsService implements IAppEventService {
  final FacebookAppEvents _facebookAppEvents = FacebookAppEvents();
  final IDeviceInfoService _deviceInfoService;

  FacebookAppEventsService(this._deviceInfoService);

  @override
  Future<void> initialize() async {
    try {
      await _facebookAppEvents.setAutoLogAppEventsEnabled(true);
      LogDev.data('Facebook App Events initialized');
    } catch (e) {
      LogDev.error('Error initializing Facebook App Events: $e');
    }
  }

  /// Request tracking authorization on iOS (required for iOS 14+)
  /// This should be called early in the app lifecycle
  @override
  Future<bool> requestTrackingAuthorization() async {
    // if (!Platform.isIOS) return true;

    try {
      // Check current status
      final trackingStatus = await AppTrackingTransparency.trackingAuthorizationStatus;

      // Only show the dialog if not determined yet
      if (trackingStatus != TrackingStatus.authorized) {
        // Wait a moment for app to fully load (recommended by Apple)
        await Future.delayed(const Duration(milliseconds: 200));

        // Request tracking authorization
        final status = await AppTrackingTransparency.requestTrackingAuthorization();
        final isGranted = status == TrackingStatus.authorized;

        // Get iOS version for additional Facebook SDK configuration
        final iosInfo = await _deviceInfoService.deviceInfo;
        final version = double.tryParse(iosInfo?.data['systemVersion']?.split('.').take(2).join('.') ?? '0.0') ?? 0.0;

        // For iOS < 17, we need to explicitly set the tracking status
        if (version < 17.0) {
          await _facebookAppEvents.setAdvertiserIdCollectionEnabled(isGranted);
        }

        LogDev.data('ATT permission request completed. Status: $status');
        return isGranted;
      } else {
        // Return true if already authorized
        final isGranted = trackingStatus == TrackingStatus.authorized;
        LogDev.data('ATT status already determined: $trackingStatus');
        return isGranted;
      }
    } catch (e) {
      LogDev.error('Error requesting tracking authorization: $e');
      return false;
    }
  }

  // Core events
  @override
  Future<void> logAppInstall() async {
    try {
      await _facebookAppEvents.logEvent(
        name: 'fb_mobile_install',
      );
    } catch (e) {
      LogDev.error('Error logging app install: $e');
    }
  }

  Future<void> logActivateApp() async {
    try {
      // Direct SDK call without wrapper method
      await _facebookAppEvents.logEvent(
        name: 'fb_mobile_activate_app',
      );
    } catch (e) {
      LogDev.error('Error logging activate app: $e');
    }
  }

  // Commerce events
  Future<void> logAddToCart({
    required String id,
    required String type,
    required String name,
    required double price,
    int quantity = 1,
    String? currency,
  }) async {
    try {
      await _facebookAppEvents.logAddToCart(
        id: id,
        type: type,
        currency: currency ?? 'USD',
        price: price,
      );
    } catch (e) {
      LogDev.error('Error logging add to cart: $e');
    }
  }

  Future<void> logPurchase({
    required double amount,
    String? currency,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      await _facebookAppEvents.logPurchase(
        amount: amount,
        currency: currency ?? 'USD',
        parameters: parameters,
      );
    } catch (e) {
      LogDev.error('Error logging purchase: $e');
    }
  }

  // Custom events
  @override
  Future<void> logEvent(
    String name, {
    Map<String, dynamic>? parameters,
  }) async {
    try {
      await _facebookAppEvents.logEvent(
        name: name,
        parameters: parameters,
      );
    } catch (e) {
      LogDev.error('Error logging custom event: $e');
    }
  }

  // User data
  Future<void> setUserData({
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    String? dateOfBirth,
    String? gender,
    String? city,
    String? state,
    String? zip,
    String? country,
  }) async {
    try {
      await _facebookAppEvents.setUserData(
        email: email,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        dateOfBirth: dateOfBirth,
        gender: gender,
        city: city,
        state: state,
        zip: zip,
        country: country,
      );
    } catch (e) {
      LogDev.error('Error setting user data: $e');
    }
  }
}
