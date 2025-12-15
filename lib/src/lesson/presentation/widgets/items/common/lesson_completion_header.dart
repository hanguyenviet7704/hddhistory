part of '../../../../lesson.dart';

class KeypointCompleteHeader extends StatelessWidget {
  final EdgeInsets margin;
  const KeypointCompleteHeader({
    super.key,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: 12.h,
      ),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundGray,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Container(
            width: 24.w,
            height: 24.w,
            decoration: BoxDecoration(
              color: AppCustomColor.successGreen,
              borderRadius: BorderRadius.circular(12.r),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.check_rounded,
              size: 16.sp,
              color: Colors.white,
            ),
          ),
          12.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BlocSelector<CourseLessonCubit, CourseLessonState, String>(
                  selector: (state) => state.selectedLesson.keypoints.firstWhere((keypoint) => keypoint.id == state.currentKeypointId).title.text,
                  builder: (context, title) {
                    return AppText(
                      title.toUpperCase(),
                      maxLines: 1,
                      enableFitScaleDown: true,
                      style: AppStyle.text10.copyWith(
                        color: AppCustomColor.textTertiary,
                        height: 1.75,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
                2.verticalSpace,
                BlocSelector<LessonCubit, LessonState, String>(
                  selector: (state) => state.currentLearningItem.title.text,
                  builder: (context, title) {
                    return AppText(
                      title,
                      maxLines: 2,
                      enableFitScaleDown: true,
                      style: AppStyle.textBold14.copyWith(
                        color: AppCustomColor.textSecondary,
                        height: 1.4,
                      ),
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
