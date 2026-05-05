part of '../../onboard_v2.dart';

class OnboardV2NotificationPage extends StatefulWidget {
  const OnboardV2NotificationPage({super.key});

  @override
  State<OnboardV2NotificationPage> createState() => _OnboardV2NotificationPageState();
}

class _OnboardV2NotificationPageState extends State<OnboardV2NotificationPage> {
  bool _isHandling = false;
  Future<NotificationState>? _permissionRefreshTask;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _permissionRefreshTask = context.read<NotificationCubit>().refreshPermissionState(syncAuthorizedPreference: true);
      unawaited(_permissionRefreshTask);
    });
  }

  Future<void> _handlePrimary() async {
    if (_isHandling) return;
    setState(() => _isHandling = true);
    OnboardV2Tracking.track(TrackingKey.onboardV2NotificationNotifyClick);
    final notificationCubit = context.read<NotificationCubit>();
    var beforeState = notificationCubit.state;
    if (!beforeState.hasLoadedPermissionState) {
      beforeState = await (_permissionRefreshTask ?? notificationCubit.refreshPermissionState(syncAuthorizedPreference: true));
      if (!mounted) return;
    }
    final result = beforeState.canRequestPermission ? await notificationCubit.enableFromOnboardingGate() : beforeState;
    if (!mounted) return;
    _complete(
      beforeState.canRequestPermission ? OnboardV2NotificationStatusMapper.fromRequestResult(result) : OnboardV2NotificationStatusMapper.fromCurrentState(beforeState),
    );
  }

  Future<void> _handleSecondary() async {
    if (_isHandling) return;
    setState(() => _isHandling = true);
    OnboardV2Tracking.track(TrackingKey.onboardV2NotificationMaybeLaterClick);
    await context.read<NotificationCubit>().disableAppPreference();
    if (!mounted) return;
    _complete(OnboardV2NotificationStatusMapper.maybeLater());
  }

  void _complete(OnboardV2NotificationStatus status) {
    OnboardV2Tracking.track(
      TrackingKey.onboardV2NotificationResult,
      parameters: {'notification_status': OnboardV2Tracking.notificationStatus(status)},
    );
    context.read<UserCubit>().completeFirstTimeNotificationGate();
    context.read<OnboardV2Cubit>().continueFromP6(notificationStatus: status);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardV2Cubit>();
    final onboardingL10n = context.l10n.onboarding;
    return OnboardV2ScreenShell(
      header: OnboardV2ProgressHeader(activeSegments: 4, showBack: true, onBack: _isHandling ? null : cubit.goBack),
      cta: OnboardV2BottomCta(
        label: onboardingL10n.onboardingV2NotifyCta,
        isLoading: _isHandling,
        onPressed: _handlePrimary,
        secondaryLabel: onboardingL10n.onboardingV2MaybeLaterCta,
        onSecondaryPressed: _handleSecondary,
      ),
      child: Column(
        children: [
          SizedBox(height: 32.w),
          Image.asset(AppAsset.images.app.bellGold.path, width: 24.w, height: 24.w),
          SizedBox(height: 8.w),
          Wrap(
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            spacing: 6.w,
            children: [
              AppText(
                onboardingL10n.onboardingV2P6HeadingPrefix,
                textAlign: TextAlign.center,
                maxLines: 1,
                style: AppStyle.text28.copyWith(color: AppCustomColor.textSecondary, fontWeight: FontWeight.w700, height: 1.4),
              ),
              OnboardV2GradientText(
                onboardingL10n.onboardingV2P6HeadingHighlight,
                textAlign: TextAlign.center,
                style: AppStyle.text28.copyWith(fontWeight: FontWeight.w700, height: 1.4),
              ),
            ],
          ),
          SizedBox(height: 4.w),
          AppText(
            onboardingL10n.onboardingV2P6Subtitle,
            textAlign: TextAlign.center,
            style: AppStyle.text16.copyWith(color: AppCustomColor.streakTextMuted, height: 1.5),
          ),
          SizedBox(height: 32.w),
          const OnboardV2NotificationPreview(),
        ],
      ),
    );
  }
}
