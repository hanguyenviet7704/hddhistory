part of '../../progress.dart';

@freezed
abstract class UpdateUserProgressExerciseParams with _$UpdateUserProgressExerciseParams {
  const factory UpdateUserProgressExerciseParams({
    String? userId,
    String? courseId,
    String? lessonId,
    @Default([]) List<UpdateUserProgressExerciseData> exercises,
  }) = _UpdateUserProgressExerciseParams;

  factory UpdateUserProgressExerciseParams.fromJson(Map<String, dynamic> json) => _$UpdateUserProgressExerciseParamsFromJson(json);
}

@freezed
abstract class UpdateUserProgressExerciseData with _$UpdateUserProgressExerciseData {
  const factory UpdateUserProgressExerciseData({
    String? exerciseId,
    double? score,
    bool? passed,
    int? numberOfCorrect,
    int? numberOfIncorrect,
    String? reviews,
    DateTime? submittedAt,
  }) = _UpdateUserProgressExerciseData;

  factory UpdateUserProgressExerciseData.fromJson(Map<String, dynamic> json) => _$UpdateUserProgressExerciseDataFromJson(json);
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
