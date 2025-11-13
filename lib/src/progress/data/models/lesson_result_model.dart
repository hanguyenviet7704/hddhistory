part of '../../progress.dart';

@freezed
abstract class LessonResultModel with _$LessonResultModel {
  const factory LessonResultModel({
    @Default('') String lessonId,
    @Default(0.0) double averageScore,
    @Default(false) bool passed,
    @Default([]) List<KeypointResultModel> keypointsResult,
    @Default('') String reviews,
    DateTime? submittedAt,
  }) = _LessonResultModel;

  factory LessonResultModel.fromJson(Map<String, dynamic> json) => _$LessonResultModelFromJson(json);
}

extension LessonResultModelExtension on LessonResultModel {
  LessonResultEntity toEntity() => LessonResultEntity(
    lessonId: lessonId,
    averageScore: averageScore,
    passed: passed,
    keypointsResult: keypointsResult.map((model) => model.toEntity()).toList(),
    reviews: reviews,
    submittedAt: submittedAt,
  );
}
