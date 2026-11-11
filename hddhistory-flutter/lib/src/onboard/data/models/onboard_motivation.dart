part of '../../onboard.dart';

@freezed
abstract class OnboardMotivationModel with _$OnboardMotivationModel {
  const factory OnboardMotivationModel({
    @Default(BaseMultiLanguage()) BaseMultiLanguage content,
    @Default('') String image,
  }) = _OnboardMotivationModel;

  factory OnboardMotivationModel.fromJson(Map<String, dynamic> json) => _$OnboardMotivationModelFromJson(json);
}

extension OnboardMotivationModelExtension on OnboardMotivationModel {
  OnboardMotivationEntity toEntity() => OnboardMotivationEntity(
    content: content,
    image: image,
  );
}
