part of '../../onboard_v2.dart';

class OnboardV2PathMapPage extends StatelessWidget {
  const OnboardV2PathMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OnboardV2Cubit>().state;
    final cubit = context.read<OnboardV2Cubit>();
    final onboardingL10n = context.l10n.onboarding;
    return OnboardV2ScreenShell(
      backgroundColor: AppCustomColor.backgroundBrandSoft,
      header: OnboardV2ProgressHeader(
        activeSegments: 2,
        totalSegments: 3,
        pageStep: OnboardV2PageStep.p6PathMap,
        showBack: true,
        onBack: cubit.goBack,
      ),
      cta: OnboardV2BottomCta(label: onboardingL10n.onboardingV2ContinueCta, onPressed: cubit.continueFromP6PathMap),
      child: Column(
        children: [
          24.verticalSpace,
          Wrap(
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            spacing: 6.w,
            children: [
              AppText(
                onboardingL10n.onboardingV2P5HeadingPrefix,
                textAlign: TextAlign.center,
                maxLines: 1,
                style: AppStyle.text28.copyWith(color: AppCustomColor.textSecondary, fontWeight: FontWeight.w800, height: 1.4),
              ),
              OnboardV2GradientText(
                onboardingL10n.onboardingV2P5HeadingHighlight,
                textAlign: TextAlign.center,
                style: AppStyle.text28.copyWith(fontWeight: FontWeight.w800, height: 1.4),
              ),
            ],
          ),
          AppText(
            onboardingL10n.onboardingV2P5HeadingSuffix,
            textAlign: TextAlign.center,
            style: AppStyle.text28.copyWith(color: AppCustomColor.textSecondary, fontWeight: FontWeight.w800, height: 1.4),
          ),
          4.verticalSpace,
          OnboardV2PathMapSubtitle(count: state.selectedPaths.length),
          32.verticalSpace,
          OnboardV2PathMap(activePaths: state.selectedPaths),
        ],
      ),
    );
  }
}
