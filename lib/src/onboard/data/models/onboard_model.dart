part of '../../onboard.dart';

@freezed
abstract class OnboardModel with _$OnboardModel {
  const factory OnboardModel({
    @Default('') String id,
    @Default('') String name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _OnboardModel;


  factory OnboardModel.fromJson(Map<String, dynamic> json) => _$OnboardModelFromJson(json);
}

extension OnboardModelExtension on OnboardModel {
  OnboardEntity toEntity() => OnboardEntity(
        id: id,
        name: name,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}