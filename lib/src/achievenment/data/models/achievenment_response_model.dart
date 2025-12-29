part of '../../achievenment.dart';

@freezed
abstract class AchievenmentResponseModel with _$AchievenmentResponseModel {
  const factory AchievenmentResponseModel({
    @Default('') String id,
    @Default('') String name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _AchievenmentResponseModel;


  factory AchievenmentResponseModel.fromJson(Map<String, dynamic> json) => _$AchievenmentResponseModelFromJson(json);
}

extension AchievenmentResponseModelExtension on AchievenmentResponseModel {
  AchievenmentResponseEntity toEntity() => AchievenmentResponseEntity(
        id: id,
        name: name,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

