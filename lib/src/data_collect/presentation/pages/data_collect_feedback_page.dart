part of '../../data_collect.dart';

class DataCollectFeedbackPage extends StatefulWidget {
  const DataCollectFeedbackPage({super.key});

  @override
  State<DataCollectFeedbackPage> createState() => _DataCollectFeedbackPageState();
}

class _DataCollectFeedbackPageState extends State<DataCollectFeedbackPage> {
  bool _didTrackSwipe = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppService.instance.appTrackingService.trackObdFeedbackScrView();
    });
  }

  void _onPressed(BuildContext context) {
    AppService.instance.appTrackingService.trackObdFeedbackContinue();
    context.read<DataCollectCubit>().goToNextStep();
    context.back();
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (_didTrackSwipe) return false;
    if (notification.metrics.axis != Axis.horizontal) return false;
    if (notification is ScrollStartNotification) {
      _didTrackSwipe = true;
      AppService.instance.appTrackingService.trackObdFeedbackSwipe();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final texts = context.l10n.onboarding;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: AppCustomColor.darkStroke,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              children: [
                Spacer(),
                Center(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${texts.onboardingFeedbackHeadlinePrefix}\n',
                          style: AppStyle.text18.copyWith(
                            color: AppCustomColor.textWhite,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                          ),
                        ),
                        TextSpan(
                          text: '${texts.onboardingFeedbackHeadlineHighlight}\n',
                          style: AppStyle.text26.copyWith(
                            color: AppCustomColor.textWhite,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),
                        TextSpan(
                          text: texts.onboardingFeedbackHeadlineSuffix,
                          style: AppStyle.text18.copyWith(
                            color: AppCustomColor.textWhite,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Spacer(),
                NotificationListener<ScrollNotification>(
                  onNotification: _onScrollNotification,
                  child: const PaywallFeedbackList(),
                ),
                Spacer(),
                _FeedbackContinueButton(
                  onPressed: () => _onPressed(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedbackContinueButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _FeedbackContinueButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        AppHaptic.select();
        onPressed();
      },

      child: Container(
        margin: EdgeInsets.only(bottom: 24.h),
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 80.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(1000.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.op(0.18),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: AppText(
            context.l10n.onboarding.onboardingSkipGreetingButton,
            style: AppStyle.text16.copyWith(
              fontWeight: FontWeight.w700,
              color: AppCustomColor.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
