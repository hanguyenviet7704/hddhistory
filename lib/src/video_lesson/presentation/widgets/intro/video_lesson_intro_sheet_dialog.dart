part of '../../../video_lesson.dart';

Future<void> _showVideoLessonIntroSheet(
  BuildContext context, {
  required LessonEntity lesson,
  required String nodeId,
  required CourseLessonTrackingData? trackingData,
  required VoidCallback onStart,
}) async {
  var didStart = false;
  final videoUrl = lesson.video.url.trim();

  if (trackingData != null && AppDI.injector.isRegistered<ITrackingService>()) {
    AppService.instance.appTrackingService.trackVideoLessonPopupView(
      trackingData,
      nodeId: nodeId,
    );
  }
  _videoLessonPlayerWarmupCache.prepare(videoUrl);

  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'video-lesson-intro-sheet',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (dialogContext, _, _) {
      void handleClose() => dialogContext.pop();

      return VideoLessonIntroSheet(
        lesson: lesson,
        onClose: handleClose,
        onStart: () {
          didStart = true;
          if (trackingData != null && AppDI.injector.isRegistered<ITrackingService>()) {
            AppService.instance.appTrackingService.trackVideoLessonStartClick(
              trackingData,
              nodeId: nodeId,
            );
          }
          handleClose();
          onStart();
        },
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );

  if (!didStart) {
    await _videoLessonPlayerWarmupCache.clear(videoUrl);
    if (trackingData != null && AppDI.injector.isRegistered<ITrackingService>()) {
      AppService.instance.appTrackingService.trackVideoLessonPopupClose(
        trackingData,
        nodeId: nodeId,
      );
    }
  }
}
