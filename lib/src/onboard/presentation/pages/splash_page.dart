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
    _trackSplashView();
    _configAppLocalization();
    _onboardingUser();
    _setTrackingUser();
    _getAppData();
    _checkForUpdate();
    super.initState();
  }

  void _trackSplashView() {
    final userId = context.read<UserCubit>().state.user.id;
    AppService.instance.appTrackingService.trackSplashScrView(userId: userId);
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

  void _setTrackingUser() {
    context.read<UserCubit>().setTrackingUser();
  }

  void _onboardingUser() {
    //* This is for setup tracking user by tiktok and facebook app events
    bool isAppEventConfigured = context.read<UserCubit>().state.isAppEventConfigured;
    if (!isAppEventConfigured) return;
    context.read<UserCubit>().setIsAppEventConfigured(false);
    // AppService.instance.appEventService.logAppInstall();
  }

  Future<void> _checkForUpdate() async {
    try {
      final shouldUpdate = await AppService.instance.remoteConfigService.shouldForceUpdate();
      if (!mounted) return;

      if (!shouldUpdate) {
        // Only proceed with normal flow if no update is needed
        WidgetsBinding.instance.addPostFrameCallback(_initScreen);
        return;
      }

      _showUpdateDialog();
    } catch (e) {
      LogDev.error('Error checking for update: $e');
      if (!mounted) return;
      // On error, proceed with normal flow
      WidgetsBinding.instance.addPostFrameCallback(_initScreen);
    }
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

    if (AppGlobalValue.accessToken.isEmpty) return;
    AppDI.injector.get<HomeCubit>().initializeData();
  }

  void _initScreen(_) async {
    if (!mounted) return;

    bool isInitialLink = await context.read<DeeplinkCubit>().initialLink();
    if (isInitialLink) return;

    if (!mounted) return;
    bool isUserPassOnboarding = context.read<UserCubit>().state.isUserPassOnboarding;

    Future.delayed(const Duration(milliseconds: 1500), () async {
      if (!mounted) return;

      if (AppGlobalValue.accessToken.isEmpty) {
        if (isUserPassOnboarding) {
          OnboardIntroduceRoute().go(context);
          return;
        }

        RegisterRoute().go(context);
        return;
      }

      String roadmapId = AppDI.injector.get<CourseRoadmapCubit>().state.roadmap.id;
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
          ? 'https://apps.apple.com/us/app/meup-up-your-skills/id6755175330' // Replace with your App Store ID
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
    final double bottomInset = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF5953EA),
                Color(0xFF838AF2),
              ],
            ),
          ),
          child: SafeArea(
            top: false,
            bottom: false,
            child: Column(
              children: [
                SizedBox(height: 60.h),
                Expanded(
                  child: Center(
                    child: Image.asset(
                      AppAsset.images.common.mainIconSplash.path,
                      width: 80.w,
                      height: 80.w,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 60.h + bottomInset),
                  child: AppText(
                    'Meup',
                    style: AppStyle.text20.copyWith(
                      color: AppCustomColor.textWhite,
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
