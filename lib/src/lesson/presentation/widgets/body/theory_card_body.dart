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
    // No scroller of its own: the card is a fixed panel filling its page and
    // scrolls its own CONTENTS (see `LessonContentCard`), exactly as the design
    // does. Wrapping the whole card in a scroll view instead made it slide under
    // the pager's clip, slicing the first line of text in half.
    final Widget content = isLive
        ? TheoryLessonBody(onAnswerChecked: onAnswerChecked)
        : DocumentWidget(documents: context.read<KeypointCardCubit>().documentForCard(descriptor).document, frosted: true);

    // Narration reads whichever card is ON SCREEN — including one the reader
    // swiped back to re-read — so that is the card whose text follows the voice,
    // not necessarily the live one.
    return NarrationAutoScroll(cardIndex: cardIndex, child: content);
  }
}
