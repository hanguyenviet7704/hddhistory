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
class KeypointCardCubit extends Cubit<KeypointCardState> with WidgetsBindingObserver {
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
    _audioSubscription = _audioCubit.stream.listen(_onAudioStateChanged);
    // Merged mode: `canContinue` (the explanation-choice gate) changes on
    // TheoryCubit emits that never reach LessonCubit, and the allowed-cue
    // bound must follow it at once — the voice would otherwise sail through
    // a boundary the deck meant to hold.
    _theorySubscription = _theoryCubit.stream.listen((_) => _pushAllowedThroughCue());
    // Whether the app is on screen decides who walks narration forward — this
    // cubit, or the player reading on by itself (see [_listenOnWhileAway]).
    WidgetsBinding.instance.addObserver(this);
    _pushAllowedThroughCue();
  }

  final LessonCubit _lessonCubit;
  final TheoryCubit _theoryCubit;
  final LessonAudioCubit _audioCubit;

  StreamSubscription<LessonState>? _lessonSubscription;
  StreamSubscription<LessonAudioState>? _audioSubscription;
  StreamSubscription<TheoryState>? _theorySubscription;

  /// Merged-mode reveal target (card IDENTITY), the cue-map counterpart of
  /// [_revealToClipIndex]. Same lifetime rules: fed back into every rebuild,
  /// cleared once the live edge catches up.
  ({String learningItemId, int documentIndex})? _revealToCardTarget;

  /// Last cue index acted on, so one boundary crossing moves the deck exactly
  /// once (the audio cubit re-emits state for position ticks too).
  int _lastSeenCueIndex = -1;

  /// Flat card index → its narration-clip index.
  ///
  /// Clips are numbered across the keypoint's theory documents and exercise
  /// questions in item order, which is NOT the flat card index: a video or
  /// roleplay item contributes cards but no clips. Only revealed cards appear
  /// here.
  Map<int, int> _cardToClip = const {};

  /// Clip narration reached while the app was off screen, or -1 when the deck and
  /// the voice are in step.
  ///
  /// Kept OUTSIDE state on purpose: `_rebuildCards` re-derives
  /// `furthestCardIndex` from the lesson on every lesson emit, so a reveal stored
  /// only in state would be wiped on the next tick. This is the input that
  /// survives and is fed back into every rebuild.
  int _revealToClipIndex = -1;

  LessonCompletionOrigin _previousCompletionOrigin = LessonCompletionOrigin.none;

  /// Holds the view on the FIRST card for as long as the reader has not moved
  /// the deck themselves — see [_rebuildCards].
  ///
  /// Not a one-shot "first build" flag: opening a keypoint produces a burst of
  /// rebuilds (LessonCubit emits `currentLearningItemIndex: 0`, then the first
  /// readable item, then the loaded item, then TheoryCubit restores its document
  /// index), and the live edge only climbs to the stored position somewhere in
  /// the middle of that burst. A flag cleared on the first build would let the
  /// very next one jump to the restored edge, which is exactly what it did.
  ///
  /// Cleared by [viewCard] and by [releaseEntryPin].
  bool _entryPinActive = true;

  /// Releases the entry pin for a deliberate forward move that does NOT go
  /// through [viewCard].
  ///
  /// The live-edge swipe is one: it reveals the next card (`nextDocument()` /
  /// `nextQuestion()`) and lets `wasFollowingEdge` carry the view along, so it
  /// never calls [viewCard] — and the pin then held the view on card 1 while the
  /// new card appeared behind it. On the first card of a fresh keypoint, where
  /// the live edge IS card 1, that swallowed the reader's swipe outright: they
  /// swiped, nothing moved, and the deck only caught up when narration finished
  /// the card and turned the page for them.
  // ignore: use_setters_to_change_properties
  void releaseEntryPin() => _entryPinActive = false;

  bool _pausedForQuiz = false;

  /// Whether the clip that has finished was already acted on, so one completion
  /// turns exactly one page. `hasCompletedPlayback` stays true until another clip
  /// loads, and any later emit on the audio cubit would otherwise read as a
  /// second completion — that is the shape the old audio-driven paging cascaded
  /// through, advancing several cards from one clip.
  bool _completionHandled = false;

  /// Card whose clip is currently loaded in the player, so progress can be read
  /// off real playback instead of being inferred.
  int _loadedClipCardIndex = -1;

  /// The card the player is reading RIGHT NOW, or -1 when narration isn't scoped
  /// to a card at all (a keypoint still dubbed as one whole file, or one with no
  /// clip for this card). Anything syncing itself to the voice — the pip fill, the
  /// text auto-scroll — has to gate on this: with a whole-keypoint file the
  /// position/duration pair describes the keypoint, not the page on screen, so
  /// treating it as page progress moves the text by a fraction of a percent per
  /// second and reads as nothing happening at all.
  int get loadedClipCardIndex => _loadedClipCardIndex;

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
    // Left of where the reader/voice currently stands reads as PASSED — the
    // bar is a position indicator. Without this, a lock-screen seek that
    // jumped several cards left the skipped pips empty: a hole in the middle
    // of the bar ("tua ngoài nền xong quay lại thanh bị trống giữa").
    if (index < current.viewedCardIndex && index <= current.revealBound) return 1;
    // Past the live edge but within reach means narration read ahead to it, so
    // let the theory branch below show real playback rather than an empty pip.
    if (index > current.revealBound) return 0;
    if (index > current.furthestCardIndex && index != _loadedClipCardIndex) return 0;

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
  /// Highest card index the in-lesson paywall lets the reader reach, or `null`
  /// when nothing gates this keypoint.
  ///
  /// Owned by `KeypointCardShell`, which holds the paywall decision (config,
  /// premium, which keypoint is armed) and pushes the resulting bound down here.
  /// This cubit only enforces it — it deliberately knows nothing about paywalls.
  int? _paywallCardCap;

  // ignore: use_setters_to_change_properties
  void setPaywallCardCap(int? cap) => _paywallCardCap = cap;

  /// Whether the view already sits on the last card the paywall allows, so
  /// revealing another one would hand over paid content.
  bool get isAtPaywallWall {
    final cap = _paywallCardCap;
    return cap != null && state.viewedCardIndex >= cap;
  }

  /// Called by the `PageView`'s `onPageChanged` (drag) or a pip tap. Only
  /// ever asked for an index already within `furthestCardIndex` — the
  /// `PageView` is built with `itemCount: furthestCardIndex + 1`, so forward
  /// swipe/tap past the live edge is structurally impossible, never a gate
  /// this cubit has to re-check.
  /// [startAt] is the resume path only: narration is already playing this card
  /// mid-clip, so the source is reloaded out of queue mode at that position
  /// instead of restarting the card. It also bypasses the same-index early
  /// return — coming back onto the card the reader left still has to leave queue
  /// mode, or the voice would walk off the page again at the end of the clip.
  void viewCard(int index, {Duration? startAt}) {
    // The paywall wall is enforced HERE rather than at each call site because
    // the deck is driven from four of them — the reader's swipe, a progress-pip
    // tap, the voice turning the page, and the return-from-background jump —
    // and only the swipe goes through the widget that knows about the paywall.
    // Walling that one alone left the other three walking straight past it.
    final cap = _paywallCardCap;
    if (cap != null && index > cap) index = cap;

    if (index == state.viewedCardIndex && startAt == null) return;
    if (index < 0 || index >= state.cards.length) return;
    // TEMP-DEBUG(deck): remove once the entry position and the paywall wall are
    // both confirmed settled.
    LogDev.warning('[DeckDbg] viewCard($index) from=${state.viewedCardIndex} pinWas=$_entryPinActive cap=$cap startAt=$startAt');
    // A deliberate move off the entry card — swipe, pip tap, the voice turning
    // the page, or the return-from-background jump. From here on the deck is
    // being driven, so it may follow the live edge again (see [_entryPinActive]).
    _entryPinActive = false;
    final previousIndex = state.viewedCardIndex;
    emit(state.copyWith(viewedCardIndex: index));
    _reconcileQuizPause(previousIndex, index);
    _loadCardNarration(index, startAt: startAt);
  }

  /// Points the player at [index]'s own clip, so the card on screen is the one
  /// being read — swiping forward, swiping back to re-read, and tapping a pip all
  /// land here. Playback then simply ends with the card: nothing to seek, and no
  /// way to spill into a page the reader hasn't opened.
  ///
  /// Keypoints still on a single whole-keypoint dub have no per-card clips; there
  /// narration is left exactly as the reader set it (the audio button is the only
  /// control) until the keypoint is re-dubbed.
  void _loadCardNarration(int index, {Duration? startAt}) {
    // Merged mode: one file, so pointing narration at a card is a SEEK to its
    // cue — never a source reload. Identity lookup, no clip arithmetic.
    if (_audioCubit.isMergedMode) {
      if (index < 0 || index >= state.cards.length) return;
      final descriptor = state.cards[index];
      if (!descriptor.isTheory) return;
      final cueIndex = _audioCubit.cueForCard(
        learningItemId: descriptor.learningItemId,
        documentIndex: descriptor.documentIndex,
      );
      if (cueIndex == null) return;
      final previousNarratedIndex = _loadedClipCardIndex;
      _loadedClipCardIndex = index;
      // The voice is already reading this very cue (deck following player):
      // do NOT seek — that restarts the sentence mid-word.
      if (cueIndex == _audioCubit.state.activeCueIndex && startAt == null) return;
      final audioState = _audioCubit.state;
      // Moving FORWARD onto a new card is a listening intent in itself ("mở
      // loa lên luôn", user call 2026-08-04): the reader just answered the
      // question card or swiped on, and the next card must start talking even
      // when the carry flags (playing / just-completed) got consumed along
      // the way. Requires a started session so a silent read-mode entry
      // never starts speaking by itself; backward swipes keep the old carry
      // rule.
      final movingForward = audioState.hasStartedSession && index > previousNarratedIndex;
      final autoplay = startAt != null || audioState.isPlaying || audioState.hasCompletedPlayback || movingForward;
      unawaited(_audioCubit.playCue(cueIndex, autoplay: autoplay, offset: startAt));
      return;
    }

    if (!_audioCubit.hasCardClips) return;
    if (index < 0 || index >= state.cards.length) return;

    // Whether this card has a clip at all is `_cardToClip`'s answer, not the
    // card type's: theory cards are read in full and exercise cards have their
    // question read, while video/roleplay cards carry their own audio.
    final clipIndex = _cardToClip[index];
    if (clipIndex == null) return;
    if (!_audioCubit.hasClipAt(clipIndex)) return;

    // Keep talking if it was talking, and keep going when the previous card's
    // clip had simply run to its end — that is a reader listening through, not
    // one who asked for silence. A manual pause leaves both false, so it stays
    // quiet.
    // A resume always keeps playing: the voice was mid-sentence when the reader
    // came back, and `isPlaying` is not a reliable read of that — coming out of
    // queue mode the player is between sources.
    final audioState = _audioCubit.state;
    final autoplay = startAt != null || audioState.isPlaying || audioState.hasCompletedPlayback;
    _loadedClipCardIndex = index;
    unawaited(_audioCubit.loadCard(clipIndex, autoplay: autoplay, startAt: startAt));
  }

  // ---- LessonState reactions ----

  void _onLessonStateChanged(LessonState lessonState) {
    _rebuildCards(lessonState);
  }

  /// Reaching the end of a card's clip turns the page, exactly as the reader's
  /// own swipe would — that is what makes the screen read itself instead of
  /// waiting to be pushed.
  ///
  /// The last page is included: reading a keypoint to its end IS finishing it, so
  /// the clip running out there completes the keypoint exactly as the final swipe
  /// would. (This deliberately does NOT resurrect the old "audio finished →
  /// complete the keypoint, skipping the quiz" shortcut — completion still comes
  /// from the last card being reached in order, and an unanswered quiz card below
  /// still stops the deck dead.)
  ///
  /// Two deliberate places it refuses to turn:
  ///
  /// - **An exercise card.** Its clip reads the question and then the deck holds:
  ///   the reader has to answer, and a page that walked itself past the question
  ///   would be answering for them.
  /// - **A card still owing an explanation choice** (`TheoryCubit.canContinue`) —
  ///   the same gate the swipe has.
  void _onAudioStateChanged(LessonAudioState audioState) {
    // The clips may have arrived after the cards did (see
    // [_ensureNarrationOnViewedCard]) — this is the other half of that.
    _ensureNarrationOnViewedCard();

    // Merged mode: the file plays THROUGH open boundaries without stopping,
    // so "the voice moved on" arrives as a cue change, not a completion.
    if (_audioCubit.isMergedMode && audioState.activeCueIndex >= 0 && audioState.activeCueIndex != _lastSeenCueIndex) {
      _lastSeenCueIndex = audioState.activeCueIndex;
      _onMergedCueChanged(audioState.activeCueIndex);
    }

    if (!audioState.hasCompletedPlayback) {
      _completionHandled = false;
      return;
    }
    if (_completionHandled) return;

    // Narration is off reading the rest of the keypoint on its own, so this
    // completion is the END of that whole run — not "the page on screen
    // finished". Turning a card here would turn one the voice left behind
    // several clips ago.
    if (_audioCubit.isAheadOfDeck) {
      _completionHandled = true;
      return;
    }

    final index = state.viewedCardIndex;

    // Merged mode: a completion may only drive the deck when the app is ON
    // screen and the voice ended on the very cue of the card being viewed.
    // Backgrounded, the file plays ahead of the deck — acting on its end here
    // would advance (or complete) from wherever the reader left the deck,
    // which is the merged equivalent of the isAheadOfDeck case above. The
    // resumed path reveals to wherever the voice got instead.
    if (_audioCubit.isMergedMode) {
      if (_isBackgrounded) {
        _completionHandled = true;
        return;
      }
      final descriptor = (index >= 0 && index < state.cards.length) ? state.cards[index] : null;
      final viewedCue = descriptor != null && descriptor.isTheory
          ? _audioCubit.cueForCard(learningItemId: descriptor.learningItemId, documentIndex: descriptor.documentIndex)
          : null;
      if (viewedCue == null || viewedCue != audioState.activeCueIndex) {
        _completionHandled = true;
        return;
      }
    }
    // Only the clip of the card ON SCREEN may turn that card. On a keypoint
    // dubbed as one whole file `_loadedClipCardIndex` is -1, so this never fires:
    // "the audio finished" there means the whole keypoint, not this page.
    if (_loadedClipCardIndex != index) return;
    if (index < 0 || index >= state.cards.length) return;

    _completionHandled = true;

    // An exercise card: its clip has read the QUESTION (the backend never dubs
    // the options) and the deck holds here — answering is the reader's to do,
    // confirmed as the intended flow on 2026-07-30. Off screen there is nobody
    // to answer, so the voice reads on alone.
    if (!state.cards[index].isTheory) {
      _listenOnWhileAway();
      return;
    }

    // A card the reader had already passed — the next one is revealed, so this is
    // just moving the view (and narration with it) forward through the deck.
    if (index < state.furthestCardIndex) {
      viewCard(index + 1);
      return;
    }

    // The in-lesson paywall stands here. The voice must not read its way past a
    // wall the reader cannot swipe past: this is the path that REVEALS the next
    // card, so letting it through hands over the paid content and lifts
    // `furthestCardIndex` above the wall, after which every other bound in this
    // deck (the drag's `clamp(0, furthestCardIndex)`, the progress pips) happily
    // follows. Not `_listenOnWhileAway()` either — that reads the rest of the
    // keypoint aloud, which is the same giveaway through the speaker.
    if (isAtPaywallWall) return;

    if (!_theoryCubit.state.canContinue) {
      _listenOnWhileAway();
      return;
    }
    // On the keypoint's last document this runs through `nextLearningItem()`
    // into `completeCurrentKeypoint()` — deliberate (product decision,
    // 2026-07-30): a keypoint is read theory card by theory card, and hearing
    // the final card out IS finishing the lesson. A guard against this briefly
    // existed, added while a stream-replay bug was burning through all cards in
    // seconds and "completing" keypoints nobody had listened to; with that
    // fixed (see LessonAudioCubit's completed-listener), auto-completion at the
    // true end is the wanted behaviour again.
    _theoryCubit.nextDocument();
  }

  /// Hands the rest of the keypoint to the player when the deck has refused to
  /// turn AND the app is off screen.
  ///
  /// The two gates the deck holds at — an unanswered question, and an
  /// explanation the reader still owes a choice on — both exist to stop a page
  /// from acting on the reader's behalf. Backgrounded there is no page and no
  /// way to act: the reader is looking at the OS now-playing controls, which
  /// promise an ordinary audio player. So the voice reads on, and the deck stays
  /// exactly where they left it.
  void _listenOnWhileAway() {
    // Merged mode: background continuation is automatic — the file simply
    // keeps playing and [_pushAllowedThroughCue] lifts the bound on lifecycle
    // change. The legacy queue would fight the single source.
    if (_audioCubit.isMergedMode) return;
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    // Anything short of genuinely backgrounded counts as on screen. `inactive`
    // in particular is the half-second of pulling down notification centre or
    // taking a call — the deck is still there and still the reader's to drive,
    // and reading ahead for it would need undoing the moment they let go.
    // A null state (before the first lifecycle event) reads as on screen too:
    // never read ahead on a guess.
    if (lifecycle == null || lifecycle == AppLifecycleState.resumed || lifecycle == AppLifecycleState.inactive) return;
    if (!_audioCubit.hasCardClips) return;
    unawaited(_audioCubit.playRestOfKeypoint());
  }

  /// Whether the app is genuinely off screen (merged-mode gate + follow rules
  /// relax there). `inactive`/null count as ON screen — same reasoning as
  /// [_listenOnWhileAway].
  bool get _isBackgrounded {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    return !(lifecycle == null || lifecycle == AppLifecycleState.resumed || lifecycle == AppLifecycleState.inactive);
  }

  /// Cue bound for the paywall CARD cap, computed over the keypoint's FULL
  /// card walk (straight from the lesson items) — never from the
  /// incrementally built deck. At entry only card 0 exists, and bounding by
  /// built cards made the wall bite one card early: the voice stalled at the
  /// end of the FIRST card of a plain-theory keypoint even though the free
  /// allowance was two ("card đầu chỉ có theory phải chạy bình thường",
  /// 2026-08-04). The walk mirrors [KeypointCardsBuilder]: theory + video
  /// documents are cards, theory documents carry the cues, in item order —
  /// the same order the merged cue list is built in.
  ///
  /// Null = nothing to bound yet (items still loading) — treat as unbounded;
  /// the first cue outlasts the entry burst by an order of magnitude.
  int? _cueBoundForCardCap(int cap) {
    var cardIndex = -1;
    var cueIndex = -1;
    int? lastAllowedAudibleCue;
    for (final item in _lessonCubit.state.pageData.items) {
      final isTheory = item.type == LearningItemType.theory;
      final isVideo = item.type == LearningItemType.video;
      if (!isTheory && !isVideo) continue;
      for (var d = 0; d < item.documents.length; d++) {
        cardIndex++;
        if (isTheory) cueIndex++;
        if (cardIndex > cap) return lastAllowedAudibleCue;
        if (isTheory) lastAllowedAudibleCue = cueIndex;
      }
    }
    return lastAllowedAudibleCue;
  }

  /// Last audible cue among the built cards up to [cardBound], or null when
  /// none of them is dubbed (entry burst, empty deck).
  int? _lastAudibleCueUpTo(int cardBound) {
    int? found;
    for (var index = 0; index <= cardBound && index < state.cards.length; index++) {
      final descriptor = state.cards[index];
      if (!descriptor.isTheory) continue;
      final cue = _audioCubit.cueForCard(
        learningItemId: descriptor.learningItemId,
        documentIndex: descriptor.documentIndex,
      );
      if (cue != null) found = cue;
    }
    return found;
  }

  /// Highest cue the voice may play INTO without stopping.
  ///
  /// The flow rules (user call, 2026-08-04): BACKGROUNDED the voice reads
  /// straight through everything — questions included — because the lock
  /// screen promises an ordinary audio player. IN THE APP an interactive card
  /// (a `canContinue` gate: choice/question) holds the voice at the END of
  /// its own cue — the question gets read aloud, then narration waits for the
  /// answer; answering lifts the bound and [_resumeNarrationIfGateOpened]
  /// presses play. The gate only lives at the LIVE EDGE: revealed (read-only)
  /// question cards cannot be answered, so holding on them would deadlock —
  /// and the crossing-based clamp in [LessonAudioCubit._onMergedTick] already
  /// leaves a voice that is PAST the bound alone. The paywall wall wins over
  /// everything, background included.
  void _pushAllowedThroughCue() {
    if (!_audioCubit.isMergedMode) return;
    if (_audioCubit.timeline == null) return;

    final cap = _paywallCardCap;
    final capCue = cap == null ? null : _cueBoundForCardCap(cap);

    int? gateCue;
    if (!_isBackgrounded && !_theoryCubit.state.canContinue) {
      gateCue = _lastAudibleCueUpTo(state.furthestCardIndex);
    }

    var bound = LessonAudioCubit.unboundedCue;
    if (capCue != null && capCue < bound) bound = capCue;
    if (gateCue != null && gateCue < bound) bound = gateCue;
    _audioCubit.setAllowedThroughCue(bound);
  }

  // Answering a question does NOT auto-play (user call, 2026-08-04: the
  // feedback under the chosen option deserves a quiet read) — the FIRST swipe
  // after answering is what turns the page and brings narration with it:
  // the hold leaves `hasCompletedPlayback` standing, and
  // [_loadCardNarration]'s autoplay rule reads that as "listening through",
  // so the new card starts talking on its own. Backgrounding while held still
  // reads on (see [didChangeAppLifecycleState]).

  /// The player crossed into a new cue: bring the deck along. Mirrors the
  /// per-clip completion branches — same gates, same order — but as a FOLLOW
  /// (the audio kept playing through the boundary; nothing reloads).
  void _onMergedCueChanged(int cueIndex) {
    final timeline = _audioCubit.timeline;
    final cue = timeline?.cueAt(cueIndex);
    if (cue == null) return;

    int cardIndexForCue() {
      for (var i = 0; i < state.cards.length; i++) {
        final descriptor = state.cards[i];
        if (descriptor.isTheory && descriptor.learningItemId == cue.learningItemId && descriptor.documentIndex == cue.documentIndex) {
          return i;
        }
      }
      return -1;
    }

    final isBackground = _isBackgrounded;
    var cardIndex = cardIndexForCue();

    // Cue past the built deck (true live edge). Foreground with an open gate:
    // advance for real — this is where lesson progress moves (the per-clip
    // path's nextDocument call, relocated). One cue can be several documents
    // ahead when silent cards sit between audible ones, so advance until the
    // cue's card exists; nextDocument emits synchronously but the deck's own
    // stream listener runs a microtask later, hence the direct _rebuildCards.
    // Backgrounded: leave the deck alone; the return path reveals to wherever
    // the voice got (didChangeAppLifecycleState → jumpToCard).
    if (cardIndex < 0 && !isBackground) {
      var guard = 0;
      while (cardIndex < 0 && guard++ < 50) {
        if (isAtPaywallWall || !_theoryCubit.state.canContinue) break;
        final before = (_lessonCubit.state.currentLearningItemIndex, _theoryCubit.state.currentDocumentIndex);
        _theoryCubit.nextDocument();
        _rebuildCards(_lessonCubit.state);
        final after = (_lessonCubit.state.currentLearningItemIndex, _theoryCubit.state.currentDocumentIndex);
        if (after == before) break; // refused (gate/end) — stop pushing
        cardIndex = cardIndexForCue();
      }
      if (cardIndex < 0 && !isAtPaywallWall) {
        // The gate refused (a choice still owed): the voice reads ON — audio
        // never auto-stops mid-listen (user call, 2026-08-04) — so reveal the
        // card it entered and follow read-only. Progress stays behind: the
        // reveal is not progress, exactly like the background read-ahead.
        _revealToCardTarget = (learningItemId: cue.learningItemId, documentIndex: cue.documentIndex);
        _rebuildCards(_lessonCubit.state);
        cardIndex = cardIndexForCue();
      }
    }

    if (cardIndex >= 0) {
      if (cardIndex != state.viewedCardIndex && !isBackground) viewCard(cardIndex);
      if (cardIndex == state.viewedCardIndex) _loadedClipCardIndex = cardIndex;
    }
    _pushAllowedThroughCue();
  }

  /// Moves the view onto the card with this identity, revealing it first when
  /// it sits past the live edge (revealed cards are NOT progress — they render
  /// read-only past the edge exactly like the legacy narration reveal).
  void jumpToCard({required String learningItemId, required int documentIndex, Duration? startAt}) {
    _revealToCardTarget = (learningItemId: learningItemId, documentIndex: documentIndex);
    _rebuildCards(_lessonCubit.state);

    for (var i = 0; i < state.cards.length; i++) {
      final descriptor = state.cards[i];
      if (descriptor.isTheory && descriptor.learningItemId == learningItemId && descriptor.documentIndex == documentIndex) {
        viewCard(i, startAt: startAt);
        return;
      }
    }
  }

  /// Moves the view onto the card carrying [clipIndex], building the card list
  /// out to it first when the lesson's own live edge has not reached it.
  ///
  /// Order is load-bearing: raise the bound and rebuild BEFORE looking the clip
  /// up, because until then no descriptor for that card exists and the lookup can
  /// only fail. Returns false when the clip has no card even after rebuilding.
  bool _followNarrationToClip(int clipIndex, {Duration? startAt}) {
    _revealToClipIndex = clipIndex;
    _rebuildCards(_lessonCubit.state);

    int? cardIndex;
    for (final entry in _cardToClip.entries) {
      if (entry.value == clipIndex) {
        cardIndex = entry.key;
        break;
      }
    }
    if (cardIndex == null || cardIndex >= state.cards.length) return false;

    viewCard(cardIndex, startAt: startAt);
    return true;
  }

  /// Coming back on screen lands on the card the voice is reading, at the second
  /// it is at, still playing.
  ///
  /// The reveal bound is raised and the cards rebuilt BEFORE the clip is looked
  /// up: [KeypointCardsBuilder] normally stops at the lesson's live position, so
  /// until then no descriptor for that card exists and the lookup can only fail.
  ///
  /// Progress is untouched. [viewCard] moves the view, reconciles the quiz pause
  /// and points narration — it never calls `nextDocument()` /
  /// `nextLearningItem()`, so nothing here can write keypoint progress or reach
  /// `completeCurrentKeypoint()` for questions nobody answered. Cards past the
  /// live edge render read-only (see [QuizPreviewCardBody]).
  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (_audioCubit.isMergedMode) {
      _pushAllowedThroughCue();
      if (lifecycleState != AppLifecycleState.resumed) {
        // Going away while the voice was held at a question: backgrounded
        // listening reads STRAIGHT THROUGH exercises (user call, 2026-08-04)
        // — the bound was just lifted above, so press play. A manual pause
        // never carries hasCompletedPlayback and stays paused.
        final audioState = _audioCubit.state;
        final lastAudible = _audioCubit.timeline?.lastAudibleCueIndex ?? -1;
        if (audioState.hasCompletedPlayback && !audioState.isPlaying && audioState.activeCueIndex >= 0 && audioState.activeCueIndex < lastAudible) {
          unawaited(_audioCubit.play());
        }
        return;
      }
      // Back on screen: land the deck on the card being read, at full flight —
      // the player never stopped, so this is pure view work (no reload, no
      // seek). Progress is untouched; revealed cards render read-only.
      final cue = _audioCubit.timeline?.cueAt(_audioCubit.state.activeCueIndex);
      if (cue != null) {
        jumpToCard(learningItemId: cue.learningItemId, documentIndex: cue.documentIndex);
      }
      return;
    }

    if (lifecycleState != AppLifecycleState.resumed) return;
    if (!_audioCubit.isAheadOfDeck) return;

    final narratedClip = _audioCubit.narratingClipIndex;
    if (narratedClip != null) {
      // Read the position BEFORE anything touches the player.
      final position = _audioCubit.narratingPosition;
      if (_followNarrationToClip(narratedClip, startAt: position)) return;
      // The clip has no card even after rebuilding (content shorter than the
      // clip list, e.g. a keypoint dubbed before an item was removed): fall
      // through to the old behaviour rather than leave the deck lying.
    }

    // Nothing to follow — the run finished, or the player has no slot to report.
    unawaited(_audioCubit.pause());
    final clipIndex = _cardToClip[state.viewedCardIndex];
    if (clipIndex == null || !_audioCubit.hasClipAt(clipIndex)) return;
    unawaited(_audioCubit.loadCard(clipIndex));
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
        // A different keypoint's reveal means nothing here — drop it with the cards.
        _revealToClipIndex = -1;
        emit(state.copyWith(status: KeypointCardStatus.initial, cards: const [], viewedCardIndex: 0, furthestCardIndex: 0, narrationRevealIndex: 0));
      }
      return;
    }

    final built = const KeypointCardsBuilder().build(
      items: lessonState.pageData.items,
      currentLearningItemIndex: lessonState.currentLearningItemIndex,
      liveIndexInCurrentItem: _liveIndexForCurrentItem(
        lessonState,
        lessonState.pageData.items.elementAtOrDefault(
          lessonState.currentLearningItemIndex,
          defaultValue: const LearningItemEntity(),
        ),
      ),
      revealToClipIndex: _revealToClipIndex,
      revealToCard: _revealToCardTarget,
    );
    _cardToClip = built.cardToClip;
    // Tell the player which clips belong to the reading flow at all, so the
    // background queue never reads an exercise question's clip aloud.
    _audioCubit.setNarratableClips(built.narratableClips);

    // Once the lesson's own live edge has caught up with the card narration read
    // ahead to, the extra bound has done its job and must go: leaving it set
    // keeps every later rebuild extending the list past the live edge, long after
    // the reader is driving the deck again.
    //
    // Cleared HERE rather than at the end of the resume jump on purpose — clearing
    // it there would make the very next lesson emit rebuild without the revealed
    // cards, and the reader looking at one would be yanked back.
    if (_revealToClipIndex >= 0 && built.liveCardIndex >= built.revealCardIndex) {
      _revealToClipIndex = -1;
    }
    if (_revealToCardTarget != null && built.liveCardIndex >= built.revealCardIndex) {
      _revealToCardTarget = null;
    }

    final wasFollowingEdge = state.viewedCardIndex == state.furthestCardIndex;
    final previousViewedIndex = state.viewedCardIndex.clamp(0, built.cards.length - 1);

    // Do NOT clamp this to the pinned view. `furthestCardIndex` is what the
    // `PageView` is sized from (`itemCount: furthestCardIndex + 1`), so holding
    // it at 0 during the entry pin leaves the deck with a single page: nothing
    // to swipe to, and the pin is released by [viewCard] — which that swipe is
    // the only way to reach. Tried on 2026-08-03 to stop the pip bar showing a
    // fresh keypoint's cards as already read; it deadlocked every keypoint
    // instead. The pip-bar leak is stale `@lazySingleton` TheoryCubit /
    // ExerciseCubit indices read back by [_liveIndexForCurrentItem] during the
    // entry burst, and it has to be fixed at that source, not here.
    final nextFurthestIndex = completionJustTriggered ? built.doneCardIndex : built.liveCardIndex;

    // Opening a keypoint always lands on its FIRST card, never where the reader
    // left off. Position inside a keypoint is deliberately not restored (product
    // call): re-entering re-reads from the top.
    //
    // The pin has to outlive the entry BURST, not just the first build: the live
    // edge climbs to the stored position several rebuilds in, and by then
    // `wasFollowingEdge` is trivially true (view 0 == edge 0) and would carry the
    // view along with it. It is released by the first [viewCard], i.e. the moment
    // the reader — or the voice — actually moves the deck.
    final restoredViewedIndex = completionJustTriggered
        ? nextFurthestIndex
        : _entryPinActive
        ? 0
        : (wasFollowingEdge ? nextFurthestIndex : previousViewedIndex);

    // The paywall wall clamps the restored position too. Without this, a reader
    // who got past the wall before it existed would be handed straight back to
    // where they were, every time they re-entered — this emit does not go through
    // [viewCard], so its cap does not cover it.
    final cap = _paywallCardCap;
    final nextViewedIndex = cap != null && restoredViewedIndex > cap ? cap : restoredViewedIndex;

    // TEMP-DEBUG(deck): remove once the entry position and the paywall wall are
    // both confirmed settled.
    LogDev.warning(
      '[DeckDbg] rebuild pin=$_entryPinActive cap=$cap cards=${built.cards.length} live=${built.liveCardIndex} '
      'furthest=${state.furthestCardIndex}→$nextFurthestIndex viewed=$previousViewedIndex→$nextViewedIndex '
      'followEdge=$wasFollowingEdge completion=$completionJustTriggered itemIdx=${lessonState.currentLearningItemIndex}',
    );

    emit(
      state.copyWith(
        status: KeypointCardStatus.ready,
        cards: built.cards,
        furthestCardIndex: nextFurthestIndex,
        narrationRevealIndex: built.revealCardIndex,
        viewedCardIndex: nextViewedIndex,
        isLiveCardAnswered: _isCardAnswered(built.cards, nextFurthestIndex),
      ),
    );

    if (nextViewedIndex != previousViewedIndex) {
      _reconcileQuizPause(previousViewedIndex, nextViewedIndex);
    }
    // Every card change takes narration with it, so the voice is always reading
    // the page on screen.
    _ensureNarrationOnViewedCard();
    // The card region just changed shape, so the voice's permission to cross
    // the next boundary may have too.
    _pushAllowedThroughCue();
  }

  /// Points narration at the card on screen unless it is already there.
  ///
  /// The card-CHANGE path can't cover entry: the deck's first card is already
  /// the viewed one, so nothing changes and nothing would ever claim it — which
  /// left the first page of every keypoint with `_loadedClipCardIndex == -1`, so
  /// it neither turned itself nor scrolled, and the screen only came alive from
  /// the second page on.
  ///
  /// Entry also has no fixed order: the cards arrive when the learning items load
  /// and the clips arrive when [LessonAudioCubit.configure] runs, either way
  /// round. So this is called from BOTH sides — the card rebuild and the audio
  /// state — and whichever lands last is the one that starts narration.
  void _ensureNarrationOnViewedCard() {
    if (_loadedClipCardIndex == state.viewedCardIndex) return;
    _loadCardNarration(state.viewedCardIndex);
  }

  /// Whether [index] is a quiz card whose question already carries a result.
  ///
  /// Theory and done cards are never "answered" — they have no verdict to wait
  /// for, and the forward gate for them lives in `TheoryCubit.canContinue`.
  bool _isCardAnswered(List<KeypointCardDescriptor> cards, int index) {
    if (index < 0 || index >= cards.length) return false;
    final descriptor = cards[index];
    if (!descriptor.isQuiz) return false;
    return questionForCard(descriptor).hasResult;
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

  /// Legacy (whole-keypoint dub) fallback: silence a quiz card.
  ///
  /// On a keypoint with per-card clips there is nothing to reconcile — an
  /// exercise card's clip reads its question and ends there, so narration can't
  /// advance behind the reader's back while they answer. On a keypoint still
  /// dubbed as ONE file the voice would read straight through the question and
  /// on into later pages, so entering an unanswered quiz pauses it; that only
  /// resumes on the way back onto a theory card, and only if THIS cubit was what
  /// paused it — a reader's own pause stays paused.
  void _reconcileQuizPause(int previousIndex, int nextIndex) {
    if (_audioCubit.hasCardClips) return;
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
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_lessonSubscription?.cancel());
    unawaited(_audioSubscription?.cancel());
    unawaited(_theorySubscription?.cancel());
    return super.close();
  }
}
