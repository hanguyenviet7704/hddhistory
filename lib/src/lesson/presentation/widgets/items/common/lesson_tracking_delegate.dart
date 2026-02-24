part of '../../../../lesson.dart';

class LessonTrackingDelegate {
  const LessonTrackingDelegate();

  void trackKeypointTheoryScrView(TheoryState state) {
    if (state.currentLearningItem.id.isEmpty) return;

    final trackingData = KeypointTrackingData.fromContext();
    if (trackingData == null) return;

    AppService.instance.appTrackingService.trackKeypointTheoryScrView(trackingData);
  }

  void trackKeypointExerciseScrView(ExerciseState state) {
    if (state.currentLearningItem.type != LearningItemType.exercise) return;
    if (state.currentQuestion.id == 0) return;

    final trackingData = KeypointTrackingData.fromContext();
    if (trackingData == null) return;

    AppService.instance.appTrackingService.trackKeypointExerciseScrView(trackingData);
  }

  void trackCurrentLearningItemScroll({
    required LessonState lessonState,
    required bool Function(String scrollKey) shouldTrackScroll,
  }) {
    final learningItemType = lessonState.currentLearningItem.type;
    if (learningItemType != LearningItemType.exercise && learningItemType != LearningItemType.theory) return;

    final trackingData = KeypointTrackingData.fromContext();
    if (trackingData == null) return;

    final scrollKey = '${lessonState.currentLearningItem.id}:${lessonState.currentLessonIndex}:${learningItemType.name}';
    if (!shouldTrackScroll(scrollKey)) return;

    if (learningItemType == LearningItemType.exercise) {
      AppService.instance.appTrackingService.trackKeypointExerciseScroll(trackingData);
      return;
    }

    AppService.instance.appTrackingService.trackKeypointTheoryScroll(trackingData);
  }
}
