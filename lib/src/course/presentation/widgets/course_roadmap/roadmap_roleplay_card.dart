part of '../../../course.dart';

class RoadmapLessonCard extends StatelessWidget {
  final LessonEntity lesson;
  final VoidCallback? onTap;

  const RoadmapLessonCard({
    super.key,
    required this.lesson,
    this.onTap,
  });

  Color _borderColor(bool isLastInProgress) => isLastInProgress ? AppCustomColor.brandPrimary : AppCustomColor.neutral100;

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
            decoration: BoxDecoration(
              color: AppCustomColor.backgroundWhite,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: _borderColor(isLastInProgress),
                width: isLastInProgress ? 3.w : 2.w,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DCachedImage(
                  url: lesson.image,
                  width: double.infinity,
                  height: 120.h,
                  fit: BoxFit.cover,
                  margin: EdgeInsets.zero,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(13.r)),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 14.h),
                  child: AppText(
                    lesson.title.text,
                    style: AppStyle.textBold14.copyWith(
                      color: AppCustomColor.textPrimary,
                      height: 1.75,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
