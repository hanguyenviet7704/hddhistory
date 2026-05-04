part of '../../onboard_v2.dart';

@freezed
abstract class OnboardV2Model with _$OnboardV2Model {
  const factory OnboardV2Model({
    @Default('') String id,
    @Default('') String name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _OnboardV2Model;


  factory OnboardV2Model.fromJson(Map<String, dynamic> json) => _$OnboardV2ModelFromJson(json);
}

extension OnboardV2ModelExtension on OnboardV2Model {
  OnboardV2Entity toEntity() => OnboardV2Entity(
        id: id,
        name: name,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

