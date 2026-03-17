
part of '../../../setting.dart';

enum SettingStatus { initial, loading, success, failure }

@freezed
abstract class SettingState with _$SettingState {
  const factory SettingState({
    @Default(SettingStatus.initial) SettingStatus status,
    SettingEntity? selectedItem,
    String? errorMessage,
  }) = _SettingState;

  factory SettingState.initial() => SettingState();

  factory SettingState.fromJson(Map<String, dynamic> json) => _$SettingStateFromJson(json);
}

