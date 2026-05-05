part of '../../onboard_v2.dart';

class OnboardV2SkillsetChoicePage extends StatelessWidget {
  const OnboardV2SkillsetChoicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OnboardV2Cubit>().state;
    final cubit = context.read<OnboardV2Cubit>();
    final onboardingL10n = context.l10n.onboarding;
    return OnboardV2ScreenShell(
      header: OnboardV2ProgressHeader(activeSegments: 2, showBack: true, onBack: cubit.goBack),
      cta: OnboardV2BottomCta(
        label: onboardingL10n.onboardingV2ContinueCta,
        onPressed: state.canContinueSkillsets ? cubit.continueFromP4 : null,
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
          if (state.skillsetStatus == OnboardV2AsyncStatus.loading)
            const Center(child: CircularProgressIndicator())
          else if (state.skillsetStatus == OnboardV2AsyncStatus.failure)
            _InlineError(message: state.skillsetErrorMessage ?? onboardingL10n.onboardingV2SkillsetLoadError, onRetry: cubit.loadSkillsets)
          else if (state.skillsets.isEmpty)
            _InlineError(message: onboardingL10n.onboardingV2SkillsetEmpty, onRetry: cubit.loadSkillsets)
          else
            ...state.skillsets.map((skillset) {
              final selected = state.selectedSkillsets.any((item) => item.id == skillset.id);
              final introduce = skillset.onboardingIntroduce;
              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: OnboardV2SelectableOptionRow(
                  label: _skillsetLabel(skillset),
                  iconPath: introduce != null ? introduce.image : (skillset.image.isEmpty ? null : skillset.image),
                  selected: selected,
                  onTap: () => cubit.toggleSkillset(skillset),
                ),
              );
            }),
        ],
      ),
    );
  }

  String _skillsetLabel(SkillsetEntity skillset) {
    final introduce = skillset.onboardingIntroduce;
    if (introduce != null) return introduce.title;
    final localized = skillset.title.text.trim();
    if (localized.isNotEmpty) return localized;
    if (skillset.title.en.trim().isNotEmpty) return skillset.title.en.trim();
    return skillset.id;
  }
}
