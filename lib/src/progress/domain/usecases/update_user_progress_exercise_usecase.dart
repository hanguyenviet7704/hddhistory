part of '../../progress.dart';

@freezed
abstract class UpdateUserProgressExerciseParams with _$UpdateUserProgressExerciseParams {
  @JsonSerializable(includeIfNull: false)
  const factory UpdateUserProgressExerciseParams({
    String? userId,
    String? courseId,
    String? lessonId,
    String? keypointId,
    @Default([]) List<UpdateUserProgressExerciseData> exercises,
  }) = _UpdateUserProgressExerciseParams;

  factory UpdateUserProgressExerciseParams.fromJson(Map<String, dynamic> json) => _$UpdateUserProgressExerciseParamsFromJson(json);
}

@freezed
abstract class UpdateUserProgressExerciseData with _$UpdateUserProgressExerciseData {
  @JsonSerializable(includeIfNull: false)
  const factory UpdateUserProgressExerciseData({
    String? exerciseId,
    QuestionType? type,
    FormDragDropType? form,
    bool? passed,
    List<UpdateUserProgressExerciseOption>? multipleAnswer,
    UpdateUserProgressExerciseOption? singleAnswer,
    List<UpdateUserProgressExerciseDragDropOption>? dragDropAnswer,
    UpdateUserProgressExerciseRecordAnswer? recordAnswer,
  }) = _UpdateUserProgressExerciseData;

  factory UpdateUserProgressExerciseData.fromJson(Map<String, dynamic> json) => _$UpdateUserProgressExerciseDataFromJson(json);
}

@freezed
abstract class UpdateUserProgressExerciseOptionValue with _$UpdateUserProgressExerciseOptionValue {
  @JsonSerializable(includeIfNull: false)
  const factory UpdateUserProgressExerciseOptionValue({
    String? en,
    String? vi,
  }) = _UpdateUserProgressExerciseOptionValue;

  factory UpdateUserProgressExerciseOptionValue.fromJson(Map<String, dynamic> json) => _$UpdateUserProgressExerciseOptionValueFromJson(json);
}

@freezed
abstract class UpdateUserProgressExerciseOption with _$UpdateUserProgressExerciseOption {
  @JsonSerializable(includeIfNull: false)
  const factory UpdateUserProgressExerciseOption({
    UpdateUserProgressExerciseOptionValue? value,
    bool? isCorrect,
  }) = _UpdateUserProgressExerciseOption;

  factory UpdateUserProgressExerciseOption.fromJson(Map<String, dynamic> json) => _$UpdateUserProgressExerciseOptionFromJson(json);
}

@freezed
abstract class UpdateUserProgressExerciseDragDropOption with _$UpdateUserProgressExerciseDragDropOption {
  @JsonSerializable(includeIfNull: false)
  const factory UpdateUserProgressExerciseDragDropOption({
    int? id,
    UpdateUserProgressExerciseOptionValue? text,
  }) = _UpdateUserProgressExerciseDragDropOption;

  factory UpdateUserProgressExerciseDragDropOption.fromJson(Map<String, dynamic> json) => _$UpdateUserProgressExerciseDragDropOptionFromJson(json);
}

@freezed
abstract class UpdateUserProgressExerciseRecordAnswer with _$UpdateUserProgressExerciseRecordAnswer {
  @JsonSerializable(includeIfNull: false)
  const factory UpdateUserProgressExerciseRecordAnswer({
    String? record,
    String? review,
  }) = _UpdateUserProgressExerciseRecordAnswer;

  factory UpdateUserProgressExerciseRecordAnswer.fromJson(Map<String, dynamic> json) => _$UpdateUserProgressExerciseRecordAnswerFromJson(json);
}

@lazySingleton
class UpdateUserProgressExerciseUseCase implements UseCaseWithParams<UpdateUserProgressExerciseParams, UserProgressEntity> {
  final IProgressRepository _repository;

  UpdateUserProgressExerciseUseCase(this._repository);

  @override
  TaskEither<AppException, UserProgressEntity> call(UpdateUserProgressExerciseParams params) {
    return _repository.updateUserProgressExercise(params.toJson());
  }
}
