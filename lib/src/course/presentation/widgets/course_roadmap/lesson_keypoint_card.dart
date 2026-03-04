part of '../../../course.dart';

enum _LessonKeypointCardVisualState {
  lock,
  active,
  complete,
}

class _LessonKeypointCardStyle {
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final Color textColor;
  final bool showLockOverlay;

  const _LessonKeypointCardStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.borderWidth,
    required this.textColor,
    required this.showLockOverlay,
  });
}

class LessonKeypointCard extends StatelessWidget {
  final LessonEntity lesson;
  final VoidCallback? onTap;

  static const _lockedImageOverlayColor = Color(0x80B6B6B6);

  const LessonKeypointCard({
    super.key,
    required this.lesson,
    this.onTap,
  });

  KeypointEntity get keypoint => lesson.firstKeypoint;
  String get _thumbnailUrl => keypoint.image.isNotEmpty ? keypoint.image : lesson.image;

  bool _isLocked(bool isLastInProgress) => !isLastInProgress && lesson.roadmapProgress == ProcessEnum.notStarted;

  _LessonKeypointCardVisualState _resolveVisualState(bool isLastInProgress) {
    if (isLastInProgress) return _LessonKeypointCardVisualState.active;
    if (_isLocked(isLastInProgress)) return _LessonKeypointCardVisualState.lock;
    return _LessonKeypointCardVisualState.complete;
  }

  _LessonKeypointCardStyle _styleFor(_LessonKeypointCardVisualState state) {
    switch (state) {
      case _LessonKeypointCardVisualState.active:
        return const _LessonKeypointCardStyle(
          backgroundColor: AppCustomColor.backgroundWhite,
          borderColor: AppCustomColor.brandPrimary,
          borderWidth: 2,
          textColor: AppCustomColor.textPrimary,
          showLockOverlay: false,
        );
      case _LessonKeypointCardVisualState.complete:
        return const _LessonKeypointCardStyle(
          backgroundColor: AppCustomColor.backgroundWhite,
          borderColor: AppCustomColor.neutral300,
          borderWidth: 1,
          textColor: AppCustomColor.textPrimary,
          showLockOverlay: false,
        );
      case _LessonKeypointCardVisualState.lock:
        return const _LessonKeypointCardStyle(
          backgroundColor: AppCustomColor.backgroundGray,
          borderColor: Colors.transparent,
          borderWidth: 0,
          textColor: AppCustomColor.textTertiary,
          showLockOverlay: true,
        );
    }
  }

  Widget _buildLockBadge() {
    return Container(
      width: 24.w,
      height: 24.w,
      padding: EdgeInsets.all(6.w),
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: AppCustomColor.neutral100,
        shape: RoundedRectangleBorder(
          side: const BorderSide(
            width: 2,
            color: Colors.white,
          ),
          borderRadius: BorderRadius.circular(40.r),
        ),
      ),
      child: Image.asset(
        AppAsset.icons.common.lock.path,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildThumbnail(_LessonKeypointCardStyle style) {
    final imageUrl = _thumbnailUrl;

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 80.w,
          height: 80.w,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (imageUrl.isNotEmpty)
                  DCachedImage(
                    url: imageUrl,
                    width: 80.w,
                    height: 80.w,
                    fit: BoxFit.cover,
                  )
                else
                  Container(color: AppCustomColor.neutral100),
                if (style.showLockOverlay)
                  const ColoredBox(
                    color: _lockedImageOverlayColor,
                  ),
              ],
            ),
          ),
        ),
        if (style.showLockOverlay) _buildLockBadge(),
      ],
    );
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
          final style = _styleFor(_resolveVisualState(isLastInProgress));

          return Container(
            padding: EdgeInsets.all(8.w),
            constraints: BoxConstraints(minHeight: 96.h, minWidth: double.infinity),
            decoration: BoxDecoration(
              color: style.backgroundColor,
              borderRadius: BorderRadius.circular(16.r),
              border: style.borderWidth == 0
                  ? null
                  : Border.all(
                      color: style.borderColor,
                      width: style.borderWidth.w,
                    ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildThumbnail(style),
                Expanded(
                  child: Container(
                    constraints: BoxConstraints(minHeight: 44.h),
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.all(12.w),
                    child: AppText(
                      keypoint.title.text,
                      style: AppStyle.text14.copyWith(
                        fontWeight: FontWeight.w600,
                        color: style.textColor,
                        height: 1.75,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
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
