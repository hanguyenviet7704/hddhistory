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
          24.verticalSpace,
          Icon(Icons.notifications_rounded, size: 24.w, color: AppCustomColor.brandPrimary),
          12.verticalSpace,
          AppText(
            onboardingL10n.onboardingV2P6HeadingPrefix,
            textAlign: TextAlign.center,
            style: AppStyle.text28.copyWith(color: AppCustomColor.textPrimary, fontWeight: FontWeight.w800, height: 1.4),
          ),
          OnboardV2GradientText(
            onboardingL10n.onboardingV2P6HeadingHighlight,
            textAlign: TextAlign.center,
            style: AppStyle.text28.copyWith(fontWeight: FontWeight.w800, height: 1.4),
          ),
          12.verticalSpace,
          AppText(
            onboardingL10n.onboardingV2P6Subtitle,
            textAlign: TextAlign.center,
            style: AppStyle.text16.copyWith(color: AppCustomColor.textSecondary),
          ),
          20.verticalSpace,
          const OnboardV2NotificationPreview(),
        ],
      ),
    );
  }
}
