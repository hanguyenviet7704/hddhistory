part of '../../../../lesson.dart';

class KeypointCompleteProgressCard extends StatelessWidget {
  final CourseLevelProgressEntity progress;

  const KeypointCompleteProgressCard({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: AppCustomColor.textBrand,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        children: [
          _KeypointProgressBadge(url: progress.badgeUrl),
          12.horizontalSpace,
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: AppText(
                        progress.title,
                        maxLines: 1,
                        style: AppStyle.text16.copyWith(
                          color: AppCustomColor.textWhite,
                          fontWeight: FontWeight.w700,
                          height: 1.5,
                        ),
                      ),
                    ),
                    8.horizontalSpace,
                    AppText(
                      context.text.exercise.exerciseProgressCompletedPercent(percent: progress.progressPercent),
                      maxLines: 1,
                      style: AppStyle.text10.copyWith(
                        color: AppCustomColor.textWhite,
                        fontWeight: FontWeight.w600,
                        height: 1.75,
                      ),
                    ),
                  ],
                ),
                12.verticalSpace,
                LayoutBuilder(
                  builder: (context, constraints) {
                    return LinearPercentIndicator(
                      width: constraints.maxWidth,
                      lineHeight: 8.h,
                      percent: progress.progress.clamp(0.0, 1.0),
                      animation: true,
                      animationDuration: 800,
                      animateFromLastPercent: true,
                      padding: EdgeInsets.zero,
                      backgroundColor: AppCustomColor.brandPrimary700,
                      progressColor: AppCustomColor.textWhite,
                      barRadius: Radius.circular(18.r),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KeypointProgressBadge extends StatelessWidget {
  const _KeypointProgressBadge({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Container(
        width: 36.w,
        height: 45.h,
        decoration: BoxDecoration(
          color: AppCustomColor.brandPrimary700,
          borderRadius: BorderRadius.circular(8.r),
        ),
      );
    }

    return CacheNetworkGraphic(
      url: url,
      width: 36.w,
      height: 45.h,
      fit: BoxFit.contain,
    );
  }
}
