part of '../../../course.dart';

class RoadmapLessonCard extends StatelessWidget {
  final LessonEntity lesson;
  final bool isLocked;
  final VoidCallback? onTap;

  const RoadmapLessonCard({
    super.key,
    required this.lesson,
    this.isLocked = false,
    this.onTap,
  });

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
        final isLockedVisual = !isActive &&
            (isLocked || lesson.roadmapProgress == ProcessEnum.notStarted);
        return Semantics(
          button: true,
          label: lesson.title.text,
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
                color: isLockedVisual
                    ? AppCustomColor.backgroundGray
                    : studyThemeCardColor(context),
                borderRadius: BorderRadius.circular(16.r),
                border: isLockedVisual
                    ? null
                    : Border.all(
                        color: isActive
                            ? AppCustomColor.brandPrimary
                            : AppCustomColor.neutral300,
                        width: isActive ? 2.w : 1.w,
                      ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _RoadmapCardThumbnail(
                    imageUrl: lesson.roadmapDisplayImage,
                    isLocked: isLockedVisual,
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(12.w),
                      child: AppText(
                        lesson.title.text,
                        style: AppStyle.text14.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isLockedVisual
                              ? AppCustomColor.textTertiary
                              : AppCustomColor.textPrimary,
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

/// Shared square thumbnail widget used by roadmap lesson cards.
/// Applies a grayscale filter and a bottom-right lock badge when [isLocked] is true.
class _RoadmapCardThumbnail extends StatelessWidget {
  final String imageUrl;
  final bool isLocked;

  static const _grayscaleMatrix = ColorFilter.matrix([
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0,      0,      0,      1, 0,
  ]);

  const _RoadmapCardThumbnail({
    required this.imageUrl,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15.r),
      child: SizedBox(
        width: 88.w,
        height: 88.w,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColorFiltered(
              colorFilter: isLocked
                  ? _grayscaleMatrix
                  : const ColorFilter.mode(Colors.transparent, BlendMode.color),
              child: imageUrl.isNotEmpty
                  ? DCachedImage(
                      url: imageUrl,
                      width: 88.w,
                      height: 88.w,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 88.w,
                      height: 88.w,
                      color: AppCustomColor.neutral100,
                    ),
            ),
            if (isLocked)
              Center(
                child: Container(
                  width: 24.w,
                  height: 24.w,
                  decoration: const BoxDecoration(
                    color: AppCustomColor.neutral100,
                    shape: BoxShape.circle,
                  ),
                  child: Semantics(
                    label: context.l10n.courseroadmap.lockedSemanticLabel,
                    child: Icon(
                      Icons.lock_rounded,
                      color: AppCustomColor.textTertiary,
                      size: 14.w,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
