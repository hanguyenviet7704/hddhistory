part of '../../daily_warm_up.dart';

class _DailyWarmUpExplanationCard extends StatelessWidget {
  const _DailyWarmUpExplanationCard({required this.explanationText});

  final String explanationText;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('daily-warm-up-lesson-style-explanation-card'),
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF8FF),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                AppAsset.svg.app.icTennisRacket,
                width: 20.w,
                height: 20.w,
              ),
              6.horizontalSpace,
              Flexible(
                child: AppText(
                  context.l10n.exercise.exerciseExplanationTitle,
                  maxLines: 1,
                  style: AppStyle.textBold14.copyWith(
                    color: const Color(0xFF175CD3),
                    height: 1.75,
                  ),
                ),
              ),
            ],
          ),
          8.verticalSpace,
          AppText(
            explanationText,
            maxLines: 100,
            style: AppStyle.text14.copyWith(
              color: const Color(0xFF364152),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
