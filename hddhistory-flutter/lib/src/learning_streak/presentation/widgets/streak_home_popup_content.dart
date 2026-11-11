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
    return SizedBox(
      height: 753.h,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
        decoration: BoxDecoration(
          color: AppCustomColor.backgroundBrandSoft,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Spacer(),
                GestureDetector(
                  key: const ValueKey('learningStreakPopupCloseButton'),
                  onTap: onClose,
                  child: SizedBox(
                    width: 24.r,
                    height: 24.r,
                    child: SvgPicture.asset(
                      AppAsset.svg.app.icClose,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.r),
            Column(
              children: [
                SizedBox(
                  width: 100.r,
                  height: 100.r,
                  child: Lottie.asset(
                    AppAsset.lottie.flame,
                    fit: BoxFit.contain,
                  ),
                ),
                AppText(
                  context.l10n.learningStreak.streakDays(count: streak.currentStreak),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: AppStyle.textBold24.copyWith(color: AppCustomColor.textBrand),
                ),
                4.verticalSpace,
                AppText(
                  context.l10n.learningStreak.popupSubtitle,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  style: AppStyle.text12.copyWith(
                    color: AppCustomColor.streakTextMuted,
                    fontWeight: FontWeight.w500,
                    height: 1.75,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.r),
            Row(
              children: [
                Expanded(
                  child: _StreakMetricCard(
                    icon: SvgPicture.asset(
                      AppAsset.svg.app.icRingClock,
                      width: 24.r,
                      height: 24.r,
                      fit: BoxFit.contain,
                    ),
                    title: context.l10n.learningStreak.thisWeekLabel,
                    value: context.l10n.learningStreak.minutesShort(count: streak.studyTime),
                  ),
                ),
                SizedBox(width: 12.r),
                Expanded(
                  child: _StreakMetricCard(
                    icon: SvgPicture.asset(
                      AppAsset.svg.app.icFlame,
                      width: 19.2.r,
                      height: 24.r,
                      fit: BoxFit.contain,
                    ),
                    title: context.l10n.learningStreak.bestStreakLabel,
                    value: context.l10n.learningStreak.daysShort(count: streak.bestStreak),
                  ),
                ),
              ],
            ),
            16.verticalSpace,
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 20.h),
              decoration: BoxDecoration(
                color: AppCustomColor.backgroundWhite,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: StreakWeekBar(weekStudy: streak.normalizedWeekStudy),
            ),
            const Spacer(),
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
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        color: AppCustomColor.backgroundWhite,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24.r,
            height: 24.r,
            child: Center(child: icon),
          ),
          SizedBox(width: 8.r),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  value,
                  style: AppStyle.textBold16.copyWith(
                    color: AppCustomColor.textSecondary,
                  ),
                ),
                AppText(
                  title,
                  style: AppStyle.text12.copyWith(
                    color: AppCustomColor.textTertiary,
                    fontWeight: FontWeight.w500,
                    height: 1.75,
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
