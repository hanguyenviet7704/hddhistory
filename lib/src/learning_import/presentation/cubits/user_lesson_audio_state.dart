part of '../../learning_import.dart';

@freezed
abstract class UserLessonAudioState with _$UserLessonAudioState {
  const factory UserLessonAudioState({
    @Default('') String lessonId,
    @Default(false) bool isPlaying,

    /// True from the moment playback is asked for until the first position tick
    /// arrives — the pill shows a spinner rather than a stale play icon while
    /// the platform buffers a file it has never seen.
    @Default(false) bool isLoading,
    @Default(Duration.zero) Duration position,
    @Default(Duration.zero) Duration duration,
    @Default(1.0) double speed,

    /// Which card the voice is on, derived from the cue map. The deck follows
    /// this; it is not the deck's own index.
    @Default(0) int voiceCardIndex,
    String? errorMessage,
  }) = _UserLessonAudioState;

  factory UserLessonAudioState.initial() => const UserLessonAudioState();
}

extension UserLessonAudioStateX on UserLessonAudioState {
  bool get hasStarted => position > Duration.zero || isPlaying;

  double get progress {
    if (duration.inMilliseconds <= 0) return 0;

    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }
}
