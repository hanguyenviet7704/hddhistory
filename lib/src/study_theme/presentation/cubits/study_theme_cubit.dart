part of '../../study_theme.dart';

/// Single source of truth for the user's study background. Read by the shell's
/// global [ThemedBackground] (behind every tab) and by full-screen surfaces
/// (Keypoint, Warm-up) that cover the shell, so the choice stays consistent
/// everywhere. Persisted with [HydratedCubit] (design `cb_bg3`).
@lazySingleton
class StudyThemeCubit extends HydratedCubit<StudyThemeState> {
  StudyThemeCubit() : super(StudyThemeState.initial());

  /// Apply a catalogue preset, clearing any previously uploaded image.
  void selectPreset(StudyThemePreset preset) {
    emit(StudyThemeState(
      preset: preset,
      soundOn: state.soundOn,
      scrimOn: state.scrimOn,
    ));
  }

  /// Apply a user-picked image as the background (transient — never persisted).
  void selectUploadedImage(File file) {
    emit(StudyThemeState(
      preset: PresetCatalog.uploadPreset,
      soundOn: state.soundOn,
      scrimOn: state.scrimOn,
      uploadedFile: file,
    ));
  }

  /// Back to the stock light background.
  void reset() => selectPreset(PresetCatalog.defaultPreset);

  void setSound(bool on) => emit(state.copyWith(soundOn: on));

  void setApplying(bool applying) => emit(state.copyWith(applying: applying));

  // ── Persistence (design cb_bg3) ────────────────────────────────────────────
  // Only default/solid/gradient presets survive a restart; image/video/upload
  // do not (see StudyThemePresetX.isPersistable). We store just the preset id
  // and re-resolve it from the catalogue on load, so the persisted blob is a
  // tiny pointer that stays valid as the catalogue grows.
  @override
  StudyThemeState? fromJson(Map<String, dynamic> json) {
    final preset = PresetCatalog.byId(json['presetId'] as String?);
    if (preset == null || !preset.isPersistable) return StudyThemeState.initial();
    return StudyThemeState(preset: preset, soundOn: json['soundOn'] as bool? ?? true);
  }

  @override
  Map<String, dynamic>? toJson(StudyThemeState state) {
    if (!state.preset.isPersistable) return null; // skip image/video/upload
    return {'presetId': state.preset.id, 'soundOn': state.soundOn};
  }
}
