part of '../../../lesson.dart';

enum LessonAudioLoadStatus {
  initial,
  unavailable,
  loading,
  ready,
  failure,
}

@freezed
abstract class LessonAudioState with _$LessonAudioState {
  const factory LessonAudioState({
    @Default(LessonAudioLoadStatus.initial) LessonAudioLoadStatus status,
    @Default('') String keypointId,
    @Default('') String sourceUrl,
    @Default('') String imageUrl,
    @Default('') String title,

    /// In merged mode these two are CARD-relative — position inside / duration
    /// of the active cue — so per-card consumers (pip fill, narration
    /// auto-scroll) keep reading them unchanged. The lock screen shows the
    /// real whole-file position straight from the player.
    @Default(0) int positionSeconds,
    @Default(0) int durationSeconds,
    @Default(1.0) double speed,
    @Default(false) bool isPlaying,
    @Default(false) bool hasStartedSession,
    @Default(false) bool hasCompletedPlayback,

    /// True when this keypoint plays its ONE merged narration file (cue map
    /// from the backend) instead of per-card clips.
    @Default(false) bool isMergedMode,

    /// Cue the merged file is currently inside, or -1 (legacy mode / nothing
    /// loaded). The deck follows this across boundaries.
    @Default(-1) int activeCueIndex,
    String? errorMessage,
  }) = _LessonAudioState;

  factory LessonAudioState.initial() => const LessonAudioState();

  factory LessonAudioState.fromJson(Map<String, dynamic> json) => _$LessonAudioStateFromJson(json);
}

extension LessonAudioStateX on LessonAudioState {
  static const List<double> supportedSpeeds = [0.75, 1.0, 1.25, 1.5];

  bool get hasUsableSource => sourceUrl.trim().isNotEmpty;

  bool get isLoading => status == LessonAudioLoadStatus.loading;

  bool get isReady => status == LessonAudioLoadStatus.ready;

  bool get hasFailure => status == LessonAudioLoadStatus.failure;

  bool get isUnavailable => status == LessonAudioLoadStatus.unavailable;

  Duration get position => Duration(seconds: positionSeconds.clamp(0, 359999));

  Duration get duration => Duration(seconds: durationSeconds.clamp(0, 359999));

  double get progressFraction {
    if (durationSeconds <= 0) return 0;
    return (positionSeconds / durationSeconds).clamp(0.0, 1.0);
  }

  bool get canSeekBackward => positionSeconds > 10;

  bool get canSeekForward => durationSeconds > 0 && (durationSeconds - positionSeconds) > 10;

  String get playbackLabel => '${_formatLessonAudioDuration(position)} / ${_formatLessonAudioDuration(duration)}';

  String get speedValueLabel {
    if (speed == 1.0) return '1x';
    final normalized = speed.toStringAsFixed(speed.truncateToDouble() == speed ? 0 : 2);
    return '${normalized.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')}x';
  }
}

String _formatLessonAudioDuration(Duration duration) {
  final totalSeconds = duration.inSeconds.clamp(0, 359999);
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}
