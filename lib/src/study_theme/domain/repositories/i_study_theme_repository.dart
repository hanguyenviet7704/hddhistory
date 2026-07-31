part of '../../study_theme.dart';

abstract class IStudyThemeRepository {
  /// The DB-managed background catalogue. Callers must treat failure/empty as
  /// "fall back to the bundled [PresetCatalog]" — this repository does not do
  /// that itself so [StudyThemeCubit] stays the single place that decision is
  /// made (and can be unit-tested independently of the network layer).
  TaskEither<AppException, List<StudyThemePreset>> getStudyThemes();
}
