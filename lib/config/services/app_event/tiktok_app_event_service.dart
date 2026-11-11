part of '../services.dart';

@Named(DIKey.tikTokAppEventService)
@LazySingleton(as: IAppEventService)
class TikTokService implements IAppEventService {
  late final MethodChannel _channel;

  TikTokService() {
    _channel = const MethodChannel('com.hddhistory.app/tiktok');
  }

  /// Initialize TikTok SDK
  @override
  Future<bool> initialize() async {
    try {
      final bool result = await _channel.invokeMethod('initialize');
      return result;
    } on PlatformException catch (e) {
      LogDev.error('Failed to initialize TikTok SDK: ${e.message}');
      return false;
    } catch (e) {
      LogDev.error('Error in TikTok SDK initialization: $e');
      return false;
    }
  }

  @override
  Future<bool> requestTrackingAuthorization() async {
    return true;
  }

  @override
  Future<void> logAppInstall() async {
    await logEvent('app_install');
  }

  /// Track custom event
  @override
  Future<void> logEvent(String eventName, {Map<String, dynamic>? parameters}) async {
    try {
      await _channel.invokeMethod('trackEvent', {
        'eventName': eventName,
        'properties': parameters ?? {},
      });
    } on PlatformException catch (e) {
      LogDev.error('Failed to track TikTok event: ${e.message}');
    }
  }

  /// Track registration event
  Future<void> trackRegistration({Map<String, dynamic>? parameters}) async {
    return logEvent('Registration', parameters: parameters);
  }

  /// Track purchase event
  Future<void> trackPurchase(double value, String currency, {String? contentType, String? contentId}) async {
    return logEvent(
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
