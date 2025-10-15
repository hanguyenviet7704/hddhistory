part of '../../data_collect.dart';

@freezed
abstract class UserCollectDataEntity with _$UserCollectDataEntity {
  const factory UserCollectDataEntity({
    @Default('') String id,
    @Default('') String name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _UserCollectDataEntity;

  factory UserCollectDataEntity.fromJson(Map<String, dynamic> json) => _$UserCollectDataEntityFromJson(json);
}
