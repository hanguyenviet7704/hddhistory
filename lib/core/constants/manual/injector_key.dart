part of '../constants.dart';

mixin DIKey {
  static const BaseConfigKey baseConfigKey = BaseConfigKey();
  static const InterceptorKey interceptorKey = InterceptorKey();
  static const NetworkServiceKey networkServiceKey = NetworkServiceKey();
  static const RouteObserverKey routeObserverKey = RouteObserverKey();
  static const SocketServiceKey socketServiceKey = SocketServiceKey();
  static const TrackingConfigKey trackingConfigKey = TrackingConfigKey();
  static const SupabaseConfigKey supabaseConfigKey = SupabaseConfigKey();
  static const GoogleOAuthConfigKey googleOAuthConfigKey = GoogleOAuthConfigKey();
  static const CacheConfigKey cacheConfigKey = CacheConfigKey();

  //* Base configurations
  static const String baseUrl = 'baseUrl';
  static const String baseUrlStorage = 'baseUrlStorage';
  static const String apiBaseUrl = 'apiBaseUrl';
  static const String graphqlBaseUrl = 'graphqlBaseUrl';
  static const String aiServiceBaseUrl = 'aiServiceBaseUrl';
  static const String apiKey = 'apiKey';
  static const String connectTimeout = 'connectTimeout';
  static const String receiveTimeout = 'receiveTimeout';
  static const String token = 'token';
  static const String refreshToken = 'refreshToken';

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
  static const String settingRouterObserver = 'settingRouterObserver';
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

  //* Supabase Services
  static const String supabaseUrl = 'supabaseUrl';
  static const String supabaseAnonKey = 'supabaseAnonKey';

  //* Google OAuth Services
  static const String googleWebClientId = 'googleWebClientId';
  static const String googleIosClientId = 'googleIosClientId';
  static const String googleAndroidClientId = 'googleAndroidClientId';

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

class BaseConfigKey {
  const BaseConfigKey();
  final String baseUrl = 'baseUrl';
  final String baseUrlStorage = 'baseUrlStorage';
  final String apiBaseUrl = 'apiBaseUrl';
  final String graphqlBaseUrl = 'graphqlBaseUrl';
  final String aiServiceBaseUrl = 'aiServiceBaseUrl';
  final String apiKey = 'apiKey';
  final String connectTimeout = 'connectTimeout';
  final String receiveTimeout = 'receiveTimeout';
  final String token = 'token';
  final String refreshToken = 'refreshToken';
}

class InterceptorKey {
  const InterceptorKey();
  String get appInterceptor => 'appInterceptor';
  String get thirdPartyInterceptor => 'thirdPartyInterceptor';
  String get authInterceptor => 'authInterceptor';
}

class NetworkServiceKey {
  const NetworkServiceKey();
  String get appDio => 'appDio';
  String get thirdPartyDio => 'thirdPartyDio';
  String get aiDio => 'aiDio';
  String get authDio => 'authDio';
  String get appGraphql => 'appGraphql';
}

class RouteObserverKey {
  const RouteObserverKey();
  String get appRouterObserver => 'appRouterObserver';
  String get homeRouterObserver => 'homeRouterObserver';
  String get shopRouterObserver => 'shopRouterObserver';
  String get createPostRouterObserver => 'createPostRouterObserver';
  String get notificationRouterObserver => 'notificationRouterObserver';
  String get profileRouterObserver => 'profileRouterObserver';
  String get rootNavigatorKey => 'rootNavigatorKey';
  String get shellNavigatorKey => 'shellNavigatorKey';
}

class SocketServiceKey {
  const SocketServiceKey();
  String get socketLive => 'socketLive';
}

class TrackingConfigKey {
  const TrackingConfigKey();
  String get trackingService => 'trackingService';
  String get firebaseAnalyticsService => 'firebaseAnalyticsService';
  String get sentryTrackingService => 'sentryTrackingService';
  String get noOpTrackingService => 'noOpTrackingService';
  String get compositeTrackingService => 'compositeTrackingService';
  String get facebookAppEventsService => 'facebookAppEventsService';
}

class SupabaseConfigKey {
  const SupabaseConfigKey();
  String get supabaseUrl => 'supabaseUrl';
  String get supabaseAnonKey => 'supabaseAnonKey';
}

class GoogleOAuthConfigKey {
  const GoogleOAuthConfigKey();
  String get googleWebClientId => 'googleWebClientId';
  String get googleIosClientId => 'googleIosClientId';
  String get googleAndroidClientId => 'googleAndroidClientId';
}

class CacheConfigKey {
  const CacheConfigKey();
  String get defaultCacheManager => 'defaultCacheManager';
  String get imageCacheManager => 'imageCacheManager';
  String get videoCacheManager => 'videoCacheManager';
  String get fileCacheManager => 'fileCacheManager';
  String get cacheService => 'cacheService';
}
