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
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.w),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.circular(16.r),
        border: GradientBoxBorder(gradient: OnboardV2GradientText.gradient, width: 2.w),
        boxShadow: [BoxShadow(color: AppCustomColor.brandPrimary.op(0.12), blurRadius: 8.r, offset: Offset(0, 2.w))],
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(color: AppCustomColor.brandPrimary, borderRadius: BorderRadius.circular(8.r)),
            child: Icon(Icons.all_inclusive_rounded, color: AppCustomColor.textWhite, size: 26.w),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AppText(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppStyle.text14.copyWith(fontWeight: FontWeight.w700, color: AppCustomColor.textPrimary, height: 1.75),
                      ),
                    ),
                    AppText(
                      onboardingL10n.onboardingV2NotificationCardTimestamp,
                      style: AppStyle.text12.copyWith(color: AppCustomColor.streakTextMuted, height: 1.75),
                    ),
                  ],
                ),
                AppText(
                  onboardingL10n.onboardingV2NotificationCardBody,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyle.text14.copyWith(color: AppCustomColor.textPrimary, height: 1.75),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
