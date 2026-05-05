part of '../../../onboard_v2.dart';

class OnboardV2FloatingNotificationCard extends StatelessWidget {
  const OnboardV2FloatingNotificationCard({super.key});

  @override
  Widget build(BuildContext context) {
    final onboardingL10n = context.l10n.onboarding;
    final title = '${onboardingL10n.onboardingV2NotificationCardTitle} \u{1F31F}';
    return Container(
      key: const Key('onboard_v2_notification_card'),
      width: 300.w,
      height: 74.w,
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.circular(16.r),
        border: GradientBoxBorder(gradient: OnboardV2GradientText.gradient, width: 2.w),
        boxShadow: [BoxShadow(color: AppCustomColor.brandPrimary.op(0.12), blurRadius: 8.r, offset: Offset(0, 2.w))],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 16.w,
            top: 17.w,
            width: 40.w,
            height: 40.w,
            child: Container(
              decoration: BoxDecoration(color: AppCustomColor.brandPrimary, borderRadius: BorderRadius.circular(8.r)),
              child: Icon(Icons.all_inclusive_rounded, color: AppCustomColor.textWhite, size: 26.w),
            ),
          ),
          Positioned(
            left: 72.w,
            top: 12.w,
            width: 212.w,
            height: 50.w,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  width: 158.w,
                  height: 25.w,
                  child: AppText(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyle.text14.copyWith(fontWeight: FontWeight.w700, color: AppCustomColor.textPrimary, height: 1.45),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  width: 32.w,
                  height: 21.w,
                  child: AppText(
                    onboardingL10n.onboardingV2NotificationCardTimestamp,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    style: AppStyle.text12.copyWith(color: AppCustomColor.streakTextMuted, height: 1.45),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 25.w,
                  width: 212.w,
                  height: 25.w,
                  child: AppText(
                    onboardingL10n.onboardingV2NotificationCardBody,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyle.text14.copyWith(color: AppCustomColor.textPrimary, height: 1.45),
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
