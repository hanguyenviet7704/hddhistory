part of '../../../lesson.dart';

/// Builds the card list for one keypoint from its learning items.
///
/// Pure on purpose — no cubit, no DI, no [LessonState]. This is the piece with
/// the fiddly index arithmetic (clip numbering that skips undubbed items, a live
/// edge that stops the list short), and it used to sit inside
/// [KeypointCardCubit], where testing it meant standing up `LessonCubit`,
/// `TheoryCubit` and `LessonAudioCubit` first. Callable with plain values, that
/// arithmetic is testable on its own.
///
/// Resolving where the reader is inside the current item stays the cubit's job
/// ([KeypointCardCubit._liveIndexForCurrentItem]) — it reads `TheoryCubit` /
/// `ExerciseCubit` — and arrives here as [liveIndexInCurrentItem].
class KeypointCardsBuilder {
  const KeypointCardsBuilder();

  BuiltKeypointCards build({
    required List<LearningItemEntity> items,
    required int currentLearningItemIndex,
    required int liveIndexInCurrentItem,

    /// Clip the narration is reading. When it sits past the live edge the list
    /// keeps emitting descriptors until the card carrying this clip exists —
    /// otherwise there is nothing to show a reader coming back to the app, since
    /// the list normally ends at the lesson's own position.
    ///
    /// Cards emitted for this reason are NOT progress: nothing about the lesson
    /// has advanced, and each renders read-only (see `QuizCardBody`'s preview
    /// branch). Pass -1 for "no narration to follow", which builds exactly what
    /// the live edge alone would.
    int revealToClipIndex = -1,
  }) {
    final cards = <KeypointCardDescriptor>[];
    final cardToClip = <int, int>{};
    var liveCardIndex = -1;
    var revealCardIndex = -1;

    // True while the reveal clip has been asked for and not yet emitted. This is
    // the ONLY reason a card past the live edge is built, and it goes false the
    // moment that card exists — so the list never grows further than it must.
    bool stillSeekingReveal() => revealToClipIndex >= 0 && revealCardIndex < 0;

    void emitCard(KeypointCardDescriptor descriptor, int? clipIndex) {
      cards.add(descriptor);
      if (clipIndex == null) return;
      cardToClip[cards.length - 1] = clipIndex;
      if (clipIndex == revealToClipIndex) revealCardIndex = cards.length - 1;
    }

    // Clip numbering counts theory documents across the WHOLE keypoint, in the
    // order the backend dubbed them — so it keeps advancing past the revealed
    // edge and must not be derived from the (growing) card list.
    var clipPosition = 0;
    for (var itemIndex = 0; itemIndex < items.length; itemIndex++) {
      final item = items[itemIndex];
      final isCurrentItem = itemIndex == currentLearningItemIndex;
      final isPastLiveItem = itemIndex > currentLearningItemIndex;
      if (isPastLiveItem && !stillSeekingReveal()) break;

      final isTheoryLike = item.type == LearningItemType.theory || item.type == LearningItemType.video;
      final isQuizLike = item.type == LearningItemType.exercise || item.type == LearningItemType.roleplay;
      if (!isTheoryLike && !isQuizLike) continue;

      final unitCount = isTheoryLike ? item.documents.length : item.questions.length;
      if (unitCount == 0) continue;

      // Video items are NOT dubbed — they carry their own audio, and the backend
      // leaves them out of its clip list (see `VoiceoverService.buildSegments`).
      // Roleplay items are not dubbed either (their lines are recorded), and
      // neither is the synthetic sub-question round `LessonCubit.reviewDone`
      // appends: those come from `subQuestions`, which the backend never dubs.
      // Counting any of them would shift every later clip index, so those cards
      // played a neighbour's clip (or ran past the end and played nothing).
      final isDubbed = isTheoryLike ? item.type == LearningItemType.theory : item.type == LearningItemType.exercise && !item.isPlayingSubQuestions;

      final liveUnitIndex = isCurrentItem ? math.min(liveIndexInCurrentItem, unitCount - 1) : unitCount - 1;

      for (var unitIndex = 0; unitIndex < unitCount; unitIndex++) {
        final withinLive = !isPastLiveItem && unitIndex <= liveUnitIndex;
        if (!withinLive && !stillSeekingReveal()) break;

        emitCard(
          isTheoryLike
              ? KeypointCardDescriptor.theory(learningItemId: item.id, documentIndex: unitIndex)
              : KeypointCardDescriptor.quiz(learningItemId: item.id, questionIndex: unitIndex),
          isDubbed ? clipPosition + unitIndex : null,
        );

        if (withinLive && isCurrentItem && unitIndex == liveUnitIndex) liveCardIndex = cards.length - 1;
      }

      // Advance by the item's FULL unit count, not by what was emitted: clip
      // numbering is the backend's, and it counts every dubbed unit whether the
      // reader has reached it or not.
      if (isDubbed) clipPosition += unitCount;
    }

    if (liveCardIndex < 0) liveCardIndex = cards.isEmpty ? 0 : cards.length - 1;
    // An unreachable bound is simply ignored rather than shortening anything.
    if (revealCardIndex < liveCardIndex) revealCardIndex = liveCardIndex;
    cards.add(const KeypointCardDescriptor.done());

    return BuiltKeypointCards(
      cards: cards,
      liveCardIndex: liveCardIndex,
      cardToClip: cardToClip,
      revealCardIndex: revealCardIndex,
    );
  }
}

class BuiltKeypointCards {
  const BuiltKeypointCards({
    required this.cards,
    required this.liveCardIndex,
    required this.cardToClip,
    required this.revealCardIndex,
  });

  /// Includes the trailing synthetic done card.
  final List<KeypointCardDescriptor> cards;

  /// Index of the current active real card (== `doneCardIndex - 1`, or the
  /// done card's own index when there is no real content at all).
  final int liveCardIndex;

  /// Flat card index → narration-clip index (theory cards only).
  final Map<int, int> cardToClip;

  /// Card carrying the clip narration is reading, when that sits past
  /// [liveCardIndex]; otherwise equal to it. Never below it — an unreachable
  /// bound reveals nothing.
  final int revealCardIndex;

  int get doneCardIndex => cards.length - 1;
}
