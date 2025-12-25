part of '../../roleplay.dart';

@freezed
abstract class RoleplayMissionEntity with _$RoleplayMissionEntity {
  const factory RoleplayMissionEntity({
    @Default(0) int id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage content,
  }) = _RoleplayMissionEntity;

  factory RoleplayMissionEntity.fromJson(Map<String, dynamic> json) => _$RoleplayMissionEntityFromJson(json);
}