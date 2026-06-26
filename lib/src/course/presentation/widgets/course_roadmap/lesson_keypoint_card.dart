part of '../../../course.dart';

class LessonKeypointCard extends StatelessWidget {
  final LessonEntity lesson;
  final bool isLocked;
  final VoidCallback? onTap;

  const LessonKeypointCard({
    super.key,
    required this.lesson,
    this.isLocked = false,
    this.onTap,
  });

  KeypointEntity get _keypoint => lesson.firstKeypoint;

  String get _thumbnailUrl => _keypoint.image.isNotEmpty ? _keypoint.image : lesson.image;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CourseRoadmapCubit, CourseRoadmapState, bool>(
      selector: (state) {
        final lastInProgress = state.roadmap.lastInProgressLesson;
        if (lastInProgress == null) return false;
        return lastInProgress.isSameLesson(lesson);
      },
      builder: (context, isLastInProgress) {
        final isActive = isLastInProgress;
        return Semantics(
          button: true,
          label: _keypoint.title.text,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                color: AppCustomColor.backgroundWhite,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: isActive
                      ? AppCustomColor.brandPrimary
                      : AppCustomColor.borderDefault,
                  width: isActive ? 2.w : 1.w,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _RoadmapCardThumbnail(
                      imageUrl: _thumbnailUrl,
                      isLocked: isLocked,
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 12.h),
                      child: AppText(
                        _keypoint.title.text,
                        style: AppStyle.textBold16.copyWith(
                          color: isLocked
                              ? AppCustomColor.textTertiary
                              : AppCustomColor.textPrimary,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
