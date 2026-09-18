part of '../../onboard_v2.dart';

/// S7 — "MeUp giúp bạn thế nào": 4 thẻ bước (Hiểu / Thử / Ôn / Dùng) trôi lên
/// lần lượt rồi lặp lại. Màn thuần chữ, không hỏi gì, nên CTA luôn bật.
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
          14.verticalSpace,
          // Design: chữ thường, KHÔNG viết hoa toàn bộ (khác các eyebrow cũ).
          AppText(
            onbCopy(onboardData, 'onboardingV3P7Eyebrow', fallback: onboardingL10n.onboardingV3P7Eyebrow),
            maxLines: 2,
            overflow: TextOverflow.visible,
            style: AppStyle.text12.copyWith(
              fontSize: 11.sp,
              color: AppCustomColor.onboardMutedLabel,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.22,
              height: 1.4,
            ),
          ),
          10.verticalSpace,
          AppText(
            onbCopy(onboardData, 'onboardingV3P7HeadingPrefix', fallback: onboardingL10n.onboardingV3P7HeadingPrefix),
            maxLines: 3,
            overflow: TextOverflow.visible,
            style: onboardV2HeadingStyle().copyWith(color: AppCustomColor.textPrimary),
          ),
          OnboardV2GradientText(
            onbCopy(onboardData, 'onboardingV3P7HeadingHighlight', fallback: onboardingL10n.onboardingV3P7HeadingHighlight),
            style: onboardV2HeadingStyle(),
          ),
          28.verticalSpace,
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0) 12.verticalSpace,
            OnboardV2StepRevealCard(
              key: ValueKey('onboard_v2_how_step_$i'),
              index: i,
              child: _HowStepCard(index: i + 1, title: steps[i].$1, body: steps[i].$2),
            ),
          ],
          28.verticalSpace,
          SizedBox(
            width: double.infinity,
            child: AppText(
              onbCopy(onboardData, 'onboardingV3P7Footer', fallback: onboardingL10n.onboardingV3P7Footer),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.visible,
              style: AppStyle.text14.copyWith(
                fontSize: 14.5.sp,
                color: AppCustomColor.brandPrimary,
                fontWeight: FontWeight.w600,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HowStepCard extends StatelessWidget {
  const _HowStepCard({required this.index, required this.title, required this.body});

  final int index;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: AppCustomColor.onboardStepCardBg,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        children: [
          Container(
            width: 38.w,
            height: 38.w,
            decoration: BoxDecoration(
              color: AppCustomColor.backgroundWhite,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF252525).op(0.08),
                  blurRadius: 12.r,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: AppText(
              '$index',
              maxLines: 1,
              style: AppStyle.text16.copyWith(color: AppCustomColor.brandPrimary, fontWeight: FontWeight.w800),
            ),
          ),
          16.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.visible,
                  style: AppStyle.text16.copyWith(color: AppCustomColor.textPrimary, fontWeight: FontWeight.w700, height: 1.3),
                ),
                3.verticalSpace,
                AppText(
                  body,
                  maxLines: 4,
                  overflow: TextOverflow.visible,
                  style: AppStyle.text14.copyWith(
                    fontSize: 13.5.sp,
                    color: AppCustomColor.streakTextMuted,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
