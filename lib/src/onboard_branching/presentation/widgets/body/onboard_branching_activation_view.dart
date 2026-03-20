part of '../../../onboard_branching.dart';

class OnboardBranchingActivationView extends StatelessWidget {
  const OnboardBranchingActivationView({
    super.key,
    required this.activation,
    required this.onContinue,
  });

  final OnboardingScenarioActivationEntity activation;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 20.h),
      child: Column(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppText(
                  activation.title.text,
                  textAlign: TextAlign.center,
                  maxLines: 5,
                  style: AppStyle.text20.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (activation.description.text.trim().isNotEmpty) ...[
                  4.verticalSpace,
                  AppText(
                    activation.description.text,
                    maxLines: 5,
                    textAlign: TextAlign.center,
                    style: AppStyle.text14.copyWith(
                      color: const Color(0xE6FFFFFF),
                    ),
                  ),
                ],
                20.verticalSpace,
                OnboardBranchingActivationContentCard(content: activation.content),
              ],
            ),
          ),
          12.verticalSpace,
          OnboardBranchingPrimaryButton(
            text: context.l10n.onboarding.onboardingSkipGreetingButton,
            onPressed: onContinue,
            isLightStyle: true,
          ),
        ],
      ),
    );
  }
}
