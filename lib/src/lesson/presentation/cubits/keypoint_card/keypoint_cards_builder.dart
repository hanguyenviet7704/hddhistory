part of '../../../lesson.dart';

/// The keypoint's takeaway/summary theory item — authored as "Take This With
/// You" / "Bỏ túi ngay": a theory with exactly ONE document whose first block
/// is a caption, seeded alongside the main reading (titles carry a "(2)"
/// suffix, but the SHAPE is the contract, not the title).
///
/// It no longer contributes a card of its own: its bullets are the back face
/// of the deck's terminal recap flip card ([KeypointDoneCard]), so rendering it
/// as a card too would show the reader the same summary twice in a row.
/// The keypoint's takeaway/summary material, resolved from [items] by
/// POSITION, not by content sniffing. Authoring styles vary and keep changing
/// (a "Bỏ túi ngay" caption block, a "🔑 KEY TAKEAWAY" text line, tomorrow
/// something else), so the contract is structural: the reading deck is the
/// run of theories carrying more than one page, and whatever single-page
/// theories TRAIL the last of those are summary material. They fold into the
/// recap flip card instead of appearing as cards of their own; the last of
/// them that actually carries text is THE takeaway — the recap's back face
/// and the clip narration reads on the recap card.
///
/// A keypoint whose every theory is single-page resolves to none: folding
/// them away would leave nothing to read, so they stay ordinary cards.
class TakeawaySummary {
  const TakeawaySummary.none() : itemIndex = -1, hiddenItemIndexes = const {};
  const TakeawaySummary({required this.itemIndex, required this.hiddenItemIndexes});

  /// Index into the item list of THE takeaway, -1 when the keypoint has none.
  final int itemIndex;

  /// Item indexes folded into the recap — the whole trailing single-page run,
  /// which absorbs duplicated takeaway seeds instead of rendering the spare
  /// copy as a card.
  final Set<int> hiddenItemIndexes;

  bool get exists => itemIndex >= 0;
}

TakeawaySummary resolveTakeawaySummary(List<LearningItemEntity> items) {
  final theoryIndexes = <int>[];
  for (var i = 0; i < items.length; i++) {
    if (items[i].type == LearningItemType.theory) theoryIndexes.add(i);
  }
  final trailing = <int>[];
  for (final i in theoryIndexes.reversed) {
    if (items[i].documents.length != 1) break;
    trailing.add(i);
  }
  if (trailing.isEmpty || trailing.length == theoryIndexes.length) return const TakeawaySummary.none();
  // Reverse order — the keypoint's very last theory first, so the takeaway is
  // the LAST trailing item that has text to show.
  for (final i in trailing) {
    if (items[i].takeawaySummaryText.isNotEmpty) {
      return TakeawaySummary(itemIndex: i, hiddenItemIndexes: trailing.toSet());
    }
  }
  return const TakeawaySummary.none();
}

extension TakeawaySummaryItemX on LearningItemEntity {
  /// This item's text blocks flattened for the recap card's back face, in ALL
  /// FIVE languages. NOT a takeaway test — whether an item is the takeaway is
  /// positional ([resolveTakeawaySummary]); any single-page theory answers here.
  ///
  /// Multi-language on purpose. A saved card stores this text as a SNAPSHOT
  /// (the recap is derived here, not a stored field on the keypoint — see
  /// [SavedCardEntity]), and a snapshot of one language is a card that stops
  /// following the reader: save in Vietnamese, switch the app to English, and
  /// the Library shows an English title over a Vietnamese body (reported
  /// on-device 2026-09-10). Flattening per language costs nothing here — the
  /// source blocks already carry all five — and keeps the snapshot honest.
  BaseMultiLanguage get takeawaySummary => BaseMultiLanguage(
    en: _flattenTakeaway((content) => content.en),
    vi: _flattenTakeaway((content) => content.vi),
    zh: _flattenTakeaway((content) => content.zh),
    ja: _flattenTakeaway((content) => content.ja),
    ko: _flattenTakeaway((content) => content.ko),
  );

  /// The recap in the language the app is showing right now. Kept as the
  /// reading path for the card on screen; the SAVE path wants
  /// [takeawaySummary] instead.
  String get takeawaySummaryText => takeawaySummary.text;

  /// One language's worth. `pick` reads that language off each block, so a
  /// language nobody authored comes back empty rather than borrowing another
  /// — `BaseMultiLanguage.text` already owns the fallback order, and baking a
  /// fallback in here would freeze the card into whichever language happened
  /// to exist on the day it was saved.
  String _flattenTakeaway(String Function(BaseMultiLanguage) pick) {
    if (documents.isEmpty) return '';
    final joined = documents.first.document
        .where((block) => block.type == ContentDocumentType.text)
        .map((block) => pick(block.data.content).trim())
        .where((text) => text.isNotEmpty)
        .join('\n\n');
    // Some authored variants embed their own heading line ("🔑 KEY TAKEAWAY")
    // and inline HTML in the block; the card draws its own heading, so drop
    // the marker line and flatten the tags. A no-op for plain bullet lines.
    final text = joined
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '');
    final lines = text.split('\n').map((line) => line.trim()).toList();
    while (lines.isNotEmpty && (lines.first.isEmpty || lines.first.startsWith('🔑'))) {
      lines.removeAt(0);
    }
    return lines.join('\n').trim();
  }
}

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

    // The takeaway's dubbed clips belong to the DONE card (its back face is
    // the takeaway text). Located in a pass over ALL items, NOT inside the
    // card walk below: that walk breaks at the live edge, and the takeaway
    // sits past the last readable item — inside the walk it was simply never
    // reached, so the done card never got its clips (recap tap-to-read dead,
    // 2026-08-07). Position accounting mirrors the walk's exactly.
    final takeaway = resolveTakeawaySummary(items);
    String? takeawayItemId;
    var takeawayClipStart = -1;
    var takeawayClipCount = 0;
    {
      var position = 0;
      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        if (item.type == LearningItemType.theory) {
          if (i == takeaway.itemIndex) {
            takeawayItemId = item.id;
            takeawayClipStart = position;
            takeawayClipCount = item.documents.length;
          }
          position += item.documents.length;
        } else if (item.type == LearningItemType.exercise && !item.isPlayingSubQuestions) {
          position += item.questions.length;
        }
      }
    }
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

      // The takeaway summary is content, but not a card of its own — it IS the
      // recap flip card's back face, and its dubbed clips are re-pointed at
      // the done card after the walk (so narration reads it and the deck
      // follows onto the recap, exactly like every other card). Here it only
      // has to keep its slots in the clip numbering — the anchor itself was
      // resolved in the pre-pass above, so a duplicated summary seed can't
      // re-point it.
      if (takeaway.hiddenItemIndexes.contains(itemIndex)) {
        clipPosition += item.documents.length;
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
        // The takeaway's clips are narratable too — their on-screen card is
        // the terminal recap card, wired up right below.
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

    // The done card carries the takeaway's clips: narration pointing works
    // when the reader lands on it, and a reveal aimed at the takeaway (by clip
    // index or by cue identity) resolves to it — so listening scrolls the deck
    // onto the recap card exactly like any other card.
    final doneCardIndex = cards.length - 1;
    if (takeawayItemId != null && takeawayClipStart >= 0 && takeawayClipCount > 0) {
      cardToClip[doneCardIndex] = takeawayClipStart;
      final clipHit = revealToClipIndex >= takeawayClipStart && revealToClipIndex < takeawayClipStart + takeawayClipCount;
      final cueHit = revealToCard != null && revealToCard.learningItemId == takeawayItemId;
      if (clipHit || cueHit) revealCardIndex = doneCardIndex;
    }

    return BuiltKeypointCards(
      cards: cards,
      liveCardIndex: liveCardIndex,
      cardToClip: cardToClip,
      revealCardIndex: revealCardIndex,
      narratableClips: narratableClips,
      takeawayLearningItemId: takeawayItemId,
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
    this.takeawayLearningItemId,
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

  /// Learning-item id of the takeaway summary, when the keypoint has one. Cues
  /// carry (learningItemId, documentIndex) and the takeaway has no theory card
  /// to match — its card is the terminal done card, and the cubit needs this id
  /// to make that resolution.
  final String? takeawayLearningItemId;

  int get doneCardIndex => cards.length - 1;
}
