part of '../../home.dart';

@freezed
abstract class CategoryModel with _$CategoryModel {
  const factory CategoryModel({
    @JsonKey(name: '_id') @Default('') String id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default(BaseMultiLanguage()) BaseMultiLanguage description,
    @Default('') String image,
    @Default([]) List<CourseModel> courses,
    @JsonKey(
      fromJson: _categoryOnboardingIntroduceFromJson,
      toJson: _categoryOnboardingIntroduceToJson,
    )
    CategoryOnboardingIntroduce? onboardingIntroduce,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _CategoryModel;

  factory CategoryModel.fromJson(Map<String, dynamic> json) => _$CategoryModelFromJson(json);
}

extension CategoryModelExtension on CategoryModel {
  CategoryEntity toEntity() => CategoryEntity(
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

CategoryOnboardingIntroduce? _categoryOnboardingIntroduceFromJson(Object? value) {
  final rawValue = value?.toString().trim();
  if (rawValue == null || rawValue.isEmpty) return null;

  for (final introduce in CategoryOnboardingIntroduce.values) {
    if (introduce.name == rawValue) return introduce;
  }

  return null;
}

String? _categoryOnboardingIntroduceToJson(CategoryOnboardingIntroduce? value) => value?.name;
