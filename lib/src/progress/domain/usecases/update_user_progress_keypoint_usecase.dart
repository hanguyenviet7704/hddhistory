part of '../../progress.dart';

@freezed
abstract class UpdateUserProgressKeypointParams with _$UpdateUserProgressKeypointParams {
  const factory UpdateUserProgressKeypointParams({
    String? userId,
    String? courseId,
    String? lessonId,
    @Default([]) List<UpdateUserProgressKeypointData> keypoints,
  }) = _UpdateUserProgressKeypointParams;

  factory UpdateUserProgressKeypointParams.fromJson(Map<String, dynamic> json) => _$UpdateUserProgressKeypointParamsFromJson(json);
}

@freezed
abstract class UpdateUserProgressKeypointData with _$UpdateUserProgressKeypointData {
  const factory UpdateUserProgressKeypointData({
    String? keypointId,
    double? averageScore,
    bool? passed,
    String? reviews,
  }) = _UpdateUserProgressKeypointData;

  factory UpdateUserProgressKeypointData.fromJson(Map<String, dynamic> json) => _$UpdateUserProgressKeypointDataFromJson(json);
}

@lazySingleton
class UpdateUserProgressKeypointUseCase implements UseCaseWithParams<UpdateUserProgressKeypointParams, UserProgressEntity> {
  final IProgressRepository _repository;

  UpdateUserProgressKeypointUseCase(this._repository);

  @override
  TaskEither<AppException, UserProgressEntity> call(UpdateUserProgressKeypointParams params) {
    return _repository.updateUserProgressKeypoint(params.toJson());
  }
}
