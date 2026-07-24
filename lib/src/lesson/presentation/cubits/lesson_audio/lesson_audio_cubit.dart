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
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<just_audio.PlayerState>? _playerStateSubscription;
  StreamSubscription<just_audio.ProcessingState>? _processingStateSubscription;

  Future<void> configure(KeypointEntity keypoint) async {
    final nextSourceUrl = keypoint.resolvedAudioUrl;
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

  Future<void> enterAudioMode({bool autoplay = true}) async {
    if (!state.hasUsableSource) {
      emit(
        state.copyWith(
          status: LessonAudioLoadStatus.unavailable,
          isPlaying: false,
        ),
      );
      return;
    }

    if (autoplay) _playWhenReady = true;

    // Already prepared (e.g. background preload finished): just play.
    if (state.isReady) {
      if (autoplay) await play();
      return;
    }

    // Not started yet → start loading now. If a preload is already in flight
    // (loading), _initializePlayer's completion will honor _playWhenReady, so
    // we don't kick off a second load here.
    if (!state.hasStartedSession) {
      await _initializePlayer();
    }
  }

  Future<void> retry() async {
    if (!state.hasUsableSource) return;
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
    await enterAudioMode();
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

  Future<void> _initializePlayer() async {
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
    bool isStale() =>
        isClosed || state.keypointId != loadKeypointId || state.sourceUrl != loadUrl;

    try {
      await _cancelSubscriptions();

      _playerStateSubscription = _handler.playerStateStream.listen((playerState) {
        if (isClosed) return;
        if (state.isPlaying == playerState.playing) return;
        emit(state.copyWith(isPlaying: playerState.playing));
      });

      _positionSubscription = _handler.positionStream.listen((position) {
        if (isClosed) return;
        final nextPosition = position.inSeconds.clamp(0, state.durationSeconds > 0 ? state.durationSeconds : 359999);
        if (nextPosition == state.positionSeconds) return;
        emit(state.copyWith(positionSeconds: nextPosition));
      });

      _durationSubscription = _handler.durationStream.listen((duration) {
        if (isClosed || duration == null) return;
        final nextDuration = duration.inSeconds.clamp(0, 359999);
        if (nextDuration == state.durationSeconds) return;
        emit(state.copyWith(durationSeconds: nextDuration));
      });

      _processingStateSubscription = _handler.processingStateStream.listen((processingState) async {
        if (isClosed || processingState != just_audio.ProcessingState.completed) return;
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

      final duration = await _handler.loadItem(
        url: loadUrl,
        id: state.keypointId,
        title: state.title,
        artUri: state.imageUrl,
        speed: state.speed,
      );
      if (isStale()) return;
      if (duration != null && duration.inSeconds > 0) {
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
      _handleFailure(error, stackTrace, errorType: 'LessonAudioCubit.initialize');
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

  /// Stops whatever the shared handler/player was doing for the previous
  /// keypoint and clears its media item/notification — the handler's player
  /// is app-lifetime, so this replaces the old `_disposePlayer()` (which used
  /// to tear down and recreate a cubit-owned `AudioPlayer`).
  ///
  /// Only touches the handler if a session was actually started: mirrors the
  /// old `_disposePlayer()`, which was a cheap no-op (`_audioPlayer?.dispose()`
  /// on a null player) whenever a keypoint was configured/reset/retried
  /// without ever entering audio mode — e.g. every keypoint that has no
  /// usable audio at all.
  Future<void> _resetHandlerForNewKeypoint() async {
    await _cancelSubscriptions();
    if (state.hasStartedSession) {
      await _handler.stop();
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
