part of '../../in_app_survey.dart';

@lazySingleton
class CreateInAppSurveyResponseUseCase implements BaseUseCase<InAppSurveyResponseEntity, Unit> {
  final IInAppSurveyRepository _repository;

  CreateInAppSurveyResponseUseCase(this._repository);

  @override
  TaskEither<AppException, Unit> call(InAppSurveyResponseEntity params) {
    return _repository.createInAppSurveyResponse(params);
  }
}

