part of '../../../onboard_branching.dart';

class OnboardBranchingPersonAdmireDetailView extends StatelessWidget {
  const OnboardBranchingPersonAdmireDetailView({
    super.key,
    required this.option,
    required this.onContinue,
  });

  final OnboardingScenarioPersonOptionEntity option;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final factText = option.subTitle.text.trim().isNotEmpty ? option.subTitle.text : option.title.text;

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  100.verticalSpace,
                  Opacity(
                    opacity: 0.9,
                    child: CacheNetworkGraphic(
                      url: option.image!,
                      width: 200.w,
                      height: 300.h,
                      borderRadius: BorderRadius.circular(12.r),
                      fit: BoxFit.cover,
                    ),
                  ),
                  40.verticalSpace,
                  AppText(
                    context.text.onboarding.onboardingBranchingDidYouKnowTitle,
                    textAlign: TextAlign.center,
                    style: AppStyle.textBold20.copyWith(
                      color: const Color(0xFF110751),
                    ),
                  ),
                  4.verticalSpace,
                  AppText(
                    factText,
                    textAlign: TextAlign.center,
                    style: AppStyle.text14.copyWith(
                      color: const Color(0xB3110751),
                    ),
                  ),
                ],
              ),
            ),
          ),
          12.verticalSpace,
          OnboardBranchingPrimaryButton(
            text: context.text.onboarding.onboardingSkipGreetingButton,
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}
