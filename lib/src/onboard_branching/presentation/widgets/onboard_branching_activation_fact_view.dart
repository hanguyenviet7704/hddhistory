part of '../../onboard_branching.dart';

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (activation.content.icon.trim().isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18.r),
                      child: CacheNetworkGraphic(
                        url: activation.content.icon,
                        width: double.infinity,
                        height: 180.h,
                        fit: BoxFit.cover,
                      ),
                    ),
                  16.verticalSpace,
                  DText(
                    text: activation.title.text,
                    textAlign: TextAlign.start,
                    textType: DTextType.titleLarge,
                  ),
                  if (activation.description.text.trim().isNotEmpty) ...[
                    10.verticalSpace,
                    DText(
                      text: activation.description.text,
                      textAlign: TextAlign.start,
                      textType: DTextType.textDefault,
                    ),
                  ],
                  12.verticalSpace,
                  ...activation.content.labels.map(
                    (label) => Container(
                      margin: EdgeInsets.only(bottom: 10.h),
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: DText(
                        text: label.label.text,
                        textAlign: TextAlign.start,
                        textType: DTextType.textDefault,
                      ),
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

class OnboardBranchingFactView extends StatelessWidget {
  const OnboardBranchingFactView({
    super.key,
    required this.fact,
    required this.onContinue,
  });

  final OnboardOptionEntity fact;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (fact.icon.trim().isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18.r),
                      child: CacheNetworkGraphic(
                        url: fact.icon,
                        width: double.infinity,
                        height: 180.h,
                        fit: BoxFit.cover,
                      ),
                    ),
                  16.verticalSpace,
                  DText(
                    text: fact.label.text,
                    textAlign: TextAlign.start,
                    textType: DTextType.textDefault,
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
