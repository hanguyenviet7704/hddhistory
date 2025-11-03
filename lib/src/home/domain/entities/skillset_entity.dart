part of '../../home.dart';

@freezed
abstract class SkillsetEntity with _$SkillsetEntity {
  const factory SkillsetEntity({
    @Default('') String id,
    @Default('') String name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _SkillsetEntity;

  factory SkillsetEntity.fromJson(Map<String, dynamic> json) => _$SkillsetEntityFromJson(json);
}
