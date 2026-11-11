part of '../../onboard_v2.dart';

/// S5 — câu 2 "Vấn đề". Chip `Wrap`, tối đa 10 lựa chọn do
/// [OnboardV2SelectionRules.problemOptions] chia sẵn theo thứ tự nhánh đã chọn.
class OnboardV2ProblemPage extends StatelessWidget {
  const OnboardV2ProblemPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OnboardV2Cubit>().state;
    final cubit = context.read<OnboardV2Cubit>();
    final onboardingL10n = context.l10n.onboarding;
    final onboardData = state.onboardData;

    return OnboardV2ScreenShell(
      header: OnboardV2ProgressHeader(
        activeSegments: 4,
        totalSegments: _onboardV2TotalProgressSegments,
        pageStep: OnboardV2PageStep.p5Problems,
        showBack: true,
        onBack: cubit.goBack,
      ),
      cta: OnboardV2BottomCta(
        label: onboardingL10n.onboardingV2ContinueCta,
        onPressed: state.canContinueProblems ? cubit.continueFromP5Problems : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          8.verticalSpace,
          AppText(
            onbCopy(onboardData, 'onboardingV3P5HeadingPrefix', fallback: onboardingL10n.onboardingV3P5HeadingPrefix),
            maxLines: 3,
            overflow: TextOverflow.visible,
            style: onboardV2HeadingStyle(fontSize: 24).copyWith(color: AppCustomColor.textPrimary),
          ),
          OnboardV2GradientText(
            onbCopy(onboardData, 'onboardingV3P5HeadingHighlight', fallback: onboardingL10n.onboardingV3P5HeadingHighlight),
            style: onboardV2HeadingStyle(fontSize: 24),
          ),
          4.verticalSpace,
          AppText(
            onbCopy(onboardData, 'onboardingV3P5Helper', fallback: onboardingL10n.onboardingV3P5Helper),
            overflow: TextOverflow.visible,
            style: onboardV2SubtitleStyle(fontSize: 13.5),
          ),
          14.verticalSpace,
          if (state.problemOptions.isEmpty)
            OnboardV2InlineError(message: onboardingL10n.onboardingV3PickBranchFirst, onRetry: cubit.goBack)
          else
            Wrap(
              spacing: 9.w,
              runSpacing: 9.h,
              children: [
                for (final package in state.problemOptions)
                  OnboardV2Chip(
                    key: ValueKey('onboard_v2_problem_${package.code}'),
                    label: package.problemLabel.text,
                    selected: state.selectedPackageCodes.contains(package.code),
                    onTap: () => cubit.togglePackage(package.code),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
