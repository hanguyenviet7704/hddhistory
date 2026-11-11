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
        // Locked appearance mirrors the timeline indicator: a lesson that isn't
        // the active one and hasn't been started yet (or is paywall-locked)
        // shows the dimmed/grayscale "locked" card.
        final isLockedVisual = !isActive && (isLocked || lesson.roadmapProgress == ProcessEnum.notStarted);
        return Semantics(
          button: true,
          label: _keypoint.title.text,
          child: GestureDetector(
            onTap: onTap == null
                ? null
                : () {
                    AppHaptic.select();
                    onTap!();
                  },
            child: Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: isLockedVisual ? AppCustomColor.backgroundGray : studyThemeCardColor(context),
                borderRadius: BorderRadius.circular(16.r),
                border: isLockedVisual
                    ? null
                    : Border.all(
                        color: isActive ? AppCustomColor.brandPrimary : AppCustomColor.neutral300,
                        width: isActive ? 2.w : 1.w,
                      ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _RoadmapCardThumbnail(
                    imageUrl: _thumbnailUrl,
                    seed: _keypoint.id.isNotEmpty ? _keypoint.id : lesson.id,
                    label: _keypoint.title.text,
                    isLocked: isLockedVisual,
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(12.w),
                      child: AppText(
                        _keypoint.title.text,
                        style: AppStyle.text14.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isLockedVisual ? AppCustomColor.textTertiary : AppCustomColor.textPrimary,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
