part of '../../../course.dart';

class KeypointsSectionHeader extends StatelessWidget {
  const KeypointsSectionHeader({super.key});

  LessonExplainTrackingData? _buildTrackingData(BuildContext context) {
    final lesson = context.read<CourseLessonCubit>().state.selectedLesson;
    if (lesson.id.isEmpty) return null;

    final homeState = context.read<HomeCubit>().state;
    final skillset = homeState.skillsets.resolveSkillsetByCourseId(
      lesson.courseId,
      fallback: homeState.currentSkillset,
    );
    final course = homeState.skillsets.resolveCourseByCourseId(
      lesson.courseId,
      fallback: homeState.currentCourse,
      skillsetFallback: homeState.currentSkillset,
    );

    return LessonExplainTrackingData(
      skillset: skillset,
      course: course,
      lesson: lesson,
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
            if (trackingData != null) {
              AppService.instance.appTrackingService.trackHowItWorkClick(
                skillset: trackingData.skillset,
                course: trackingData.course,
                lesson: trackingData.lesson,
                source: trackingData.source,
              );
            }
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
