part of '../../lesson.dart';

/// Centralizes shared result overlay logic across exercise lesson bodies.
///
/// Extracts tracking, overlay flag management, and continue/review handling
/// that was previously duplicated across 8 lesson body widgets.
class LessonResultOverlayHelper {
  LessonResultOverlayHelper._();

  /// Shows the result overlay with tracking and common continue/review logic.
  ///
  /// [overlayBuilder] receives the parent [context] and a pre-built [onContinue]
  /// callback that handles review mode, tracking, and advancing to next question.
  static void showResultOverlay({
    required BuildContext context,
    required Widget Function(BuildContext parentContext, VoidCallback onContinue) overlayBuilder,
    bool isReview = false,
  }) {
    final trackingData = KeypointTrackingData.fromContext();
    if (trackingData != null) {
      AppService.instance.appTrackingService.trackKeypointExerciseResultView(trackingData);
    }
    context.read<LessonCubit>().setIsShowResultOverlay(true);
    LessonResultOverlayManager.show(
      context: context,
      builder: (_) => overlayBuilder(
        context,
        () {
          if (isReview) {
            LessonResultOverlayManager.hide();
            context.read<LessonCubit>().setIsShowResultOverlay(false);
            return;
          }
          if (trackingData != null) {
            AppService.instance.appTrackingService.trackKeypointExerciseContinue(trackingData);
          }
          LessonResultOverlayManager.hide();
          AppDI.injector.get<ExerciseCubit>().nextQuestion();
        },
      ),
    );
  }
}
