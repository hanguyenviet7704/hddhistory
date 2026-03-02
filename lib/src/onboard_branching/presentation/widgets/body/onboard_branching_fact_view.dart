part of '../../../onboard_branching.dart';

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
