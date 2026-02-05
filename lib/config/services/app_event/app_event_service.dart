part of '../services.dart';


class AppEventService {
  late final IAppEventService _facebookAppEventsService;
  late final IAppEventService _tikTokService;

  AppEventService._() {
    _facebookAppEventsService = AppDI.injector.get<IAppEventService>(instanceName: DIKey.facebookAppEventsService);
    _tikTokService = AppDI.injector.get<IAppEventService>(instanceName: DIKey.tikTokAppEventService);
  }
  static final AppEventService _instance = AppEventService._();
  static AppEventService get instance => _instance;

  /// Initialize the tracking services
  /// Call this method as early as possible in your app lifecycle
  Future<void> initialize() async {
    try {
      // Initialize both services - they'll handle tracking authorization internally on iOS
      LogDev.data('Initializing app event services');
      await _facebookAppEventsService.initialize();
      await _tikTokService.initialize();
      LogDev.data('App event services initialized');
    } catch (e) {
      LogDev.error('Error initializing app event services: $e');
    }
  }

  /// Request tracking authorization explicitly
  /// This can be called separately if needed
  Future<bool> requestTrackingPermission() async {
    if (!Platform.isIOS) return true;

    final facebookResult = await _facebookAppEventsService.requestTrackingAuthorization();
    final tikTokResult = await _tikTokService.requestTrackingAuthorization();

    // Return true if either service got permission
    return facebookResult || tikTokResult;
  }

  Future<void> logAppInstall() async {
    await _facebookAppEventsService.logAppInstall();
    await _tikTokService.logAppInstall();
  }

  Future<void> trackEvent(String eventName, {Map<String, dynamic>? parameters}) async {
    await _facebookAppEventsService.logEvent(eventName, parameters: parameters);
    await _tikTokService.logEvent(eventName, parameters: parameters);
  }

  Future<void> trackRegistration({Map<String, dynamic>? parameters}) async {
    await _facebookAppEventsService.logEvent('Registration', parameters: parameters);
    await _tikTokService.logEvent('Registration', parameters: parameters);
  }

  Future<void> trackPurchase(double value, String currency, {String? contentType, String? contentId}) async {
    await _facebookAppEventsService.logEvent(
      'Purchase',
      parameters: {
        'value': value,
        'currency': currency,
        'content_type': contentType,
        'content_id': contentId,
      },
    );
    await _tikTokService.logEvent(
      'Purchase',
      parameters: {
        'value': value,
        'currency': currency,
        'content_type': contentType,
        'content_id': contentId,
      },
    );
  }
}
