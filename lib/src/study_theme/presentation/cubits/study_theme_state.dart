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
  }) = _StudyThemeState;

  factory StudyThemeState.initial() => const StudyThemeState(preset: PresetCatalog.defaultPreset);
}
