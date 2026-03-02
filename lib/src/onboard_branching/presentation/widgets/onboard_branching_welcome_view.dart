part of '../../onboard_branching.dart';

class OnboardBranchingWelcomeView extends StatelessWidget {
  const OnboardBranchingWelcomeView({
    super.key,
    required this.userName,
    required this.onContinue,
  });

  final String userName;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final displayName = userName.trim();
    final title = displayName.isNotEmpty ? context.text.onboarding.onboardingBranchingWelcomeTitle(userName: displayName) : context.text.onboarding.onboardingMascotGreetingTitle;

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppText(
                  '👋🏻',
                  style: TextStyle(
                    fontSize: 58.sp,
                    height: 1,
                  ),
                ),
                20.verticalSpace,
                AppText(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: AppStyle.textBold20.copyWith(
                    color: const Color(0xFF110751),
                    height: 1.5,
                  ),
                ),
                4.verticalSpace,
                AppText(
                  context.text.onboarding.onboardingBranchingWelcomeSubtitle,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  style: AppStyle.text14.copyWith(
                    color: const Color(0xB3110751),
                    height: 1.75,
                  ),
                ),
              ],
            ),
          ),
          OnboardBranchingPrimaryButton(
            text: context.text.onboarding.onboardingSkipGreetingButton,
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}
