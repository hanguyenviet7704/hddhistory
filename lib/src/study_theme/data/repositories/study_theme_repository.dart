part of '../../study_theme.dart';

@LazySingleton(as: IStudyThemeRepository)
class StudyThemeRepository with RestfulRequestHandlerMixin implements IStudyThemeRepository {
  final StudyThemeApi _api;

  StudyThemeRepository(this._api);

  @override
  TaskEither<AppException, List<StudyThemePreset>> getStudyThemes() {
    // Silent (no toast) — a catalogue sync is a background concern the sheet
    // never blocks on; [StudyThemeCubit.loadCatalog] quietly keeps the bundled
    // [PresetCatalog] on any failure, so surfacing a network error here would
    // be noise the user can't act on.
    return callApiWithTransform<List<StudyThemePresetModel>, List<StudyThemePreset>>(
      apiCall: () => _api.getStudyThemes(),
      transform: (models) => models.map((m) => m.toEntity()).toList(),
      defaultValue: const [],
      enableErrorMessages: false,
    );
  }
}
