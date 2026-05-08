part of '../../../onboard_v2.dart';

class OnboardV2PathMapSubtitle extends StatelessWidget {
  const OnboardV2PathMapSubtitle({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final onboardingL10n = context.l10n.onboarding;
    final remaining = 6 - count;
    final firstLine = count <= 0
        ? onboardingL10n.onboardingV2P5SubtitleZeroFirst
        : count == 1
        ? onboardingL10n.onboardingV2P5SubtitleSingularFirst
        : onboardingL10n.onboardingV2P5SubtitlePluralFirst(count: count);
    final secondLine = count <= 0
        ? onboardingL10n.onboardingV2P5SubtitleZeroSecond
        : remaining > 0
        ? onboardingL10n.onboardingV2P5SubtitleRemainingSecond(count: remaining)
        : '';

    return Column(
      children: [
        AppText(
          firstLine,
          textAlign: TextAlign.center,
          overflow: TextOverflow.visible,
          style: AppStyle.text16.copyWith(color: const Color(0xFF5F6F86)),
        ),
        if (secondLine.isNotEmpty)
          AppText(
            secondLine,
            textAlign: TextAlign.center,
            overflow: TextOverflow.visible,
            style: AppStyle.text16.copyWith(color: const Color(0xFF5F6F86)),
          ),
      ],
    );
  }
}
