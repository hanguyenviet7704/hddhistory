part of '../../onboard_v2.dart';

/// S7 — "MeUp dạy thế nào": 4 bước đánh số (Hiểu / Thử / Ôn / Dùng). Màn thuần
/// chữ, không hỏi gì, nên CTA luôn bật.
class OnboardV2HowPage extends StatelessWidget {
  const OnboardV2HowPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OnboardV2Cubit>().state;
    final cubit = context.read<OnboardV2Cubit>();
    final onboardingL10n = context.l10n.onboarding;
    final onboardData = state.onboardData;

    final steps = <(String, String)>[
      (
        onbCopy(onboardData, 'onboardingV3P7Step1Title', fallback: onboardingL10n.onboardingV3P7Step1Title),
        onbCopy(onboardData, 'onboardingV3P7Step1Body', fallback: onboardingL10n.onboardingV3P7Step1Body),
      ),
      (
        onbCopy(onboardData, 'onboardingV3P7Step2Title', fallback: onboardingL10n.onboardingV3P7Step2Title),
        onbCopy(onboardData, 'onboardingV3P7Step2Body', fallback: onboardingL10n.onboardingV3P7Step2Body),
      ),
      (
        onbCopy(onboardData, 'onboardingV3P7Step3Title', fallback: onboardingL10n.onboardingV3P7Step3Title),
        onbCopy(onboardData, 'onboardingV3P7Step3Body', fallback: onboardingL10n.onboardingV3P7Step3Body),
      ),
      (
        onbCopy(onboardData, 'onboardingV3P7Step4Title', fallback: onboardingL10n.onboardingV3P7Step4Title),
        onbCopy(onboardData, 'onboardingV3P7Step4Body', fallback: onboardingL10n.onboardingV3P7Step4Body),
      ),
    ];

    return OnboardV2ScreenShell(
      header: OnboardV2ProgressHeader(
        activeSegments: 6,
        totalSegments: _onboardV2TotalProgressSegments,
        pageStep: OnboardV2PageStep.p7How,
        showBack: true,
        onBack: cubit.goBack,
      ),
      cta: OnboardV2BottomCta(
        label: onbCopy(onboardData, 'onboardingV3P7Cta', fallback: onboardingL10n.onboardingV3P7Cta),
        onPressed: cubit.continueFromP7How,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          24.verticalSpace,
          AppText(
            onbCopy(onboardData, 'onboardingV3P7Eyebrow', fallback: onboardingL10n.onboardingV3P7Eyebrow).toUpperCase(),
            maxLines: 2,
            overflow: TextOverflow.visible,
            style: AppStyle.text12.copyWith(color: AppCustomColor.brandPrimary, fontWeight: FontWeight.w700, height: 1.6),
          ),
          8.verticalSpace,
          AppText(
            onbCopy(onboardData, 'onboardingV3P7HeadingPrefix', fallback: onboardingL10n.onboardingV3P7HeadingPrefix),
            maxLines: 3,
            overflow: TextOverflow.visible,
            style: AppStyle.text28.copyWith(color: AppCustomColor.textPrimary, fontWeight: FontWeight.w800, height: 1.4),
          ),
          OnboardV2GradientText(
            onbCopy(onboardData, 'onboardingV3P7HeadingHighlight', fallback: onboardingL10n.onboardingV3P7HeadingHighlight),
            style: AppStyle.text28.copyWith(fontWeight: FontWeight.w800, height: 1.4),
          ),
          28.verticalSpace,
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: 20.h),
              child: _HowStepRow(index: i + 1, title: steps[i].$1, body: steps[i].$2),
            ),
          4.verticalSpace,
          AppText(
            onbCopy(onboardData, 'onboardingV3P7Footer', fallback: onboardingL10n.onboardingV3P7Footer),
            maxLines: 4,
            overflow: TextOverflow.visible,
            style: AppStyle.text14.copyWith(color: AppCustomColor.textSecondary, height: 1.6),
          ),
        ],
      ),
    );
  }
}

class _HowStepRow extends StatelessWidget {
  const _HowStepRow({required this.index, required this.title, required this.body});

  final int index;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36.w,
          height: 36.w,
          decoration: BoxDecoration(color: AppCustomColor.brandPrimary.op(0.1), shape: BoxShape.circle),
          alignment: Alignment.center,
          child: AppText(
            '$index',
            maxLines: 1,
            style: AppStyle.text16.copyWith(color: AppCustomColor.brandPrimary, fontWeight: FontWeight.w800),
          ),
        ),
        12.horizontalSpace,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                title,
                maxLines: 2,
                overflow: TextOverflow.visible,
                style: AppStyle.text16.copyWith(color: AppCustomColor.textPrimary, fontWeight: FontWeight.w700, height: 1.4),
              ),
              2.verticalSpace,
              AppText(
                body,
                maxLines: 3,
                overflow: TextOverflow.visible,
                style: AppStyle.text14.copyWith(color: AppCustomColor.textSecondary, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
