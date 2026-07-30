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
  }) async {
    final art = artUri.isNotEmpty ? Uri.tryParse(artUri) : null;
    final item = MediaItem(id: id, title: title, artUri: art);
    mediaItem.add(item);

    final duration = await _player.setAudioSource(
      just_audio.AudioSource.uri(Uri.parse(url), tag: item),
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

  // play/pause/seek/setSpeed deliberately do NOT swallow errors: when called
  // from [LessonAudioCubit] (the normal in-app path), the cubit wraps every
  // call in its own try/catch and reports failures via `_handleFailure` —
  // exactly like it did when it owned the player directly. When called by
  // the OS (lock-screen/Control Center/notification button), an exception
  // here is safely converted into an error reply by audio_service's platform
  // channel dispatch rather than crashing the app.
  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

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
