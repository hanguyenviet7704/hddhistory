part of '../services.dart';

/// A composite implementation of AppTrackingService that delegates
/// to multiple tracking services.
///
/// This allows using multiple tracking providers simultaneously
/// (e.g., both Firebase Analytics and Sentry).
class CompositeTrackingService extends BaseTrackingService {
  final List<BaseTrackingService> _services;

  CompositeTrackingService(this._services)
    : super(
        trackingServiceName: 'CompositeTrackingService',
        isEnabled: true,
      );

  @override
  Future<void> initialize() async {
    if (!isEnabled) return;

    // Initialize all services
    await Future.wait(_services.map((service) => service.initialize()));

    super.initialize();
  }

  @override
  Future<void> setUserId(String? userId) async {
    if (!isEnabled) return;

    // Set user ID on all services
    for (final service in _services) {
      await service.setUserId(userId);
    }

    super.setUserId(userId);
  }

  @override
  Future<void> setUserProperties(Map<String, dynamic> properties) async {
    if (!isEnabled) return;

    // Set properties on all services
    for (final service in _services) {
      await service.setUserProperties(properties);
    }

    super.setUserProperties(properties);
  }

  @override
  Future<void> trackEvent(
    String eventName, {
    Map<String, dynamic>? parameters,
  }) async {
    if (!isEnabled) return;

    // Track event on all services
    for (final service in _services) {
      await service.trackEvent(eventName, parameters: parameters);
    }

    // No super call on purpose: BaseTrackingService.trackEvent mirrors into the
    // DEV Event Inspector, and the children above already did that. Calling it
    // here too would show every event twice.
  }

  @override
  Future<void> trackScreenView(
    String screenName, {
    String? screenClass,
  }) async {
    if (!isEnabled) return;

    // Track screen view on all services
    for (final service in _services) {
      await service.trackScreenView(screenName, screenClass: screenClass);
    }

    // Same reason as trackEvent: the children already fed the Event Inspector.
  }

  @override
  Future<void> trackError(
    dynamic exception, {
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    String? errorType,
  }) async {
    if (!isEnabled) return;

    // Track error on all services
    for (final service in _services) {
      await service.trackError(
        exception,
        stackTrace: stackTrace,
        context: context,
        errorType: errorType,
      );
    }

    super.trackError(exception, stackTrace: stackTrace, context: context, errorType: errorType);
  }

  @override
  Future<void> addBreadcrumb(
    String message, {
    Map<String, dynamic>? data,
    String? category,
  }) async {
    if (!isEnabled) return;

    // Add breadcrumb to all services
    for (final service in _services) {
      await service.addBreadcrumb(message, data: data, category: category);
    }

    super.addBreadcrumb(message, data: data, category: category);
  }

  @override
  Future<void> resetUser() async {
    if (!isEnabled) return;

    // Reset user on all services
    for (final service in _services) {
      await service.resetUser();
    }

    super.resetUser();
  }

  @override
  Future<void> setTrackingEnabled(bool isEnabled) async {
    // Set tracking enabled status on all services
    for (final service in _services) {
      await service.setTrackingEnabled(isEnabled);
    }

    super.setTrackingEnabled(isEnabled);
  }

  /// Add a new tracking service to the composite
  void addTrackingService(BaseTrackingService service) {
    _services.add(service);

    // Initialize the new service if tracking is enabled
    if (isEnabled) {
      service.initialize();
    }
  }

  /// Remove a tracking service from the composite
  void removeTrackingService(BaseTrackingService service) {
    _services.remove(service);
  }
}
