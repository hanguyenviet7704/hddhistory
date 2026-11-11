part of '../../learning_streak.dart';

/// When the streak popup is allowed to appear, served by `GET /streak-config`.
///
/// The trigger used to be hard-coded to "finished a keypoint". That only ever
/// fired for people already deep in a lesson — the users who least needed
/// reminding — so it now keys off time spent in the app instead, and the
/// timing is tunable from admin without an app release.
@freezed
abstract class StreakPopupConfigEntity with _$StreakPopupConfigEntity {
  const factory StreakPopupConfigEntity({
    @Default(true) bool popupEnabled,
    @Default(120) int triggerAfterSeconds,
    @Default(3) int autoHideSeconds,
  }) = _StreakPopupConfigEntity;
}

extension StreakPopupConfigEntityX on StreakPopupConfigEntity {
  Duration get triggerAfter => Duration(seconds: triggerAfterSeconds);

  /// Zero means "stay until tapped", so callers must not schedule a timer.
  Duration? get autoHideAfter =>
      autoHideSeconds <= 0 ? null : Duration(seconds: autoHideSeconds);
}
