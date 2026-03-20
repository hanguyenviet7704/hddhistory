part of '../../data_collect.dart';

@visibleForTesting
bool shouldSkipNotificationRequestGate({
  required bool hasCompletedFirstTimeNotificationGate,
  required NotificationState notificationState,
}) {
  return hasCompletedFirstTimeNotificationGate || notificationState.shouldSkipOnboardingGate;
}

class NotificationRequestPage extends StatefulWidget {
  const NotificationRequestPage({
    super.key,
    this.forceChooseCourseAfterLogin = false,
    this.showPaywallAfterAuth = false,
  }) : assert(
         !(forceChooseCourseAfterLogin && showPaywallAfterAuth),
         'NotificationRequestPage cannot force course selection and show paywall after auth at the same time.',
       );

  final bool forceChooseCourseAfterLogin;
  final bool showPaywallAfterAuth;

  @override
  State<NotificationRequestPage> createState() => _NotificationRequestPageState();
}

class _NotificationRequestPageState extends State<NotificationRequestPage> {
  bool _hasTrackedView = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeGate();
    });
  }

  Future<void> _initializeGate() async {
    if (!mounted) return;
    final userCubit = context.read<UserCubit>();
    if (userCubit.state.hasCompletedFirstTimeNotificationGate) {
      _goToRegister();
      return;
    }

    final notificationState = await context.read<NotificationCubit>().refreshPermissionState(
      syncAuthorizedPreference: true,
    );
    if (!mounted) return;

    if (shouldSkipNotificationRequestGate(
      hasCompletedFirstTimeNotificationGate: userCubit.state.hasCompletedFirstTimeNotificationGate,
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
    _hasNavigated = true;
    context.read<UserCubit>().completeFirstTimeNotificationGate();
    _goToRegister();
  }

  void _goToRegister() {
    RegisterRoute(
      forceChooseCourseAfterLogin: widget.forceChooseCourseAfterLogin,
      showPaywallAfterAuth: widget.showPaywallAfterAuth,
    ).go(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationCubit, NotificationState>(
      builder: (context, state) {
        final isLoading = state.isLoading && !_hasNavigated;
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 20.h),
              child: Column(
                children: [
                  const Spacer(),
                  Container(
                    width: 220.w,
                    height: 220.w,
                    padding: EdgeInsets.all(24.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F0FF),
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      AppAsset.images.app.bell.path,
                      fit: BoxFit.contain,
                    ),
                  ),
                  32.verticalSpace,
                  AppText(
                    context.l10n.onboarding.onboardingNotificationRequestTitle,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: AppStyle.textBold20.copyWith(
                      color: const Color(0xFF110751),
                      height: 1.35,
                    ),
                  ),
                  12.verticalSpace,
                  AppText(
                    context.l10n.onboarding.onboardingNotificationRequestBody,
                    maxLines: 5,
                    textAlign: TextAlign.center,
                    style: AppStyle.text16.copyWith(
                      color: const Color(0xFF5E6282),
                      height: 1.5,
                    ),
                  ),
                  const Spacer(),
                  _NotificationGateButton(
                    key: const Key('notification_request_primary_cta'),
                    label: context.l10n.onboarding.onboardingNotificationRequestPrimaryCta,
                    isLoading: isLoading,
                    onPressed: isLoading ? null : _handlePrimaryAction,
                  ),
                  12.verticalSpace,
                  TextButton(
                    key: const Key('notification_request_secondary_cta'),
                    onPressed: isLoading ? null : _handleSecondaryAction,
                    child: AppText(
                      context.l10n.onboarding.onboardingNotificationRequestSecondaryCta,
                      style: AppStyle.text16.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF5E6282),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
          backgroundColor: const Color(0xFF554FF0),
          disabledBackgroundColor: const Color(0xFF554FF0),
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
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.5,
                ),
              ),
      ),
    );
  }
}
