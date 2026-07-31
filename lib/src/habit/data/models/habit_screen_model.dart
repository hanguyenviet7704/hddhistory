part of '../../habit.dart';

/// Combined Habit-tab bootstrap payload (`GET /user-habits/screen`): the same
/// `habits` + `summary` shapes as the individual endpoints, plus the
/// admin-configured slot cap nested under `config` — one round trip instead
/// of three separate calls on the tab's initial load.
@freezed
abstract class HabitScreenModel with _$HabitScreenModel {
  const factory HabitScreenModel({
    @Default(HabitScreenConfigModel()) HabitScreenConfigModel config,
    @Default([]) List<UserHabitModel> habits,
    @Default(UserHabitSummaryModel()) UserHabitSummaryModel summary,
  }) = _HabitScreenModel;

  factory HabitScreenModel.fromJson(Map<String, dynamic> json) => _$HabitScreenModelFromJson(json);
}

/// Same shape as `GET /habit-config`, nested under `config` in the combined
/// response.
@freezed
abstract class HabitScreenConfigModel with _$HabitScreenConfigModel {
  const factory HabitScreenConfigModel({
    @Default('default') String configKey,
    @Default(kFreeActiveHabitSlots) int freeActiveSlots,
  }) = _HabitScreenConfigModel;

  factory HabitScreenConfigModel.fromJson(Map<String, dynamic> json) => _$HabitScreenConfigModelFromJson(json);
}

extension HabitScreenModelX on HabitScreenModel {
  HabitScreenEntity toEntity() => HabitScreenEntity(
    // Guard against a missing/zero-ish cap the same way GetHabitConfigUseCase
    // does — the server remains the real enforcer either way.
    freeActiveSlots: config.freeActiveSlots >= 1 ? config.freeActiveSlots : kFreeActiveHabitSlots,
    habits: habits.map((model) => model.toEntity()).toList(),
    summary: summary.toEntity(),
  );
}
