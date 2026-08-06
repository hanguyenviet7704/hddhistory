part of '../constants.dart';

mixin DIKey {
  //* Base configurations
  static const String apiBaseUrl = 'apiBaseUrl';
  static const String socketBaseUrl = 'socketBaseUrl';
  static const String aiServiceBaseUrl = 'aiServiceBaseUrl';
  static const String apiKey = 'apiKey';
  static const String connectTimeout = 'connectTimeout';
  static const String receiveTimeout = 'receiveTimeout';

  //* Interceptors
  static const String appInterceptor = 'appInterceptor';
  static const String thirdPartyInterceptor = 'thirdPartyInterceptor';
  static const String authInterceptor = 'authInterceptor';
  static const String appGraphqlInterceptor = 'appGraphqlInterceptor';

  //* Network Services
  static const String appDio = 'appDio';
  static const String thirdPartyDio = 'thirdPartyDio';
  static const String aiDio = 'aiDio';
  static const String authDio = 'authDio';
  static const String appGraphql = 'appGraphql';

  //* Route Observers
  static const String appRouterObserver = 'appRouterObserver';
  static const String homeRouterObserver = 'homeRouterObserver';
  static const String courseRouterObserver = 'courseRouterObserver';
  static const String exploreRouterObserver = 'exploreRouterObserver';
  static const String settingRouterObserver = 'settingRouterObserver';
  static const String habitRouterObserver = 'habitRouterObserver';
  static const String rootNavigatorKey = 'rootNavigatorKey';
  static const String shellNavigatorKey = 'shellNavigatorKey';

  //* Socket Services
  static const String socketLive = 'socketLive';

  //* Tracking Services
  static const String trackingService = 'trackingService';
  static const String firebaseAnalyticsService = 'firebaseAnalyticsService';
  static const String sentryTrackingService = 'sentryTrackingService';
  static const String noOpTrackingService = 'noOpTrackingService';
  static const String compositeTrackingService = 'compositeTrackingService';
  static const String backendTrackingService = 'backendTrackingService';

  //* Cache Services
  static const String defaultCacheManager = 'defaultCacheManager';
  static const String imageCacheManager = 'imageCacheManager';
  static const String videoCacheManager = 'videoCacheManager';
  static const String fileCacheManager = 'fileCacheManager';
  static const String cacheService = 'cacheService';

  //* App Event Services
  static const String facebookAppEventsService = 'facebookAppEventsService';
  static const String tikTokAppEventService = 'tikTokAppEventService';
}
