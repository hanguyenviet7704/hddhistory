part of '../../onboard_v2.dart';

class OnboardV2IntroPage extends StatelessWidget {
  const OnboardV2IntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    final onboardingL10n = context.l10n.onboarding;
    final onboardData = context.select<OnboardV2Cubit, OnboardEntity>((cubit) => cubit.state.onboardData);
    final isVisible = context.select<OnboardV2Cubit, bool>((cubit) => cubit.state.currentPage == OnboardV2PageStep.p1Intro);
    return OnboardV2ScreenShell(
      cta: OnboardV2BottomCta(
        label: onbCopy(onboardData, 'onboardingV2P1GetStartedCta', fallback: onboardingL10n.onboardingV2P1GetStartedCta),
        onPressed: context.read<OnboardV2Cubit>().continueFromIntro,
      ),
      child: Column(
        children: [
          58.verticalSpace,
          OnboardV2IntroCarousel(isVisible: isVisible),
          48.verticalSpace,
          AppText(
            onbCopy(onboardData, 'onboardingV2P1TitlePrefix', fallback: onboardingL10n.onboardingV2P1TitlePrefix),
            textAlign: TextAlign.center,
            style: onboardV2HeadingStyle(fontSize: 29).copyWith(
              color: AppCustomColor.brandPrimary,
              letterSpacing: -0.3,
            ),
          ),
          OnboardV2GradientText(
            onbCopy(onboardData, 'onboardingV2P1TitleBrand', fallback: onboardingL10n.onboardingV2P1TitleBrand),
            textAlign: TextAlign.center,
            style: onboardV2HeadingStyle(fontSize: 29).copyWith(letterSpacing: -0.3),
          ),
          16.verticalSpace,
          AppText(
            '${onbCopy(onboardData, 'onboardingV2P1SubtitleLine1', fallback: onboardingL10n.onboardingV2P1SubtitleLine1)}\n'
            '${onbCopy(onboardData, 'onboardingV2P1SubtitleLine2', fallback: onboardingL10n.onboardingV2P1SubtitleLine2)}',
            textAlign: TextAlign.center,
            overflow: TextOverflow.visible,
            style: AppStyle.text14.copyWith(fontSize: 15.sp, color: AppCustomColor.streakTextMuted, fontWeight: FontWeight.w500, height: 1.55),
          ),
        ],
      ),
    );
  }
}
