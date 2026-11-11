part of '../../../lesson.dart';

/// A quiz card narration has read but the reader has not reached.
///
/// Deliberately NOT [LessonBodyFactory.buildReviewBody]: that path applies
/// `question.result` and means "already answered". For a question nobody has
/// answered it would read as reviewed, and it puts the answer state one bug away
/// from being shown. This renders the stem the voice just read aloud and nothing
/// else — there is no code path from here into `applyExerciseResult`, so there is
/// no way for it to give away an answer the reader has not earned.
///
/// Reachable only while the deck is showing a card past its live edge, which
/// happens when narration read on through a gate while the app was off screen
/// (see `KeypointCardCubit.didChangeAppLifecycleState`).
class QuizPreviewCardBody extends StatelessWidget {
  const QuizPreviewCardBody({super.key, required this.question});

  final QuestionEntity question;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The stem only. Options are not rendered at all rather than rendered
        // disabled: nothing to mis-tap, and nothing to style into looking graded.
        DocumentWidget(documents: question.document, frosted: true),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(Icons.lock_outline_rounded, size: 16, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                context.l10n.lesson.cardNotReachedHint,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
