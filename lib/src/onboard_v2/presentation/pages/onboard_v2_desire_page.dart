part of '../../onboard_v2.dart';

/// S6 — câu 3 "Mong muốn". Single-select; danh sách do
/// [OnboardV2SelectionRules.desireOptions] sinh theo số gói đã chọn (§3.3).
class OnboardV2DesirePage extends StatelessWidget {
  const OnboardV2DesirePage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OnboardV2Cubit>().state;
    final cubit = context.read<OnboardV2Cubit>();
    final onboardingL10n = context.l10n.onboarding;
    final onboardData = state.onboardData;

    return OnboardV2ScreenShell(
      header: OnboardV2ProgressHeader(
        activeSegments: 5,
        totalSegments: _onboardV2TotalProgressSegments,
        pageStep: OnboardV2PageStep.p6Desire,
        showBack: true,
        onBack: cubit.goBack,
      ),
      cta: OnboardV2BottomCta(
        label: onboardingL10n.onboardingV2ContinueCta,
        onPressed: state.canContinueDesire ? cubit.continueFromP6Desire : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          24.verticalSpace,
          AppText(
            onbCopy(onboardData, 'onboardingV3P6HeadingPrefix', fallback: onboardingL10n.onboardingV3P6HeadingPrefix),
            maxLines: 3,
            overflow: TextOverflow.visible,
            style: AppStyle.text28.copyWith(color: AppCustomColor.textPrimary, fontWeight: FontWeight.w800, height: 1.4),
          ),
          OnboardV2GradientText(
            onbCopy(onboardData, 'onboardingV3P6HeadingHighlight', fallback: onboardingL10n.onboardingV3P6HeadingHighlight),
            style: AppStyle.text28.copyWith(fontWeight: FontWeight.w800, height: 1.4),
          ),
          12.verticalSpace,
          AppText(
            onbCopy(onboardData, 'onboardingV3P6Helper', fallback: onboardingL10n.onboardingV3P6Helper),
            overflow: TextOverflow.visible,
            style: AppStyle.text16.copyWith(color: AppCustomColor.textSecondary),
          ),
          28.verticalSpace,
          if (state.desireOptions.isEmpty)
            OnboardV2InlineError(message: onboardingL10n.onboardingV3PickBranchFirst, onRetry: cubit.goBack)
          else
            ...state.desireOptions.map(
              (package) => Padding(
                key: ValueKey('onboard_v2_desire_${package.code}'),
                padding: EdgeInsets.only(bottom: 12.h),
                child: OnboardV2SelectableOptionRow(
                  label: package.desireLabel.text,
                  selected: state.selectedDesireCode == package.code,
                  onTap: () => cubit.selectDesire(package.code),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
