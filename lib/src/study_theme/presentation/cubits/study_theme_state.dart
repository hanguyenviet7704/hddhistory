part of '../../study_theme.dart';

@freezed
abstract class StudyThemeState with _$StudyThemeState {
  const factory StudyThemeState({
    /// Currently applied preset (catalogue preset or the synthetic upload one).
    required StudyThemePreset preset,

    /// Ambient audio toggle for live presets (persisted alongside the preset).
    /// This is the reader's PREFERENCE — see [soundAudible] for whether the
    /// ambience is actually playing right now.
    @Default(true) bool soundOn,

    /// Ambience silenced for as long as something else needs the ears — a
    /// keypoint being narrated (see `LessonPage`). Deliberately separate from
    /// [soundOn] and deliberately NOT persisted: a lesson must be able to
    /// silence the background without rewriting the reader's preference, so that
    /// the app being killed mid-lesson can't leave their music off for good.
    @Default(false) bool soundSuspended,

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

extension StudyThemeStateX on StudyThemeState {
  /// Whether the background's ambient audio should be heard right now: the
  /// reader wants it AND nothing is currently borrowing the ears. This — not
  /// [StudyThemeState.soundOn] — is what the player and the sound toggles read.
  bool get soundAudible => soundOn && !soundSuspended;
}
