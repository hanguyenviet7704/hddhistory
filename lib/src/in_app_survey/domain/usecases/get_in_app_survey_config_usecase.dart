part of '../../in_app_survey.dart';

@lazySingleton
class GetInAppSurveyConfigUseCase implements BaseUseCase<Unit, InAppSurveyConfigEntity> {
  final IInAppSurveyRepository _repository;

  GetInAppSurveyConfigUseCase(this._repository);

  @override
  TaskEither<AppException, InAppSurveyConfigEntity> call(Unit _) {
    return _repository.getInAppSurveyConfig();
  }
}

