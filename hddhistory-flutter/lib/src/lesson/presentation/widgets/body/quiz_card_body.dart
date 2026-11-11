part of '../../../lesson.dart';

/// One quiz card in the keypoint reading screen's continuous scroll.
///
/// Zero duplicated answer-checking logic: the LIVE card reuses
/// [LessonBodyFactory.buildExerciseBody] unchanged (still bound to the
/// singleton `ExerciseCubit`/`ChoiceCubit` + sibling exercise-type cubits, and
/// their own Check flow). Already-answered quiz cards above it render via the
/// existing [LessonBodyFactory.buildReviewBody] (`LessonReviewBodyBuilder`) —
/// the same read-only path the old `LessonTimelineBuilder` history used, so
/// scrolling back to look never resets a given answer.
///
/// No scroller of its own: this card is one item in [KeypointCardShell]'s single
/// continuous scroll, which owns the padding and the room a floating action
/// needs.
class QuizCardBody extends StatelessWidget {
  const QuizCardBody({
    super.key,
    required this.descriptor,
    required this.isLive,
    required this.isPreview,
    required this.bodyFactory,
  });

  final KeypointCardDescriptor descriptor;
  final bool isLive;

  /// Past the live edge: narration read this question aloud while the app was
  /// away, but the reader has not reached it. Neither of the other two branches
  /// fits — see [QuizPreviewCardBody].
  final bool isPreview;

  final LessonBodyFactory bodyFactory;

  @override
  Widget build(BuildContext context) {
    final question = context.read<KeypointCardCubit>().questionForCard(descriptor);
    if (isLive) return bodyFactory.buildExerciseBody(question);
    if (isPreview) return QuizPreviewCardBody(question: question);
    return bodyFactory.buildReviewBody(question);
  }
}
