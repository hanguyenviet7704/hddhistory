part of '../../../video_lesson.dart';

class VideoLessonSummarySheet extends StatelessWidget {
  const VideoLessonSummarySheet({
    super.key,
    required this.summary,
    required this.onClose,
    required this.onScroll,
  });

  final String summary;
  final VoidCallback onClose;
  final VoidCallback onScroll;

  @override
  Widget build(BuildContext context) {
    return _VideoLessonDraggableBottomSheetFrame(
      height: 406.h,
      onDismiss: onClose,
      handleKey: const ValueKey('video-lesson-summary-sheet-handle'),
      dragRegionKey: const ValueKey('video-lesson-summary-sheet-header-drag-region'),
      header: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 6.h, 20.w, 16.h),
        child: Row(
          children: [
            Expanded(
              child: AppText(
                context.l10n.videoLesson.summaryTitle,
                style: AppStyle.textBold18.copyWith(
                  color: AppCustomColor.textPrimary,
                  height: 1.5,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                AppHaptic.select();
                onClose();
              },
              icon: Icon(
                Icons.close_rounded,
                size: 24.r,
                color: AppCustomColor.textTertiary,
              ),
            ),
          ],
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollUpdateNotification && notification.scrollDelta != null && notification.scrollDelta != 0) {
                  onScroll();
                }
                return false;
              },
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h),
                child: AppText(
                  summary,
                  maxLines: 100,
                  style: AppStyle.text16.copyWith(
                    color: AppCustomColor.textSecondary,
                    height: 1.55,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.viewPaddingOf(context).bottom),
        ],
      ),
    );
  }
}
