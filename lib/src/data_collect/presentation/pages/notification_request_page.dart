part of '../../data_collect.dart';

@visibleForTesting
bool shouldSkipNotificationRequestGate({
  required bool hasCompletedFirstTimeNotificationGate,
  bool hasCompletedCourseEntryNotificationGate = false,
  bool courseEntryMode = false,
  required NotificationState notificationState,
}) {
  if (courseEntryMode) {
    return hasCompletedCourseEntryNotificationGate;
  }

  return hasCompletedFirstTimeNotificationGate || notificationState.shouldSkipOnboardingGate;
}

class NotificationRequestPage extends StatefulWidget {
  const NotificationRequestPage({
    super.key,
    this.courseEntryMode = false,
    this.showPaywallAfterAuth = false,
  }) : assert(
         !(courseEntryMode && showPaywallAfterAuth),
         'NotificationRequestPage cannot enter course mode and show paywall after auth at the same time.',
       );

  final bool courseEntryMode;
  final bool showPaywallAfterAuth;

  @override
  State<NotificationRequestPage> createState() => _NotificationRequestPageState();
}

class _NotificationRequestPageState extends State<NotificationRequestPage> {
  bool _hasTrackedView = false;
  bool _hasNavigated = false;
  bool _isCourseEntryBootstrapping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeGate();
      _requestTrackingPermission();
    });
  }

  void _requestTrackingPermission() {
    AppService.instance.appEventService.requestTrackingPermission();
  }

  Future<void> _initializeGate() async {
    if (!mounted) return;
    final userCubit = context.read<UserCubit>();
    if (!widget.courseEntryMode && userCubit.state.hasCompletedFirstTimeNotificationGate) {
      _goToRegister();
      return;
    }

    final notificationState = await context.read<NotificationCubit>().refreshPermissionState(
      syncAuthorizedPreference: true,
    );
    if (!mounted) return;

    if (shouldSkipNotificationRequestGate(
      hasCompletedFirstTimeNotificationGate: userCubit.state.hasCompletedFirstTimeNotificationGate,
      hasCompletedCourseEntryNotificationGate: userCubit.state.hasCompletedCourseEntryNotificationGate,
      courseEntryMode: widget.courseEntryMode,
      notificationState: notificationState,
    )) {
      _completeGateAndContinue();
      return;
    }

    if (_hasTrackedView) return;
    AppService.instance.appTrackingService.trackObdNotificationGateView();
    _hasTrackedView = true;
  }

  Future<void> _handlePrimaryAction() async {
    AppService.instance.appTrackingService.trackObdNotificationNotifyMeClick();
    await context.read<NotificationCubit>().enableFromOnboardingGate();
    if (!mounted) return;
    _completeGateAndContinue();
  }

  Future<void> _handleSecondaryAction() async {
    AppService.instance.appTrackingService.trackObdNotificationMaybeLaterClick();
    await context.read<NotificationCubit>().disableAppPreference();
    if (!mounted) return;
    _completeGateAndContinue();
  }

  void _completeGateAndContinue() {
    if (_hasNavigated) return;
    if (widget.courseEntryMode) {
      _completeCourseEntryGateAndContinue();
      return;
    }

    _hasNavigated = true;
    context.read<UserCubit>().completeFirstTimeNotificationGate();
    _goToRegister();
  }

  Future<void> _completeCourseEntryGateAndContinue() async {
    if (_isCourseEntryBootstrapping) return;
    final userCubit = context.read<UserCubit>()..completeCourseEntryNotificationGate();

    setState(() {
      _isCourseEntryBootstrapping = true;
    });

    final result = await context.read<AuthBloc>().bootstrapCourseEntrySession();
    if (!mounted) return;

    setState(() {
      _isCourseEntryBootstrapping = false;
    });

    switch (result) {
      case CourseEntryBootstrapResult.success:
        _hasNavigated = true;
        userCubit.setIsUserPassOnboarding(false);
        const CourseRoute(selectedTabIndex: 0).go(context);
        return;
      case CourseEntryBootstrapResult.retryableFailure:
        return;
      case CourseEntryBootstrapResult.unrecoverableFailure:
        _hasNavigated = true;
        const RegisterRoute().go(context);
        return;
    }
  }

  void _goToRegister() {
    RegisterRoute(
      showPaywallAfterAuth: widget.showPaywallAfterAuth,
    ).go(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationCubit, NotificationState>(
      builder: (context, state) {
        final isLoading = (state.isLoading || _isCourseEntryBootstrapping) && !_hasNavigated;
        final onboardingL10n = context.l10n.onboarding;
        return OnboardV2ScreenShell(
          cta: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _NotificationGateButton(
                key: const Key('notification_request_primary_cta'),
                label: onboardingL10n.onboardingV2NotifyCta,
                isLoading: isLoading,
                onPressed: isLoading ? null : _handlePrimaryAction,
              ),
              10.verticalSpace,
              TextButton(
                key: const Key('notification_request_secondary_cta'),
                onPressed: isLoading ? null : _handleSecondaryAction,
                child: AppText(
                  onboardingL10n.onboardingV2MaybeLaterCta,
                  style: AppStyle.text14.copyWith(
                    color: AppCustomColor.brandPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
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
      },
    );
  }
}

class _NotificationGateButton extends StatelessWidget {
  const _NotificationGateButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.isLoading,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54.h,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppCustomColor.brandPrimary,
          disabledBackgroundColor: AppCustomColor.buttonDisable,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(1000.r),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? SizedBox(
                width: 20.w,
                height: 20.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : AppText(
                label,
                style: AppStyle.text16.copyWith(
                  fontWeight: FontWeight.w700,
                  color: onPressed == null ? AppCustomColor.textTertiary : AppCustomColor.textWhite,
                  height: 1.5,
                ),
              ),
      ),
    );
  }
}
