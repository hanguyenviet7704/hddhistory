part of '../services.dart';

class FirebaseAnalyticsService extends BaseTrackingService {
  final FirebaseAnalytics _analytics;
  final FirebaseCrashlytics _crashlytics;

  FirebaseAnalyticsService({
    FirebaseAnalytics? analytics,
    FirebaseCrashlytics? crashlytics,
  }) : _analytics = analytics ?? FirebaseAnalytics.instance,
       _crashlytics = crashlytics ?? FirebaseCrashlytics.instance,
       super(trackingServiceName: 'FirebaseAnalyticsService', isEnabled: true);

  @override
  Future<void> initialize() async {
    // Enable collection if allowed by user
    await _crashlytics.setCrashlyticsCollectionEnabled(isEnabled);
    await _analytics.setAnalyticsCollectionEnabled(isEnabled);
    _setDefaultEventParameters();

    super.initialize();
    // Set up automatic screen tracking if needed
    // await _analytics.setAutomaticScreenReportingEnabled(true);
  }

  void _setDefaultEventParameters() async {
    PackageInfo packageInfo = AppDI.injector.get<PackageInfoService>().packageInfo;
    IDeviceInfoService deviceInfo = AppDI.injector.get<IDeviceInfoService>();
    final userState = AppConfig.instance.context?.read<UserCubit>().state ?? UserState.initial();
    // (String userId, String paymentStatus, int numberLessonCompleted, String country, DateTime? lastLessonCompletedAt) userInfo = (
    //   userState.user.id,
    //   userState.paymentStatus,
    //   userState.profile.numberLessonCompleted,
    //   userState.profile.geolocation.currentCity,
    //   userState.profile.timestamps.lastLessonCompletedAt
    // );

    String userId = userState.user.id;

    String deviceId = await deviceInfo.deviceToken;
    String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    await _analytics.setDefaultEventParameters({
      'device_id': deviceId,
      'timestamp': timestamp,
      'app_version': packageInfo.version,
      'app_env': EnvConstant.appEnv,
      if (userId.isNotEmpty) 'user_id_param': userId,
      // if (userInfo.$1.isNotEmpty) 'user_id_param': userInfo.$1,
      // if (userInfo.$2.isNotEmpty) 'payment_status': userInfo.$2,
      // if (userInfo.$3 > -1) 'number_lesson_completed': userInfo.$3,
      // if (userInfo.$4.isNotEmpty) 'city': userInfo.$4,
      // if (userInfo.$5 != null) 'last_lesson_completed_at': userInfo.$5?.toUTCDateTimeString,
    });
  }

  @override
  Future<void> setUserId(String? userId) async {
    if (!isEnabled) return;

    if (userId != null) {
      await _analytics.setUserId(id: userId);
      _setDefaultEventParameters();
      await _crashlytics.setUserIdentifier(userId);
    } else {
      await _analytics.setUserId(id: null);
      await _crashlytics.setUserIdentifier('');
    }

    super.setUserId(userId);
  }

  @override
  Future<void> setUserProperties(Map<String, dynamic> properties) async {
    if (!isEnabled) return;

    // Set analytics user properties
    for (final entry in properties.entries) {
      if (entry.value != null) {
        await _analytics.setUserProperty(
          name: entry.key,
          value: entry.value.toString(),
        );
      }
    }

    // Set crashlytics custom keys
    for (final entry in properties.entries) {
      if (entry.value != null) {
        await _crashlytics.setCustomKey(entry.key, entry.value.toString());
      }
    }

    super.setUserProperties(properties);
  }

  @override
  Future<void> trackEvent(
    String eventName, {
    Map<String, dynamic>? parameters,
  }) async {
    if (!isEnabled) return;

    // Firebase has naming restrictions for events and parameters
    final sanitizedParams = parameters != null ? _sanitizeParameters(parameters) : null;

    await _analytics.logEvent(
      name: _sanitizeEventName(eventName),
      parameters: sanitizedParams,
    );

    super.trackEvent(eventName, parameters: parameters);
  }

  @override
  Future<void> trackScreenView(
    String screenName, {
    String? screenClass,
  }) async {
    if (!isEnabled) return;

    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );

    super.trackScreenView(screenName, screenClass: screenClass);
  }

  @override
  Future<void> trackError(
    dynamic exception, {
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    String? errorType,
  }) async {
    if (!isEnabled) return;

    // Set extra context if available
    if (context != null) {
      for (final entry in context.entries) {
        await _crashlytics.setCustomKey(entry.key, entry.value.toString());
      }
    }

    if (errorType != null) {
      await _crashlytics.setCustomKey('error_type', errorType);
    }

    // Log to Firebase Analytics
    await _analytics.logEvent(
      name: 'app_error',
      parameters: {
        'error_message': exception.toString(),
        if (errorType != null) 'error_type': errorType,
        if (context != null) 'context': context.toString(),
      },
    );

    // Log to Crashlytics (non-fatal)
    await _crashlytics.recordError(
      exception,
      stackTrace,
      reason: errorType,
      fatal: false,
    );

    super.trackError(exception, stackTrace: stackTrace, context: context, errorType: errorType);
  }

  @override
  Future<void> addBreadcrumb(
    String message, {
    Map<String, dynamic>? data,
    String? category,
  }) async {
    if (!isEnabled) return;

    await _crashlytics.log(message);

    if (data != null) {
      final dataString = data.entries.map((e) => '${e.key}: ${e.value}').join(', ');

      await _crashlytics.log('$message - $dataString');
    }

    super.addBreadcrumb(message, data: data, category: category);
  }

  @override
  Future<void> resetUser() async {
    if (!isEnabled) return;

    await _analytics.setUserId(id: null);
    await _crashlytics.setUserIdentifier('');

    // Reset custom keys/properties
    // Note: Firebase doesn't have a direct method to clear all properties
    // You may need to set important ones to null or a default value

    super.resetUser();
  }

  @override
  Future<void> setTrackingEnabled(bool isEnabled) async {
    await _crashlytics.setCrashlyticsCollectionEnabled(isEnabled);
    await _analytics.setAnalyticsCollectionEnabled(isEnabled);

    super.setTrackingEnabled(isEnabled);
  }

  // Helper methods for Firebase naming restrictions
  String _sanitizeEventName(String name) {
    // Firebase event names must be <= 40 chars, alphanumeric + underscores
    final sanitized = name.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_').replaceAll(RegExp(r'__+'), '_');

    return sanitized.length > 40 ? sanitized.substring(0, 40) : sanitized;
  }

  Map<String, Object> _sanitizeParameters(Map<String, dynamic> parameters) {
    final result = <String, Object>{};

    for (final entry in parameters.entries) {
      // Firebase parameter names must be <= 40 chars, alphanumeric + underscores
      final key = entry.key.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_').replaceAll(RegExp(r'__+'), '_');

      final sanitizedKey = key.length > 40 ? key.substring(0, 40) : key;

      // Convert values to types supported by Firebase
      final convertedValue = _convertToSupportedType(entry.value);
      if (convertedValue != null) {
        result[sanitizedKey] = convertedValue;
      }
    }

    return result;
  }

  Object? _convertToSupportedType(dynamic value) {
    if (value == null) return null;
    if (value is String || value is num) return value;
    if (value is bool) return value.toString(); // Convert boolean to string
    return value.toString();
  }
}
