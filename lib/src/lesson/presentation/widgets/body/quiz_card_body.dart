part of '../../../lesson.dart';

/// One quiz card in the unified keypoint swipe screen.
///
/// Zero duplicated answer-checking logic: the LIVE card reuses
/// [LessonBodyFactory.buildExerciseBody] unchanged (still bound to the
/// singleton `ExerciseCubit`/`ChoiceCubit` + sibling exercise-type cubits, and
/// their own Check/Continue + result-overlay flow). Already-answered quiz
/// cards behind `viewedCardIndex` render via the existing
/// [LessonBodyFactory.buildReviewBody] (`LessonReviewBodyBuilder`) — the same
/// read-only path `LessonTimelineBuilder`'s `ListView` history used, so
/// swiping back to look never resets a given answer.
class QuizCardBody extends StatelessWidget {
  const QuizCardBody({
    super.key,
    required this.descriptor,
    required this.isLive,
    required this.bodyFactory,
  });

  final KeypointCardDescriptor descriptor;
  final bool isLive;
  final LessonBodyFactory bodyFactory;

  @override
  Widget build(BuildContext context) {
    final question = context.read<KeypointCardCubit>().questionForCard(descriptor);
    final body = isLive ? bodyFactory.buildExerciseBody(question) : bodyFactory.buildReviewBody(question);

    return SingleChildScrollView(
      // Extra bottom room on the live card: its Check action floats OVER the
      // pager (so the pager's viewport height never changes — see
      // `KeypointCardShell`), which would otherwise cover the last option.
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, isLive ? 108.h : 20.h),
      child: body,
    );
  }
}
