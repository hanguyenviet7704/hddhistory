part of '../../../lesson.dart';

@lazySingleton
class LessonAudioCubit extends Cubit<LessonAudioState> {
  LessonAudioCubit() : super(LessonAudioState.initial());

  just_audio.AudioPlayer? _audioPlayer;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<just_audio.PlayerState>? _playerStateSubscription;
  StreamSubscription<just_audio.ProcessingState>? _processingStateSubscription;

  Future<void> configure(KeypointEntity keypoint) async {
    final nextSourceUrl = keypoint.resolvedAudioUrl;
    final nextTitle = keypoint.trackingNameOrText.isNotEmpty ? keypoint.trackingNameOrText : keypoint.title.text;

    if (state.keypointId == keypoint.id && state.sourceUrl == nextSourceUrl && state.imageUrl == keypoint.image && state.title == nextTitle) {
      return;
    }

    await _disposePlayer();

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

    if (!state.hasStartedSession) {
      await _initializePlayer();
    }

    if (!state.isReady || !autoplay) return;
    await play();
  }

  Future<void> retry() async {
    if (!state.hasUsableSource) return;
    await _disposePlayer();
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
    if (!state.isReady || _audioPlayer == null) return;

    try {
      await _audioPlayer!.play();
      if (!isClosed) {
        emit(state.copyWith(isPlaying: true, hasCompletedPlayback: false));
      }
    } catch (error, stackTrace) {
      _handleFailure(error, stackTrace, errorType: 'LessonAudioCubit.play');
    }
  }

  Future<void> pause() async {
    if (_audioPlayer == null) return;

    try {
      await _audioPlayer!.pause();
      if (!isClosed) {
        emit(state.copyWith(isPlaying: false));
      }
    } catch (error, stackTrace) {
      _handleFailure(error, stackTrace, errorType: 'LessonAudioCubit.pause');
    }
  }

  Future<void> pauseForModeSwitch() => pause();

  Future<void> pauseForOverlay() => pause();

  Future<void> seekBy(Duration delta) async {
    if (_audioPlayer == null || !state.isReady) return;

    final target = (state.position + delta).inSeconds.clamp(0, state.durationSeconds);
    try {
      await _audioPlayer!.seek(Duration(seconds: target));
      if (!isClosed) {
        emit(state.copyWith(positionSeconds: target));
      }
    } catch (error, stackTrace) {
      _handleFailure(error, stackTrace, errorType: 'LessonAudioCubit.seekBy');
    }
  }

  Future<void> setSpeed(double speed) async {
    if (!LessonAudioStateX.supportedSpeeds.contains(speed)) return;
    if (_audioPlayer != null) {
      try {
        await _audioPlayer!.setSpeed(speed);
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
    await _disposePlayer();
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

    try {
      final player = _audioPlayer ??= just_audio.AudioPlayer();
      await _cancelSubscriptions();

      _playerStateSubscription = player.playerStateStream.listen((playerState) {
        if (isClosed) return;
        if (state.isPlaying == playerState.playing) return;
        emit(state.copyWith(isPlaying: playerState.playing));
      });

      _positionSubscription = player.positionStream.listen((position) {
        if (isClosed) return;
        final nextPosition = position.inSeconds.clamp(0, state.durationSeconds > 0 ? state.durationSeconds : 359999);
        if (nextPosition == state.positionSeconds) return;
        emit(state.copyWith(positionSeconds: nextPosition));
      });

      _durationSubscription = player.durationStream.listen((duration) {
        if (isClosed || duration == null) return;
        final nextDuration = duration.inSeconds.clamp(0, 359999);
        if (nextDuration == state.durationSeconds) return;
        emit(state.copyWith(durationSeconds: nextDuration));
      });

      _processingStateSubscription = player.processingStateStream.listen((processingState) async {
        if (isClosed || processingState != just_audio.ProcessingState.completed) return;
        await player.pause();
        if (isClosed) return;
        emit(
          state.copyWith(
            isPlaying: false,
            hasCompletedPlayback: true,
            positionSeconds: state.durationSeconds,
          ),
        );
      });

      final duration = await player.setUrl(state.sourceUrl);
      if (duration != null && duration.inSeconds > 0) {
        emit(state.copyWith(durationSeconds: duration.inSeconds));
      }
      if (state.speed != 1.0) {
        await player.setSpeed(state.speed);
      }

      emit(state.copyWith(status: LessonAudioLoadStatus.ready));
    } catch (error, stackTrace) {
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

  Future<void> _disposePlayer() async {
    await _cancelSubscriptions();
    await _audioPlayer?.dispose();
    _audioPlayer = null;
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
    await _disposePlayer();
    return super.close();
  }
}
