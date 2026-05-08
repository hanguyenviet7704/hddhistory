part of '../../onboard_v2.dart';

class OnboardV2SymptomSelectionPage extends StatelessWidget {
  const OnboardV2SymptomSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OnboardV2Cubit>().state;
    final cubit = context.read<OnboardV2Cubit>();
    final onboardingL10n = context.l10n.onboarding;
    return OnboardV2ScreenShell(
      header: OnboardV2ProgressHeader(
        activeSegments: 3,
        totalSegments: 3,
        pageStep: OnboardV2PageStep.p7Symptoms,
        showBack: true,
        onBack: cubit.goBack,
      ),
      cta: OnboardV2BottomCta(
        label: onboardingL10n.onboardingV2ContinueCta,
        onPressed: state.canContinueSymptoms ? () => unawaited(cubit.continueFromP7Symptoms()) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          24.verticalSpace,
          AppText(
            onboardingL10n.onboardingV2P4HeadingPrefix,
            style: AppStyle.text28.copyWith(color: AppCustomColor.textPrimary, fontWeight: FontWeight.w800, height: 1.4),
          ),
          OnboardV2GradientText(onboardingL10n.onboardingV2P4HeadingHighlight, style: AppStyle.text28.copyWith(fontWeight: FontWeight.w800, height: 1.4)),
          12.verticalSpace,
          AppText(onboardingL10n.onboardingV2P4Subtitle, style: AppStyle.text16.copyWith(color: AppCustomColor.textSecondary)),
          28.verticalSpace,
          if (state.availableSymptoms.isEmpty)
            _InlineError(message: onboardingL10n.onboardingV2GenericError, onRetry: cubit.goBack)
          else
            ...state.availableSymptoms.map((symptom) {
              final selected = state.selectedSymptoms.contains(symptom);
              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: OnboardV2SelectableOptionRow(
                  label: symptom.title,
                  selected: selected,
                  onTap: () => cubit.toggleSymptom(symptom),
                ),
              );
            }),
        ],
      ),
    );
  }
}
