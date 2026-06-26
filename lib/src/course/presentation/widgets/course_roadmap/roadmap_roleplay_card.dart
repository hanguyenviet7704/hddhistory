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
        return Semantics(
          button: true,
          label: lesson.title.text,
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
                      imageUrl: lesson.roadmapDisplayImage,
                      isLocked: isLocked,
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 12.h),
                      child: AppText(
                        lesson.title.text,
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

/// Shared full-width thumbnail widget used by roadmap lesson cards.
/// Applies a grayscale filter and a centred lock badge when [isLocked] is true.
class _RoadmapCardThumbnail extends StatelessWidget {
  final String imageUrl;
  final bool isLocked;

  static const _grayscaleMatrix = ColorFilter.matrix([
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0,      0,      0,      1, 0,
  ]);

  static const _identityMatrix = ColorFilter.mode(
    Colors.transparent,
    BlendMode.color,
  );

  const _RoadmapCardThumbnail({
    required this.imageUrl,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ColorFiltered(
          colorFilter: isLocked ? _grayscaleMatrix : _identityMatrix,
          child: imageUrl.isNotEmpty
              ? DCachedImage(
                  url: imageUrl,
                  width: double.infinity,
                  height: 140.h,
                  fit: BoxFit.cover,
                )
              : Container(
                  width: double.infinity,
                  height: 140.h,
                  color: AppCustomColor.neutral100,
                ),
        ),
        if (isLocked)
          Positioned.fill(
            child: Center(
              child: Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: AppCustomColor.textPrimary.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Semantics(
                  label: 'Locked',
                  child: Icon(
                    Icons.lock_rounded,
                    color: AppCustomColor.backgroundWhite,
                    size: 20.w,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
