part of '../../progress.dart';

class UpdateUserProgressKeypointParams {
  final String keypointId;
  final Map<String, dynamic> body;

  UpdateUserProgressKeypointParams({required this.keypointId, required this.body});
}

@lazySingleton
class UpdateUserProgressKeypointUseCase implements UseCaseWithParams<UpdateUserProgressKeypointParams, UserProgressEntity> {
  final IProgressRepository _repository;

  UpdateUserProgressKeypointUseCase(this._repository);

  @override
  TaskEither<AppException, UserProgressEntity> call(UpdateUserProgressKeypointParams params) {
    return _repository.updateUserProgressKeypoint(params.keypointId, params.body);
  }
}
