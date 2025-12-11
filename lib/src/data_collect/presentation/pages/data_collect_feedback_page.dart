part of '../../data_collect.dart';

class DataCollectFeedbackPage extends StatelessWidget {
  const DataCollectFeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    final texts = context.text.onboarding;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: AppCustomColor.darkStroke,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                16.verticalSpace,
                Center(
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: AppStyle.text18.copyWith(
                        color: AppCustomColor.textWhite,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                      children: [
                        TextSpan(text: '${texts.onboardingFeedbackHeadlinePrefix} '),
                        TextSpan(
                          text: texts.onboardingFeedbackHeadlineHighlight,
                          style: AppStyle.textBold24.copyWith(
                            color: AppCustomColor.textWhite,
                            fontWeight: FontWeight.w800,
                            height: 1.3,
                          ),
                        ),
                        TextSpan(text: ' ${texts.onboardingFeedbackHeadlineSuffix}'),
                      ],
                    ),
                  ),
                ),
                32.verticalSpace,
                const PaywallFeedbackList(),
                const Spacer(),
                _FeedbackContinueButton(
                  onPressed: () {
                    final cubit = AppDI.injector.get<DataCollectCubit>();
                    cubit
                      ..startAnalysis()
                      ..loginAnonymous();
                    DataCollectSummaryRoute().go(context);
                  },
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
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      width: double.infinity,
      height: 54.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(1000.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(1000.r),
          onTap: onPressed,
          child: Center(
            child: AppText(
              context.text.onboarding.onboardingSkipGreetingButton,
              style: AppStyle.text16.copyWith(
                fontWeight: FontWeight.w700,
                color: AppCustomColor.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
