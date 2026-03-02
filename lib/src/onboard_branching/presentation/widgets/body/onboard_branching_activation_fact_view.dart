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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 110.h,
                    child: Stack(
                      children: [
                        Positioned(
                          top: -120.h,
                          left: -20.w,
                          right: -20.w,
                          child: Container(
                            height: 260.h,
                            decoration: const BoxDecoration(
                              gradient: RadialGradient(
                                center: Alignment.topCenter,
                                radius: 0.95,
                                colors: [
                                  Color(0x99A5A9FF),
                                  Color(0x005953EA),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  DText(
                    text: activation.title.text,
                    textAlign: TextAlign.center,
                    textType: DTextType.titleLarge,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  if (activation.description.text.trim().isNotEmpty) ...[
                    4.verticalSpace,
                    DText(
                      text: activation.description.text,
                      textAlign: TextAlign.center,
                      textType: DTextType.textDefault,
                      color: const Color(0xE6FFFFFF),
                    ),
                  ],
                  20.verticalSpace,
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (activation.content.icon.trim().isNotEmpty) ...[
                          Center(
                            child: CacheNetworkGraphic(
                              url: activation.content.icon,
                              width: 120.w,
                              height: 120.w,
                              fit: BoxFit.cover,
                            ),
                          ),
                          8.verticalSpace,
                        ],
                        for (var index = 0; index < activation.content.labels.length; index++) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(top: 2.h),
                                child: AppText(
                                  '${index + 1}.',
                                  style: AppStyle.text14.copyWith(
                                    color: const Color(0xB3110751),
                                    fontWeight: FontWeight.w700,
                                    height: 1.75,
                                  ),
                                ),
                              ),
                              14.horizontalSpace,
                              Expanded(
                                child: DText(
                                  text: activation.content.labels[index].label.text,
                                  textAlign: TextAlign.start,
                                  textType: DTextType.textDefault,
                                  color: const Color(0xB3110751),
                                ),
                              ),
                            ],
                          ),
                          if (index != activation.content.labels.length - 1)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              child: const Divider(height: 1, color: Color(0xFFE3E8EF)),
                            ),
                        ],
                      ],
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
            isLightStyle: true,
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
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.rotate(
                        angle: 0.07,
                        child: Container(
                          width: 196.w,
                          height: 240.h,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEBEAFD),
                            borderRadius: BorderRadius.circular(12.r),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x3CE7E7E9),
                                blurRadius: 3,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Transform.rotate(
                        angle: -0.07,
                        child: Container(
                          width: 196.w,
                          height: 240.h,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEBEAFD),
                            borderRadius: BorderRadius.circular(12.r),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x3CE7E7E9),
                                blurRadius: 3,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        width: 250.w,
                        padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 20.h),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x3CE7E7E9),
                              blurRadius: 3,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            SizedBox(
                              width: 160.w,
                              height: 86.h,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8.r),
                                    child: Opacity(
                                      opacity: 0.32,
                                      child: Image.asset(
                                        'assets/images/app/onboarding_fact_background_decoration.jpg',
                                        width: 160.w,
                                        height: 86.h,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  if (fact.icon.trim().isNotEmpty)
                                    CacheNetworkGraphic(
                                      url: fact.icon,
                                      width: 48.w,
                                      height: 48.w,
                                      fit: BoxFit.cover,
                                    ),
                                ],
                              ),
                            ),
                            16.verticalSpace,
                            DText(
                              text: fact.label.text,
                              textAlign: TextAlign.start,
                              textType: DTextType.textLarge,
                              color: const Color(0xB3110751),
                            ),
                          ],
                        ),
                      ),
                    ],
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
