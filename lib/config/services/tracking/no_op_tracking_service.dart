part of '../services.dart';

/// A no-operation implementation of AppTrackingService that does nothing.
///
/// Useful for when tracking is disabled or in test environments.
class NoOpTrackingService extends BaseTrackingService {
  NoOpTrackingService()
    : super(
        trackingServiceName: 'NoOpTrackingService',
        isEnabled: false,
      );

  @override
  Future<void> initialize() async {
    // Do nothing
    super.initialize();
  }

  @override
  Future<void> setUserId(String? userId) async {
    // Do nothing
    super.setUserId(userId);
  }

  @override
  Future<void> setUserProperties(Map<String, dynamic> properties) async {
    // Do nothing
    super.setUserProperties(properties);
  }

  @override
  Future<void> trackEvent(
    String eventName, {
    Map<String, dynamic>? parameters,
  }) async {
    // Do nothing
    super.trackEvent(eventName, parameters: parameters);
  }

  @override
  Future<void> trackScreenView(
    String screenName, {
    String? screenClass,
  }) async {
    // Do nothing
    super.trackScreenView(screenName, screenClass: screenClass);
  }

  @override
  Future<void> trackError(
    dynamic exception, {
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    String? errorType,
  }) async {
    // Do nothing
    super.trackError(exception, stackTrace: stackTrace, context: context, errorType: errorType);
  }

  @override
  Future<void> addBreadcrumb(
    String message, {
    Map<String, dynamic>? data,
    String? category,
  }) async {
    // Do nothing
    super.addBreadcrumb(message, data: data, category: category);
  }

  @override
  Future<void> resetUser() async {
    // Do nothing
    super.resetUser();
  }

  @override
  Future<void> setTrackingEnabled(bool isEnabled) async {
    // Do nothing
    super.setTrackingEnabled(isEnabled);
  }
}
