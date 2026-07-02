part of '../../home.dart';

@freezed
abstract class SkillsetModel with _$SkillsetModel {
  const factory SkillsetModel({
    @JsonKey(name: '_id') @Default('') String id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default(BaseMultiLanguage()) BaseMultiLanguage description,
    @Default('') String image,
    @Default([]) List<CourseModel> courses,
    @JsonKey(
      fromJson: _skillsetOnboardingIntroduceFromJson,
      toJson: _skillsetOnboardingIntroduceToJson,
    )
    SkillsetOnboardingIntroduce? onboardingIntroduce,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _SkillsetModel;

  factory SkillsetModel.fromJson(Map<String, dynamic> json) => _$SkillsetModelFromJson(json);
}

extension SkillsetModelExtension on SkillsetModel {
  SkillsetEntity toEntity() => SkillsetEntity(
    id: id,
    title: title,
    description: description,
    image: image,
    courses: courses.map((model) => model.toEntity()).toList(),
    onboardingIntroduce: onboardingIntroduce,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

SkillsetOnboardingIntroduce? _skillsetOnboardingIntroduceFromJson(Object? value) {
  final rawValue = value?.toString().trim();
  if (rawValue == null || rawValue.isEmpty) return null;

  for (final introduce in SkillsetOnboardingIntroduce.values) {
    if (introduce.name == rawValue) return introduce;
  }

  return null;
}

String? _skillsetOnboardingIntroduceToJson(SkillsetOnboardingIntroduce? value) => value?.name;
