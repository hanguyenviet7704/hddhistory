part of '../../achievenment.dart';

@freezed
abstract class AchievenmentResponseModel with _$AchievenmentResponseModel {
  const factory AchievenmentResponseModel({
    @Default('') String skillsetId,
    @Default(BaseMultiLanguage()) BaseMultiLanguage skillsetTitle,
    @Default([]) List<CourseLevelProgressModel> courses,
  }) = _AchievenmentResponseModel;

  factory AchievenmentResponseModel.fromJson(Map<String, dynamic> json) => _$AchievenmentResponseModelFromJson(json);
}

extension AchievenmentResponseModelExtension on AchievenmentResponseModel {
  AchievenmentResponseEntity toEntity() => AchievenmentResponseEntity(
    skillsetId: skillsetId,
    skillsetTitle: skillsetTitle,
    courses: courses.map((model) => model.toEntity()).toList(),
  );
}
