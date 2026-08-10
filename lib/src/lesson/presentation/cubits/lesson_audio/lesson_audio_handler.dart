part of '../../../lesson.dart';

/// Background-audio + OS media-controls handler for the lesson "Listen mode"
/// (Nghe) player ONLY. Registered once at app bootstrap via
/// `AudioService.init` (see `AppService._configLessonAudio`) and resolved as
/// an app-lifetime singleton through [AppDI.injector] — NOT annotated with
/// `@injectable`/`@lazySingleton` because the instance must come from
/// `AudioService.init`'s `builder` callback, not from a plain constructor
/// call.
///
/// Deliberately scoped to this one player: every other `just_audio` instance
/// in the app (ambient study-theme audio, roleplay audio, the generic
/// `AudioPlayerWidget`) stays untouched by `audio_service`, so it never turns
/// into a media notification.
///
/// [LessonAudioCubit] delegates all playback to this handler and only keeps
/// its own derived UI state (position/duration/playing/completed) by
/// listening to the player streams exposed below.
class LessonAudioHandler extends BaseAudioHandler with SeekHandler {
  final just_audio.AudioPlayer _player = just_audio.AudioPlayer();

  /// Fired when the OS transport (lock screen / Control Center / headphone
  /// button) — not the app — pauses or plays. The overrides below are the only
  /// path those buttons take, while the app itself calls [pauseFromApp]/
  /// [playFromApp]; that split is what lets the cubit treat an OS pause as the
  /// reader's own silence (`pausedByUser`) without every internal soft pause
  /// (gates, overlays, source switches) pinning it too.
  void Function()? onOsPause;
  void Function()? onOsPlay;

  LessonAudioHandler() {
    _player.playbackEventStream.listen(
      _broadcastState,
      onError: (Object error, StackTrace stackTrace) {
        // Surfaced to the cubit via its own try/catch around play/pause/seek/
        // loadItem — nothing actionable to do with a bare stream error here.
      },
    );
  }

  static const Map<just_audio.ProcessingState, AudioProcessingState> _processingStateMap = {
    just_audio.ProcessingState.idle: AudioProcessingState.idle,
    just_audio.ProcessingState.loading: AudioProcessingState.loading,
    just_audio.ProcessingState.buffering: AudioProcessingState.buffering,
    just_audio.ProcessingState.ready: AudioProcessingState.ready,
    just_audio.ProcessingState.completed: AudioProcessingState.completed,
  };

  /// Exposed so [LessonAudioCubit] can keep deriving its own
  /// position/duration/playing/completed state exactly as it did when it
  /// owned the player directly.
  Stream<just_audio.PlayerState> get playerStateStream => _player.playerStateStream;

  Stream<Duration> get positionStream => _player.positionStream;

  Stream<Duration?> get durationStream => _player.durationStream;

  Stream<just_audio.ProcessingState> get processingStateStream => _player.processingStateStream;

  /// Where the player is inside the CURRENT source. In queue mode that is the
  /// current item, not the whole run — `just_audio` reports position and duration
  /// per item — which is exactly what resuming onto one card needs.
  Duration get position => _player.position;

  /// Which queue slot is playing, or null when the source is a single item.
  /// Only meaningful together with [LessonAudioCubit]'s slot → clip map: the
  /// queue skips cards with nothing to read, so a slot is not a clip index.
  int? get currentIndex => _player.currentIndex;

  /// Loads [url] as the active source and pushes the matching [MediaItem] so
  /// the lock-screen/Control Center/Android notification show the right
  /// title + artwork. Returns the resolved duration (mirrors
  /// `just_audio.AudioPlayer.setUrl`'s return value) so the cubit can seed
  /// `durationSeconds` immediately instead of waiting on the duration stream.
  Future<Duration?> loadItem({
    required String url,
    required String id,
    required String title,
    required String artUri,
    double speed = 1.0,

    /// Start the source here instead of at zero. Handed to `setAudioSource` so
    /// resuming lands mid-clip in one step — loading at zero and seeking after
    /// is audible as the clip restarting before it jumps.
    Duration? initialPosition,

    /// Keep the downloaded bytes on disk and replay from there next time.
    ///
    /// Set for the merged whole-keypoint file: it is ~900KB, the CDN serves it
    /// with no `Cache-Control` and no edge cache (`cf-cache-status: DYNAMIC`,
    /// measured 2026-08-04), and neither AVPlayer nor ExoPlayer persists
    /// streamed media — so every re-entry, every kill-and-resume and every
    /// lock-screen seek re-fetched the whole thing over the network. Cached,
    /// the second listen and every resume read locally.
    bool cacheToDisk = false,
  }) async {
    final art = artUri.isNotEmpty ? Uri.tryParse(artUri) : null;
    final item = MediaItem(id: id, title: title, artUri: art);
    mediaItem.add(item);

    final uri = Uri.parse(url);
    // A one-item PLAYLIST, not a bare source: position/duration/seek are all
    // per-item in `just_audio`, so with a single item this behaves exactly like
    // `setAudioSource` did — but the playlist can later be APPENDED to while it
    // plays (see [appendItem]), which is what lets narration carry on into the
    // next keypoint with no Dart at the boundary.
    final duration = await _player.setAudioSources(
      [
        cacheToDisk
            ? just_audio.LockCachingAudioSource(uri, tag: item)
            : just_audio.AudioSource.uri(uri, tag: item),
      ],
      initialPosition: initialPosition,
    );

    if (speed != 1.0) {
      await _player.setSpeed(speed);
    }

    if (duration != null && mediaItem.value?.id == id) {
      mediaItem.add(mediaItem.value!.copyWith(duration: duration));
    }

    return duration;
  }

  /// Loads [urls] as ONE gapless queue and reports the first item's duration.
  ///
  /// The backgrounded listener's source. `just_audio` walks the queue natively:
  /// the next clip is prefetched and started by the platform player, with no
  /// Dart code at the boundary. Chaining clip-by-clip from a `completed`
  /// listener instead puts a network fetch and an isolate round-trip between
  /// every card — audible as a gap, and dependent on Dart still being scheduled
  /// when the OS has the app in the background.
  ///
  /// [MediaItem] is the whole run, not the clip: the lock-screen shows the
  /// keypoint, and the queue moving underneath does not flicker the title.
  Future<Duration?> loadQueue({
    required List<String> urls,
    required String id,
    required String title,
    required String artUri,
    double speed = 1.0,
  }) async {
    final art = artUri.isNotEmpty ? Uri.tryParse(artUri) : null;
    final item = MediaItem(id: id, title: title, artUri: art);
    mediaItem.add(item);

    final duration = await _player.setAudioSources(
      [for (final url in urls) just_audio.AudioSource.uri(Uri.parse(url), tag: item)],
    );

    if (speed != 1.0) {
      await _player.setSpeed(speed);
    }

    return duration;
  }

  /// Which queue slot is playing, as a stream — the ONLY signal that the player
  /// has walked out of one keypoint's merged file and into the next one's.
  Stream<int?> get currentIndexStream => _player.currentIndexStream;

  /// Appends [url] to the LIVE playlist without touching what is playing.
  ///
  /// The whole mechanism behind listening across keypoints: the next keypoint's
  /// merged file is handed to the platform player while the current one is still
  /// being read, so the boundary is walked natively — no Dart runs at the hop,
  /// which is the one thing an app the OS has put in the background cannot
  /// promise (the same reason [pauseForSourceSwitch] exists instead of a
  /// load-at-the-boundary chain).
  ///
  /// Cached to disk for the same reason [loadItem]'s merged path is: the file is
  /// re-read by every resume and lock-screen seek, and the CDN serves it with no
  /// edge cache.
  Future<void> appendItem({
    required String url,
    required String id,
    required String title,
    required String artUri,
    Duration? duration,
  }) async {
    final art = artUri.isNotEmpty ? Uri.tryParse(artUri) : null;
    await _player.addAudioSource(
      just_audio.LockCachingAudioSource(
        Uri.parse(url),
        tag: MediaItem(id: id, title: title, artUri: art, duration: duration),
      ),
    );
  }

  /// Removes every slot AFTER the one playing — the queued-but-unheard tail.
  ///
  /// Disarming the chain: back on screen (the deck owns narration again), or the
  /// reader pressed pause on the lock screen. Deliberately leaves the current
  /// item alone, so the keypoint being read finishes normally.
  Future<void> dropTailAfterCurrent() async {
    final current = _player.currentIndex ?? 0;
    for (var index = _player.audioSources.length - 1; index > current; index--) {
      await _player.removeAudioSourceAt(index);
    }
  }

  /// Republishes the now-playing metadata after the queue moved into a new
  /// keypoint, so the lock screen names the keypoint being read rather than the
  /// one the session started on.
  ///
  /// [duration] comes from the cue map rather than the player: the platform has
  /// only just started the new item, so its own duration is not known yet — and a
  /// [MediaItem] with none leaves the lock-screen scrubber without a total.
  void publishMediaItem({
    required String id,
    required String title,
    required String artUri,
    Duration? duration,
  }) {
    final art = artUri.isNotEmpty ? Uri.tryParse(artUri) : null;
    mediaItem.add(MediaItem(id: id, title: title, artUri: art, duration: duration));
  }

  // play/pause/seek/setSpeed deliberately do NOT swallow errors: when called
  // from [LessonAudioCubit] (the normal in-app path), the cubit wraps every
  // call in its own try/catch and reports failures via `_handleFailure` —
  // exactly like it did when it owned the player directly. When called by
  // the OS (lock-screen/Control Center/notification button), an exception
  // here is safely converted into an error reply by audio_service's platform
  // channel dispatch rather than crashing the app.
  @override
  Future<void> play() {
    onOsPlay?.call();
    return _player.play();
  }

  @override
  Future<void> pause() {
    onOsPause?.call();
    return _player.pause();
  }

  /// The app's own transport — no OS-intent callbacks.
  Future<void> playFromApp() => _player.play();

  Future<void> pauseFromApp() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  /// Halts playback so a different clip can be loaded over it, WITHOUT tearing
  /// the background audio service down.
  ///
  /// Switching clips must never go through [stop]. Both halves of that method
  /// publish `AudioProcessingState.idle` — `_player.stop()` via
  /// [_broadcastState], and `super.stop()` directly — and `audio_service`
  /// treats idle as "this handler is finished": `AudioService`'s
  /// `_observePlaybackState` sees it and calls `stopService`, which deactivates
  /// the iOS audio session / stops the Android foreground service. In the
  /// foreground the next `loadItem` + `play` quietly brings it all back, so the
  /// damage is invisible; in the BACKGROUND there is nothing left to bring it
  /// back — iOS suspends the app before the replacement source finishes
  /// loading, and narration ends with whatever card was playing when the reader
  /// locked the screen.
  ///
  /// `pause` keeps the processing state at `completed`/`ready`, so the service
  /// stays alive and [loadItem] can swap the source underneath it.
  Future<void> pauseForSourceSwitch() async {
    try {
      await _player.pause();
    } catch (_) {}
  }

  /// Stops playback and clears the media item/notification. Only for LEAVING
  /// Listen mode (the cubit closing) — dismissing the lock-screen controls is
  /// the point there. Use [pauseForSourceSwitch] when merely changing clips.
  /// The player itself is app-lifetime and is intentionally never disposed here.
  @override
  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
    mediaItem.add(null);
    await super.stop();
  }

  void _broadcastState(just_audio.PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.rewind,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.fastForward,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: _processingStateMap[_player.processingState] ?? AudioProcessingState.idle,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
      ),
    );
  }
}
