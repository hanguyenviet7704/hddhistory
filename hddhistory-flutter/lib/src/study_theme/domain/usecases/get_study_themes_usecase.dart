part of '../../study_theme.dart';

@lazySingleton
class GetStudyThemesUseCase implements BaseUseCase<Unit, List<StudyThemePreset>> {
  final IStudyThemeRepository _repository;

  GetStudyThemesUseCase(this._repository);

  @override
  TaskEither<AppException, List<StudyThemePreset>> call(Unit _) {
    return _repository.getStudyThemes();
  }
}
