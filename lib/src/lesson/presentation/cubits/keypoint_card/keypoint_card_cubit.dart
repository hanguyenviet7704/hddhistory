part of '../../../lesson.dart';

/// View-layer sequencing + narration sync for the unified keypoint swipe
/// screen. Owns NONE of the domain progress/answer-checking logic — that
/// stays exactly where it already lived: [TheoryCubit] / [ExerciseCubit] /
/// [ChoiceCubit] (+ sibling exercise-type cubits) / [LessonCubit]. This cubit
/// only:
///
/// - turns [LessonState]'s existing item/document/question indices into a
///   flat, ordered list of swipeable [KeypointCardDescriptor]s — the SAME
///   traversal `LessonTimelineBuilder` used to build `ListView` widgets,
///   repurposed to build descriptors instead of widgets;
/// - points narration at the card on screen: each card has its own clip
///   (`keypoint.audio.segments`), so a card change just loads that clip. There
///   is no timeline to estimate and no way for the voice to run into a page the
///   reader hasn't opened — reaching the end of a card ends its clip;
/// - reconciles two indices: [KeypointCardState.viewedCardIndex] (freely
///   browsable backward) vs [KeypointCardState.furthestCardIndex]
///   (progress-gated forward). The forward gate is never duplicated here —
///   it's derived straight from [LessonState.currentLearningItemIndex] /
///   [LessonState.currentLessonIndex], which themselves only ever advance
///   once `TheoryCubit.nextDocument()` / `ExerciseCubit.nextQuestion()`'s
///   OWN existing gates (`TheoryState.canContinue`, a checked question's
///   stored result) allow it.
///
/// NOT annotated `@lazySingleton`/`@injectable` — mirrors [LessonAudioCubit]'s
/// existing precedent: this needs a FRESH instance per lesson-flow route
/// entry, wired to that SAME route's freshly-created [LessonAudioCubit]
/// (also not a singleton), not a process-lifetime singleton holding a stale
/// sibling. Constructed directly in `_buildLessonFlowPage`
/// (`routes_shell_course_lesson_data.dart`).
class KeypointCardCubit extends Cubit<KeypointCardState> {
  KeypointCardCubit({
    required LessonCubit lessonCubit,
    required TheoryCubit theoryCubit,
    required LessonAudioCubit audioCubit,
  }) : _lessonCubit = lessonCubit,
       _theoryCubit = theoryCubit,
       _audioCubit = audioCubit,
       super(KeypointCardState.initial()) {
    _previousCompletionOrigin = _lessonCubit.state.completionOrigin;
    _rebuildCards(_lessonCubit.state);
    _lessonSubscription = _lessonCubit.stream.listen(_onLessonStateChanged);
  }

  final LessonCubit _lessonCubit;
  final TheoryCubit _theoryCubit;
  final LessonAudioCubit _audioCubit;

  StreamSubscription<LessonState>? _lessonSubscription;

  /// Flat card index → its narration-clip index.
  ///
  /// Clips are numbered across the keypoint's theory documents in order, which
  /// is NOT the flat card index: quiz cards sit between theory cards and carry
  /// no narration. Only revealed theory cards appear here.
  Map<int, int> _cardToClip = const {};

  LessonCompletionOrigin _previousCompletionOrigin = LessonCompletionOrigin.none;

  bool _pausedForQuiz = false;

  /// Card whose clip is currently loaded in the player, so progress can be read
  /// off real playback instead of being inferred.
  int _loadedClipCardIndex = -1;

  // ---- Lookups consumed by the card widgets ----

  DocumentEntity documentForCard(KeypointCardDescriptor descriptor) {
    final item = _findLearningItem(descriptor.learningItemId);
    return item.documents.elementAtOrDefault(descriptor.documentIndex, defaultValue: const DocumentEntity());
  }

  QuestionEntity questionForCard(KeypointCardDescriptor descriptor) {
    final item = _findLearningItem(descriptor.learningItemId);
    return item.questions.elementAtOrDefault(descriptor.questionIndex, defaultValue: const QuestionEntity());
  }

  LearningItemEntity _findLearningItem(String id) {
    for (final item in _lessonCubit.state.pageData.items) {
      if (item.id == id) return item;
    }
    return const LearningItemEntity();
  }

  /// Fill fraction for the segmented pip bar (0..1). Quiz cards are binary —
  /// no partial credit while answering — and snap to 1 only once the
  /// question has a stored result; the live narrated theory card reflects
  /// real playback progress; every other card is fully filled once passed,
  /// empty otherwise.
  double progressForCard(int index) {
    final current = state;
    if (index < 0 || index >= current.cards.length) return 0;
    if (index < current.furthestCardIndex) return 1;
    if (index > current.furthestCardIndex) return 0;

    final descriptor = current.cards[index];
    if (descriptor.isDone) return 1;
    if (descriptor.isQuiz) return questionForCard(descriptor).hasResult ? 1 : 0;

    if (descriptor.isTheory && index == _loadedClipCardIndex) {
      // Real playback of THIS card's own clip — no estimate involved.
      final duration = _audioCubit.state.durationSeconds;
      if (duration <= 0) return 0.14;
      final elapsed = _audioCubit.state.positionSeconds;
      // Small floor so a card that has only just opened never looks empty.
      return (elapsed / duration).clamp(0.14, 1.0);
    }
    return 0;
  }

  // ---- Navigation entry points (swipe / pip tap) ----

  /// Called by the `PageView`'s `onPageChanged` (drag) or a pip tap. Only
  /// ever asked for an index already within `furthestCardIndex` — the
  /// `PageView` is built with `itemCount: furthestCardIndex + 1`, so forward
  /// swipe/tap past the live edge is structurally impossible, never a gate
  /// this cubit has to re-check.
  void viewCard(int index) {
    if (index == state.viewedCardIndex) return;
    if (index < 0 || index >= state.cards.length) return;
    final previousIndex = state.viewedCardIndex;
    emit(state.copyWith(viewedCardIndex: index));
    _reconcileQuizPause(previousIndex, index);
    _loadCardNarration(index);
  }

  /// Points the player at [index]'s own clip, so the card on screen is the one
  /// being read — swiping forward, swiping back to re-read, and tapping a pip all
  /// land here. Playback then simply ends with the card: nothing to seek, and no
  /// way to spill into a page the reader hasn't opened.
  ///
  /// Keypoints still on a single whole-keypoint dub have no per-card clips; there
  /// narration is left exactly as the reader set it (the audio button is the only
  /// control) until the keypoint is re-dubbed.
  void _loadCardNarration(int index) {
    if (!_audioCubit.hasCardClips) return;
    if (index < 0 || index >= state.cards.length) return;
    if (!state.cards[index].isTheory) return;

    final clipIndex = _cardToClip[index];
    if (clipIndex == null) return;

    // Keep talking if it was talking, and keep going when the previous card's
    // clip had simply run to its end — that is a reader listening through, not
    // one who asked for silence. A manual pause leaves both false, so it stays
    // quiet.
    final audioState = _audioCubit.state;
    final autoplay = audioState.isPlaying || audioState.hasCompletedPlayback;
    _loadedClipCardIndex = index;
    unawaited(_audioCubit.loadCard(clipIndex, autoplay: autoplay));
  }

  // ---- LessonState reactions ----

  void _onLessonStateChanged(LessonState lessonState) {
    _rebuildCards(lessonState);
  }

  void _rebuildCards(LessonState lessonState) {
    final completionJustTriggered = _previousCompletionOrigin == LessonCompletionOrigin.none && lessonState.completionOrigin != LessonCompletionOrigin.none;
    _previousCompletionOrigin = lessonState.completionOrigin;

    // Content not fetched yet (the state at route entry) is NOT the same thing
    // as "every card is done". Building the terminal done card here would make
    // it fire its empty-keypoint completion fallback immediately, completing
    // the keypoint and bouncing straight to KeypointCompleteRoute before the
    // user ever sees a single card. Hold at `initial`/no cards instead and let
    // `LessonPage`'s existing isLoading state own the screen until items land.
    if (lessonState.pageData.items.isEmpty && lessonState.status != LessonStatus.success) {
      if (state.status != KeypointCardStatus.initial || state.cards.isNotEmpty) {
        emit(state.copyWith(status: KeypointCardStatus.initial, cards: const [], viewedCardIndex: 0, furthestCardIndex: 0));
      }
      return;
    }

    final built = _buildCardList(lessonState);
    _cardToClip = built.cardToClip;

    final wasFollowingEdge = state.viewedCardIndex == state.furthestCardIndex;
    final nextFurthestIndex = completionJustTriggered ? built.doneCardIndex : built.liveCardIndex;
    final previousViewedIndex = state.viewedCardIndex.clamp(0, built.cards.length - 1);
    final nextViewedIndex = (completionJustTriggered || wasFollowingEdge) ? nextFurthestIndex : previousViewedIndex;

    emit(
      state.copyWith(
        status: KeypointCardStatus.ready,
        cards: built.cards,
        furthestCardIndex: nextFurthestIndex,
        viewedCardIndex: nextViewedIndex,
      ),
    );

    if (nextViewedIndex != previousViewedIndex) {
      _reconcileQuizPause(previousViewedIndex, nextViewedIndex);
      // Every card change takes narration with it, so the voice is always
      // reading the page on screen.
      _loadCardNarration(nextViewedIndex);
    }
  }

  /// How far into the CURRENT learning item the reader actually is.
  ///
  /// Deliberately not [LessonState.currentLessonIndex]: `nextLearningItem()`
  /// bumps the item index without resetting that value, so on the frame the
  /// keypoint crosses from a theory item into an exercise it still holds the
  /// last document's index (e.g. 11). Clamping that against the question count
  /// revealed EVERY question of the exercise at once and threw the reader onto
  /// the last one. Each content cubit owns an index that is always in range for
  /// the item it is bound to, so ask it instead.
  int _liveIndexForCurrentItem(LessonState lessonState, LearningItemEntity item) {
    switch (item.type) {
      case LearningItemType.theory:
      case LearningItemType.video:
        return _theoryCubit.state.currentLearningItem.id == item.id ? _theoryCubit.state.currentDocumentIndex : 0;
      case LearningItemType.exercise:
      case LearningItemType.roleplay:
        final exerciseCubit = AppDI.injector.get<ExerciseCubit>();
        return exerciseCubit.state.currentLearningItem.id == item.id ? exerciseCubit.state.currentQuestionIndex : 0;
      case LearningItemType.unknown:
        return 0;
    }
  }

  _BuiltKeypointCards _buildCardList(LessonState lessonState) {
    final cards = <KeypointCardDescriptor>[];
    final cardToClip = <int, int>{};
    var liveCardIndex = -1;

    final items = lessonState.pageData.items;

    if (items.isNotEmpty) {
      final lastItemIndex = math.min(lessonState.currentLearningItemIndex, items.length - 1);
      // Clip numbering counts theory documents across the WHOLE keypoint, in the
      // order the backend dubbed them — so it keeps advancing past the revealed
      // edge and must not be derived from the (growing) card list.
      var clipPosition = 0;
      for (var itemIndex = 0; itemIndex <= lastItemIndex; itemIndex++) {
        final item = items[itemIndex];
        final isCurrentItem = itemIndex == lessonState.currentLearningItemIndex;

        if (item.type == LearningItemType.theory || item.type == LearningItemType.video) {
          final documents = item.documents;
          if (documents.isEmpty) continue;
          final activeDocIndex = isCurrentItem ? math.min(_liveIndexForCurrentItem(lessonState, item), documents.length - 1) : documents.length - 1;
          for (var docIndex = 0; docIndex <= activeDocIndex; docIndex++) {
            cards.add(KeypointCardDescriptor.theory(learningItemId: item.id, documentIndex: docIndex));
            cardToClip[cards.length - 1] = clipPosition + docIndex;
            if (isCurrentItem && docIndex == activeDocIndex) liveCardIndex = cards.length - 1;
          }
          clipPosition += documents.length;
        } else if (item.type == LearningItemType.exercise || item.type == LearningItemType.roleplay) {
          final questions = item.questions;
          if (questions.isEmpty) continue;
          final activeQuestionIndex = isCurrentItem ? math.min(_liveIndexForCurrentItem(lessonState, item), questions.length - 1) : questions.length - 1;
          for (var questionIndex = 0; questionIndex <= activeQuestionIndex; questionIndex++) {
            cards.add(KeypointCardDescriptor.quiz(learningItemId: item.id, questionIndex: questionIndex));
            if (isCurrentItem && questionIndex == activeQuestionIndex) liveCardIndex = cards.length - 1;
          }
        }
      }
    }

    if (liveCardIndex < 0) liveCardIndex = cards.isEmpty ? 0 : cards.length - 1;
    cards.add(const KeypointCardDescriptor.done());

    return _BuiltKeypointCards(
      cards: cards,
      liveCardIndex: liveCardIndex,
      cardToClip: cardToClip,
    );
  }

  /// Quiz cards are narration-silent: entering an unanswered one pauses
  /// playback (if it was playing) so narration doesn't keep advancing behind
  /// the user's back while they answer; only resumes automatically when
  /// leaving back onto a theory card, and only if THIS cubit was the one that
  /// paused it — a user-initiated pause stays paused.
  void _reconcileQuizPause(int previousIndex, int nextIndex) {
    if (previousIndex == nextIndex) return;
    final cards = state.cards;
    if (nextIndex < 0 || nextIndex >= cards.length) return;
    final nextDescriptor = cards[nextIndex];

    if (nextDescriptor.isQuiz && !questionForCard(nextDescriptor).hasResult) {
      if (_audioCubit.state.isPlaying) {
        _pausedForQuiz = true;
        unawaited(_audioCubit.pause());
      }
      return;
    }

    if (_pausedForQuiz && nextDescriptor.isTheory) {
      _pausedForQuiz = false;
      unawaited(_audioCubit.play());
    } else if (!nextDescriptor.isTheory) {
      _pausedForQuiz = false;
    }
  }

  @override
  Future<void> close() {
    unawaited(_lessonSubscription?.cancel());
    return super.close();
  }
}

class _BuiltKeypointCards {
  const _BuiltKeypointCards({
    required this.cards,
    required this.liveCardIndex,
    required this.cardToClip,
  });

  /// Includes the trailing synthetic done card.
  final List<KeypointCardDescriptor> cards;

  /// Index of the current active real card (== `doneCardIndex - 1`, or the
  /// done card's own index when there is no real content at all).
  final int liveCardIndex;

  /// Flat card index → narration-clip index (theory cards only).
  final Map<int, int> cardToClip;

  int get doneCardIndex => cards.length - 1;
}
