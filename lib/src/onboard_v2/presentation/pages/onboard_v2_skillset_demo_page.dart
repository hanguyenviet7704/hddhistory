part of '../../onboard_v2.dart';

class OnboardV2SkillsetDemoPage extends StatelessWidget {
  const OnboardV2SkillsetDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OnboardV2Cubit>().state;
    final cubit = context.read<OnboardV2Cubit>();
    final introduces = state.selectedSkillsetSelection.introduces;
    final onboardingL10n = context.l10n.onboarding;
    return OnboardV2ScreenShell(
      backgroundColor: AppCustomColor.backgroundBrandSoft,
      header: OnboardV2ProgressHeader(activeSegments: 3, showBack: true, onBack: cubit.goBack),
      cta: OnboardV2BottomCta(label: onboardingL10n.onboardingV2ContinueCta, onPressed: cubit.continueFromP5),
      child: Column(
        children: [
          24.verticalSpace,
          AppText(
            onboardingL10n.onboardingV2P5HeadingPrefix,
            textAlign: TextAlign.center,
            style: AppStyle.text28.copyWith(color: AppCustomColor.textPrimary, fontWeight: FontWeight.w800, height: 1.4),
          ),
          OnboardV2GradientText(
            onboardingL10n.onboardingV2P5HeadingHighlight,
            textAlign: TextAlign.center,
            style: AppStyle.text28.copyWith(fontWeight: FontWeight.w800, height: 1.4),
          ),
          AppText(
            onboardingL10n.onboardingV2P5HeadingSuffix,
            textAlign: TextAlign.center,
            style: AppStyle.text28.copyWith(color: AppCustomColor.textPrimary, fontWeight: FontWeight.w800, height: 1.4),
          ),
          12.verticalSpace,
          OnboardV2SkillsetDemoSubtitle(count: introduces.length),
          28.verticalSpace,
          OnboardV2SkillsetMap(activeIntroduces: introduces),
        ],
      ),
    );
  }
}
