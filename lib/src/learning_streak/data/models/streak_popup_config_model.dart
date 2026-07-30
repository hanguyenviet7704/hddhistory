part of '../../learning_streak.dart';

@freezed
abstract class StreakPopupConfigModel with _$StreakPopupConfigModel {
  const factory StreakPopupConfigModel({
    @Default(true) bool popupEnabled,
    @Default(120) int triggerAfterSeconds,
    @Default(3) int autoHideSeconds,
  }) = _StreakPopupConfigModel;

  factory StreakPopupConfigModel.fromJson(Map<String, dynamic> json) =>
      _$StreakPopupConfigModelFromJson(json);
}

extension StreakPopupConfigModelX on StreakPopupConfigModel {
  StreakPopupConfigEntity toEntity() => StreakPopupConfigEntity(
    popupEnabled: popupEnabled,
    // Clamp rather than trust: a bad admin value should degrade to the
    // default, not disable the popup for everyone by pushing the threshold
    // out of reach.
    triggerAfterSeconds: triggerAfterSeconds < 0 || triggerAfterSeconds > 7200
        ? 120
        : triggerAfterSeconds,
    autoHideSeconds: autoHideSeconds < 0 || autoHideSeconds > 60
        ? 3
        : autoHideSeconds,
  );
}
