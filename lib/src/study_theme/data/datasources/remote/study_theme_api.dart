part of '../../../study_theme.dart';

@lazySingleton
@RestApi()
abstract class StudyThemeApi {
  @factoryMethod
  factory StudyThemeApi(@Named(DIKey.appDio) Dio dio) = _StudyThemeApi;

  /// Active presets, sorted by `order` ascending (server-side).
  @GET(AppEndpoint.studyThemes)
  Future<BaseResponse<List<StudyThemePresetModel>>> getStudyThemes();
}
