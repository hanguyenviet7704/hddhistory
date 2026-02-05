part of '../../progress.dart';

@freezed
abstract class KeypointResultModel with _$KeypointResultModel {
  const factory KeypointResultModel({
    @Default('') String keypointId,
    @Default(0) double averageScore,
    @Default(false) bool passed,
    @Default([]) List<ExerciseResultModel> exercisesResult,
    @Default('') String reviews,
    DateTime? submittedAt,
  }) = _KeypointResultModel;

  factory KeypointResultModel.fromJson(Map<String, dynamic> json) => _$KeypointResultModelFromJson(json);
}

extension KeypointResultModelExtension on KeypointResultModel {
  KeypointResultEntity toEntity() => KeypointResultEntity(
    keypointId: keypointId,
    averageScore: averageScore,
    passed: passed,
    exercisesResult: exercisesResult.map((model) => model.toEntity()).toList(),
    reviews: reviews,
    submittedAt: submittedAt,
  );
}
