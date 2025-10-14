part of '../services.dart';

class SentryTrackingService extends BaseTrackingService {
  SentryTrackingService()
    : super(
        trackingServiceName: 'SentryTrackingService',
        isEnabled: true,
      );

  @override
  Future<void> initialize() async {
    if (!isEnabled) return;

    // Sentry is initialized at app startup with SentryFlutter.init()
    // This method can be used for additional configuration
    await SentryFlutter.init(
      (options) {
        options.dsn = 'https://examplePublicKey@o0.ingest.sentry.io/0';
        // Adds request headers and IP for users, for more info visit:
        // https://docs.sentry.io/platforms/dart/guides/flutter/data-management/data-collected/
        options.sendDefaultPii = true;
      },
    );

    super.initialize();
  }

  @override
  Future<void> setUserId(String? userId) async {
    if (!isEnabled) return;

    // Set user context
    final user = userId != null ? SentryUser(id: userId) : null;

    Sentry.configureScope((scope) {
      scope.setUser(user);
    });

    super.setUserId(userId);
  }

  @override
  Future<void> setUserProperties(Map<String, dynamic> properties) async {
    if (!isEnabled) return;

    // Create user object with properties
    final user = SentryUser(
      // Don't override existing user ID
      // id: Sentry.currentHub.scope.user?.id,
      data: properties,
    );

    // Set updated user
    Sentry.configureScope((scope) {
      scope.setUser(user);
    });

    super.setUserProperties(properties);
  }

  @override
  Future<void> trackEvent(
    String eventName, {
    Map<String, dynamic>? parameters,
  }) async {
    if (!isEnabled) return;

    // Create a message event
    final event = SentryEvent(
      message: SentryMessage(eventName),
      // Convert parameters to tags and extras
      tags: parameters?.map((key, value) => MapEntry(key, value?.toString() ?? '')),
      // extra: parameters,
    );

    await Sentry.captureEvent(event);

    super.trackEvent(eventName, parameters: parameters);
  }

  @override
  Future<void> trackScreenView(
    String screenName, {
    String? screenClass,
  }) async {
    if (!isEnabled) return;

    // Create a navigation breadcrumb
    final breadcrumb = Breadcrumb(
      category: 'navigation',
      message: 'Viewed $screenName screen',
      data: {
        'screen_name': screenName,
        if (screenClass != null) 'screen_class': screenClass,
      },
      level: SentryLevel.info,
      type: 'navigation',
    );

    Sentry.addBreadcrumb(breadcrumb);

    // Add as a transaction for performance monitoring
    final transaction = Sentry.startTransaction(
      'screenView',
      'navigation',
      description: 'Viewing $screenName',
    );

    // Set additional data
    transaction.setData('screen_name', screenName);
    if (screenClass != null) {
      transaction.setData('screen_class', screenClass);
    }

    // Finish transaction after a short delay
    // In a real app, you might finish when leaving the screen
    Future.delayed(const Duration(milliseconds: 100), () {
      transaction.finish();
    });

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

    // Create scope with context data
    final scope = Scope(
      SentryOptions(
        checker: RuntimeChecker(),
      ),
    );

    if (context != null) {
      // Add context as tags and extras
      for (final entry in context.entries) {
        scope.setTag(entry.key, entry.value.toString());
        scope.setContexts(entry.key, entry.value);
      }
    }

    if (errorType != null) {
      scope.setTag('error_type', errorType);
    }

    // Capture exception with scope
    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: (scope) => scope,
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

    final breadcrumb = Breadcrumb(
      message: message,
      category: category ?? 'app',
      data: data,
      level: SentryLevel.info,
    );

    Sentry.addBreadcrumb(breadcrumb);

    super.addBreadcrumb(message, data: data, category: category);
  }

  @override
  Future<void> resetUser() async {
    if (!isEnabled) return;

    // Clear user data
    Sentry.configureScope((scope) {
      scope.setUser(null);
      scope.clearBreadcrumbs();
    });

    super.resetUser();
  }

  @override
  Future<void> setTrackingEnabled(bool isEnabled) async {
    if (!isEnabled) {
      // Clear scope when disabling
      Sentry.configureScope((scope) {
        scope.clear();
      });
    }

    super.setTrackingEnabled(isEnabled);
  }
}
