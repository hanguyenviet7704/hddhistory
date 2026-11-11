part of '../../achievenment.dart';

@freezed
abstract class AchievenmentResponseModel with _$AchievenmentResponseModel {
  const factory AchievenmentResponseModel({
    @Default('') String categoryId,
    @Default(BaseMultiLanguage()) BaseMultiLanguage categoryTitle,
    @Default([]) List<CourseLevelProgressModel> courses,
  }) = _AchievenmentResponseModel;

  factory AchievenmentResponseModel.fromJson(Map<String, dynamic> json) => _$AchievenmentResponseModelFromJson(json);
}

extension AchievenmentResponseModelExtension on AchievenmentResponseModel {
  AchievenmentResponseEntity toEntity() => AchievenmentResponseEntity(
    categoryId: categoryId,
    categoryTitle: categoryTitle,
    courses: courses.map((model) => model.toEntity()).toList(),
  );
}
