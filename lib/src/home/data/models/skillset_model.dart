part of '../../home.dart';

@freezed
abstract class SkillsetModel with _$SkillsetModel {
  const factory SkillsetModel({
    @Default('') String id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default(BaseMultiLanguage()) BaseMultiLanguage description,
    @Default('') String image,
    @Default([]) List<CourseModel> courses,
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
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
