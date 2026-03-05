part of '../../learning_streak.dart';

class StreakHomePopupContent extends StatelessWidget {
  const StreakHomePopupContent({
    super.key,
    required this.streak,
    required this.onClose,
  });

  final UserLearningStreakEntity streak;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
        decoration: BoxDecoration(
          color: AppCustomColor.backgroundWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Spacer(),
                GestureDetector(
                  onTap: onClose,
                  child: Container(
                    width: 28.w,
                    height: 28.w,
                    decoration: BoxDecoration(
                      color: AppCustomColor.backgroundGray,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, size: 18.sp, color: AppCustomColor.textSecondary),
                  ),
                ),
              ],
            ),
            8.verticalSpace,
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(
                        width: 100.w,
                        height: 100.w,
                        child: Lottie.asset(
                          AppAsset.lottie.flame,
                          fit: BoxFit.contain,
                        ),
                      ),
                      AppText(
                        context.text.learningStreak.streakDays(count: streak.currentStreak),
                        textAlign: TextAlign.center,
                        style: AppStyle.textBold24.copyWith(color: AppCustomColor.textBrand),
                      ),
                      4.verticalSpace,
                      AppText(
                        context.text.learningStreak.popupSubtitle,
                        textAlign: TextAlign.center,
                        style: AppStyle.text12.copyWith(
                          color: AppCustomColor.streakTextMuted,
                          fontWeight: FontWeight.w500,
                          height: 1.75,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            16.verticalSpace,
            Row(
              children: [
                Expanded(
                  child: _StreakMetricCard(
                    icon: SvgPicture.asset(
                      AppAsset.svg.app.icRingClock,
                      width: 22.w,
                      height: 22.w,
                      fit: BoxFit.contain,
                    ),
                    title: context.text.learningStreak.thisWeekLabel,
                    value: context.text.learningStreak.minutesShort(count: streak.studyTime),
                  ),
                ),
                12.horizontalSpace,
                Expanded(
                  child: _StreakMetricCard(
                    icon: SvgPicture.asset(
                      AppAsset.svg.app.icFlame,
                      width: 18.w,
                      height: 22.w,
                      fit: BoxFit.contain,
                    ),
                    title: context.text.learningStreak.bestStreakLabel,
                    value: context.text.learningStreak.daysShort(count: streak.bestStreak),
                  ),
                ),
              ],
            ),
            16.verticalSpace,
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: AppCustomColor.backgroundWhite,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppCustomColor.borderDefault, width: 2),
              ),
              child: StreakWeekBar(weekStudy: streak.normalizedWeekStudy),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakMetricCard extends StatelessWidget {
  const _StreakMetricCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final Widget icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppCustomColor.borderDefault, width: 1.5),
        color: AppCustomColor.backgroundWhite,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 22.w,
            height: 22.w,
            child: icon,
          ),
          8.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  title,
                  style: AppStyle.text10.copyWith(
                    color: AppCustomColor.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                2.verticalSpace,
                AppText(
                  value,
                  style: AppStyle.textBold14.copyWith(
                    color: AppCustomColor.textSecondary,
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
