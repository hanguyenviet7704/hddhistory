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
        totalSegments: _onboardV2TotalProgressSegments,
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
            style: onboardV2HeadingStyle(fontSize: 26).copyWith(color: AppCustomColor.textPrimary),
          ),
          OnboardV2GradientText(
            onbCopy(onboardData, 'onboardingV2P3HeadingHighlight', fallback: onboardingL10n.onboardingV2P3HeadingHighlight),
            style: onboardV2HeadingStyle(fontSize: 26),
          ),
          12.verticalSpace,
          AppText(onboardingL10n.onboardingV2P3Subtitle, style: AppStyle.text16.copyWith(color: AppCustomColor.textSecondary)),
          28.verticalSpace,
          if (state.onboardStatus == OnboardV2AsyncStatus.loading)
            const Center(child: CircularProgressIndicator())
          else if (state.onboardStatus == OnboardV2AsyncStatus.failure)
            OnboardV2InlineError(message: state.onboardErrorMessage ?? onboardingL10n.onboardingV2AgeLoadError, onRetry: cubit.loadOnboardData)
          else if (state.onboardData.age.isEmpty)
            OnboardV2InlineError(message: onboardingL10n.onboardingV2AgeEmpty, onRetry: cubit.loadOnboardData)
          else
            _AgeGrid(options: state.onboardData.age, selectedAge: state.selectedAge, onSelect: cubit.selectAge),
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

/// Lưới 2 cột theo design S3. Số lựa chọn lẻ thì ô CUỐI chiếm trọn hàng thay vì
/// để một khoảng trống bên phải.
class _AgeGrid extends StatelessWidget {
  const _AgeGrid({required this.options, required this.selectedAge, required this.onSelect});

  final List<OnboardOptionEntity> options;
  final OnboardOptionEntity? selectedAge;
  final ValueChanged<OnboardOptionEntity> onSelect;

  @override
  Widget build(BuildContext context) {
    // Shell padding là 20.w mỗi bên (OnboardV2ScreenShell).
    final fullWidth = MediaQuery.sizeOf(context).width - 40.w;
    final halfWidth = (fullWidth - 12.w) / 2;
    return Wrap(
      spacing: 12.w,
      runSpacing: 12.h,
      children: [
        for (var i = 0; i < options.length; i++)
          SizedBox(
            width: (options.length.isOdd && i == options.length - 1) ? fullWidth : halfWidth,
            child: OnboardV2SelectableOptionRow(
              label: OnboardV2AgeTextResolver.resolve(options[i]),
              selected: selectedAge == options[i],
              trailingCheck: false,
              centered: true,
              onTap: () => onSelect(options[i]),
            ),
          ),
      ],
    );
  }
}
