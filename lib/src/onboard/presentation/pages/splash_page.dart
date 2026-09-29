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

  void _getAppData() {
    final onboardingConfig = AppService.instance.remoteConfigService.onboardingConfig;
    if (onboardingConfig.isEnabled) {
      AppDI.injector.get<OnboardCubit>().loadAllOnboards();
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
      final splashDelay = Future<void>.delayed(const Duration(milliseconds: 300));
      // Cổng buộc cập nhật đã bị gỡ khỏi splash: nó đọc Remote Config của Meup,
      // nên trên bản fork này nó chặn mọi bản build dev bằng một hộp thoại mang
      // thương hiệu sai. Bản cập nhật tuỳ chọn ở Home (HomeCubit.checkOptionalUpdate)
      // không bị ảnh hưởng.
      final deeplinkCubit = context.read<DeeplinkCubit>();
      final hasHandledPendingLink = deeplinkCubit.setIsPassSplashScreen(true);
      if (!mounted) return;
      if (hasHandledPendingLink) {
        context.read<IapCubit>().suppressPaywallAutoOpenForSession();
        return;
      }

      final hasHandledInitialLink = await deeplinkCubit.initialLink();
      if (!mounted) return;
      if (hasHandledInitialLink) {
        context.read<IapCubit>().suppressPaywallAutoOpenForSession();
        return;
      }
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
    );

    switch (destination) {
      case SplashAuthenticatedDestination.onboardingEntry:
        _goOnboardingEntryByFlowConfig();
        return;
      case SplashAuthenticatedDestination.home:
        // Một cú chạm push đã dẫn đi đâu đó rồi thì đừng kéo về Home. Chạm
        // push không đi qua `_serviceRoutePath` nên `hasHandledPendingLink` và
        // `initialLink()` ở trên đều KHÔNG thấy nó; thiếu chốt này thì mọi đích
        // của noti đều có thể bị cú `.go()` cuối cùng này nuốt mất.
        if (context.read<DeeplinkCubit>().hasNotificationNavigated) return;
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

    // onboard_v2 — the shipped, design-matching onboarding UI. Its content
    // (paths / symptoms / copy / age options) is API-driven via /onboardings.
    OnboardV2Route().go(context);
  }

  void _goToCourseEntryNotification() {
    unawaited(AppDI.injector.get<AuthBloc>().warmUpCourseEntrySession());
    const NotificationRequestRoute(courseEntryMode: true).go(context);
  }

  void _goToRegister({required bool showPaywallAfterAuth}) {
    NotificationRequestRoute(showPaywallAfterAuth: showPaywallAfterAuth).go(context);
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          // Design "Splash mới": nền sáng, ô logo thương hiệu đặt giữa. Nền đổi từ
          // tím nhạt #F2F1FA sang kem thương hiệu khi app chuyển sang tông vàng.
          decoration: const BoxDecoration(
            color: AppCustomColor.brandPrimary50,
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
                      width: 120.w,
                      height: 120.w,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                // Design shows only the tile (no wordmark); keep symmetric
                // bottom spacing so the tile reads as centred.
                SizedBox(height: 60.h + bottomInset),
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

/// Where an ORDINARY launch lands — a launch that already has a token.
///
/// Home, always. The only fork left is onboarding, which owns its own routing and
/// is untouched by this (as are the unauthenticated entry flows above:
/// register/notification-gate/course-entry all still go where they went).
///
/// It used to send a reader with an EMPTY roadmap to Explore instead, on the
/// theory that someone with no course should be picking one. But that is the
/// state a guest is in on every single launch, so the app opened on a browse grid
/// rather than on the screen carrying their streak, their day and their "jump
/// back in" (product call, 2026-08-13). Explore stays one nav tap away.
@visibleForTesting
SplashAuthenticatedDestination resolveAuthenticatedSplashDestination({
  required bool needsOnboarding,
}) {
  if (needsOnboarding) return SplashAuthenticatedDestination.onboardingEntry;
  return SplashAuthenticatedDestination.home;
}

@visibleForTesting
bool shouldInitializeAuthenticatedHomeData({
  required String accessToken,
  required bool needsOnboarding,
}) {
  return accessToken.isNotEmpty && !needsOnboarding;
}
