part of '../../roleplay.dart';

@freezed
abstract class RoleplayModel with _$RoleplayModel {
  const factory RoleplayModel({
    @Default(0) int id,
    @Default('') String image,
    @Default([]) List<RoleplayContentModel> contents,
    @Default([]) List<RoleplayMissionModel> missions,
  }) = _RoleplayModel;

  factory RoleplayModel.fromJson(Map<String, dynamic> json) => _$RoleplayModelFromJson(json);
}

extension RoleplayModelExtension on RoleplayModel {
  RoleplayEntity toEntity() => RoleplayEntity(
    id: id,
    image: image,
    contents: contents.map((model) => model.toEntity()).toList(),
    missions: missions.map((model) => model.toEntity()).toList(),
  );
}
