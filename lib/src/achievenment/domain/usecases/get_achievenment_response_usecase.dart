part of '../../achievenment.dart';

@lazySingleton
class GetAchievenmentResponseUseCase implements UseCaseWithParams<String, AchievenmentResponseEntity> {
  final IAchievenmentRepository _repository;

  GetAchievenmentResponseUseCase(this._repository);

  @override
  TaskEither<AppException, AchievenmentResponseEntity> call(String params) {
    return _repository.getAchievenmentResponse(params);
  }
}

