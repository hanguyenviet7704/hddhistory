part of '../../study_theme.dart';

/// Single source of truth for the user's study background. Read by the shell's
/// global [ThemedBackground] (behind every tab) and by full-screen surfaces
/// (Keypoint, Warm-up) that cover the shell, so the choice stays consistent
/// everywhere. Persisted with [HydratedCubit] (design `cb_bg3`).
///
/// The picker's catalogue is DB-managed ([GetStudyThemesUseCase] →
/// `/study-themes`) so backgrounds can be added/edited without a release, but
/// the bundled [PresetCatalog] always ships in the app binary and is used
/// whenever the endpoint is unreachable/not-yet-deployed or returns nothing —
/// the feature must keep working fully offline.
@lazySingleton
class StudyThemeCubit extends HydratedCubit<StudyThemeState> with CubitUseCaseHandlerMixin<StudyThemeState> {
  final GetStudyThemesUseCase _getStudyThemesUseCase;

  /// Best-effort snapshot of the last successfully loaded remote catalogue.
  /// [fromJson] runs synchronously during hydration (before [loadCatalog] can
  /// possibly resolve), so in practice it only helps a same-process hot
  /// restart; a cold start always falls back to [PresetCatalog] here, which is
  /// the correct offline-safe behaviour.
  static List<StudyThemePreset>? _remoteCatalogSnapshot;

  StudyThemeCubit(this._getStudyThemesUseCase) : super(StudyThemeState.initial()) {
    loadCatalog();
  }

  /// Fetches the DB-managed catalogue. Silent by design (see
  /// [StudyThemeRepository]) — on failure or an empty list we simply keep
  /// showing the bundled [PresetCatalog] the state already started with, so
  /// the sheet is never empty and never shows a scary network error for a
  /// background sync the user didn't ask for.
  Future<void> loadCatalog() => runUseCaseList<StudyThemePreset>(
        usecase: () => _getStudyThemesUseCase(unit),
        buildLoadingState: () => state.copyWith(catalogLoading: true),
        onFailure: (_) => emit(state.copyWith(catalogLoading: false, catalogLoaded: true)),
        onSuccess: (items) {
          final catalog = items.isEmpty ? PresetCatalog.presets : items;
          _remoteCatalogSnapshot = catalog;
          emit(state.copyWith(catalog: catalog, catalogLoading: false, catalogLoaded: true));
        },
      );

  /// Apply a catalogue preset, clearing any previously uploaded image.
  void selectPreset(StudyThemePreset preset) {
    emit(state.copyWith(preset: preset, applying: false, uploadedFile: null));
  }

  /// Apply a user-picked image as the background (transient — never persisted).
  void selectUploadedImage(File file) {
    emit(state.copyWith(preset: PresetCatalog.uploadPreset, applying: false, uploadedFile: file));
  }

  /// Back to the stock light background — always available offline.
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
    final id = json['presetId'] as String?;
    final catalog = _remoteCatalogSnapshot ?? PresetCatalog.presets;
    final preset = _byId(catalog, id) ?? PresetCatalog.byId(id);
    if (preset == null || !preset.isPersistable) return StudyThemeState.initial();
    return StudyThemeState(preset: preset, soundOn: json['soundOn'] as bool? ?? true, catalog: catalog);
  }

  @override
  Map<String, dynamic>? toJson(StudyThemeState state) {
    if (!state.preset.isPersistable) return null; // skip image/video/upload
    return {'presetId': state.preset.id, 'soundOn': state.soundOn};
  }

  static StudyThemePreset? _byId(List<StudyThemePreset> catalog, String? id) {
    if (id == null) return null;
    for (final p in catalog) {
      if (p.id == id) return p;
    }
    return null;
  }
}
