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
  late NavigatorObserver settingRouterObserver;

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
    settingRouterObserver = AppDI.injector.get<NavigatorObserver>(instanceName: DIKey.settingRouterObserver);
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

  IFirebaseRemoteConfigService get firebaseRemoteConfigService => AppDI.injector.get<IFirebaseRemoteConfigService>();

  AppEventService get appEventService => AppEventService.instance;

  void init(void Function() initApp) {
    _configErrorWidget();

    runZonedGuarded(
      () async {
        _configEnvironment();
        _configUIResponsible();
        _configLoading();
        _configErrorHandle();
        _configHelper();
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

  void _configEnvironment() async {
    await AppDI.initializeDependencies();
    AppConfig.instance.init();
  }

  Future<void> _configService() async {
    // Initialize device info first for iOS version detection

    // Initialize Firebase first
    await HydrateBlocService.instance.initialize();
    await Firebase.initializeApp(options: F.firebaseOptions);

    await packageInfoService.initialize();
    appTrackingService.initialize();

    // Initialize app event services early - they now handle tracking permission internally
    await appEventService.initialize();

    await firebaseRemoteConfigService.initialize();
    // AppDI.source.get<CacheService>(instanceName: DIKey.cacheService).initialize();
    // await graphql.initHiveForFlutter();
    // DeepLinkService.init();
    // FlutterIsolateService.init();
    // GeolocatorService.init();
    // NotificationService.initialize();
    // UnityAdsService.init();
    // AdMobService.init();
  }

  Future<void> _configHelper() async {
    // await CameraService.initCameras();
  }

  void _configUIResponsible() async {
    await ScreenUtil.ensureScreenSize();

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.dark,
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
