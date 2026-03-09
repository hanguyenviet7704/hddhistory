part of '../../onboard.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
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

  Future<void> _configAppLocalization() async {
    final isUserPassOnboarding = context.read<UserCubit>().state.isUserPassOnboarding;
    if (!isUserPassOnboarding) return;
    final locale = await LocaleSettings.useDeviceLocale();
    if (!mounted) return;
    context.read<LocaleCubit>().setLocale(locale);
  }

  void _setTrackingUser() {
    context.read<UserCubit>().setTrackingUser();
  }

  void _onboardingUser() {
    bool isAppEventConfigured = context.read<UserCubit>().state.isAppEventConfigured;
    if (!isAppEventConfigured) return;
    context.read<UserCubit>().setIsAppEventConfigured(false);
  }

  Future<void> _checkForUpdate() async {
    try {
      final shouldUpdate = await AppService.instance.remoteConfigService.shouldForceUpdate();
      if (!mounted) return;

      if (!shouldUpdate) {
        WidgetsBinding.instance.addPostFrameCallback(_initScreen);
        return;
      }

      _showUpdateDialog();
    } catch (e) {
      LogDev.error('Error checking for update: $e');
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback(_initScreen);
    }
  }

  void _getAppData() {
    AppDI.injector.get<OnboardCubit>().loadAllOnboards();
    AppDI.injector.get<OnboardBranchingCubit>().loadOnboardingScenarioBranching();
    UserState userState = context.read<UserCubit>().state;
    AppGlobalValue.accessToken = userState.accessToken;
    AppGlobalValue.refreshToken = userState.refreshToken;

    context.read<IapCubit>().init();
    context.read<PageCubit>().setIsPassSplashScreen(true);

    if (AppGlobalValue.accessToken.isEmpty) return;
    AppDI.injector.get<HomeCubit>().initializeData();
  }

  Future<void> _initScreen(_) async {
    if (!mounted) return;
    final isInitialLink = await context.read<DeeplinkCubit>().initialLink();
    if (!mounted || isInitialLink) return;
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    if (AppGlobalValue.accessToken.isEmpty) {
      await _handleUnauthenticatedEntry();
      return;
    }

    _routeAuthenticatedEntry();
  }

  Future<void> _handleUnauthenticatedEntry() async {
    final userCubit = context.read<UserCubit>();
    if (!userCubit.state.isUserPassOnboarding) {
      const RegisterRoute().go(context);
      return;
    }

    final onboardCubit = AppDI.injector.get<OnboardCubit>();
    await onboardCubit.loadUserByDeviceId();
    if (!mounted) return;

    if (onboardCubit.state.hasRecognizedDevice) {
      userCubit.setIsUserPassOnboarding(false);
      const RegisterRoute(forceChooseCourseAfterLogin: true).go(context);
      return;
    }

    _goOnboardingEntryByFlowConfig();
  }

  void _routeAuthenticatedEntry() {
    final roadmapId = AppDI.injector.get<CourseRoadmapCubit>().state.roadmap.id;
    if (roadmapId.isEmpty) {
      CourseRoute().go(context);
      return;
    }
    HomeRoute().go(context);
  }

  void _goOnboardingEntryByFlowConfig() {
    OnboardIntroduceRoute().go(context);
  }

  void _handleUpdatePressed() async {
    try {
      final String appStoreUrl = Platform.isIOS ? 'https://apps.apple.com/us/app/meup-up-your-skills/id6755175330' : 'https://play.google.com/store/apps/details?id=com.eup.meup';

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
