part of '../services.dart';

/// Interface for application tracking services
///
/// Provides a consistent API for tracking events, errors,
/// screen views and user attributes across different
/// analytics and error reporting providers.
abstract class BaseTrackingService {
  final String trackingServiceName;
  final bool isEnabled;
  BaseTrackingService({this.trackingServiceName = 'BaseTrackingService', this.isEnabled = true});

  /// Initialize the tracking service
  Future<void> initialize() async {
    LogDev.info('$trackingServiceName initialize');
  }

  /// Set a user identifier for associating events with a specific user
  Future<void> setUserId(String? userId) async {
    LogDev.one('$trackingServiceName setUserId: $userId');
  }

  /// Set user properties/attributes that apply to all future events
  Future<void> setUserProperties(Map<String, dynamic> properties) async {
    LogDev.one('$trackingServiceName setUserProperties: $properties');
  }

  /// Track a specific event with optional parameters
  Future<void> trackEvent(
    String eventName, {
    Map<String, dynamic>? parameters,
  }) async {
    // LogDev.one('$trackingServiceName [Tracking] trackEvent: $eventName parameters: $parameters');
    // LogDev.info('$trackingServiceName [Tracking] $eventName params: $parameters');

    // Mirror every fired event into the in-app Event Inspector (DEV only) so a
    // tester can tap through a screen and see exactly what went out. This is
    // the one choke point all events reach: the `AppTrackingService.track*`
    // helpers call `BaseTrackingService.trackEvent` on the concrete service,
    // and FirebaseAnalyticsService (the DI-bound one) calls `super` here.
    _recordForInspector(eventName, parameters, InspectedEventKind.event);
  }

  /// Log when a screen is viewed
  Future<void> trackScreenView(
    String screenName, {
    String? screenClass,
  }) async {
    LogDev.one('$trackingServiceName trackScreenView: $screenName \n screenClass: $screenClass');
    _recordForInspector(
      screenName,
      screenClass == null ? null : {'screen_class': screenClass},
      InspectedEventKind.screen,
    );
  }

  /// DEV-flavor-only tap into [EventInspectorStore]. No-op everywhere else, so
  /// stg/prod pay nothing beyond the flavor check.
  void _recordForInspector(
    String name,
    Map<String, dynamic>? parameters,
    InspectedEventKind kind,
  ) {
    if (F.appFlavor != Flavor.dev) return;
    EventInspectorStore.instance.add(
      InspectedEvent(
        name: name,
        time: DateTime.now(),
        kind: kind,
        parameters: parameters,
      ),
    );
  }

  /// Track an error or exception
  Future<void> trackError(
    dynamic exception, {
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    String? errorType,
  }) async {
    LogDev.one('$trackingServiceName exception: $exception \n errorType: $errorType \n context: $context \n stackTrace: $stackTrace');
  }

  /// Add a breadcrumb to help with error context
  Future<void> addBreadcrumb(
    String message, {
    Map<String, dynamic>? data,
    String? category,
  }) async {
    LogDev.one('$trackingServiceName addBreadcrumb: $message \n data: $data \n category: $category');
  }

  /// Reset all user data (for logout/privacy)
  Future<void> resetUser() async {
    LogDev.one('$trackingServiceName resetUser');
  }

  /// Enable or disable tracking
  Future<void> setTrackingEnabled(bool isEnabled) async {
    LogDev.one('$trackingServiceName setTrackingEnabled: $isEnabled');
  }
}
