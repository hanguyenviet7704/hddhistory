part of '../../onboard_v2.dart';

class OnboardV2PathSelectionPage extends StatelessWidget {
  const OnboardV2PathSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OnboardV2Cubit>().state;
    final cubit = context.read<OnboardV2Cubit>();
    final onboardingL10n = context.l10n.onboarding;
    final pathSelectionCount = state.selectedPaths.length.clamp(0, 2);
    final selectablePaths = [
      for (final resolvedPath in OnboardV2PathResolver.resolvePaths(state.onboardData))
        if (OnboardV2PathResolver.matchPath(resolvedPath.key) case final path?) (path: path, entity: resolvedPath),
    ];
    return OnboardV2ScreenShell(
      header: OnboardV2ProgressHeader(
        activeSegments: 1,
        totalSegments: 3,
        pageStep: OnboardV2PageStep.p5PathSelection,
        // Back hidden: the previous step is the notification gate (p4), which
        // shouldn't be re-entered from here.
        showBack: false,
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
            onbCopy(state.onboardData, 'onboardingV2P5PathHeadingPrefix', fallback: onboardingL10n.onboardingV2P5PathHeadingPrefix),
            style: AppStyle.text28.copyWith(color: AppCustomColor.textPrimary, fontWeight: FontWeight.w800, height: 1.4),
          ),
          OnboardV2GradientText(
            onbCopy(state.onboardData, 'onboardingV2P5PathHeadingHighlight', fallback: onboardingL10n.onboardingV2P5PathHeadingHighlight),
            style: AppStyle.text28.copyWith(fontWeight: FontWeight.w800, height: 1.4),
          ),
          12.verticalSpace,
          AppText(
            onbCopy(state.onboardData, 'onboardingV2P5PathSubtitle', fallback: onboardingL10n.onboardingV2P5PathSubtitle(count: pathSelectionCount)),
            style: AppStyle.text16.copyWith(color: AppCustomColor.textSecondary),
          ),
          28.verticalSpace,
          ...selectablePaths.map((selectable) {
            final selected = state.selectedPaths.contains(selectable.path);
            final resolvedLabel = selectable.entity.title.text.trim();
            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: OnboardV2SelectableOptionRow(
                label: resolvedLabel.isNotEmpty ? resolvedLabel : selectable.path.title,
                iconPath: OnboardV2IconResolver.resolve(
                  iconUrl: selectable.entity.iconUrl,
                  iconKey: selectable.entity.iconKey,
                  selected: selected,
                ),
                selected: selected,
                onTap: () => cubit.togglePath(selectable.path),
              ),
            );
          }),
        ],
      ),
    );
  }
}
