part of '../../setting.dart';

@freezed
abstract class SettingEntity with _$SettingEntity {
  const factory SettingEntity({
    @Default('') String id,
    @Default('') String name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _SettingEntity;

  factory SettingEntity.fromJson(Map<String, dynamic> json) => _$SettingEntityFromJson(json);
}

