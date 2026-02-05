part of '../../../course.dart';

class LessonKeypointCard extends StatelessWidget {
  final LessonEntity lesson;
  final VoidCallback? onTap;

  const LessonKeypointCard({
    super.key,
    required this.lesson,
    this.onTap,
  });

  KeypointEntity get keypoint => lesson.firstKeypoint;

  Color _borderColor(bool isLastInProgress) => isLastInProgress ? AppCustomColor.brandPrimary : AppCustomColor.neutral100;

  Color _textColor(bool isLastInProgress) {
    if (isLastInProgress) return AppCustomColor.brandPrimary;
    if (keypoint.isCompleted) return AppCustomColor.textPrimary;
    return AppCustomColor.textTertiary;
  }

  Color _backgroundColor(bool isLastInProgress) {
    if (isLastInProgress) return AppCustomColor.backgroundWhite;
    if (keypoint.isCompleted) return AppCustomColor.backgroundWhite;
    return AppCustomColor.backgroundGray;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: BlocSelector<CourseRoadmapCubit, CourseRoadmapState, bool>(
        selector: (state) {
          final lastInProgress = state.roadmap.lastInProgressLesson;
          if (lastInProgress == null) return false;
          return lastInProgress.isSameLesson(lesson);
        },
        builder: (context, isLastInProgress) {
          return Container(
            padding: EdgeInsets.all(12.w),
            constraints: BoxConstraints(minHeight: 44.h, minWidth: double.infinity),
            decoration: BoxDecoration(
              color: _backgroundColor(isLastInProgress),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: _borderColor(isLastInProgress),
                width: isLastInProgress ? 2.w : 1.w,
              ),
            ),
            child: AppText(
              keypoint.title.text,
              style: AppStyle.text14.copyWith(
                fontWeight: FontWeight.w500,
                color: _textColor(isLastInProgress),
                height: 1.75,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          );
        },
      ),
    );
  }
}
