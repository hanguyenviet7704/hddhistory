part of '../../onboard.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    // _requestTrackingPermission();
    _configAppLocalization();
    _getAppData();
    _setTrackingUser();
    _onboardingUser();
    _checkForUpdate();
    super.initState();
  }

  // void _requestTrackingPermission() {
  //   AppService.instance.appEventService.requestTrackingPermission();
  // }

  Future<void> _configAppLocalization() async {
    bool isUserPassOnboarding = context.read<UserCubit>().state.isUserPassOnboarding;
    if (!isUserPassOnboarding) return;
    AppLocale locale = await LocaleSettings.useDeviceLocale();

    if (!mounted) return;
    context.read<LocaleCubit>().setLocale(locale);
  }

  void _getAppData() async {
    AppDI.injector.get<OnboardCubit>().loadAllOnboards();
    UserState userState = context.read<UserCubit>().state;
    AppGlobalValue.accessToken = userState.accessToken;
    AppGlobalValue.refreshToken = userState.refreshToken;

    // if (!mounted) return;
    // Clipboard.setData(ClipboardData(text: 'access token: ${AppGlobalValue.accessToken}'));

    context.read<IapCubit>().init();
    context.read<PageCubit>().setIsPassSplashScreen(true);
    // context.read<HandfeelingCubit>().getBrushes();
  }

  void _setTrackingUser() {
    context.read<UserCubit>().setTrackingUser();
  }

  void _onboardingUser() {
    //* This is for setup tracking user by tiktok and facebook app events
    bool isAppEventConfigured = context.read<UserCubit>().state.isAppEventConfigured;
    if (!isAppEventConfigured) return;
    context.read<UserCubit>().setIsAppEventConfigured(false);
    AppService.instance.appEventService.logAppInstall();
  }

  Future<void> _checkForUpdate() async {
    try {
      final shouldUpdate = await AppService.instance.firebaseRemoteConfigService.shouldForceUpdate();

      if (!shouldUpdate) {
        // Only proceed with normal flow if no update is needed
        WidgetsBinding.instance.addPostFrameCallback(_initScreen);
        return;
      }

      _showUpdateDialog();
    } catch (e) {
      LogDev.error('Error checking for update: $e');
      // On error, proceed with normal flow
      WidgetsBinding.instance.addPostFrameCallback(_initScreen);
    }
  }

  void _initScreen(_) async {
    AppService.instance.appTrackingService.trackEvent(TrackingKey.splashScrView);
    
    bool isInitialLink = await context.read<DeeplinkCubit>().initialLink();
    if (isInitialLink) return;

    if (!mounted) return;
    bool isUserPassOnboarding = context.read<UserCubit>().state.isUserPassOnboarding;
    if (AppGlobalValue.accessToken.isEmpty) {
      if (isUserPassOnboarding) {
        OnboardIntroduceRoute().go(context);
        return;
      }

      RegisterRoute().go(context);
      return;
    }

    AppDI.injector.get<HomeCubit>().initializeData();
    String roadmapId = AppDI.injector.get<CourseRoadmapCubit>().state.roadmap.id;
    Future.delayed(const Duration(milliseconds: 3000), () async {
      if (!mounted) return;

      if (roadmapId.isEmpty) {
        CourseRoute().go(context);
        return;
      }

      HomeRoute().go(context);
    });
  }

  void _handleUpdatePressed() async {
    try {
      final String appStoreUrl = Platform.isIOS
          ? 'http://apps.apple.com/us/app/meup-up-your-skills/id6755175330' // Replace with your App Store ID
          : 'https://play.google.com/store/apps/details?id=com.eup.meup'; // Replace with your package name

      appStoreUrl.launchURL();
    } catch (e) {
      LogDev.error('Error launching app store: $e');
    }
  }

  void _showUpdateDialog() {
    showDDialog(
      context,
      backgroundColor: AppColorLight.surface,
      dialogContent: ForceUpdateContent(
        onUpdatePressed: _handleUpdatePressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        top: false,
        child: Center(
          child: Image.asset(
            AppAsset.images.common.mainIcon.path,
            width: 100.w,
            height: 100.w,
          ).animate().fadeIn(duration: 0.8.seconds),
        ),
      ),
    );
  }
}
