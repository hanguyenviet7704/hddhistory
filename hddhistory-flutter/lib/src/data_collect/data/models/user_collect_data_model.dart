part of '../../data_collect.dart';

@freezed
abstract class UserCollectDataModel with _$UserCollectDataModel {
  const factory UserCollectDataModel({
    @Default('') String id,
    @Default('') String name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _UserCollectDataModel;


  factory UserCollectDataModel.fromJson(Map<String, dynamic> json) => _$UserCollectDataModelFromJson(json);
}

extension UserCollectDataModelExtension on UserCollectDataModel {
  UserCollectDataEntity toEntity() => UserCollectDataEntity(
        id: id,
        name: name,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}