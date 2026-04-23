part of '../../progress.dart';

@freezed
abstract class UserProgressModel with _$UserProgressModel {
  const factory UserProgressModel({
    @Default('') String id,
    @Default('') String userId,
    @Default('') String courseId,
    @Default([]) List<LessonResultModel> lessonsResult,
    @Default([]) List<CompletedLevelModel> completedLevels,
  }) = _UserProgressModel;

  factory UserProgressModel.fromJson(Map<String, dynamic> json) => _$UserProgressModelFromJson(json);
}

enum GradeResultType {
  @JsonValue('course')
  course,
  @JsonValue('lesson')
  lesson,
  @JsonValue('keypoint')
  keypoint,
  @JsonValue('exercise')
  exercise,
}

extension UserProgressModelExtension on UserProgressModel {
  UserProgressEntity toEntity() => UserProgressEntity(
    id: id,
    userId: userId,
    courseId: courseId,
    lessonsResult: lessonsResult.map((model) => model.toEntity()).toList(),
    completedLevels: completedLevels.map((model) => model.toEntity()).toList(),
  );
}
