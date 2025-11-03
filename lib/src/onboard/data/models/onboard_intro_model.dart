part of '../../onboard.dart';

@freezed
abstract class OnboardIntroModel with _$OnboardIntroModel {
  const factory OnboardIntroModel({
    @Default(0) int id,
    @Default('') String image,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default(BaseMultiLanguage()) BaseMultiLanguage content,
  }) = _OnboardIntroModel;

  factory OnboardIntroModel.fromJson(Map<String, dynamic> json) => _$OnboardIntroModelFromJson(json);
}

extension OnboardIntroModelExtension on OnboardIntroModel {
  OnboardIntroEntity toEntity() => OnboardIntroEntity(
    id: id,
    image: image,
    title: title,
    content: content,
  );
}
