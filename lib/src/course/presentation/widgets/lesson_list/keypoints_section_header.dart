part of '../../../course.dart';

class KeypointsSectionHeader extends StatelessWidget {
  const KeypointsSectionHeader({super.key});

  LessonExplainTrackingData? _buildTrackingData(BuildContext context) {
    final lesson = context.read<CourseLessonCubit>().state.selectedLesson;
    return LessonExplainTrackingData.fromLesson(
      context,
      lesson,
      source: 'lesson_keypoint',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // "Key points" title
        AppText(
          context.text.lesson.lessonLessonKeypointTitle,
          style: AppStyle.text16.copyWith(
            color: AppCustomColor.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),

        // "How it works" button (UI only, action to be added later)
        GestureDetector(
          onTap: () {
            final trackingData = _buildTrackingData(context);
            LessonExplainPopup.show(context, trackingData: trackingData);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                context.text.lesson.lessonLessonKeypointInstruction,
                style: AppStyle.text12.copyWith(
                  color: AppCustomColor.textQuaternary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              8.horizontalSpace,
              Container(
                width: 20.w,
                height: 20.w,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppCustomColor.textQuaternary,
                    width: 2,
                  ),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: AppText(
                  'i',
                  style: AppStyle.text12.copyWith(
                    color: AppCustomColor.textQuaternary,
                    fontWeight: FontWeight.w600,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
