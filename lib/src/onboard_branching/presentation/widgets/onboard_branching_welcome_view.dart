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
    final displayName = userName.trim().isEmpty ? 'friend' : userName.trim();

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 96.w,
                  height: 96.w,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3F4F6),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.waving_hand_rounded, size: 42.w, color: const Color(0xFF554FF0)),
                ),
                24.verticalSpace,
                AppText(
                  'Welcome, $displayName!',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: AppStyle.textBold24.copyWith(
                    color: const Color(0xFF111827),
                  ),
                ),
                12.verticalSpace,
                AppText(
                  'Let me understand what matters most to you so we can build the right learning path.',
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  style: AppStyle.text16.copyWith(
                    color: const Color(0xFF4B5563),
                    height: 1.5,
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
