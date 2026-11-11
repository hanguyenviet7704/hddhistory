part of 'di.dart';

@module
abstract class TrackingModule {
  // The service AppTrackingService fans out to: Firebase Analytics (unchanged)
  // plus the hddhistory-api sink that backs the admin panel's behaviour tab. Sentry is
  // deliberately left out — it never received events before either, and putting
  // ~442 events through it would be a behaviour change nobody asked for.
  @Named(DIKey.trackingService)
  @lazySingleton
  BaseTrackingService get trackingService => CompositeTrackingService([
    firebaseAnalyticsService,
    backendTrackingService,
  ]);

  // Behaviour sink read by the admin panel.
  @Named(DIKey.backendTrackingService)
  @lazySingleton
  BaseTrackingService get backendTrackingService => BackendTrackingService();

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
