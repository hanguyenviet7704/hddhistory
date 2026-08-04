part of '../../../lesson.dart';

class LessonAudioCubit extends Cubit<LessonAudioState> {
  LessonAudioCubit() : super(LessonAudioState.initial());

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

  /// "No bound" sentinel for [_allowedThroughCue] — any real cue index is
  /// smaller.
  static const int unboundedCue = 1 << 30;

  /// Highest cue the voice may play INTO without stopping. Owned by the deck
  /// ([KeypointCardCubit] computes it from its gates + app lifecycle); this
  /// cubit only enforces it at cue boundaries in [_onMergedTick].
  int _allowedThroughCue = unboundedCue;

  /// File-time home of one card, or null (no cue / silent card) — the deck's
  /// bridge from card identity to [playCue]'s cue index.
  int? cueForCard({required String learningItemId, required int documentIndex}) => _timeline?.cueIndexForCard(learningItemId: learningItemId, documentIndex: documentIndex);

  /// The deck's gate bound. RAISING it while the voice sits paused at that
  /// very boundary does not auto-play — the deck decides that (it knows why
  /// the bound rose).
  void setAllowedThroughCue(int cueIndex) => _allowedThroughCue = cueIndex;

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
    // Merged-first: one file for the whole keypoint when the backend has it,
    // else first card's clip when dubbed per card, else the legacy single file.
    final mergedAudio = keypoint.resolvedMergedAudio;
    _timeline = mergedAudio == null ? null : MergedNarrationTimeline(mergedAudio);
    _allowedThroughCue = unboundedCue;
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

    _playWhenReady = false;
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
  Future<void> playCue(int cueIndex, {bool autoplay = false, Duration? offset}) async {
    final timeline = _timeline;
    final cue = timeline?.cueAt(cueIndex);
    if (timeline == null || cue == null || cue.durMs <= 0) return;

    final target = Duration(milliseconds: cue.startMs + (offset?.inMilliseconds ?? 0));
    if (!state.hasStartedSession) {
      _playWhenReady = autoplay;
      await _initializePlayer(startAt: target);
      return;
    }
    try {
      await _handler.seek(target);
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

  Future<void> play() async {
    if (!state.hasStartedSession) {
      await enterAudioMode();
      return;
    }
    if (!state.isReady) return;

    try {
      await _handler.play();
      if (!isClosed) {
        emit(state.copyWith(isPlaying: true, hasCompletedPlayback: false));
      }
    } catch (error, stackTrace) {
      _handleFailure(error, stackTrace, errorType: 'LessonAudioCubit.play');
    }
  }

  Future<void> pause() async {
    // Asking for silence also withdraws any pending "play when the load lands"
    // intent — otherwise pausing during the ~5s fetch is ignored and the clip
    // starts talking the moment it is ready.
    _playWhenReady = false;
    try {
      await _handler.pause();
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
        await _handler.pause();
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

    if (cueIndex > _allowedThroughCue) {
      // Already holding at the bound — don't re-emit on every late tick.
      if (!state.isPlaying && state.hasCompletedPlayback) return;
      final boundCue = _allowedThroughCue.clamp(0, timeline.merged.cues.length - 1);
      final holdMs = timeline.endMsOf(boundCue);
      unawaited(_handler.pause());
      unawaited(_handler.seek(Duration(milliseconds: holdMs)));
      final heldCueIndex = timeline.cueIndexAtMs(holdMs > 0 ? holdMs - 1 : 0);
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

    _positionSubscription = null;
    _durationSubscription = null;
    _playerStateSubscription = null;
    _processingStateSubscription = null;
  }

  @override
  Future<void> close() async {
    await _cancelSubscriptions();
    // Leaving Listen mode: stop playback and clear the media item so the
    // lock-screen/notification controls disappear. The handler's player is
    // app-lifetime and shared across lesson sessions — it must NOT be
    // disposed here (that would break the next keypoint/lesson's playback).
    // Only touches the handler if this cubit ever actually started a
    // session (mirrors the old no-op `_disposePlayer()` on a null player).
    if (state.hasStartedSession) {
      await _handler.stop();
    }
    return super.close();
  }
}
