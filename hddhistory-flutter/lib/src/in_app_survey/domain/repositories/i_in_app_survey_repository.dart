part of '../../in_app_survey.dart';

abstract class IInAppSurveyRepository {
  TaskEither<AppException, InAppSurveyConfigEntity> getInAppSurveyConfig();
  TaskEither<AppException, Unit> createInAppSurveyResponse(InAppSurveyResponseEntity entity);
}

