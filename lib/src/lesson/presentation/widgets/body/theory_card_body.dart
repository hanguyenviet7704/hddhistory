part of '../../../lesson.dart';

/// One theory card in the unified keypoint swipe screen.
///
/// The LIVE card (the only one still bound to the singleton [TheoryCubit])
/// reuses [TheoryLessonBody] unchanged. Historical (already-passed) cards
/// render the SAME document read-only, with no cubit binding at all, so
/// swiping back to look never mutates `TheoryCubit`'s live position (see
/// `KeypointCardCubit`'s docs on why that matters).
///
/// Narration is tied to the CARD, not to any span of text inside it: swiping
/// to a page — forwards or backwards — restarts the voice at that page.
class TheoryCardBody extends StatelessWidget {
  const TheoryCardBody({
    super.key,
    required this.cardIndex,
    required this.descriptor,
    required this.isLive,
    required this.onAnswerChecked,
  });

  final int cardIndex;
  final KeypointCardDescriptor descriptor;
  final bool isLive;
  final ValueChanged<bool> onAnswerChecked;

  @override
  Widget build(BuildContext context) {
    if (!isLive) {
      final document = context.read<KeypointCardCubit>().documentForCard(descriptor);
      return SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        child: DocumentWidget(documents: document.document, frosted: true),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      child: TheoryLessonBody(onAnswerChecked: onAnswerChecked),
    );
  }
}
