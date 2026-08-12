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

  /// Keypoint the last build was for, so a switch inside one route (the
  /// listening chain hopping keypoints, a lesson re-entry) is detectable — none
  /// of the per-keypoint latches below may survive it. See [_rebuildCards].
  String _builtForKeypointId = '';

  /// Id of the keypoint's takeaway summary item, from the last build. Its
  /// cues/clips resolve to the terminal done card (the recap flip card IS its
  /// card), which no descriptor-identity lookup can discover on its own.
  String? _takeawayLearningItemId;

  /// Cue the deck last pointed narration at and is still waiting to hear back
  /// from, or null.
  ///
  /// A `playCue` seek is asynchronous: a position tick emitted BEFORE it lands
  /// arrives after, reporting the cue the voice was on a moment ago. Following
  /// that tick is what raced the deck to the end of the keypoint the instant a
  /// paywall cap was lifted — the file was open deep past the deck (a resume
  /// bookmark, which `_onMergedTick` deliberately does not clamp), so one stale
  /// tick sent [_onMergedCueChanged]'s catch-up walk through every remaining card
  /// ("lướt được 3 phát chạy xuống cuối", 2026-08-12).
  int? _awaitingSeekToCue;

  // TEMP-TRACE(deck2): timestamped so a JUMP can be told apart from the voice
  // genuinely reading its way there. Remove once the deck is confirmed settled.
  static final Stopwatch _traceClock = Stopwatch()..start();
  void _trace(String message) => LogDev.warning('[Deck2] +${_traceClock.elapsedMilliseconds}ms $message');

  /// Cue index the in-app recap gate last paused on — guards the pause to one
  /// firing per arrival, so the reader's own play/pause on that card is never
  /// fought over.
  int _recapGateCueIndex = -1;

  /// True once the reader's tap ([resumeRecapNarrationIfGated]) started the
  /// takeaway read — the ONLY playback allowed through an armed gate. A stray
  /// play (fired for a card swiped through, landing after the park's seek)
  /// plays the very same takeaway cue and is indistinguishable by position
  /// alone: without this flag it read the recap AND auto-flipped the card as
  /// if the reader had tapped ("bug tự động tap luôn", 2026-08-08).
  bool _recapTapResumed = false;

  /// The reader already opened the recap flip card (tap or auto-flip) on THIS
  /// keypoint. The PageView disposes the done card's State once it scrolls far
  /// enough away, so the flip must live here: re-mounting restores the open
  /// face instantly instead of resetting to the quote front ("đã tab rồi thì
  /// vuốt lên vuốt xuống không được quay cái card cuối lại", 2026-08-08).
  bool recapFlipOpened = false;

  /// True while the recap park's pause is still in flight. The pause is async,
  /// so a card move landing inside that window still reads `isPlaying == true`
  /// off the audio state and would autoplay the card it lands on — the reader
  /// mutes on the recap, swipes back, and the PREVIOUS card starts talking
  /// uninvited. Narration pointing treats this window as already-muted.
  bool _recapMutePending = false;

  LessonCompletionOrigin _previousCompletionOrigin = LessonCompletionOrigin.none;

  /// Completion observed by THIS cubit (the completionJustTriggered edge) —
  /// deliberately NOT [LessonState.completionOrigin] read raw. The lesson
  /// cubit is a `@lazySingleton`, so on (re-)entry the flag can still be the
  /// PREVIOUS keypoint run's; reading it raw unlocked the done card at index 1
  /// of the two-card entry skeleton, and the reader's first swipe landed on
  /// the recap UI as "card 2" with the deck never growing ("card thứ 2 mà đã
  /// giao diện card cuối", 2026-08-09 — [DeckDbg]: rebuild cards=2 live=0
  /// furthest=0→1 → viewCard(1) → park idx=1). Reset alongside the recap flip
  /// state when a different keypoint's takeaway arrives.
  bool _keypointCompletedThisRun = false;

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

  /// While set, a rebuild leaves the reader's view where it is even if they were
  /// standing on the live edge.
  ///
  /// The edge-follow is how the VOICE turns the page, and it is right for one
  /// rebuild at a time. It is wrong for a burst: [_onMergedCueChanged]'s catch-up
  /// walk rebuilds once per document it advances, and each of those would move the
  /// view again — a run of cards flicking past instead of one page turn.
  bool _edgeFollowSuspended = false;

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

  /// Whether the wall renders as a card of its own (the daily quota's
  /// "free lesson done for today" screen) sitting at `cap + 1`. The reader may
  /// swipe ONTO it — it is the wall's face, not content past the wall — while
  /// the voice and the lesson's live edge stay bounded by [_paywallCardCap].
  bool _showQuotaLockedCard = false;

  void setPaywallCardCap(int? cap, {bool quotaLockedCard = false}) {
    final showLocked = quotaLockedCard && cap != null;
    final changed = cap != _paywallCardCap || showLocked != _showQuotaLockedCard;
    _paywallCardCap = cap;
    _showQuotaLockedCard = showLocked;
    // The locked card changes the card LIST, and the access answer that flips it
    // arrives after the deck was built — so a change here must rebuild rather
    // than wait for the next lesson emit (which may never come while the reader
    // just stares at a capped deck).
    if (changed && state.status == KeypointCardStatus.ready) {
      _rebuildCards(_lessonCubit.state);
    }
  }

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
    // The locked card sits one past the cap and is the one thing there the view
    // may land on — it IS the wall's face.
    final cap = _paywallCardCap;
    final maxViewable = cap == null ? null : (_showQuotaLockedCard ? cap + 1 : cap);
    if (maxViewable != null && index > maxViewable) index = maxViewable;

    if (index == state.viewedCardIndex && startAt == null) return;
    if (index < 0 || index >= state.cards.length) return;
    _trace('viewCard($index) from=${state.viewedCardIndex} cards=${state.cards.length} cap=$_paywallCardCap');
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
      // Off screen the VOICE leads and the deck follows on return (see
      // [didChangeAppLifecycleState]); nothing the deck does here may touch the
      // player. This path went live with the listening chain: hopping into the
      // next keypoint rebuilds the deck from scratch while backgrounded, and the
      // seek below would drag the file back to the top of the new keypoint's
      // first card — or park it silent on a recap nobody is looking at.
      if (_isBackgrounded) return;
      final descriptor = state.cards[index];
      if (descriptor.isDone) {
        // Only when the deck can genuinely SHOW the recap — the same rule
        // [_onMergedCueChanged]'s cardIndexForCue states. Mid-build the done
        // card is the deck's LAST card long before the reading flow reaches it,
        // so a forward swipe off the live edge lands here for one rebuild while
        // the next theory card is still being built. Parking on that landing
        // seeked the file to the recap cue — and that phantom tick walked the
        // lesson to completion and threw the reader onto the quote card
        // ("lướt 2 card đầu đến card thứ 3 bị nhảy", trace 2026-08-12:
        // [RecapGate] park idx=2 cue=12 with furthest=1). It also muted a
        // listener mid-read even when the takeaway cue was unknown. The real
        // arrival — voice or reader actually reaching the recap — always comes
        // with the bound already raised.
        if (state.revealBound >= index) _parkNarrationAtRecap(index);
        return;
      }
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
      // A reader who pressed pause themselves keeps their silence as they move
      // through cards — forward movement is only a listening intent while the
      // session hasn't been explicitly silenced.
      final movingForward = audioState.hasStartedSession && index > previousNarratedIndex && !_audioCubit.pausedByUser;
      // `isPlaying` is stale while the recap park's pause is in flight — the
      // reader just muted on the recap card; a swipe back landing in that
      // window must not restart the previous card off the not-yet-updated
      // flag. The tap gate is the only way sound returns.
      final effectivelyPlaying = audioState.isPlaying && !_recapMutePending;
      // The completed-playback carry exists so the NEXT page keeps talking
      // when a card's clip ran to its end. It stays raised until another clip
      // loads — so after the RECAP (the terminal cue) finished, it turned any
      // later backward swipe into an autoplay that read the whole previous
      // card unasked (2026-08-07). Forward is its only meaning — and only for
      // a reader still listening: the flag survives a user pause (pause only
      // drops isPlaying), so without the pausedByUser guard a muted reader's
      // first forward swipe restarted narration AND wiped their mute, which
      // is what let the recap re-arrival talk again ("chủ động tắt âm, lật
      // card cuối vẫn bị bật lại âm thanh", 2026-08-09).
      final carriesCompletion = audioState.hasCompletedPlayback && index > previousNarratedIndex && !_audioCubit.pausedByUser;
      final autoplay = startAt != null || effectivelyPlaying || carriesCompletion || movingForward;
      // The seek is async, and a position tick from BEFORE it can land after it.
      // Remember where we asked the voice to go so such a tick can be told apart
      // from the voice genuinely being somewhere else — see [_onMergedCueChanged].
      _awaitingSeekToCue = cueIndex;
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
    // Same pausedByUser guard as the merged carry above: a completed clip
    // outlives a manual pause, and re-pointing narration must not undo the
    // reader's own silence.
    final audioState = _audioCubit.state;
    final autoplay = startAt != null || audioState.isPlaying || (audioState.hasCompletedPlayback && !_audioCubit.pausedByUser);
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

    // Parked on the recap, only the takeaway may sound in-app. The park's
    // pause races every play already in flight — a fast swipe THROUGH the
    // near-last card fires that card's autoplay, and its play() lands AFTER
    // the park's pause, reading a card nobody is on ("vẫn đọc card gần cuối
    // nếu vuốt nhanh", 2026-08-08). Ordering can't win a race that starts
    // before the park exists, so the invariant re-asserts itself here: any
    // audible playback that is not the takeaway cue while the gate holds the
    // done card is a leak — silence it and re-park.
    final isTapStartedRecapRead = audioState.activeCueIndex == _recapGateCueIndex && _recapTapResumed;
    if (_recapGateCueIndex >= 0 &&
        !_isBackgrounded &&
        audioState.isPlaying &&
        _audioCubit.isMergedMode &&
        state.cards.isNotEmpty &&
        state.viewedCardIndex == state.cards.length - 1 &&
        !isTapStartedRecapRead) {
      _recapMutePending = true;
      unawaited(() async {
        try {
          await _audioCubit.pause();
          if (_audioCubit.state.activeCueIndex != _recapGateCueIndex && _audioCubit.state.hasStartedSession) {
            await _audioCubit.playCue(_recapGateCueIndex, autoplay: false);
          }
        } finally {
          _recapMutePending = false;
        }
      }());
      return;
    }

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

  /// The voice has read this keypoint all the way to its last audible cue —
  /// the takeaway included — so there is nothing left to hear.
  ///
  /// What the done card's auto-continue keys on. Background listening reads
  /// straight through the recap gate (only the foreground park waits for a
  /// tap), so a reader who listened away from the app comes back to a finished
  /// keypoint still asking them to press Continue ("nghe ngoài nền khi vào lại
  /// ... cần hoàn thành luôn", 2026-08-08). Follows the same product line as
  /// auto-completing on the final theory card: hearing the keypoint out IS
  /// finishing it.
  ///
  /// `hasCompletedPlayback` alone would not do — it survives until the next
  /// load, and it is also what a legacy per-clip end raises. Pinning it to the
  /// LAST audible cue is what makes this mean "the whole keypoint", and keeps a
  /// stale flag from firing on the next keypoint's recap card. Backgrounded it
  /// stays false: navigation belongs to a screen the reader is looking at.
  bool get narrationFinishedKeypoint {
    if (!_audioCubit.isMergedMode || _isBackgrounded) return false;
    final audioState = _audioCubit.state;
    if (!audioState.hasCompletedPlayback) return false;
    final timeline = _audioCubit.timeline;
    final lastAudible = timeline?.lastAudibleCueIndex ?? -1;
    if (lastAudible < 0 || audioState.activeCueIndex < lastAudible) return false;
    // The timeline must be THIS keypoint's. Entering the next keypoint carries
    // the previous session's flags for the beat before its own source loads,
    // and a keypoint whose only card is the done card would act on them.
    final lastCue = timeline?.cueAt(lastAudible);
    return lastCue != null && _lessonCubit.state.pageData.items.any((item) => item.id == lastCue.learningItemId);
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
    // The canContinue gate protects the LIVE EDGE only — once the keypoint is
    // completed there is no edge left to protect, and keeping the bound armed
    // fights the recap park: the park seeks PAST the bound (the takeaway cue
    // sits on the done card, which [_lastAudibleCueUpTo] never counts), the
    // tick clamp yanks the voice back to the last real card, its completion
    // pushes the view forward again — an infinite 10↔11 bounce re-reading the
    // near-last card aloud ("nhảy ngược về và đọc card gần cuối", 2026-08-08,
    // caught in the [DeckDbg] trail). Post-completion the only in-app hold is
    // the recap park's own pause. Latched, not the raw lesson flag — a stale
    // completion from the previous run must not disarm a fresh keypoint's
    // gate (see [_keypointCompletedThisRun]).
    final isKeypointCompleted = _keypointCompletedThisRun;
    if (!_isBackgrounded && !isKeypointCompleted && !_theoryCubit.state.canContinue) {
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
      // The takeaway's cue belongs to the terminal done card — but only once
      // the deck can actually SHOW it. Reporting it missing before then lets
      // the advance loop below drive the last real cards to completion first,
      // exactly like a normal final card, which is what reveals it.
      if (_takeawayLearningItemId != null && cue.learningItemId == _takeawayLearningItemId) {
        final doneIndex = state.cards.length - 1;
        return state.cards.isNotEmpty && state.revealBound >= doneIndex ? doneIndex : -1;
      }
      for (var i = 0; i < state.cards.length; i++) {
        final descriptor = state.cards[i];
        if (descriptor.isTheory && descriptor.learningItemId == cue.learningItemId && descriptor.documentIndex == cue.documentIndex) {
          return i;
        }
      }
      return -1;
    }

    // A tick from before our own seek. Tolerant by one cue rather than exact:
    // ticks are coarse and the voice may already have crossed into the next cue by
    // the time one is emitted, and an exact match could wait forever and stop the
    // deck following the voice at all.
    final awaiting = _awaitingSeekToCue;
    if (awaiting != null) {
      if ((cueIndex - awaiting).abs() > 1) return;
      _awaitingSeekToCue = null;
    }

    final isBackground = _isBackgrounded;
    var cardIndex = cardIndexForCue();
    _trace('cue($cueIndex) cardForCue=$cardIndex viewed=${state.viewedCardIndex} furthest=${state.furthestCardIndex} playing=${_audioCubit.state.isPlaying}');

    // Cue past the built deck (true live edge). Foreground with an open gate:
    // advance for real — this is where lesson progress moves (the per-clip
    // path's nextDocument call, relocated). One cue can be several documents
    // ahead when silent cards sit between audible ones, so advance until the
    // cue's card exists; nextDocument emits synchronously but the deck's own
    // stream listener runs a microtask later, hence the direct _rebuildCards.
    // Backgrounded: leave the deck alone; the return path reveals to wherever
    // the voice got (didChangeAppLifecycleState → jumpToCard).
    // A cue with no card may drive the lesson forward ONLY while the player is
    // audibly reading — that is what this follow is for ("the audio kept playing
    // through the boundary"). Paused, such a cue can only be a seek landing
    // (a park, a claim, a stale tick), and letting it run the advance loop is
    // how a phantom completed a whole keypoint and filed its progress
    // (trace 2026-08-12: cue(12) playing=false → cueWalk → done=true).
    if (cardIndex < 0 && !isBackground && _audioCubit.state.isPlaying) {
      // The walk MOVES THE LIVE EDGE, and the deck follows the edge whenever the
      // reader is standing on it ([_rebuildCards]'s `wasFollowingEdge`) — so
      // without this pin every step of the walk drags the view one card along,
      // and the reader watches the deck run to the end of the keypoint in a few
      // milliseconds ("nhảy phát xuống card cuối", trace 2026-08-12: three
      // rebuilds inside 5ms taking the view 9→10→11→12, and the walk then ended
      // up finding no card at all). The walk exists to BUILD cards, not to
      // relocate the reader; the single [viewCard] below is the only move it may
      // make, and only once it knows where.
      _edgeFollowSuspended = true;
      try {
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
        _trace('cueWalk steps=${guard - 1} cardIndex=$cardIndex');
        if (cardIndex < 0 && !isAtPaywallWall) {
          // The gate refused (a choice still owed): the voice reads ON — audio
          // never auto-stops mid-listen (user call, 2026-08-04) — so reveal the
          // card it entered and follow read-only. Progress stays behind: the
          // reveal is not progress, exactly like the background read-ahead.
          _revealToCardTarget = (learningItemId: cue.learningItemId, documentIndex: cue.documentIndex);
          _rebuildCards(_lessonCubit.state);
          cardIndex = cardIndexForCue();
        }
      } finally {
        _edgeFollowSuspended = false;
      }
    }

    if (cardIndex >= 0) {
      // In-app, the recap card is a STOP: pause and wait for the reader to tap
      // the card open ([resumeRecapNarrationIfGated]); background listening
      // reads straight through — no one is there to tap. Paused BEFORE
      // viewCard, whose narration pointing derives autoplay from "is it
      // playing right now".
      final isTakeawayCue = _takeawayLearningItemId != null && cue.learningItemId == _takeawayLearningItemId;
      if (isTakeawayCue && !isBackground && cueIndex != _recapGateCueIndex) {
        _recapGateCueIndex = cueIndex;
        unawaited(_audioCubit.pause());
      }
      // The park's pause+seek are async: a position tick from BEFORE the seek
      // can land after it and report the PREVIOUS cue as active for one emit.
      // While the armed gate holds the view on the done card, a backward
      // cue-follow can only be that phantom — the recap is a terminal stop;
      // narration never walks the view off it. Following it re-read the
      // near-last card aloud ("nhảy ngược về và đọc card gần cuối",
      // 2026-08-08 [DeckDbg] trail: viewCard(9)→viewCard(10) between parks).
      final doneIndex = state.cards.length - 1;
      final phantomBackstep = _recapGateCueIndex >= 0 && state.viewedCardIndex == doneIndex && cardIndex < doneIndex;
      if (cardIndex != state.viewedCardIndex && !isBackground && !phantomBackstep) viewCard(cardIndex);
      if (cardIndex == state.viewedCardIndex) _loadedClipCardIndex = cardIndex;
    }
    _pushAllowedThroughCue();
  }

  /// In-app arrival on the recap card PARKS the voice: paused, seeked to the
  /// takeaway's cue, gate armed — however the reader got here (their own
  /// swipe, a pip tap, or the voice turning the page). The tap that opens the
  /// card is what reads it ([resumeRecapNarrationIfGated]). Readers with no
  /// audio session keep their silence: the gate never arms, tapping only
  /// flips.
  ///
  /// pause() BEFORE the seek — `playCue(autoplay: false)` alone only moves the
  /// position, and a playing player would read the takeaway straight through
  /// the gate from its new position.
  void _parkNarrationAtRecap(int index) {
    // Deliberately NOT gated on hasStartedSession: the gate must arm for
    // silent readers too — tapping the recap open reads it aloud whether or
    // not a listening session ever ran ("lật thẻ phải tự phát tiếng",
    // 2026-08-07). playCue handles the no-session case by initialising the
    // player itself when the tap comes.

    // Arriving on the terminal card ALWAYS silences the voice, even when the
    // takeaway has no cue to park on (a keypoint dubbed before its takeaway
    // existed): whatever it was reading no longer matches the screen. The
    // condition is deliberately not folded into the seek below — an early
    // return there must never skip the mute.
    final cueIndex = _takeawayLearningItemId == null
        ? null
        : _audioCubit.cueForCard(learningItemId: _takeawayLearningItemId!, documentIndex: 0);
    LogDev.warning(
      '[RecapGate] park idx=$index cue=$cueIndex takeaway=$_takeawayLearningItemId '
      'session=${_audioCubit.state.hasStartedSession} playing=${_audioCubit.state.isPlaying} '
      'activeCue=${_audioCubit.state.activeCueIndex}',
    );
    // The reader already tapped the recap open and the voice is reading it —
    // a re-park (any rebuild re-pointing narration at this card) must not
    // pause the very thing the tap started. `_recapTapResumed` is what proves
    // the tap: a stray autoplay landing after the park's seek plays this very
    // cue too, and without the flag this branch waved it through as the
    // reader's own listening.
    if (cueIndex != null && cueIndex == _audioCubit.state.activeCueIndex && _audioCubit.state.isPlaying && _recapTapResumed) {
      return;
    }
    // A recap the reader ALREADY opened comes back TALKING, not parked. The
    // park's contract is "sound returns on the flip" — but a re-arrival finds
    // the card still open (the flip survives in `recapFlipOpened`), so the
    // only tap left CLOSES it and the gate becomes unreachable: swipe up, swipe
    // back down, and the takeaway is dead ("card cuối lại bị tắt", 2026-08-09).
    // The flip that satisfied the gate the first time still counts; same
    // guards as the tap itself — a reader's own pause outranks it, and no
    // session never starts one.
    if (cueIndex != null && recapFlipOpened && _audioCubit.state.hasStartedSession && !_audioCubit.pausedByUser) {
      _loadedClipCardIndex = index;
      _recapGateCueIndex = cueIndex;
      _recapTapResumed = true;
      unawaited(_audioCubit.playCue(cueIndex, autoplay: true));
      return;
    }
    _recapTapResumed = false;
    if (cueIndex != null) {
      _loadedClipCardIndex = index;
      _recapGateCueIndex = cueIndex;
    }
    _recapMutePending = true;
    unawaited(() async {
      try {
        if (_audioCubit.state.isPlaying) await _audioCubit.pause();
        // Silent seek only within a RUNNING session. Without one it would
        // initialise the player — surfacing lock-screen now-playing controls
        // for a reader who never asked for audio; the tap's own playCue does
        // that initialisation at the moment sound is actually wanted.
        if (cueIndex != null && _audioCubit.state.hasStartedSession && _audioCubit.state.activeCueIndex != cueIndex) {
          await _audioCubit.playCue(cueIndex, autoplay: false);
        }
      } finally {
        _recapMutePending = false;
      }
    }());
  }

  /// The reader opened the recap flip card after the gate parked the voice —
  /// read the takeaway from its start, to the face now showing. A no-op unless
  /// the gate is armed, the player silent, and that silence is the PARK's
  /// rather than the reader's: flipping the card around in any other situation
  /// stays quiet.
  void resumeRecapNarrationIfGated() {
    LogDev.warning(
      '[RecapGate] resume gate=$_recapGateCueIndex playing=${_audioCubit.state.isPlaying} '
      'pausedByUser=${_audioCubit.pausedByUser} session=${_audioCubit.state.hasStartedSession}',
    );
    if (_recapGateCueIndex < 0 || _audioCubit.state.isPlaying) return;
    // An armed gate is not on its own a reason to make sound: the park arms it
    // on arriving at the done card whether or not the reader is listening. Only
    // a parked LISTENING flow may be resumed by the tap — silence the reader
    // asked for outranks the gate, exactly as it does for forward-swipe
    // autoplay ("mở loa lên luôn"), and with no session at all the playCue
    // below would initialise the player and start talking (lock-screen controls
    // and all) for someone who never turned narration on.
    if (_audioCubit.pausedByUser || !_audioCubit.state.hasStartedSession) return;
    _recapTapResumed = true;
    unawaited(_audioCubit.playCue(_recapGateCueIndex, autoplay: true));
  }

  /// The header play control tapped while the recap gate holds the done card:
  /// the reader's own play button is an even more explicit ask for sound than
  /// the flip tap, so it goes through the gate the same way — and, unlike the
  /// flip, it overrides the reader's earlier pause (pressing play IS the
  /// un-pause). Without this the leak guard in [_onAudioStateChanged] read the
  /// button's playback as a stray autoplay and silenced it on the spot: once
  /// quiet on the last card, sound could never be turned back on ("tắt ở card
  /// cuối thì không bật được nữa", 2026-08-09).
  ///
  /// Returns false when the deck is not parked at the gate — the caller falls
  /// back to its ordinary play path.
  bool resumeRecapFromPlayControl() {
    if (_recapGateCueIndex < 0 || _audioCubit.state.isPlaying) return false;
    if (state.cards.isEmpty || state.viewedCardIndex != state.cards.length - 1) return false;
    _recapTapResumed = true;
    // playCue handles the no-session case by initialising the player at the
    // takeaway cue itself — an explicit play tap is exactly when lock-screen
    // controls are wanted. byUser: this button IS the un-mute.
    unawaited(_audioCubit.playCue(_recapGateCueIndex, autoplay: true, byUser: true));
    return true;
  }

  /// The voice is actively reading the takeaway right now — what the recap
  /// card's auto-flip keys on. Deliberately NOT "audio is playing": a reader
  /// swiping ahead onto the recap while an earlier card is still being read
  /// must not have the card flipped out of their hands.
  bool get isNarratingRecap {
    if (_takeawayLearningItemId == null || !_audioCubit.isMergedMode || !_audioCubit.state.isPlaying) return false;
    final cue = _audioCubit.timeline?.cueAt(_audioCubit.state.activeCueIndex);
    if (cue == null || cue.learningItemId != _takeawayLearningItemId) return false;
    // An armed gate means the recap is waiting for the reader's tap — a stray
    // play sounding at this cue is a leak being silenced, not narration, and
    // treating it as such auto-flipped the card ("tự động tap", 2026-08-08).
    return _recapGateCueIndex < 0 || _recapTapResumed;
  }

  /// Moves the view onto the card with this identity, revealing it first when
  /// it sits past the live edge (revealed cards are NOT progress — they render
  /// read-only past the edge exactly like the legacy narration reveal).
  void jumpToCard({required String learningItemId, required int documentIndex, Duration? startAt}) {
    _revealToCardTarget = (learningItemId: learningItemId, documentIndex: documentIndex);
    _rebuildCards(_lessonCubit.state);

    // The takeaway's card is the terminal done card (the rebuild above raised
    // the reveal bound to it via the builder's cue match).
    if (_takeawayLearningItemId != null && learningItemId == _takeawayLearningItemId && state.cards.isNotEmpty) {
      viewCard(state.cards.length - 1, startAt: startAt);
      return;
    }

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
      // seek). When the voice got AHEAD while away, the ground it covered is
      // made REAL (live edge fast-forwarded, same as resume-after-kill), not
      // merely revealed: a reveal left the live edge parked at an unanswered
      // question the voice had long passed, and every forward swipe then ran
      // through that stale gate and died ("card exercise, thoát ra vào lại
      // không vuốt được tiếp", 2026-08-04). Background listening reads
      // through gates by product call — so coming back treats what was heard
      // as reached.
      // Arm the retry ONLY when there is a real voice position we could not place
      // yet — the chain hopped into a keypoint whose items are still loading.
      //
      // NOT merely "the follow did not move the deck": with no session started
      // `activeCueIndex` is -1 and there is no cue at all, so every resume before
      // playback armed a flag that then fired on the NEXT rebuild — i.e. on the
      // reader's next swipe — and jumped the deck to wherever the voice had got
      // to, usually the last card ("lướt qua card 3 phát chạy đến card cuối",
      // 2026-08-12).
      final voicePosition = _audioCubit.timeline?.cueAt(_audioCubit.state.activeCueIndex);
      _pendingVoiceFollow = voicePosition != null && !_followVoiceNow();
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

  /// Lands the deck on the card the voice is reading, making the ground it
  /// covered while away REAL (live edge fast-forwarded, not merely revealed) —
  /// see [didChangeAppLifecycleState] for why a reveal is not enough.
  ///
  /// Returns false when the cue's learning item is not in the lesson yet, which
  /// is not a failure: the listening chain switches keypoints while the app is
  /// off screen, so coming back can beat the new keypoint's items landing. The
  /// caller then leaves [_pendingVoiceFollow] armed and the next rebuild retries.
  bool _followVoiceNow() {
    final cue = _audioCubit.timeline?.cueAt(_audioCubit.state.activeCueIndex);
    if (cue == null) return false;
    final items = _lessonCubit.state.pageData.items;
    final itemIndex = items.indexWhere((item) => item.id == cue.learningItemId);
    if (itemIndex < 0) return false;

    final liveItemIndex = _lessonCubit.state.currentLearningItemIndex;
    final liveDocIndex = _theoryCubit.state.currentDocumentIndex;
    // Forward only — never drag the live edge BACK when the reader was
    // re-listening an earlier card.
    final voiceIsAhead = itemIndex > liveItemIndex || (itemIndex == liveItemIndex && cue.documentIndex > liveDocIndex);
    // The takeaway is not a stop in the reading flow (_nextReadableIndex
    // skips it), so the live edge is never parked ON it — jumpToCard below
    // still lands the view on the recap card, and the done card's own
    // completion fallback files the keypoint.
    if (voiceIsAhead && !resolveTakeawaySummary(items).hiddenItemIndexes.contains(itemIndex)) {
      _lessonCubit.jumpToItem(itemIndex);
      _lessonCubit.setCurrentLearningItem(items[itemIndex]);
      _theoryCubit.jumpToDocument(cue.documentIndex);
    }
    _trace('followVoice cue=${_audioCubit.state.activeCueIndex} item=$itemIndex doc=${cue.documentIndex} ahead=$voiceIsAhead');
    jumpToCard(learningItemId: cue.learningItemId, documentIndex: cue.documentIndex);
    return true;
  }

  /// True while a resume is still owed its [_followVoiceNow] — the app came back
  /// on screen before the keypoint the voice had hopped into had any cards.
  bool _pendingVoiceFollow = false;

  void _rebuildCards(LessonState lessonState) {
    final completionJustTriggered = _previousCompletionOrigin == LessonCompletionOrigin.none && lessonState.completionOrigin != LessonCompletionOrigin.none;
    _previousCompletionOrigin = lessonState.completionOrigin;
    if (completionJustTriggered) _keypointCompletedThisRun = true;

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

    // A DIFFERENT keypoint is being built in the same route — the listening
    // chain switches keypoints in place, and so does the lesson's own re-entry.
    // Every per-keypoint latch cleared here describes the run that just ended
    // and would be actively wrong now: `_keypointCompletedThisRun` alone would
    // reveal the whole new keypoint at once (it lifts `furthestCardIndex` to the
    // done card) and disarm its question gate; a stale reveal target would open
    // cards nobody has reached. Cleared BEFORE the build, so the first build of
    // the new keypoint already sees clean inputs.
    //
    // Keyed on the keypoint id, not just the takeaway item: two keypoints that
    // both lack a takeaway compare equal on that field.
    final items = lessonState.pageData.items;
    final builtKeypointId = items.isEmpty ? '' : items.first.keypointId;
    final switchedKeypoint = _builtForKeypointId != builtKeypointId;
    if (switchedKeypoint) {
      _builtForKeypointId = builtKeypointId;
      _lastSeenCueIndex = -1;
      _awaitingSeekToCue = null;
      _loadedClipCardIndex = -1;
      _completionHandled = false;
      _revealToCardTarget = null;
      _revealToClipIndex = -1;
    }

    final built = const KeypointCardsBuilder().build(
      items: items,
      currentLearningItemIndex: lessonState.currentLearningItemIndex,
      liveIndexInCurrentItem: _liveIndexForCurrentItem(
        lessonState,
        items.elementAtOrDefault(
          lessonState.currentLearningItemIndex,
          defaultValue: const LearningItemEntity(),
        ),
      ),
      revealToClipIndex: _revealToClipIndex,
      revealToCard: _revealToCardTarget,
    );
    _cardToClip = built.cardToClip;
    if (switchedKeypoint || _takeawayLearningItemId != built.takeawayLearningItemId) {
      _recapGateCueIndex = -1;
      _recapTapResumed = false;
      // A different takeaway means a different keypoint's recap — its flip
      // state must not leak onto the new card, and neither must the previous
      // keypoint's completion latch.
      recapFlipOpened = false;
      _keypointCompletedThisRun = false;
    }
    _takeawayLearningItemId = built.takeawayLearningItemId;
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

    // The daily-quota wall as a card: once the deck's content has REACHED the
    // cap, everything past it — including the done card, whose very mount files
    // a completion — is replaced by the single locked card. Before the content
    // reaches the cap the deck stays untouched, or the wall would show up a
    // card early and page mode would fight the live-edge advance for the free
    // cards still unread. Content past the cap can exist (a keypoint half-read
    // on an earlier day re-locks today: only COMPLETED keypoints stay free), and
    // is cut for the same reason narration is bounded — it is what the ticket
    // buys.
    final wallCap = _paywallCardCap;
    final lockedCardShown = _showQuotaLockedCard && wallCap != null && built.liveCardIndex >= wallCap;
    final cards = lockedCardShown
        ? [
            ...built.cards.where((c) => !c.isDone).take(wallCap + 1),
            const KeypointCardDescriptor.locked(),
          ]
        : built.cards;
    final lockedCardIndex = lockedCardShown ? cards.length - 1 : -1;

    final wasFollowingEdge = state.viewedCardIndex == state.furthestCardIndex && !_edgeFollowSuspended;
    final previousViewedIndex = state.viewedCardIndex.clamp(0, cards.length - 1);

    // Do NOT clamp this to the pinned view. `furthestCardIndex` is what the
    // `PageView` is sized from (`itemCount: furthestCardIndex + 1`), so holding
    // it at 0 during the entry pin leaves the deck with a single page: nothing
    // to swipe to, and the pin is released by [viewCard] — which that swipe is
    // the only way to reach. Tried on 2026-08-03 to stop the pip bar showing a
    // fresh keypoint's cards as already read; it deadlocked every keypoint
    // instead. The pip-bar leak is stale `@lazySingleton` TheoryCubit /
    // ExerciseCubit indices read back by [_liveIndexForCurrentItem] during the
    // entry burst, and it has to be fixed at that source, not here.
    // Once the keypoint is COMPLETED the done card stays unlocked. Keying this
    // on completionJustTriggered alone unlocked it for exactly one rebuild:
    // the next lesson emit recomputed furthest from the live edge, yanking the
    // bound — and, through wasFollowingEdge below, the reader's view — from
    // the recap card back onto the last real card, over and over ("lướt bị
    // nhảy lại card trước", 2026-08-07). Every bounce also re-parked narration,
    // pausing the recap the reader had just tapped to hear. The latch (not the
    // raw lesson flag) is what keeps a STALE completion from a previous run
    // out of a fresh entry — see [_keypointCompletedThisRun].
    final isKeypointCompleted = _keypointCompletedThisRun;
    // A locked deck's furthest IS the locked card: reachability is what makes
    // the wall swipe-able as an ordinary page (`itemCount` and the pip bar both
    // derive from it). The lesson's real progress stays where it is — the voice
    // and the live-edge advance are both bounded by [_paywallCardCap], so
    // nothing reads this as "the reader got further".
    final nextFurthestIndex = lockedCardShown
        ? lockedCardIndex
        : isKeypointCompleted
        ? built.doneCardIndex
        : built.liveCardIndex;

    // Opening a keypoint always lands on its FIRST card, never where the reader
    // left off. Position inside a keypoint is deliberately not restored (product
    // call): re-entering re-reads from the top.
    //
    // The pin has to outlive the entry BURST, not just the first build: the live
    // edge climbs to the stored position several rebuilds in, and by then
    // `wasFollowingEdge` is trivially true (view 0 == edge 0) and would carry the
    // view along with it. It is released by the first [viewCard], i.e. the moment
    // the reader — or the voice — actually moves the deck.
    // The completion jump also respects the walk's suspension: a keypoint that
    // completes DURING the catch-up walk gets its view landed by the walk's own
    // viewCard once it knows where — a jump from here would be the very slam the
    // suspension exists to stop.
    // The edge-follow may carry the view UP TO the last free card, never onto
    // the locked card itself. `furthestCardIndex` has to point at the locked
    // card so it exists as a page — but a reader riding the live edge who
    // advances the last free card must LAND on that card, not get thrown one
    // further onto the wall ("lướt được card 1 2 mà đã ra card khoá rồi",
    // 2026-08-12: the follow skipped the last free card entirely). Stepping
    // onto the wall is the reader's own swipe, always.
    // (A reader ALREADY standing on the wall stays there — the clamp is only for
    // the follow that would move them onto it, not off it.)
    final edgeFollowTarget = lockedCardShown && previousViewedIndex < lockedCardIndex
        ? math.min(nextFurthestIndex, lockedCardIndex - 1)
        : nextFurthestIndex;
    final restoredViewedIndex = completionJustTriggered && !_edgeFollowSuspended
        ? nextFurthestIndex
        : _entryPinActive
        ? 0
        : (wasFollowingEdge ? edgeFollowTarget : previousViewedIndex);

    // The paywall wall clamps the restored position too. Without this, a reader
    // who got past the wall before it existed would be handed straight back to
    // where they were, every time they re-entered — this emit does not go through
    // [viewCard], so its cap does not cover it. With the locked card shown, the
    // card itself is the one allowed place past the cap (same rule as viewCard).
    final cap = _paywallCardCap;
    final maxRestorable = cap == null ? null : (lockedCardShown ? lockedCardIndex : cap);
    final nextViewedIndex = maxRestorable != null && restoredViewedIndex > maxRestorable ? maxRestorable : restoredViewedIndex;

    // TEMP-TRACE(deck2)
    if (nextViewedIndex != previousViewedIndex || nextFurthestIndex != state.furthestCardIndex) {
      _trace(
        'rebuild view=$previousViewedIndex→$nextViewedIndex furthest=${state.furthestCardIndex}→$nextFurthestIndex '
        'live=${built.liveCardIndex} reveal=${built.revealCardIndex} cards=${built.cards.length} '
        'edge=$wasFollowingEdge pin=$_entryPinActive pendingFollow=$_pendingVoiceFollow done=$isKeypointCompleted cap=$cap',
      );
    }

    emit(
      state.copyWith(
        status: KeypointCardStatus.ready,
        cards: cards,
        furthestCardIndex: nextFurthestIndex,
        // Bounded by the truncated deck: `revealBound` sizes the PageView, so a
        // reveal index pointing past the locked card would build pages the card
        // list no longer has.
        narrationRevealIndex: lockedCardShown ? math.min(built.revealCardIndex, lockedCardIndex) : built.revealCardIndex,
        viewedCardIndex: nextViewedIndex,
        isLiveCardAnswered: _isCardAnswered(cards, nextFurthestIndex),
      ),
    );

    if (nextViewedIndex != previousViewedIndex) {
      _reconcileQuizPause(previousViewedIndex, nextViewedIndex);
    }
    // A resume that arrived before this keypoint had cards (the listening chain
    // hopped into it while the app was away) gets its follow now that they exist.
    // It lands the view itself, so the ordinary "point narration at the page"
    // step below would only fight it.
    final owedFollow = _pendingVoiceFollow && !_isBackgrounded;
    final followedVoice = owedFollow && _followVoiceNow();
    // ONE SHOT, and only while the retry can still be needed: the flag exists for
    // a resume that beat this keypoint's items, so the moment items exist it has
    // either landed or had nothing to land. Leaving it armed past that turned every
    // later rebuild — every swipe — into "jump to wherever the voice is".
    if (owedFollow && lessonState.pageData.items.isNotEmpty) _pendingVoiceFollow = false;
    // Every card change takes narration with it, so the voice is always reading
    // the page on screen.
    if (!followedVoice) _ensureNarrationOnViewedCard();
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
