part of 'di.dart';

@module
abstract class TrackingModule {
  // Default tracking service implementation that combines Firebase and Sentry
  @Named(DIKey.trackingService)
  @lazySingleton
  BaseTrackingService get trackingService => CompositeTrackingService([
    firebaseAnalyticsService,
    sentryTrackingService,
  ]);

  // Firebase Analytics Service
  @Named(DIKey.firebaseAnalyticsService)
  @lazySingleton
  BaseTrackingService get firebaseAnalyticsService => FirebaseAnalyticsService();

  // Sentry Tracking Service
  @Named(DIKey.sentryTrackingService)
  @lazySingleton
  BaseTrackingService get sentryTrackingService => SentryTrackingService();

  // NoOp Tracking Service for test or disabled environments
  @Named(DIKey.noOpTrackingService)
  @lazySingleton
  BaseTrackingService get noOpTrackingService => NoOpTrackingService();

  // Composite Tracking Service for custom configurations
  @Named(DIKey.compositeTrackingService)
  @lazySingleton
  BaseTrackingService get compositeTrackingService => CompositeTrackingService([]);
}
