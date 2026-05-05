part of '../../../onboard_v2.dart';

class OnboardV2FloatingNotificationCard extends StatelessWidget {
  const OnboardV2FloatingNotificationCard({super.key});

  @override
  Widget build(BuildContext context) {
    final onboardingL10n = context.l10n.onboarding;
    return Container(
      width: 300.w,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppCustomColor.brandPrimary, width: 2),
        boxShadow: [BoxShadow(color: AppCustomColor.brandPrimary.op(0.12), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(color: AppCustomColor.brandPrimary, borderRadius: BorderRadius.circular(8.r)),
            child: Icon(Icons.notifications_rounded, color: Colors.white, size: 24.w),
          ),
          12.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppText(
                        onboardingL10n.onboardingV2NotificationCardTitle,
                        style: AppStyle.text14.copyWith(fontWeight: FontWeight.w800, color: AppCustomColor.textPrimary),
                      ),
                    ),
                    AppText(onboardingL10n.onboardingV2NotificationCardTimestamp, style: AppStyle.text12.copyWith(color: AppCustomColor.textTertiary)),
                  ],
                ),
                AppText(
                  onboardingL10n.onboardingV2NotificationCardBody,
                  overflow: TextOverflow.visible,
                  style: AppStyle.text14.copyWith(color: AppCustomColor.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
