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

    /// Merged-mode counterpart of [revealToClipIndex]: reveal until the card
    /// with this IDENTITY exists. Cues carry (learningItemId, documentIndex),
    /// never a clip index, so the merged deck reveals by identity and the two
    /// numbering spaces never have to be reconciled.
    ({String learningItemId, int documentIndex})? revealToCard,
  }) {
    final cards = <KeypointCardDescriptor>[];
    final cardToClip = <int, int>{};
    final narratableClips = <int>{};
    var liveCardIndex = -1;
    var revealCardIndex = -1;

    // True while the reveal target has been asked for and not yet emitted. This
    // is the ONLY reason a card past the live edge is built, and it goes false
    // the moment that card exists — so the list never grows further than it must.
    bool stillSeekingReveal() => (revealToClipIndex >= 0 || revealToCard != null) && revealCardIndex < 0;

    void emitCard(KeypointCardDescriptor descriptor, int? clipIndex) {
      cards.add(descriptor);
      if (revealToCard != null && descriptor.learningItemId == revealToCard.learningItemId && descriptor.documentIndex == revealToCard.documentIndex) {
        revealCardIndex = cards.length - 1;
      }
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

      // Exercise/roleplay items contribute NO cards: the exercise flow was cut
      // from the keypoint screen (PO decision, 2026-07-30) — a keypoint is read
      // theory card by theory card, sequentially. Their DUBBED question clips
      // still occupy slots in the backend's clip numbering though, so
      // `clipPosition` must advance past them exactly as before or every theory
      // card after an exercise item plays a neighbour's clip. The same rule
      // in the other direction: video items contribute cards but no clips (the
      // backend leaves them out of its list — `VoiceoverService.buildSegments`),
      // and the synthetic sub-question round (`isPlayingSubQuestions`) is never
      // dubbed at all.
      if (isQuizLike) {
        final isDubbedExercise = item.type == LearningItemType.exercise && !item.isPlayingSubQuestions;
        if (isDubbedExercise) clipPosition += item.questions.length;
        continue;
      }

      final unitCount = item.documents.length;
      if (unitCount == 0) continue;

      final isDubbed = item.type == LearningItemType.theory;

      final liveUnitIndex = isCurrentItem ? math.min(liveIndexInCurrentItem, unitCount - 1) : unitCount - 1;

      for (var unitIndex = 0; unitIndex < unitCount; unitIndex++) {
        final withinLive = !isPastLiveItem && unitIndex <= liveUnitIndex;
        if (!withinLive && !stillSeekingReveal()) break;

        emitCard(
          KeypointCardDescriptor.theory(learningItemId: item.id, documentIndex: unitIndex),
          isDubbed ? clipPosition + unitIndex : null,
        );

        if (withinLive && isCurrentItem && unitIndex == liveUnitIndex) liveCardIndex = cards.length - 1;
      }

      // Advance by the item's FULL unit count, not by what was emitted: clip
      // numbering is the backend's, and it counts every dubbed unit whether the
      // reader has reached it or not.
      if (isDubbed) clipPosition += unitCount;
    }

    // Which clip indices belong to the reading flow at all, across the WHOLE
    // keypoint (not just the built prefix). This is what keeps the background
    // queue from reading exercise questions aloud: their clips exist in
    // `segments` but no longer belong to anything on screen.
    var narratablePosition = 0;
    for (final item in items) {
      if (item.type == LearningItemType.theory) {
        for (var i = 0; i < item.documents.length; i++) {
          narratableClips.add(narratablePosition + i);
        }
        narratablePosition += item.documents.length;
      } else if (item.type == LearningItemType.exercise && !item.isPlayingSubQuestions) {
        narratablePosition += item.questions.length;
      }
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
      narratableClips: narratableClips,
    );
  }
}

class BuiltKeypointCards {
  const BuiltKeypointCards({
    required this.cards,
    required this.liveCardIndex,
    required this.cardToClip,
    required this.revealCardIndex,
    required this.narratableClips,
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

  /// Clip indices that belong to the reading flow, across the whole keypoint —
  /// theory documents only. Exercise-question clips exist in `segments` but are
  /// narrated nowhere since the exercise flow left this screen; the background
  /// queue filters on this.
  final Set<int> narratableClips;

  int get doneCardIndex => cards.length - 1;
}
