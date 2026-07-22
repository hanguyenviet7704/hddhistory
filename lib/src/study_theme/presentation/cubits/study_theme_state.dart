part of '../../study_theme.dart';

@freezed
abstract class StudyThemeState with _$StudyThemeState {
  const factory StudyThemeState({
    /// Currently applied preset (catalogue preset or the synthetic upload one).
    required StudyThemePreset preset,

    /// Ambient audio toggle for live presets (persisted alongside the preset).
    @Default(true) bool soundOn,

    /// Whether the readability overlay is painted (design `cbScrim`).
    @Default(true) bool scrimOn,

    /// True while a heavy preset (video/audio) is warming up — drives the
    /// "Applying theme…" overlay (design item 5).
    @Default(false) bool applying,

    /// Transient user-picked image file for the "upload" preset. Never
    /// persisted (design `_cbPersist` skips image/video).
    File? uploadedFile,

    /// Background catalogue backing the picker sheet — DB-only (fetched by
    /// [StudyThemeCubit.loadCatalog] from `/study-themes`). Starts EMPTY (no
    /// bundled fallback); the sheet shows a loading state until it arrives.
    @Default(<StudyThemePreset>[]) List<StudyThemePreset> catalog,

    /// True once a [StudyThemeCubit.loadCatalog] attempt (success OR failure)
    /// has completed at least once this session.
    @Default(false) bool catalogLoaded,

    /// True while a catalogue fetch is in flight. Never blocks the sheet — the
    /// bundled/previous catalogue keeps rendering underneath.
    @Default(false) bool catalogLoading,
  }) = _StudyThemeState;

  factory StudyThemeState.initial() =>
      const StudyThemeState(preset: PresetCatalog.defaultPreset);
}
