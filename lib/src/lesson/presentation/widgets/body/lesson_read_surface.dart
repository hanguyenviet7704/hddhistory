part of '../../../lesson.dart';

class LessonReadSurface extends StatelessWidget {
  const LessonReadSurface({
    super.key,
    required this.state,
    required this.activeBody,
    required this.controller,
    required this.timelineBuilder,
    required this.buildReviewBody,
    required this.onTrackCurrentLearningItemScroll,
  });

  final LessonState state;
  final Widget activeBody;
  final LessonPageController controller;
  final LessonTimelineBuilder timelineBuilder;
  final Widget Function(QuestionEntity question) buildReviewBody;
  final VoidCallback onTrackCurrentLearningItemScroll;

  @override
  Widget build(BuildContext context) {
    return timelineBuilder.buildLessonListView(
      state: state,
      activeBody: activeBody,
      controller: controller,
      buildReviewBody: buildReviewBody,
      onTrackCurrentLearningItemScroll: onTrackCurrentLearningItemScroll,
    );
  }
}
