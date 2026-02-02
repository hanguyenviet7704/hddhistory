part of '../../../course.dart';

class RoadmapNodeIndicator extends StatelessWidget {
  final LessonEntity lesson;

  const RoadmapNodeIndicator({
    super.key,
    required this.lesson,
  });

  Color _borderColor(bool isLastInProgress) => isLastInProgress ? AppCustomColor.borderBrand : AppCustomColor.neutral100;

  bool _isLocked(bool isLastInProgress) => !isLastInProgress && lesson.roadmapProgress == ProcessEnum.notStarted;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CourseRoadmapCubit, CourseRoadmapState, bool>(
      selector: (state) {
        final lastInProgress = state.roadmap.lastInProgressLesson;
        if (lastInProgress == null) return false;
        return lastInProgress.isSameLesson(lesson);
      },
      builder: (context, isLastInProgress) {
        return Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 54.w,
              height: 54.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _borderColor(isLastInProgress),
                  width: 2.w,
                ),
              ),
              child: DCachedImage(
                url: lesson.roadmapIconUrl,
                fit: BoxFit.contain,
              ),
            ),
            if (_isLocked(isLastInProgress))
              Container(
                width: 22.w,
                height: 22.w,
                padding: EdgeInsets.all(5.w),
                clipBehavior: Clip.antiAlias,
                decoration: ShapeDecoration(
                  color: AppCustomColor.neutral100,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      width: 2,
                      strokeAlign: BorderSide.strokeAlignOutside,
                      color: Colors.white,
                    ),
                    borderRadius: BorderRadius.circular(40),
                  ),
                ),
                child: Image.asset(AppAsset.icons.common.lock.path),
              ),
          ],
        );
      },
    );
  }
}
