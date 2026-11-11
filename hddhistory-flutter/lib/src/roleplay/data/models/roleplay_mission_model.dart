part of '../../roleplay.dart';

@freezed
abstract class RoleplayMissionModel with _$RoleplayMissionModel {
  const factory RoleplayMissionModel({
    @Default(0) int id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage content,
  }) = _RoleplayMissionModel;

  factory RoleplayMissionModel.fromJson(Map<String, dynamic> json) => _$RoleplayMissionModelFromJson(json);
}

extension RoleplayMissionModelExtension on RoleplayMissionModel {
  RoleplayMissionEntity toEntity() => RoleplayMissionEntity(
    id: id,
    content: content,
  );
}