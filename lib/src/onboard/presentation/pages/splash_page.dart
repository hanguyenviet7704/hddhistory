part of '../../onboard.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    _requestTrackingPermission();
    _getAppData();
    _setTrackingUser();
    _onboardingUser();
    _checkForUpdate();
    super.initState();
  }

  void _requestTrackingPermission() {
    AppService.instance.appEventService.requestTrackingPermission();
  }

  void _getAppData() async {
    AppDI.injector.get<OnboardCubit>().loadAllOnboards();
    UserState userState = context.read<UserCubit>().state;
    AppGlobalValue.accessToken = userState.accessToken;
    AppGlobalValue.refreshToken = userState.refreshToken;
    AppGlobalValue.isGuest = userState.isGuest;

    if (!mounted) return;
    // Clipboard.setData(ClipboardData(text: 'access token: ${AppGlobalValue.accessToken}'));

    // context.read<IAPCubit>().loadIapProducts();
    context.read<PageCubit>().setIsPassSplashScreen(true);
    // context.read<HandfeelingCubit>().getBrushes();
  }

  void _onboardingUser() {
    bool isFirstTimeUserRunApp = context.read<UserCubit>().state.isFirstTimeUserRunApp;
    if (!isFirstTimeUserRunApp) return;
    AppService.instance.appEventService.logAppInstall();
    context.read<UserCubit>().setIsFirstTimeUserRunApp(false);
  }

  void _setTrackingUser() {
    context.read<UserCubit>().setTrackingUser();
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

  void _trackingDrawWelcomeScrView(String viewSource) {
    AppService.instance.appTrackingService.trackEvent(
      TrackingKey.drawWelcomeScrView,
      parameters: {
        'source': viewSource,
      },
    );
  }

  void _initScreen(_) {
    context.read<UserCubit>().setIsFirstTimeUserAccessPictureStudy(true);
    AppService.instance.appTrackingService.trackEvent(TrackingKey.splashScrView);
    Future.delayed(const Duration(milliseconds: 3000), () async {
      if (!mounted) return;
      bool isInitialLink = await context.read<PageCubit>().initialLink();
      if (isInitialLink) return;

      if (!mounted) return;
      bool isFirstTime = context.read<UserCubit>().state.isFirstTimeUserAccessApp;
      if (isFirstTime) {
        _trackingDrawWelcomeScrView('first_time');
      }
      if (AppGlobalValue.accessToken.isEmpty) {
        ChooseLanguageRoute().go(context);
        return;
      }
      AppDI.injector.get<ExerciseCubit>().loadAllLearningItems();
      ExerciseRoute().go(context);
    });
  }

  void _handleUpdatePressed() async {
    try {
      final String appStoreUrl = Platform.isIOS
          ? 'https://apps.apple.com/us/app/meup-learn-how-to-draw/id6745777751' // Replace with your App Store ID
          : 'https://play.google.com/store/apps/details?id=com.eup.meup'; // Replace with your package name

      if (await canLaunchUrl(Uri.parse(appStoreUrl))) {
        await launchUrl(
          Uri.parse(appStoreUrl),
          mode: LaunchMode.externalApplication,
        );
      }
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
        child: Stack(
          children: [
            // Image.asset(
            //   AppAsset.images.common.splashBg.path,
            //   width: 1.sw,
            //   height: 1.sh,
            //   fit: BoxFit.cover,
            // ),
            Image.asset(AppAsset.images.common.mainIcon.path),
            // Align(
            //   alignment: Alignment.bottomCenter,
            //   child: const SplashContentCard(),
            // ),
          ],
        ).animate().fadeIn(duration: 0.8.seconds),
      ),
    );
  }
}
