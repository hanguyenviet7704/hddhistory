part of '../../onboard_v2.dart';

class OnboardV2PathSelectionPage extends StatelessWidget {
  const OnboardV2PathSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OnboardV2Cubit>().state;
    final cubit = context.read<OnboardV2Cubit>();
    final onboardingL10n = context.l10n.onboarding;
    final pathSelectionCount = state.selectedPaths.length.clamp(0, 2);
    return OnboardV2ScreenShell(
      header: OnboardV2ProgressHeader(
        activeSegments: 1,
        totalSegments: 3,
        pageStep: OnboardV2PageStep.p5PathSelection,
        showBack: true,
        onBack: cubit.goBack,
      ),
      cta: OnboardV2BottomCta(
        label: onboardingL10n.onboardingV2ContinueCta,
        onPressed: state.canContinuePaths ? cubit.continueFromP5Paths : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          24.verticalSpace,
          AppText(
            onboardingL10n.onboardingV2P5PathHeadingPrefix,
            style: AppStyle.text28.copyWith(color: AppCustomColor.textPrimary, fontWeight: FontWeight.w800, height: 1.4),
          ),
          OnboardV2GradientText(onboardingL10n.onboardingV2P5PathHeadingHighlight, style: AppStyle.text28.copyWith(fontWeight: FontWeight.w800, height: 1.4)),
          12.verticalSpace,
          AppText(
            onboardingL10n.onboardingV2P5PathSubtitle(count: pathSelectionCount),
            style: AppStyle.text16.copyWith(color: AppCustomColor.textSecondary),
          ),
          28.verticalSpace,
          ...OnboardingPath.values.map((path) {
            final selected = state.selectedPaths.contains(path);
            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: OnboardV2SelectableOptionRow(
                label: path.title,
                iconPath: selected ? path.image : path.imageDisable,
                selected: selected,
                onTap: () => cubit.togglePath(path),
              ),
            );
          }),
        ],
      ),
    );
  }
}
