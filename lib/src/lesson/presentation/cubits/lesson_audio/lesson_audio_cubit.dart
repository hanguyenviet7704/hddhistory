part of '../../../lesson.dart';

class LessonAudioCubit extends Cubit<LessonAudioState> {
  LessonAudioCubit() : super(LessonAudioState.initial()) {
    // The OS transport is the reader's own hand: a lock-screen/Control-Center
    // pause pins silence exactly like the in-app pause button ("chủ động tắt
    // âm" — without this, the recap flip and forward-swipe autoplay restarted
    // narration the reader had just switched off, 2026-08-09). OS play is the
    // symmetric consent and lifts the pin. Internal soft pauses (gates,
    // overlays, source switches) go through pauseFromApp and never touch it.
    _handler.onOsPause = () {
      _setPausedByUser(true, 'os pause');
      // Pausing on the lock screen ends the listening session, so it also ends
      // the chain: nothing more is read after the keypoint in flight until the
      // reader presses play again (product call, 2026-08-10). Re-arming on play
      // belongs to [ListenChainController], which knows what may come next.
      unawaited(dropQueuedTail());
    };
    _handler.onOsPlay = () => _setPausedByUser(false, 'os play');
  }

  /// Background playback + OS media controls (lock-screen/Control Center/
  /// Android notification) for this player live in the app-lifetime
  /// [LessonAudioHandler] — registered once at bootstrap (see
  /// `AppService._configLessonAudio`) and resolved here rather than owned by
  /// this cubit, so leaving/re-entering Listen mode never tears down or
  /// recreates the underlying `just_audio` player.
  LessonAudioHandler get _handler => AppDI.injector.get<LessonAudioHandler>();

  // When the user asks to listen while the source is still (pre)loading, play
  // as soon as it becomes ready instead of dropping the intent.
  bool _playWhenReady = false;

  /// Test seam for the pending listen intent: every real path that arms it
  /// ends in player I/O, which a unit test cannot host.
  @visibleForTesting
  bool get debugPlayWhenReady => _playWhenReady;
  @visibleForTesting
  set debugPlayWhenReady(bool value) => _playWhenReady = value;

  /// Bumped by every [_initializePlayer] call, so a load that has been
  /// SUPERSEDED can tell and stay quiet.
  ///
  /// This is what keeps fast swiping from killing narration. Each card change
  /// loads that card's clip over whatever was playing; starting a load while
  /// another is in flight makes `just_audio` throw `PlayerInterruptedException`
  /// ("Loading interrupted") out of the FIRST one — which then reported failure
  /// over the perfectly good load that replaced it, leaving a dead player.
  /// Comparing generations catches that even when both loads are for the same
  /// url, which the keypointId/sourceUrl check alone cannot.
  int _loadGeneration = 0;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<just_audio.PlayerState>? _playerStateSubscription;
  StreamSubscription<just_audio.ProcessingState>? _processingStateSubscription;
  StreamSubscription<int?>? _slotSubscription;

  /// Per-CARD narration clips for the configured keypoint, in card order (see
  /// [KeypointAudioEntity.segments]). Empty for keypoints dubbed before per-card
  /// generation — those keep the single whole-keypoint clip and get no per-card
  /// behaviour until they are re-dubbed.
  List<String> _cardClips = const [];

  /// Cue math for the keypoint's ONE merged narration file, or null when the
  /// keypoint has no merged audio for the active locale — then every legacy
  /// per-card path below applies unchanged.
  MergedNarrationTimeline? _timeline;

  MergedNarrationTimeline? get timeline => _timeline;

  bool get isMergedMode => _timeline != null;

  /// Keypoints appended to the LIVE playlist but not reached yet, in queue
  /// order — background listening's chain across keypoints (see
  /// [appendKeypoint]). Empty in every other case, which is what leaves every
  /// single-keypoint path below exactly as it was.
  final List<QueuedKeypointNarration> _queuedTail = [];

  /// Queue slot the player is on, as far as this cubit has accounted for it.
  /// Seeded from the player AFTER each load (never from a stream replay — see
  /// [_initializePlayer]).
  int _playedSlot = 0;

  final StreamController<({String from, String to})> _keypointHops = StreamController<({String from, String to})>.broadcast();

  /// Fires when the QUEUE walks out of one keypoint's merged file and into the
  /// next — the chain's signal that the voice has left the keypoint the app is
  /// showing. Never fires for an ordinary keypoint switch; that one goes through
  /// [configure].
  ///
  /// Carries the keypoint LEFT as well as the one entered: progress belongs to
  /// the former, and by the time a listener runs this cubit's state already
  /// names the latter.
  Stream<({String from, String to})> get keypointHops => _keypointHops.stream;

  bool get hasQueuedNext => _queuedTail.isNotEmpty;

  /// Whether the merged file the player is reading RIGHT NOW belongs to
  /// [keypointId].
  bool isPlayingKeypoint(String keypointId) => keypointId.isNotEmpty && state.keypointId == keypointId && state.hasStartedSession;

  /// Keypoint the QUEUE walked into — playing without this cubit ever having
  /// loaded it. Cleared the moment a load takes the player somewhere else.
  String _hoppedKeypointId = '';

  /// Whether [keypointId] is playing because the chain hopped into it. The ONLY
  /// case where `LessonPage` must adopt the refreshed entity instead of
  /// configuring it.
  ///
  /// Deliberately NOT "is this keypoint playing" (which [isPlayingKeypoint]
  /// answers): entering a keypoint normally starts a session from the ROADMAP
  /// stub, which carries only the legacy whole-keypoint `audio.url` — no cue map
  /// and no per-card clips. The merged file arrives seconds later on the full
  /// lesson payload, as a refresh for the SAME keypoint, and that refresh must
  /// reach [configure]. Gating the page's adopt branch on "playing" swallowed it
  /// and left merged mode OFF for every keypoint (caught on device 2026-08-10:
  /// the deck fell back to `loadCard` per-card clips everywhere).
  bool isQueueHoppedKeypoint(String keypointId) => keypointId.isNotEmpty && _hoppedKeypointId == keypointId && state.keypointId == keypointId;

  /// Queues [keypoint]'s merged narration behind the one playing, so the voice
  /// carries on into it without a load at the boundary.
  ///
  /// Merged mode only, and only over a live session: the per-card path has no
  /// cue map to make sense of a second keypoint, and a queue appended to a
  /// player that never loaded anything would play out of order.
  ///
  /// Returns false when there is nothing to queue — the caller ([
  /// ListenChainController]) treats that as "the chain ends with this keypoint".
  Future<bool> appendKeypoint(KeypointEntity keypoint) async {
    if (!isMergedMode || !state.isReady) return false;
    if (keypoint.id.isEmpty || keypoint.id == state.keypointId) return false;
    if (_queuedTail.any((queued) => queued.keypointId == keypoint.id)) return false;
    final merged = keypoint.resolvedMergedAudio;
    if (merged == null || !merged.isUsable) return false;

    final title = keypoint.title.text;
    try {
      await _handler.appendItem(
        url: merged.url,
        id: keypoint.id,
        title: title,
        artUri: keypoint.image,
        duration: _mergedDuration(merged),
      );
    } catch (error, stackTrace) {
      // A tail that cannot be queued is not a failure of the run that IS
      // playing — the reader loses the chain, not the keypoint they are hearing.
      // Reported, never surfaced as a player failure.
      AppService.instance.appTrackingService.trackError(
        error,
        stackTrace: stackTrace,
        errorType: 'LessonAudioCubit.appendKeypoint',
        context: {'keypoint_id': keypoint.id},
      );
      return false;
    }

    _queuedTail.add(
      QueuedKeypointNarration(
        keypointId: keypoint.id,
        title: title,
        imageUrl: keypoint.image,
        url: merged.url,
        timeline: MergedNarrationTimeline(merged),
      ),
    );
    return true;
  }

  /// Drops the queued-but-unheard tail, leaving the keypoint in flight to finish
  /// normally. Disarming the chain — back on screen, or the reader paused.
  Future<void> dropQueuedTail() async {
    if (_queuedTail.isEmpty) return;
    _queuedTail.clear();
    try {
      await _handler.dropTailAfterCurrent();
    } catch (_) {
      // The tail is bookkeeping either way: it is already gone from this cubit,
      // and a slot the platform refuses to drop is one the chain no longer
      // follows (no timeline for it) — it would end the run, not misread it.
    }
  }

  /// The player walked into a new queue slot: the voice is now inside the NEXT
  /// keypoint's file. Nothing loaded, nothing paused — the platform did it — so
  /// this is pure bookkeeping plus the hop signal the chain acts on.
  void _onSlotChanged(int? slot) {
    if (slot == null || slot <= _playedSlot) return;
    // Nothing queued to walk into: either the LEGACY per-card queue is playing
    // (its slots are clips, not keypoints — see [playRestOfKeypoint]) or this is
    // a value replayed from a playlist that has since been replaced.
    // Deliberately does not advance `_playedSlot`: a stale slot recorded here
    // would read as "already accounted for" and swallow the first real hop.
    if (_queuedTail.isEmpty) return;
    // One step per slot: a queue is only ever appended to one keypoint ahead, so
    // this normally runs exactly once, but a slot jump must never desync the FIFO.
    while (_playedSlot < slot && _queuedTail.isNotEmpty) {
      _playedSlot++;
      _adoptQueuedNarration(_queuedTail.removeAt(0));
    }
    _playedSlot = slot;
  }

  void _adoptQueuedNarration(QueuedKeypointNarration queued) {
    final leftKeypointId = state.keypointId;
    _hoppedKeypointId = queued.keypointId;
    _timeline = queued.timeline;
    // A different keypoint's clip universe. The deck supplies a fresh set once
    // its learning items land (`LessonPage._syncAudioKeypoint`'s adopt branch);
    // nothing may be inherited from the keypoint just left.
    _cardClips = const [];
    _narratableClips = null;
    _activeClipIndex = -1;
    _isAheadOfDeck = false;
    _queueClipIndexes = const [];
    // The deck of the keypoint just left owned the old bound; this keypoint has
    // no deck yet, and the reader is off screen (the only way to get here), where
    // narration reads straight through by product call.
    _allowedThroughCue = unboundedCue;
    // Fresh file: the first tick is a starting point, not a boundary crossing.
    _previousTickCue = -1;
    _lastResumePersistMs = -1;

    final cueIndex = queued.timeline.cueIndexAtMs(0);
    final cue = queued.timeline.cueAt(cueIndex);
    emit(
      state.copyWith(
        keypointId: queued.keypointId,
        sourceUrl: queued.url,
        title: queued.title,
        imageUrl: queued.imageUrl,
        isMergedMode: true,
        status: LessonAudioLoadStatus.ready,
        hasStartedSession: true,
        hasCompletedPlayback: false,
        isPlaying: true,
        activeCueIndex: cueIndex,
        positionSeconds: 0,
        durationSeconds: cue == null ? 0 : (cue.durMs / 1000).round().clamp(0, 359999),
        errorMessage: null,
      ),
    );
    _handler.publishMediaItem(
      id: queued.keypointId,
      title: queued.title,
      artUri: queued.imageUrl,
      duration: _mergedDuration(queued.timeline.merged),
    );
    _keypointHops.add((from: leftKeypointId, to: queued.keypointId));
  }

  /// Whole-file length from the cue map, or null when the backend shipped none
  /// (older merges) — the lock screen then simply shows no total.
  Duration? _mergedDuration(MergedKeypointAudioEntity merged) => merged.durationMs > 0 ? Duration(milliseconds: merged.durationMs) : null;

  /// The deck's copy of the keypoint the queue hopped into has landed: take its
  /// per-card clips and metadata WITHOUT touching the player.
  ///
  /// The merged file for this keypoint is already playing; configuring it would
  /// reload the very source that is mid-sentence, which is the hiccup the queue
  /// exists to avoid.
  void adoptQueuedKeypoint(KeypointEntity keypoint) {
    if (!isPlayingKeypoint(keypoint.id)) return;
    _cardClips = keypoint.resolvedAudioSegments;
    final title = keypoint.title.text;
    final nextTitle = title.isEmpty ? state.title : title;
    final nextImage = keypoint.image.isEmpty ? state.imageUrl : keypoint.image;
    if (nextTitle == state.title && nextImage == state.imageUrl) return;
    emit(state.copyWith(title: nextTitle, imageUrl: nextImage));
    final merged = keypoint.resolvedMergedAudio;
    _handler.publishMediaItem(
      id: keypoint.id,
      title: nextTitle,
      artUri: nextImage,
      duration: merged == null ? null : _mergedDuration(merged),
    );
  }

  /// "No bound" sentinel for [_allowedThroughCue] — any real cue index is
  /// smaller.
  static const int unboundedCue = 1 << 30;

  /// Highest cue the voice may play INTO without stopping. Owned by the deck
  /// ([KeypointCardCubit] computes it from its gates + app lifecycle); this
  /// cubit only enforces it at cue boundaries in [_onMergedTick].
  int _allowedThroughCue = unboundedCue;

  /// Cue of the previous position tick, or -1 right after a load/seek.
  ///
  /// The gate bound is enforced only on a genuine CROSSING (previous tick at
  /// or under the bound, this one past it) — never on absolute position. A
  /// resume or seek legitimately OPENS the file deep past the bound while the
  /// deck is still catching up (entry burst, reveal-on-return); clamping on
  /// absolute position yanked the voice back to the top of the keypoint the
  /// moment resume playback started.
  int _previousTickCue = -1;

  /// File-time home of one card, or null (no cue / silent card) — the deck's
  /// bridge from card identity to [playCue]'s cue index.
  int? cueForCard({required String learningItemId, required int documentIndex}) => _timeline?.cueIndexForCard(learningItemId: learningItemId, documentIndex: documentIndex);

  /// The deck's gate bound. RAISING it while the voice sits paused at that
  /// very boundary does not auto-play — the deck decides that (it knows why
  /// the bound rose).
  void setAllowedThroughCue(int cueIndex) => _allowedThroughCue = cueIndex;

  /// Last merged position bookmarked, for the ~5s write throttle.
  int _lastResumePersistMs = -1;

  /// Bookmarks the merged position every ~5s of playback so an app kill loses
  /// at most a few seconds; [pause]/[close] write the exact position on top.
  void _maybePersistResume(int positionMs) {
    if (!isMergedMode || !state.isPlaying || state.keypointId.isEmpty) return;
    if (_lastResumePersistMs >= 0 && (positionMs - _lastResumePersistMs).abs() < 5000) return;
    _lastResumePersistMs = positionMs;
    ListenResumeCubit.instanceOrNull?.record(keypointId: state.keypointId, positionMs: positionMs);
  }

  void _persistResumeNow() {
    if (!isMergedMode || !state.hasStartedSession || state.keypointId.isEmpty) return;
    // A run that ENDED and sits idle is not "đang nghe dở": writing here would
    // recreate the bookmark completeCurrentKeypoint just cleared (close() runs
    // after completion) and drag the next entry to the end of the file.
    if (state.hasCompletedPlayback && !state.isPlaying) return;
    ListenResumeCubit.instanceOrNull?.record(keypointId: state.keypointId, positionMs: _handler.position.inMilliseconds);
  }

  /// True when this keypoint has per-card clips, i.e. narration can be scoped to
  /// the page on screen via [loadCard].
  bool get hasCardClips => _cardClips.any((clip) => clip.isNotEmpty);

  /// Whether [clipIndex] names a clip this keypoint actually has. A keypoint
  /// dubbed before exercise questions were narrated has clips for its theory
  /// cards only, so its later cards ask for indexes past the end — the caller
  /// leaves narration alone rather than pointing at nothing.
  bool hasClipAt(int clipIndex) => clipIndex >= 0 && clipIndex < _cardClips.length && _cardClips[clipIndex].isNotEmpty;

  /// Clip currently loaded, as an index into [_cardClips] — the same space
  /// [loadCard] takes. Kept so narration can find its own way to the next clip
  /// when the deck is not there to point it (see [playNextClip]).
  int _activeClipIndex = -1;

  /// True while the player holds the read-to-the-end QUEUE rather than the one
  /// clip the deck pointed it at — i.e. the voice is free to run ahead of the
  /// page on screen. Only [playRestOfKeypoint] sets it; any deck-driven
  /// [loadCard] tears the queue down and clears it.
  bool _isAheadOfDeck = false;

  bool get isAheadOfDeck => _isAheadOfDeck;

  /// Clip index behind each slot of the queue [playRestOfKeypoint] handed the
  /// player. Cards with nothing to read are skipped when the queue is built, so a
  /// queue slot is NOT a clip index — this is the map between them, and without
  /// it the slot the player reports means nothing to the deck.
  List<int> _queueClipIndexes = const [];

  /// Clip indices that belong to the reading flow at all — theory documents
  /// only, supplied by the deck ([KeypointCardCubit]) from the card list it
  /// builds. Exercise-question clips still exist in `segments` (the backend
  /// dubs questions), but the exercise flow left the keypoint screen, so the
  /// background queue must not read them aloud. Null means "no deck has said" —
  /// then nothing is filtered, which keeps this cubit correct stand-alone.
  Set<int>? _narratableClips;

  void setNarratableClips(Set<int> clips) {
    _narratableClips = clips;
  }

  bool _isNarratable(int clipIndex) => _narratableClips == null || _narratableClips!.contains(clipIndex);

  /// Clip the voice is on while reading ahead of the deck, or null when the two
  /// are in step (then the deck already knows where narration is) or when the
  /// player has no slot to report.
  int? get narratingClipIndex {
    if (!_isAheadOfDeck) return null;
    final slot = _handler.currentIndex;
    if (slot == null || slot < 0 || slot >= _queueClipIndexes.length) return null;
    return _queueClipIndexes[slot];
  }

  /// How far into that clip the voice is, so resuming can carry the position
  /// across instead of restarting the card.
  Duration get narratingPosition => _handler.position;

  /// Reads the rest of the keypoint straight through, WITHOUT the deck moving.
  ///
  /// This is the backgrounded listener's path. On screen the deck is what walks
  /// narration from card to card, and it deliberately holds at an unanswered
  /// question — a page that walked itself past the quiz would be answering for
  /// the reader. With the app in the background there is no page to hold and no
  /// way to answer, and the OS now-playing controls promise an ordinary audio
  /// player, so narration reads on to the end of the keypoint instead.
  ///
  /// Hands every remaining clip to the player AT ONCE so the platform walks the
  /// queue itself. Chaining them one at a time from the `completed` listener
  /// works on paper but leaves a network fetch at every card boundary and needs
  /// Dart to still be scheduled to start each one — neither is a promise worth
  /// making to an app the OS has put in the background.
  ///
  /// Deliberately touches nothing but the player. Advancing the deck for real
  /// would run `LessonCubit.nextLearningItem()` past the last item into
  /// `completeCurrentKeypoint()`, writing keypoint progress to the server (and
  /// pushing a route) for a keypoint whose questions were never answered.
  ///
  /// Uses the per-card clips rather than the keypoint's single whole-length
  /// `audio.url`: that one file would be the tidier now-playing track, but the
  /// API ships no per-segment offsets, so there is no way to start it at the
  /// card the reader actually reached — it could only ever replay the keypoint
  /// from the top.
  ///
  /// Returns false when nothing is left to read.
  Future<bool> playRestOfKeypoint() async {
    if (_activeClipIndex < 0) return false;
    // Skip cards with nothing to read (video, roleplay) rather than stopping —
    // and remember which clip each surviving slot holds, so the slot the player
    // reports can be turned back into a card when the reader returns.
    final remaining = <String>[];
    final queueClipIndexes = <int>[];
    for (var i = _activeClipIndex + 1; i < _cardClips.length; i++) {
      if (_cardClips[i].isEmpty) continue;
      // Question clips are skipped like empty ones: dubbed, but narrated nowhere
      // since the exercise flow left this screen.
      if (!_isNarratable(i)) continue;
      remaining.add(_cardClips[i]);
      queueClipIndexes.add(i);
    }
    if (remaining.isEmpty) return false;
    _queueClipIndexes = queueClipIndexes;

    _playWhenReady = true;
    await _resetHandlerForNewKeypoint();
    // This run consumes every clip that was left, so a second call finds nothing
    // and cannot queue the tail of the keypoint twice.
    _activeClipIndex = _cardClips.length - 1;
    _isAheadOfDeck = true;
    emit(
      state.copyWith(
        sourceUrl: remaining.first,
        status: LessonAudioLoadStatus.initial,
        positionSeconds: 0,
        durationSeconds: 0,
        isPlaying: false,
        hasStartedSession: false,
        hasCompletedPlayback: false,
        errorMessage: null,
      ),
    );
    await _initializePlayer(queue: remaining);
    return true;
  }

  Future<void> configure(KeypointEntity keypoint) async {
    _cardClips = keypoint.resolvedAudioSegments;
    _queueClipIndexes = const [];
    // A different keypoint's clip universe — the deck will supply a fresh set.
    _narratableClips = null;
    // A different keypoint's clip list — the old index means nothing in it.
    _activeClipIndex = -1;
    _isAheadOfDeck = false;
    // Any chain queued behind the previous keypoint belongs to a run that is
    // over: the load below replaces the whole playlist, so the tail would name
    // slots that no longer exist.
    _queuedTail.clear();
    // Merged-first: one file for the whole keypoint when the backend has it,
    // else first card's clip when dubbed per card, else the legacy single file.
    final mergedAudio = keypoint.resolvedMergedAudio;
    _timeline = mergedAudio == null ? null : MergedNarrationTimeline(mergedAudio);
    _allowedThroughCue = unboundedCue;
    _previousTickCue = -1;
    _lastResumePersistMs = -1;
    final nextSourceUrl =
        mergedAudio?.url ??
        _cardClips.firstWhere(
          (clip) => clip.isNotEmpty,
          orElse: () => keypoint.resolvedAudioUrl,
        );
    final nextTitle = keypoint.title.text;

    if (state.keypointId == keypoint.id && state.sourceUrl == nextSourceUrl && state.imageUrl == keypoint.image && state.title == nextTitle) {
      return;
    }

    // TEMP-DEBUG(mute)
    LogDev.warning(
      '[MuteDbg] configure RESET kp=${keypoint.id} sameId=${state.keypointId == keypoint.id} playWhenReady=$_playWhenReady '
      'merged=${mergedAudio != null} rawMergedLangs=${keypoint.audio?.merged?.keys.toList()} segs=${_cardClips.length}',
    );
    // A refreshed entity for the SAME keypoint — the full lesson payload
    // landing over the roadmap stub, typically swapping the source to the
    // merged file — must not eat a listen intent already pending for it. The
    // entry's enterAudioMode registered the intent while its load was in
    // flight; wiping it here left a directly-opened keypoint silent, and the
    // page-level re-sync retry couldn't rescue it because the deck's own
    // silent re-point had already flipped hasStartedSession back on ("bấm
    // trực tiếp vào 1 keypoint thì không tự động bật audio", 2026-08-09
    // [MuteDbg]). A DIFFERENT keypoint starts from silence, as always. The
    // pinned-mute invariant is untouched: the carried intent is still honoured
    // through [play], which refuses under `_pausedByUser`.
    _playWhenReady = _playWhenReady && state.keypointId == keypoint.id;
    await _resetHandlerForNewKeypoint();

    emit(
      LessonAudioState.initial().copyWith(
        keypointId: keypoint.id,
        sourceUrl: nextSourceUrl,
        imageUrl: keypoint.image,
        title: nextTitle,
        isMergedMode: _timeline != null,
        status: nextSourceUrl.isEmpty ? LessonAudioLoadStatus.unavailable : LessonAudioLoadStatus.initial,
      ),
    );
  }

  /// Warm the player in the background (no autoplay) so entering "Nghe" finds
  /// it already prepared instead of showing the ~5s load spinner. Safe no-op
  /// when there's no source or a session already started. Triggered from the
  /// lesson page while the user is still reading — kept out of [configure] so
  /// simply showing a keypoint (read mode) stays free of audio I/O.
  Future<void> preload() async {
    if (!state.hasUsableSource || state.hasStartedSession) return;
    await _initializePlayer();
  }

  /// [startAt] is the resume path: an absolute position in the MERGED file to
  /// open at (ignored in legacy mode, which has no cue map to make sense of
  /// it). Loading at the position beats loading at zero and seeking after —
  /// the latter is audible as the keypoint restarting before it jumps.
  Future<void> enterAudioMode({bool autoplay = true, Duration? startAt}) async {
    // Entering listen mode is an explicit ask for sound — any pinned silence
    // is over. Callers must therefore be genuine asks: the header play tap,
    // retry, and a NEW keypoint's standing autoplay. A same-keypoint re-sync
    // is not one (see LessonPage._syncAudioKeypoint), which used to funnel
    // through here on every entity refresh and silently wipe the reader's
    // mute ("tap card cuối tự bật tiếng", 2026-08-09 [MuteDbg]).
    if (autoplay) _setPausedByUser(false, 'enterAudioMode');
    // TEMP-DEBUG(mute)
    LogDev.warning(
      '[MuteDbg] enterAudioMode autoplay=$autoplay status=${state.status} usable=${state.hasUsableSource} '
      'session=${state.hasStartedSession} ready=${state.isReady} playWhenReady=$_playWhenReady',
    );
    if (!state.hasUsableSource) {
      emit(
        state.copyWith(
          status: LessonAudioLoadStatus.unavailable,
          isPlaying: false,
        ),
      );
      return;
    }

    // A load that FAILED (dropped connection, or one superseded so fast the
    // player gave up) leaves `hasStartedSession` true, which made every later tap
    // fall through both branches below and do nothing at all — the narration
    // button looked alive and was dead. Start the session over instead.
    if (state.status == LessonAudioLoadStatus.failure) {
      await _resetForReload();
    }

    if (autoplay) _playWhenReady = true;

    // Already prepared (e.g. background preload finished): just play.
    if (state.isReady) {
      if (startAt != null && isMergedMode) {
        try {
          await _handler.seek(startAt);
        } catch (error, stackTrace) {
          _handleFailure(error, stackTrace, errorType: 'LessonAudioCubit.enterAudioMode');
          return;
        }
      }
      if (autoplay) await play();
      return;
    }

    // Not started yet → start loading now. If a preload is already in flight
    // (loading), _initializePlayer's completion will honor _playWhenReady, so
    // we don't kick off a second load here.
    if (!state.hasStartedSession) {
      await _initializePlayer(startAt: isMergedMode ? startAt : null);
    }
  }

  /// Points the merged file at [cueIndex] (+[offset] inside it). The deck's
  /// merged-mode replacement for [loadCard] — a seek, never a source reload.
  ///
  /// [byUser] follows [play]'s contract: only the reader's own control lifts a
  /// pinned mute; a system autoplay while pinned seeks silently (the play
  /// inside is refused).
  Future<void> playCue(int cueIndex, {bool autoplay = false, Duration? offset, bool byUser = false}) async {
    if (autoplay && byUser) _setPausedByUser(false, 'playCue(byUser: true)');
    final timeline = _timeline;
    final cue = timeline?.cueAt(cueIndex);
    if (timeline == null || cue == null || cue.durMs <= 0) {
      if (autoplay) {
        LogDev.warning(
          '[RecapGate] playCue($cueIndex) refused: timeline=${timeline != null} '
          'cue=${cue != null} durMs=${cue?.durMs}',
        );
      }
      return;
    }

    final target = Duration(milliseconds: cue.startMs + (offset?.inMilliseconds ?? 0));
    if (!state.hasStartedSession) {
      // RAISE the intent, never lower it — same lesson as [loadCard]'s
      // re-point branch: entry calls arrive with autoplay:false while
      // enterAudioMode's pending `true` is what the load must honour.
      _playWhenReady = _playWhenReady || autoplay;
      await _initializePlayer(startAt: target);
      return;
    }
    // A load in flight: seeking just_audio mid-load THROWS PlayerInterrupted
    // out of that load, which resets the session to "never started" and drops
    // the pending play intent — the silent-entry bug ("bấm trực tiếp vào 1
    // keypoint thì không tự động bật audio", 2026-08-09). Leave the load
    // alone; the deck re-points narration on every card change anyway, and an
    // entry load already targets the entry cue.
    if (!state.isReady) {
      _playWhenReady = _playWhenReady || autoplay;
      return;
    }
    try {
      await _handler.seek(target);
      // The seek re-bases the crossing detector: landing here was the deck's
      // own doing, never a boundary crossing to clamp.
      _previousTickCue = cueIndex;
      emit(state.copyWith(activeCueIndex: cueIndex, hasCompletedPlayback: false));
      if (autoplay) await play();
    } catch (error, stackTrace) {
      _handleFailure(error, stackTrace, errorType: 'LessonAudioCubit.playCue');
    }
  }

  /// Switches narration to the clip that reads card [cardIndex].
  ///
  /// This is what ties the voice to the page: each card has its own file, so
  /// reaching the end of a card simply ends the clip — playback cannot spill
  /// into a page the reader hasn't opened, and finding where a card starts needs
  /// no timeline guessing. Returns false when this keypoint has no clip for that
  /// card (a legacy whole-keypoint dub, or a card with no narratable text), in
  /// which case narration is left alone.
  Future<bool> loadCard(int cardIndex, {bool autoplay = false, Duration? startAt}) async {
    if (cardIndex < 0 || cardIndex >= _cardClips.length) return false;
    final url = _cardClips[cardIndex];
    if (url.isEmpty) return false;

    // Every call that arrives here is the DECK pointing narration at a page, so
    // the two are back in step — only [playRestOfKeypoint] breaks them apart.
    // Read before clearing: the shortcut below has to know we are LEAVING queue
    // mode, and clearing first would make its own guard always true.
    final wasAheadOfDeck = _isAheadOfDeck;
    _activeClipIndex = cardIndex;
    _isAheadOfDeck = false;
    // Leaving queue mode: the slot map describes a queue that is about to be
    // replaced by a single source, so it must not outlive it.
    _queueClipIndexes = const [];

    // `!wasAheadOfDeck` matters: in queue mode the player holds every remaining
    // clip, and its first one may well be this very url. Taking the shortcut
    // below would leave that queue loaded, and the voice would walk off the page
    // again the moment the clip ended. Coming back to the deck always reloads a
    // single source.
    if (state.sourceUrl == url && state.hasStartedSession && !wasAheadOfDeck && state.status != LessonAudioLoadStatus.failure) {
      // Still fetching this very clip — starting a second load is exactly what
      // interrupts the first one, so leave the play intent for the load in flight
      // to honour and let it finish.
      if (!state.isReady) {
        // RAISE the intent, never lower it. This branch is reached by simply
        // re-pointing at the clip that is already loading, and the caller
        // computes `autoplay` from "is it playing right now?" — which is false
        // while it loads. Assigning that over a pending `true` is what silenced
        // narration on entry: `enterAudioMode` asks for autoplay at postFrame,
        // then the lesson's learning items land mid-load and
        // `KeypointCardCubit` re-points at card 0 with `autoplay: false`,
        // cancelling the very intent it was echoing.
        _playWhenReady = _playWhenReady || autoplay;
        return true;
      }
      // Same clip already loaded (e.g. swiping away and back): restart it so the
      // card is read from its beginning rather than from wherever it stopped —
      // unless a position was handed in, which is a resume, not a re-read.
      await seekTo(startAt ?? Duration.zero);
      if (autoplay) await play();
      return true;
    }

    // TEMP-DEBUG(mute)
    LogDev.warning('[MuteDbg] loadCard($cardIndex) autoplay=$autoplay playWhenReady=$_playWhenReady');
    _playWhenReady = autoplay;
    await _resetHandlerForNewKeypoint();
    emit(
      state.copyWith(
        sourceUrl: url,
        status: LessonAudioLoadStatus.initial,
        positionSeconds: 0,
        durationSeconds: 0,
        isPlaying: false,
        hasStartedSession: false,
        hasCompletedPlayback: false,
        errorMessage: null,
      ),
    );
    await _initializePlayer(startAt: startAt);
    return true;
  }

  Future<void> retry() async {
    if (!state.hasUsableSource) return;
    await _resetForReload();
    await enterAudioMode();
  }

  /// Puts the session back to "never started" for the SAME source, so the next
  /// [enterAudioMode] loads it from scratch. Silences the player first — a
  /// half-loaded or failed player left running would fight the new load.
  Future<void> _resetForReload() async {
    await _resetHandlerForNewKeypoint();
    emit(
      state.copyWith(
        status: LessonAudioLoadStatus.initial,
        positionSeconds: 0,
        durationSeconds: 0,
        isPlaying: false,
        hasStartedSession: false,
        hasCompletedPlayback: false,
        errorMessage: null,
      ),
    );
  }

  /// True when the CURRENT silence is the reader's own doing (the pause
  /// button) — as opposed to a system pause (the recap gate, an overlay, a
  /// mode switch). Forward-swipe autoplay ("mở loa lên luôn", 2026-08-04)
  /// consults this: a reader who explicitly asked for silence keeps it as they
  /// move through cards, until they press play themselves.
  bool _pausedByUser = false;
  bool get pausedByUser => _pausedByUser;

  /// Every transition of the pin goes through here so the trail shows WHO
  /// lifted a mute ("tap card cuối tự bật tiếng" was a wiped flag, 2026-08-09
  /// — the wiper was invisible without this).
  // TEMP-DEBUG(mute): remove once the pinned-silence invariant is confirmed.
  void _setPausedByUser(bool value, String reason) {
    if (_pausedByUser == value) return;
    _pausedByUser = value;
    LogDev.warning('[MuteDbg] pausedByUser=$value ($reason)');
  }

  /// [byUser] marks the reader's own play control (header headphone, recap
  /// play-through) — the ONLY thing that lifts a pinned mute. Every system
  /// caller (autoplay carries, gate resumes, load-completion intents) leaves
  /// the pin alone and is REFUSED while it holds: a reader who asked for
  /// silence keeps it until they press play themselves, no matter which
  /// heuristic upstream decided sound was wanted ("fix triệt để", 2026-08-09).
  Future<void> play({bool byUser = false}) async {
    if (byUser) _setPausedByUser(false, 'play(byUser: true)');
    // TEMP-DEBUG(mute)
    LogDev.warning(
      '[MuteDbg] play byUser=$byUser pinned=$_pausedByUser session=${state.hasStartedSession} ready=${state.isReady}\n'
      'caller: ${StackTrace.current.toString().split('\n').skip(1).take(3).join(' | ')}',
    );
    if (_pausedByUser) return;
    if (!state.hasStartedSession) {
      await enterAudioMode();
      return;
    }
    if (!state.isReady) return;

    try {
      await _handler.playFromApp();
      if (!isClosed) {
        emit(state.copyWith(isPlaying: true, hasCompletedPlayback: false));
      }
    } catch (error, stackTrace) {
      _handleFailure(error, stackTrace, errorType: 'LessonAudioCubit.play');
    }
  }

  /// [byUser] defaults to false so every system caller (gates, overlays, mode
  /// switches) stays a *soft* pause; only the reader's own pause button passes
  /// true and pins the silence.
  Future<void> pause({bool byUser = false}) async {
    if (byUser) _setPausedByUser(true, 'pause(byUser: true)');
    // TEMP-DEBUG(mute)
    LogDev.warning('[MuteDbg] pause byUser=$byUser playing=${state.isPlaying} playWhenReady=$_playWhenReady');
    // Asking for silence also withdraws any pending "play when the load lands"
    // intent — otherwise pausing during the ~5s fetch is ignored and the clip
    // starts talking the moment it is ready.
    _playWhenReady = false;
    try {
      await _handler.pauseFromApp();
      _persistResumeNow();
      if (!isClosed) {
        emit(state.copyWith(isPlaying: false));
      }
    } catch (error, stackTrace) {
      _handleFailure(error, stackTrace, errorType: 'LessonAudioCubit.pause');
    }
  }

  /// Switching to Read is a real exit from Listen mode (unlike
  /// [pauseForOverlay], a transient pause under a dialog/sheet).
  Future<void> pauseForModeSwitch() async {
    await pause();
  }

  Future<void> pauseForOverlay() => pause();

  Future<void> seekBy(Duration delta) async {
    if (!state.isReady) return;

    final target = (state.position + delta).inSeconds.clamp(0, state.durationSeconds);
    try {
      await _handler.seek(Duration(seconds: target));
      if (!isClosed) {
        emit(state.copyWith(positionSeconds: target));
      }
    } catch (error, stackTrace) {
      _handleFailure(error, stackTrace, errorType: 'LessonAudioCubit.seekBy');
    }
  }

  /// Seek to an absolute position — used by dragging/tapping the progress bar.
  Future<void> seekTo(Duration position) async {
    if (!state.isReady) return;

    final target = position.inSeconds.clamp(0, state.durationSeconds);
    try {
      await _handler.seek(Duration(seconds: target));
      if (!isClosed) {
        emit(state.copyWith(positionSeconds: target));
      }
    } catch (error, stackTrace) {
      _handleFailure(error, stackTrace, errorType: 'LessonAudioCubit.seekTo');
    }
  }

  Future<void> setSpeed(double speed) async {
    if (!LessonAudioStateX.supportedSpeeds.contains(speed)) return;
    if (state.hasStartedSession) {
      try {
        await _handler.setSpeed(speed);
      } catch (error, stackTrace) {
        _handleFailure(error, stackTrace, errorType: 'LessonAudioCubit.setSpeed');
        return;
      }
    }
    if (!isClosed) {
      emit(state.copyWith(speed: speed));
    }
  }

  Future<bool> pauseForSpeedSheet() async {
    final wasPlaying = state.isPlaying;
    if (wasPlaying) {
      await pause();
    }
    return wasPlaying;
  }

  Future<void> restoreAfterSpeedSheet({required bool resumePlayback}) async {
    if (resumePlayback) {
      await play();
    }
  }

  Future<void> resetSession() async {
    // TEMP-DEBUG(mute)
    LogDev.warning('[MuteDbg] resetSession playWhenReady=$_playWhenReady');
    final status = state.hasUsableSource ? LessonAudioLoadStatus.initial : LessonAudioLoadStatus.unavailable;
    _playWhenReady = false;
    await _resetHandlerForNewKeypoint();
    emit(
      state.copyWith(
        status: status,
        positionSeconds: 0,
        durationSeconds: 0,
        speed: 1.0,
        isPlaying: false,
        hasStartedSession: false,
        hasCompletedPlayback: false,
        errorMessage: null,
      ),
    );
  }

  /// Loads [state.sourceUrl], or [queue] as one gapless run when the
  /// backgrounded listener is reading to the end of the keypoint.
  Future<void> _initializePlayer({List<String>? queue, Duration? startAt}) async {
    final generation = ++_loadGeneration;
    // Fresh source (possibly opened deep into the file by a resume): the first
    // tick is a starting point, not a crossing — see [_previousTickCue].
    _previousTickCue = -1;
    // A load replaces the whole playlist, so any chain queued behind the old
    // source is gone with it — including the "this keypoint came from the queue"
    // mark: from here on the player is reading a source this cubit loaded.
    _queuedTail.clear();
    _playedSlot = 0;
    _hoppedKeypointId = '';

    emit(
      state.copyWith(
        status: LessonAudioLoadStatus.loading,
        isPlaying: false,
        hasStartedSession: true,
        hasCompletedPlayback: false,
        errorMessage: null,
      ),
    );

    // Capture what we're loading; if the keypoint/source changes mid-load
    // (e.g. background preload racing a keypoint switch) we must not emit a
    // stale ready/failure over the new state.
    final loadKeypointId = state.keypointId;
    final loadUrl = state.sourceUrl;
    bool isStale() => isClosed || generation != _loadGeneration || state.keypointId != loadKeypointId || state.sourceUrl != loadUrl;

    try {
      await _cancelSubscriptions();

      _playerStateSubscription = _handler.playerStateStream.listen((playerState) {
        if (isClosed) return;
        if (state.isPlaying == playerState.playing) return;
        emit(state.copyWith(isPlaying: playerState.playing));
      });

      _positionSubscription = _handler.positionStream.listen((position) {
        if (isClosed) return;
        if (isMergedMode) {
          _onMergedTick(position.inMilliseconds);
          return;
        }
        final nextPosition = position.inSeconds.clamp(0, state.durationSeconds > 0 ? state.durationSeconds : 359999);
        if (nextPosition == state.positionSeconds) return;
        emit(state.copyWith(positionSeconds: nextPosition));
      });

      _durationSubscription = _handler.durationStream.listen((duration) {
        // Merged mode: durationSeconds is CARD-relative (the active cue's
        // length, from the cue map) — the file's own duration never lands in
        // state.
        if (isClosed || duration == null || isMergedMode) return;
        final nextDuration = duration.inSeconds.clamp(0, 359999);
        if (nextDuration == state.durationSeconds) return;
        emit(state.copyWith(durationSeconds: nextDuration));
      });

      _processingStateSubscription = _handler.processingStateStream.listen((processingState) async {
        if (isClosed || processingState != just_audio.ProcessingState.completed) return;

        // just_audio's streams REPLAY their latest value to every new listener,
        // and this subscription is created while the PREVIOUS clip's `completed`
        // is still the player's current state — `loadItem` below hasn't swapped
        // the source yet. Acting on that replay marked the brand-new clip
        // finished the moment it began loading, the deck read that as the new
        // card ending and turned the page, whose load replayed `completed`
        // again… one real completion cascaded the whole keypoint in seconds,
        // with no audio ever heard. A completion can only belong to THIS load
        // once the load has finished: same generation, status out of `loading`.
        if (generation != _loadGeneration || state.status != LessonAudioLoadStatus.ready) return;

        // Publishing `hasCompletedPlayback` is what turns the page: it is
        // [KeypointCardCubit] that owns "which card comes next", because only it
        // knows the card order, which cards are revealed, and that an unanswered
        // quiz card stops the deck. It reacts by moving the view forward, which
        // points narration at the new card's clip — so the voice carries on
        // through the keypoint, screen locked or not, without this cubit
        // second-guessing the deck it cannot see.
        await _handler.pauseFromApp();
        if (isClosed) return;
        emit(
          state.copyWith(
            isPlaying: false,
            hasCompletedPlayback: true,
            positionSeconds: state.durationSeconds,
          ),
        );
      });

      final duration = queue == null
          ? await _handler.loadItem(
              url: loadUrl,
              id: state.keypointId,
              title: state.title,
              artUri: state.imageUrl,
              speed: state.speed,
              initialPosition: startAt,
              // Only the merged file is worth caching: it is loaded once per
              // keypoint and re-read by every resume and lock-screen seek. The
              // legacy per-card clips are tiny and each is played once.
              cacheToDisk: isMergedMode,
            )
          : await _handler.loadQueue(
              urls: queue,
              id: state.keypointId,
              title: state.title,
              artUri: state.imageUrl,
              speed: state.speed,
            );
      if (isStale()) return;
      if (!isMergedMode && duration != null && duration.inSeconds > 0) {
        emit(state.copyWith(durationSeconds: duration.inSeconds));
      }
      if (isStale()) return;

      emit(state.copyWith(status: LessonAudioLoadStatus.ready));

      // Subscribed only AFTER the load, and seeded from the player rather than
      // from the stream: `just_audio`'s streams replay their latest value, and
      // the replay here can still be the PREVIOUS playlist's slot. Seeding
      // `_playedSlot` from a replayed 1 would then swallow the first real hop
      // (`slot <= _playedSlot`) — the chain would go silent at the very boundary
      // it exists for.
      _playedSlot = _handler.currentIndex ?? 0;
      _slotSubscription = _handler.currentIndexStream.listen((slot) {
        if (isClosed || generation != _loadGeneration) return;
        _onSlotChanged(slot);
      });

      // TEMP-DEBUG(mute)
      LogDev.warning('[MuteDbg] load ready playWhenReady=$_playWhenReady pinned=$_pausedByUser');
      // Honor a play intent registered while (pre)loading.
      if (_playWhenReady) {
        _playWhenReady = false;
        await play();
      }
    } catch (error, stackTrace) {
      if (isStale()) return;
      // "Loading interrupted" is not a failure: `just_audio` throws it out of
      // the load that was REPLACED, so by the time it lands someone has already
      // taken the player somewhere better. [_loadGeneration] catches the
      // ordinary case, but not an interrupt from outside this cubit — the
      // handler is app-lifetime and shared, so the next route's cubit (built
      // before this one is closed) can supersede us without ever touching our
      // counter. Reporting it marked a perfectly good session dead and filed a
      // Crashlytics error for it.
      //
      // Deliberately does NOT touch the handler: whoever interrupted us is
      // driving it now, and pausing would silence THEM. Just fall back to
      // "never started" so a later tap loads this clip again from scratch.
      if (error is just_audio.PlayerInterruptedException) {
        // TEMP-DEBUG(mute)
        LogDev.warning('[MuteDbg] load interrupted (superseded) playWhenReady=$_playWhenReady');
        emit(
          state.copyWith(
            status: LessonAudioLoadStatus.initial,
            isPlaying: false,
            hasStartedSession: false,
            errorMessage: null,
          ),
        );
        return;
      }
      _handleFailure(error, stackTrace, errorType: 'LessonAudioCubit.initialize');
    }
  }

  /// One raw position tick of the merged file → cue bookkeeping.
  ///
  /// Publishes CARD-relative position/duration (per-card consumers keep
  /// working unchanged) and enforces the deck's [_allowedThroughCue] bound:
  /// crossing into a cue past it pauses EXACTLY at the allowed cue's end, in
  /// the same completed-looking state a finished per-card clip leaves — so
  /// every existing deck reaction applies unchanged. Open boundaries are
  /// flowed through without pausing; that is the whole point of the merge.
  void _onMergedTick(int positionMs) {
    final timeline = _timeline;
    if (timeline == null || state.status != LessonAudioLoadStatus.ready) return;

    final cueIndex = timeline.cueIndexAtMs(positionMs);
    if (cueIndex < 0) return;

    // Held at a gate/paywall/file end: the parked position sits ON a boundary,
    // and boundaries read as the NEXT cue — acting on these idle ticks cleared
    // the hold state and let the deck slide into the very card the gate meant
    // to keep shut (the "tự động lướt qua câu hỏi" bug). While held, ticks
    // mean nothing; [playCue]/[play] emit their own state when narration is
    // deliberately moved or resumed.
    if (!state.isPlaying && state.hasCompletedPlayback) return;

    _maybePersistResume(positionMs);

    final crossedBound = _previousTickCue >= 0 && _previousTickCue <= _allowedThroughCue && cueIndex > _allowedThroughCue;
    _previousTickCue = cueIndex;

    if (crossedBound) {
      final boundCue = _allowedThroughCue.clamp(0, timeline.merged.cues.length - 1);
      // Park a hair BEFORE the boundary, never on it: the exact boundary
      // belongs to the next cue (see [MergedNarrationTimeline.cueIndexAtMs]),
      // so parking there made every later position read report the gated-away
      // card as active. 50ms of replay on resume is inaudible.
      final holdMs = (timeline.endMsOf(boundCue) - 50).clamp(0, 1 << 62);
      unawaited(_handler.pauseFromApp());
      unawaited(_handler.seek(Duration(milliseconds: holdMs)));
      final heldCueIndex = timeline.cueIndexAtMs(holdMs);
      final heldCue = timeline.cueAt(heldCueIndex);
      final heldSeconds = heldCue == null ? 0 : (heldCue.durMs / 1000).round().clamp(0, 359999);
      emit(
        state.copyWith(
          isPlaying: false,
          hasCompletedPlayback: true,
          activeCueIndex: heldCueIndex,
          positionSeconds: heldSeconds,
          durationSeconds: heldSeconds,
        ),
      );
      return;
    }

    final cue = timeline.cueAt(cueIndex)!;
    final cardPositionSeconds = ((positionMs - cue.startMs) / 1000).floor().clamp(0, 359999);
    final cardDurationSeconds = (cue.durMs / 1000).round().clamp(0, 359999);
    if (cueIndex != state.activeCueIndex || cardPositionSeconds != state.positionSeconds || cardDurationSeconds != state.durationSeconds) {
      emit(
        state.copyWith(
          activeCueIndex: cueIndex,
          positionSeconds: cardPositionSeconds,
          durationSeconds: cardDurationSeconds,
          hasCompletedPlayback: false,
        ),
      );
    }
  }

  void _handleFailure(
    Object error,
    StackTrace stackTrace, {
    required String errorType,
  }) {
    AppService.instance.appTrackingService.trackError(
      error,
      stackTrace: stackTrace,
      errorType: errorType,
      context: {
        'keypoint_id': state.keypointId,
      },
    );

    if (!isClosed) {
      emit(
        state.copyWith(
          status: LessonAudioLoadStatus.failure,
          isPlaying: false,
          errorMessage: 'Failed to load audio.',
        ),
      );
    }
  }

  /// Halts whatever the shared handler/player was doing so a different source
  /// can be loaded over it — the handler's player is app-lifetime, so this
  /// replaces the old `_disposePlayer()` (which used to tear down and recreate
  /// a cubit-owned `AudioPlayer`).
  ///
  /// PAUSES rather than stops: `stop()` publishes `AudioProcessingState.idle`,
  /// which `audio_service` reads as "done" and answers by shutting the platform
  /// service down — inaudible in the foreground, fatal in the background, where
  /// it left narration ending with whichever card was playing when the reader
  /// locked the screen. See [LessonAudioHandler.pauseForSourceSwitch].
  ///
  /// Only touches the handler if a session was actually started: mirrors the
  /// old `_disposePlayer()`, which was a cheap no-op (`_audioPlayer?.dispose()`
  /// on a null player) whenever a keypoint was configured/reset/retried
  /// without ever entering audio mode — e.g. every keypoint that has no
  /// usable audio at all.
  Future<void> _resetHandlerForNewKeypoint() async {
    // Bump FIRST. A load already in flight is about to be interrupted by the
    // `loadItem` its replacement issues, and it has to be able to tell it was
    // superseded BEFORE it throws. Bumping only inside `_initializePlayer` was
    // too late — that runs after this returns, so the interrupted load still saw
    // its own generation (and its own sourceUrl, not yet replaced) and reported
    // failure over a session that was about to be replaced anyway.
    _loadGeneration++;
    await _cancelSubscriptions();
    if (state.hasStartedSession) {
      await _handler.pauseForSourceSwitch();
    }
  }

  Future<void> _cancelSubscriptions() async {
    await _positionSubscription?.cancel();
    await _durationSubscription?.cancel();
    await _playerStateSubscription?.cancel();
    await _processingStateSubscription?.cancel();
    await _slotSubscription?.cancel();

    _positionSubscription = null;
    _durationSubscription = null;
    _playerStateSubscription = null;
    _processingStateSubscription = null;
    _slotSubscription = null;
  }

  @override
  Future<void> close() async {
    await _cancelSubscriptions();
    await _keypointHops.close();
    // Leaving Listen mode: stop playback and clear the media item so the
    // lock-screen/notification controls disappear. The handler's player is
    // app-lifetime and shared across lesson sessions — it must NOT be
    // disposed here (that would break the next keypoint/lesson's playback).
    // Only touches the handler if this cubit ever actually started a
    // session (mirrors the old no-op `_disposePlayer()` on a null player).
    //
    // Closing = the reader LEFT the lesson on purpose (X, completion — an app
    // kill never runs this), and that ends the listening session (product
    // call, 2026-08-04): drop the "đang nghe dở" bookmark so re-opening the
    // keypoint reads from the top with a clean bar. Resume stays for the
    // paths that never reach here — kill and background.
    if (state.hasStartedSession) {
      if (isMergedMode && state.keypointId.isNotEmpty) {
        ListenResumeCubit.instanceOrNull?.clearFor(state.keypointId);
      }
      await _handler.stop();
    }
    return super.close();
  }
}
