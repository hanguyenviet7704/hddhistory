part of '../../onboard_v2.dart';

class OnboardV2AgePage extends StatelessWidget {
  const OnboardV2AgePage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OnboardV2Cubit>().state;
    final cubit = context.read<OnboardV2Cubit>();
    final onboardingL10n = context.l10n.onboarding;
    final onboardData = state.onboardData;
    // Heading template carries a {name} placeholder — prefer the config value
    // (admin-editable) and substitute the name locally; fall back to l10n.
    final ageHeadingTemplate = onbCopy(onboardData, 'onboardingV2P3HeadingPrefix', fallback: '');
    final ageHeadingPrefix = ageHeadingTemplate.isNotEmpty
        ? ageHeadingTemplate.replaceAll('{name}', state.name)
        : onboardingL10n.onboardingV2P3HeadingPrefix(name: state.name);
    return OnboardV2ScreenShell(
      header: OnboardV2ProgressHeader(
        activeSegments: 2,
        totalSegments: 2,
        pageStep: OnboardV2PageStep.p3Age,
        showBack: true,
        onBack: cubit.goBack,
      ),
      cta: OnboardV2BottomCta(
        label: onboardingL10n.onboardingV2ContinueCta,
        isLoading: state.p3SubmitStatus == OnboardV2AsyncStatus.loading,
        onPressed: state.canSubmitAge ? () => unawaited(cubit.submitAge()) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          24.verticalSpace,
          AppText(
            ageHeadingPrefix,
            overflow: TextOverflow.visible,
            style: AppStyle.text28.copyWith(color: AppCustomColor.textPrimary, fontWeight: FontWeight.w800, height: 1.4),
          ),
          OnboardV2GradientText(
            onbCopy(onboardData, 'onboardingV2P3HeadingHighlight', fallback: onboardingL10n.onboardingV2P3HeadingHighlight),
            style: AppStyle.text28.copyWith(fontWeight: FontWeight.w800, height: 1.4),
          ),
          12.verticalSpace,
          AppText(onboardingL10n.onboardingV2P3Subtitle, style: AppStyle.text16.copyWith(color: AppCustomColor.textSecondary)),
          28.verticalSpace,
          if (state.onboardStatus == OnboardV2AsyncStatus.loading)
            const Center(child: CircularProgressIndicator())
          else if (state.onboardStatus == OnboardV2AsyncStatus.failure)
            _InlineError(message: state.onboardErrorMessage ?? onboardingL10n.onboardingV2AgeLoadError, onRetry: cubit.loadOnboardData)
          else if (state.onboardData.age.isEmpty)
            _InlineError(message: onboardingL10n.onboardingV2AgeEmpty, onRetry: cubit.loadOnboardData)
          else
            ...state.onboardData.age.map(
              (age) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: OnboardV2SelectableOptionRow(
                  label: OnboardV2AgeTextResolver.resolve(age),
                  selected: state.selectedAge == age,
                  onTap: () => cubit.selectAge(age),
                ),
              ),
            ),
          if (state.p3ErrorMessage?.isNotEmpty ?? false) ...[
            8.verticalSpace,
            AppText(
              state.p3ErrorMessage!,
              overflow: TextOverflow.visible,
              style: AppStyle.text14.copyWith(color: AppCustomColor.errorRed),
            ),
          ],
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          AppText(
            message,
            textAlign: TextAlign.center,
            overflow: TextOverflow.visible,
            style: AppStyle.text14.copyWith(color: AppCustomColor.errorRed),
          ),
          TextButton(
            onPressed: () {
              AppHaptic.select();
              onRetry();
            },
            child: Text(context.l10n.onboarding.onboardingV2RetryCta),
          ),
        ],
      ),
    );
  }
}
