part of '../../onboard.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  late final Future<bool> _shouldForceUpdate;

  @override
  void initState() {
    _shouldForceUpdate = _resolveShouldForceUpdate();
    _trackSplashView();
    _configAppLocalization();
    _onboardingUser();
    _setTrackingUser();
    _getAppData();
    WidgetsBinding.instance.addPostFrameCallback(_initScreen);
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

  Future<bool> _resolveShouldForceUpdate() async {
    try {
      return await AppService.instance.remoteConfigService.shouldForceUpdate();
    } catch (e) {
      LogDev.error('Error checking for update: $e');
      return false;
    }
  }

  void _getAppData() {
    final onboardingConfig = AppService.instance.remoteConfigService.onboardingConfig;
    if (onboardingConfig.isEnabled) {
      AppDI.injector.get<OnboardCubit>().loadAllOnboards();
      AppDI.injector.get<OnboardBranchingCubit>().loadOnboardingScenarioBranching();
    }

    UserState userState = context.read<UserCubit>().state;
    AppGlobalValue.accessToken = userState.accessToken;
    AppGlobalValue.refreshToken = userState.refreshToken;

    context.read<IapCubit>().init();
    context.read<PageCubit>().setIsPassSplashScreen(true);

    if (!shouldInitializeAuthenticatedHomeData(
      accessToken: AppGlobalValue.accessToken,
      needsOnboarding: userState.isUserPassOnboarding,
    )) {
      return;
    }

    AppDI.injector.get<HomeCubit>().initializeData();
  }

  Future<void> _initScreen(_) async {
    try {
      if (!mounted) return;
      final splashDelay = Future<void>.delayed(const Duration(milliseconds: 1500));
      final shouldUpdate = await _shouldForceUpdate;
      if (!mounted) return;
      if (shouldUpdate) {
        _showUpdateDialog();
        return;
      }

      final deeplinkCubit = context.read<DeeplinkCubit>();
      final hasHandledPendingLink = deeplinkCubit.setIsPassSplashScreen(true);
      if (!mounted || hasHandledPendingLink) return;

      final hasHandledInitialLink = await deeplinkCubit.initialLink();
      if (!mounted || hasHandledInitialLink) return;
      await splashDelay;
      if (!mounted) return;

      if (AppGlobalValue.accessToken.isEmpty) {
        await _handleUnauthenticatedEntry();
        return;
      }

      _routeAuthenticatedEntry();
    } catch (error, stackTrace) {
      LogDev.error('Error initializing splash route: $error\r\n$stackTrace');
      if (!mounted) return;
      await _routeFallbackAfterInitError();
    }
  }

  Future<void> _handleUnauthenticatedEntry() async {
    final userCubit = context.read<UserCubit>();
    final onboardingConfig = AppService.instance.remoteConfigService.onboardingConfig;

    if (!userCubit.state.isUserPassOnboarding) {
      _goToRegister(
        showPaywallAfterAuth: shouldShowRegisterPaywallAfterAuth(
          hasRecognizedDevice: false,
          hasPendingFirstTimePaywallAfterAuth: userCubit.state.hasPendingFirstTimePaywallAfterAuth,
        ),
      );
      return;
    }

    if (shouldSkipOnboardingByRemoteConfig(onboardingConfig)) {
      _goToCourseEntryNotification();
      return;
    }

    final onboardCubit = AppDI.injector.get<OnboardCubit>();
    await onboardCubit.loadUserByDeviceId();
    if (!mounted) return;

    final destination = resolveUnauthenticatedSplashEntryDestination(
      needsOnboarding: userCubit.state.isUserPassOnboarding,
      onboardingDisabled: onboardingConfig.isDisabled,
      hasRecognizedDevice: onboardCubit.state.hasRecognizedDevice,
    );

    switch (destination) {
      case SplashUnauthenticatedDestination.courseEntryNotification:
        _goToCourseEntryNotification();
        return;
      case SplashUnauthenticatedDestination.legacyRegisterNotification:
        userCubit.startFirstTimeRegisterFlow();
        _goToRegister(
          showPaywallAfterAuth: shouldShowRegisterPaywallAfterAuth(
            hasRecognizedDevice: onboardCubit.state.hasRecognizedDevice,
            hasPendingFirstTimePaywallAfterAuth: userCubit.state.hasPendingFirstTimePaywallAfterAuth,
          ),
        );
        return;
      case SplashUnauthenticatedDestination.onboardingFlow:
        _goOnboardingEntryByFlowConfig();
        return;
    }
  }

  void _routeAuthenticatedEntry() {
    final destination = resolveAuthenticatedSplashDestination(
      needsOnboarding: context.read<UserCubit>().state.isUserPassOnboarding,
      hasRoadmap: AppDI.injector.get<CourseRoadmapCubit>().state.roadmap.id.isNotEmpty,
    );

    switch (destination) {
      case SplashAuthenticatedDestination.onboardingEntry:
        _goOnboardingEntryByFlowConfig();
        return;
      case SplashAuthenticatedDestination.course:
        CourseRoute().go(context);
        return;
      case SplashAuthenticatedDestination.home:
        HomeRoute().go(context);
        return;
    }
  }

  Future<void> _routeFallbackAfterInitError() async {
    final userCubit = context.read<UserCubit>();
    if (userCubit.state.isUserPassOnboarding) {
      _goOnboardingEntryByFlowConfig();
      return;
    }

    if (AppGlobalValue.accessToken.isNotEmpty) {
      HomeRoute().go(context);
      return;
    }

    if (!userCubit.state.isUserPassOnboarding) {
      _goToRegister(
        showPaywallAfterAuth: shouldShowRegisterPaywallAfterAuth(
          hasRecognizedDevice: false,
          hasPendingFirstTimePaywallAfterAuth: userCubit.state.hasPendingFirstTimePaywallAfterAuth,
        ),
      );
      return;
    }

    _goOnboardingEntryByFlowConfig();
  }

  void _goOnboardingEntryByFlowConfig() {
    final onboardingConfig = AppService.instance.remoteConfigService.onboardingConfig;
    if (shouldSkipOnboardingByRemoteConfig(onboardingConfig)) {
      _goToCourseEntryNotification();
      return;
    }

    OnboardV2Route().go(context);
  }

  void _goToCourseEntryNotification() {
    unawaited(AppDI.injector.get<AuthBloc>().warmUpCourseEntrySession());
    const NotificationRequestRoute(courseEntryMode: true).go(context);
  }

  void _goToRegister({required bool showPaywallAfterAuth}) {
    NotificationRequestRoute(showPaywallAfterAuth: showPaywallAfterAuth).go(context);
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

@visibleForTesting
bool shouldShowRegisterPaywallAfterAuth({
  required bool hasRecognizedDevice,
  required bool hasPendingFirstTimePaywallAfterAuth,
}) {
  return hasRecognizedDevice || hasPendingFirstTimePaywallAfterAuth;
}

@visibleForTesting
bool shouldSkipOnboardingByRemoteConfig(OnboardingConfigEntity config) {
  return config.isDisabled;
}

enum SplashAuthenticatedDestination {
  onboardingEntry,
  course,
  home,
}

enum SplashUnauthenticatedDestination {
  courseEntryNotification,
  legacyRegisterNotification,
  onboardingFlow,
}

@visibleForTesting
SplashUnauthenticatedDestination resolveUnauthenticatedSplashEntryDestination({
  required bool needsOnboarding,
  required bool onboardingDisabled,
  required bool hasRecognizedDevice,
}) {
  if (!needsOnboarding) return SplashUnauthenticatedDestination.legacyRegisterNotification;
  if (onboardingDisabled) return SplashUnauthenticatedDestination.courseEntryNotification;
  if (hasRecognizedDevice) return SplashUnauthenticatedDestination.legacyRegisterNotification;
  return SplashUnauthenticatedDestination.onboardingFlow;
}

@visibleForTesting
SplashAuthenticatedDestination resolveAuthenticatedSplashDestination({
  required bool needsOnboarding,
  required bool hasRoadmap,
}) {
  if (needsOnboarding) return SplashAuthenticatedDestination.onboardingEntry;
  if (hasRoadmap) return SplashAuthenticatedDestination.home;
  return SplashAuthenticatedDestination.course;
}

@visibleForTesting
bool shouldInitializeAuthenticatedHomeData({
  required String accessToken,
  required bool needsOnboarding,
}) {
  return accessToken.isNotEmpty && !needsOnboarding;
}
