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
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  AppAsset.images.app.factDecoration.path,
                  width: 320.w,
                  fit: BoxFit.cover,
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CacheNetworkGraphic(
                        url: fact.icon,
                        height: 60.h,
                        fit: BoxFit.cover,
                      ),
                      60.verticalSpace,
                      AppText(
                        fact.label.text,
                        textAlign: TextAlign.start,
                        style: AppStyle.text16.copyWith(
                          color: const Color(0xB3110751),
                        ),
                      ),
                      20.verticalSpace,
                    ],
                  ),
                ),
              ],
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
