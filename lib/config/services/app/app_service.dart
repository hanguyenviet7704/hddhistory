part of '../services.dart';

class AppConfig {
  AppConfig._();

  static final AppConfig _instance = AppConfig._();
  static AppConfig get instance => _instance;

  late GlobalKey<NavigatorState> rootNaviKey;
  late GlobalKey<NavigatorState> shellNaviKey;
  late NavigatorObserver appRouterObserver;
  late NavigatorObserver homeRouterObserver;
  late NavigatorObserver courseRouterObserver;
  late NavigatorObserver exploreRouterObserver;
  late NavigatorObserver settingRouterObserver;
  late NavigatorObserver habitRouterObserver;
  late NavigatorObserver libraryRouterObserver;
  late NavigatorObserver communityRouterObserver;

  BuildContext? get context => rootNaviKey.currentContext;
  BuildContext? get currentContext => rootNaviKey.currentState?.context;
  NavigatorState? get state => rootNaviKey.currentState;
  Widget? get widget => rootNaviKey.currentWidget;
  String? get location => GoRouter.of(currentContext!).routerDelegate.currentConfiguration.uri.toString();

  void init() {
    rootNaviKey = AppDI.injector.get<GlobalKey<NavigatorState>>(instanceName: DIKey.rootNavigatorKey);
    shellNaviKey = AppDI.injector.get<GlobalKey<NavigatorState>>(instanceName: DIKey.shellNavigatorKey);
    appRouterObserver = AppDI.injector.get<NavigatorObserver>(instanceName: DIKey.appRouterObserver);
    homeRouterObserver = AppDI.injector.get<NavigatorObserver>(instanceName: DIKey.homeRouterObserver);
    courseRouterObserver = AppDI.injector.get<NavigatorObserver>(instanceName: DIKey.courseRouterObserver);
    exploreRouterObserver = AppDI.injector.get<NavigatorObserver>(instanceName: DIKey.exploreRouterObserver);
    settingRouterObserver = AppDI.injector.get<NavigatorObserver>(instanceName: DIKey.settingRouterObserver);
    habitRouterObserver = AppDI.injector.get<NavigatorObserver>(instanceName: DIKey.habitRouterObserver);
    libraryRouterObserver = AppDI.injector.get<NavigatorObserver>(instanceName: DIKey.libraryRouterObserver);
    communityRouterObserver = AppDI.injector.get<NavigatorObserver>(instanceName: DIKey.communityRouterObserver);
  }
}

class AppService {
  AppService._();

  static final AppService _instance = AppService._();
  static AppService get instance => _instance;

  ITrackingService get appTrackingService => AppDI.injector.get<ITrackingService>();

  ILocalStoreService get localStoreService => AppDI.injector.get<ILocalStoreService>();

  IDeviceInfoService get deviceInfoService => AppDI.injector.get<IDeviceInfoService>();

  IPackageInfoService get packageInfoService => AppDI.injector.get<IPackageInfoService>();

  IRemoteConfigService get remoteConfigService => AppDI.injector.get<IRemoteConfigService>();

  AppEventService get appEventService => AppEventService.instance;

  void init(void Function() initApp) {
    _configErrorWidget();

    runZonedGuarded(
      () async {
        WidgetsFlutterBinding.ensureInitialized();
        await _configEnvironment();
        await _configUIResponsible();
        _configLoading();
        _configErrorHandle();
        await _configHelper();
        await _configService();
        initApp();
      },
      (error, stack) {
        LogDev.error('runZonedGuarded: $error \r\n $stack');
        appTrackingService.trackError(error, stackTrace: stack, errorType: 'runZoneGuarded');
      },
    );
  }

  void resetDI() async {
    await AppDI.resetDependencies();
  }

  Future<void> _configEnvironment() async {
    await AppDI.initializeDependencies();
    AppConfig.instance.init();
  }

  Future<void> _configService() async {
    // Initialize device info first for iOS version detection

    // Initialize Firebase first
    await Future.wait([
      HydrateBlocService.instance.initialize(),
      Firebase.initializeApp(options: F.firebaseOptions),
    ]);

    // After the hydrated store is up, before anything reads the session: hand
    // back a session the hydrated box no longer has but secure storage does.
    // Must finish before `runApp`, because the splash decides authenticated vs
    // not from `UserCubit` the moment it builds.
    await AppDI.injector.get<UserCubit>().restoreAuthSessionIfNeeded();
    NotificationService.initialize(
      NotificationCoreConfig(
        onTokenChanged: (state) {
          AppGlobalValue.firebaseToken = state.token;
        },
      ),
    );

    await packageInfoService.initialize();
    appTrackingService.initialize();

    // Initialize app event services early - they now handle tracking permission internally
    appEventService.initialize();

    await _configLessonAudio();

    unawaited(remoteConfigService.initialize());
    // Prefetch the paywall config from the API (falls back to the Remote
    // Config value above, then bundled defaults, if it fails) so the
    // paywall/lesson-lock reads in IapCubit.resolvedPaywallConfig have fresh
    // data ready by the time the user reaches them, without ever blocking on
    // this network round trip.
    unawaited(AppDI.injector.get<IapCubit>().prefetchPaywallConfig());
    // AppDI.source.get<CacheService>(instanceName: DIKey.cacheService).initialize();
    // await graphql.initHiveForFlutter();
    // DeepLinkService.init();
    // FlutterIsolateService.init();
    // GeolocatorService.init();
    // UnityAdsService.init();
    // AdMobService.init();
  }

  /// Background playback + OS media controls (lock-screen/Control Center/
  /// Android notification) for the lesson "Listen mode" player ONLY — every
  /// other `just_audio` instance in the app (ambient study-theme audio,
  /// roleplay audio, the generic `AudioPlayerWidget`) is untouched by
  /// `audio_service`. Must run once, after DI is initialized (so the handler
  /// can be registered into [AppDI.injector]) and before [LessonAudioCubit]
  /// can be created.
  Future<void> _configLessonAudio() async {
    // Mirrors the per-flavor Android applicationId (flavorizr.gradle.kts) so
    // dev/stg/prod each get their own notification channel.
    final androidPackageId = switch (F.appFlavor) {
      Flavor.dev => 'com.eup.meup.dev',
      Flavor.stg => 'com.eup.meup.stg',
      Flavor.prod => 'com.eup.meup',
      _ => 'com.eup.meup',
    };

    final handler = await AudioService.init(
      builder: () => LessonAudioHandler(),
      config: AudioServiceConfig(
        androidNotificationChannelId: '$androidPackageId.audio',
        androidNotificationChannelName: 'Meup Listen',
        // audio_service defaults this to 'mipmap/ic_launcher', and a launcher
        // icon used as a notification SMALL icon is flattened to a white
        // silhouette of the whole rounded square — a blob, not the logo. Point
        // it at the same monochrome mark every other Meup notification uses.
        androidNotificationIcon: 'drawable/ic_stat_meup',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );

    AppDI.injector.registerSingleton<LessonAudioHandler>(handler);
  }

  Future<void> _configHelper() async {
    // await CameraService.initCameras();

    // Loads intl's bundled month/weekday-name data for every language the app
    // supports. Without this, DateFormat tokens like MMM/MMMM/EEEE fall back
    // to English regardless of the user's chosen in-app language — bundled
    // data, so this is instant and needs no network.
    for (final languageCode in ['en', 'vi', 'zh', 'ja', 'ko']) {
      await initializeDateFormatting(languageCode);
    }
  }

  Future<void> _configUIResponsible() async {
    await ScreenUtil.ensureScreenSize();

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        statusBarColor: Colors.transparent,
        // DARK status-bar icons (clock/battery/wifi) for the app's light
        // backgrounds. On iOS this needs statusBarBrightness = light ("light
        // background" → dark content); Brightness.dark there wrongly rendered
        // WHITE icons, mismatching Android (statusBarIconBrightness.dark) and
        // the design (dark clock/battery on the periwinkle Home header).
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge, overlays: []);
  }

  void _configErrorWidget() {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      LogDev.error('ErrorWidget.builder: ${details.exception} \r\n ${details.stack}');
      if (kDebugMode) throw details.exception;
      if (kDebugMode) return Center(child: AppText('ErrorWidget.builder: ${details.exception} \r\n ${details.stack}'));
      return CommonErrorPage();
    };
  }

  void _configErrorHandle() {
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.dumpErrorToConsole(details);
      LogDev.error('FlutterError.onError: ${details.exception} \r\n ${details.stack}');
      appTrackingService.trackError(details.exception, stackTrace: details.stack, errorType: 'FlutterError.onError');
    };
  }

  void _configLoading() {
    EasyLoading.instance
      ..displayDuration = const Duration(milliseconds: 2000)
      ..indicatorType = EasyLoadingIndicatorType.ring
      ..loadingStyle = EasyLoadingStyle.custom
      ..maskType = EasyLoadingMaskType.black
      ..animationStyle = EasyLoadingAnimationStyle.scale
      ..animationDuration = const Duration(milliseconds: 200)
      ..indicatorSize = 40.0
      ..radius = 12.0
      ..progressColor = Colors.blue
      ..backgroundColor = Colors.white
      ..indicatorColor = Colors.blue
      ..textColor = Colors.white
      ..maskColor = Colors.black.op(0.2)
      ..userInteractions = false
      ..dismissOnTap = false;
  }

  bool onNavigationNotification(NavigationNotification notification) {
    // if (notification.canHandlePop) LogDev.info('onNavigationNotification: ${notification.toString()}');
    return notification.canHandlePop;
  }

  Page<dynamic> errorPageBuilder(BuildContext context, GoRouterState state) {
    LogDev.error('errorPageBuilder: ${state.error}');
    return MaterialPage(child: CommonErrorPage());
  }
}
