part of '../../study_theme.dart';

/// Single source of truth for the user's study background. Read by the shell's
/// global [ThemedBackground] (behind every tab) and by full-screen surfaces
/// (Keypoint, Warm-up) that cover the shell, so the choice stays consistent
/// everywhere. Persisted with [HydratedCubit] (design `cb_bg3`).
///
/// The picker's catalogue is DB-only ([GetStudyThemesUseCase] → `/study-themes`)
/// so backgrounds can be added/edited without a release; there is NO bundled
/// fallback list — the sheet shows a loading state until the fetch resolves.
/// The APPLIED preset still persists in full (see [toJson]), so the user's
/// current background survives a restart even before the catalogue reloads.
@lazySingleton
class StudyThemeCubit extends HydratedCubit<StudyThemeState> with CubitUseCaseHandlerMixin<StudyThemeState> {
  final GetStudyThemesUseCase _getStudyThemesUseCase;

  /// Best-effort snapshot of the last successfully loaded remote catalogue.
  /// [fromJson] runs synchronously during hydration (before [loadCatalog] can
  /// possibly resolve), so in practice it only helps a same-process hot
  /// restart; a cold start begins with an EMPTY catalogue here and [loadCatalog]
  /// fills it right after (the applied preset itself restores from its own JSON).
  static List<StudyThemePreset>? _remoteCatalogSnapshot;

  StudyThemeCubit(this._getStudyThemesUseCase) : super(StudyThemeState.initial()) {
    loadCatalog();
  }

  /// Fetches the DB-managed catalogue. Silent by design (see
  /// [StudyThemeRepository]); the sheet drives its own loading / empty-retry UI
  /// off [StudyThemeState.catalogLoading]/[catalogLoaded]/[catalog] — there is
  /// no bundled fallback, so a failed/empty fetch leaves the catalogue empty.
  Future<void> loadCatalog() => runUseCaseList<StudyThemePreset>(
        usecase: () => _getStudyThemesUseCase(unit),
        buildLoadingState: () => state.copyWith(catalogLoading: true),
        onFailure: (_) => emit(state.copyWith(catalogLoading: false, catalogLoaded: true)),
        onSuccess: (items) {
          // DB is the single source of truth — no bundled fallback. An empty
          // result stays empty (the sheet shows its empty/retry state).
          _remoteCatalogSnapshot = items;
          emit(state.copyWith(catalog: items, catalogLoading: false, catalogLoaded: true));
        },
      );

  Future<void>? _catalogInFlight;

  /// Self-heal for the picker, called every time the sheet opens.
  ///
  /// `/study-themes` is an AUTHENTICATED endpoint, but [loadCatalog] also runs
  /// from this cubit's constructor — i.e. whenever DI first resolves it, which on
  /// a cold start happens before the guest/auth token is attached. That attempt
  /// 401s, `onFailure` marks the catalogue "loaded" (and empty), and nothing ever
  /// retried: the sheet showed its empty state and the user had to tap Reload by
  /// hand every time. Retrying on open fixes that — and because it flips
  /// [StudyThemeState.catalogLoading], the sheet now shows its skeleton instead
  /// of an empty grid while the retry runs.
  ///
  /// No-op once the catalogue is populated, and de-duped while a fetch is in
  /// flight, so re-opening the sheet costs nothing. Mirrors
  /// `HomeCubit.ensureHomeDataLoaded` / `HabitCubit.ensureLoaded`.
  Future<void> ensureCatalogLoaded() {
    final inFlight = _catalogInFlight;
    if (inFlight != null) return inFlight;
    if (state.catalog.isNotEmpty || state.catalogLoading) return Future.value();
    final future = loadCatalog().whenComplete(() => _catalogInFlight = null);
    _catalogInFlight = future;
    return future;
  }

  /// Apply a catalogue preset, clearing any previously uploaded image.
  void selectPreset(StudyThemePreset preset) {
    emit(state.copyWith(preset: preset, applying: false, uploadedFile: null));
  }

  /// Apply a user-picked image as the background. Unlike curated presets we
  /// don't know the photo's brightness up front, so detect it and pick
  /// light-vs-dark ink + a matching gentle overlay, so the app's text stays
  /// readable whether the user picks a bright or a dark photo. The photo is
  /// copied into app documents (a stable path) so the choice survives a restart
  /// — see [toJson]/[fromJson].
  Future<void> selectUploadedImage(File file) async {
    emit(state.copyWith(applying: true, uploadedFile: file));
    final dark = await _uploadedImageIsDark(file);
    // Persist a stable copy — the picker hands back a cache/temp path that may
    // be purged before the next launch. Fall back to the transient file if the
    // copy fails (still works this session, just won't survive a restart).
    final persisted = await _persistUploadCopy(file) ?? file;
    emit(state.copyWith(
      preset: PresetCatalog.uploadPreset.copyWith(
        isDark: dark,
        // A user photo is usually MIXED brightness (bright + dark patches), so a
        // gentle overlay isn't enough — apply a firm scrim in the detected
        // direction so light ink survives the photo's bright spots (and dark ink
        // its dark spots). ~45% either way.
        overlay: dark ? const Color(0x73000000) : const Color(0x73FFFFFF),
      ),
      applying: false,
      uploadedFile: persisted,
    ));
  }

  /// Copies the picked photo into app documents under a single fixed name
  /// (overwriting any previous upload) so its path stays valid across restarts.
  /// Returns null on any failure so the caller keeps the transient file.
  Future<File?> _persistUploadCopy(File src) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final dotIndex = src.path.lastIndexOf('.');
      final ext = dotIndex >= 0 ? src.path.substring(dotIndex) : '.img';
      return await src.copy('${dir.path}/study_theme_upload$ext');
    } catch (_) {
      return null;
    }
  }

  /// Back to the stock light background — always available offline.
  void reset() => selectPreset(PresetCatalog.defaultPreset);

  /// The reader's own toggle. Also clears any suspension: asking for sound while
  /// something else had silenced it is an explicit override, and leaving the
  /// switch on with nothing playing would read as broken.
  void setSound(bool on) => emit(state.copyWith(soundOn: on, soundSuspended: false));

  /// Silences the ambience WITHOUT touching the reader's preference — narration
  /// and background music competing makes the voice hard to follow, so a lesson
  /// borrows the ears for as long as it is open and hands them back on the way
  /// out (see [StudyThemeState.soundSuspended]).
  void suspendSound(bool suspended) {
    if (state.soundSuspended == suspended) return;
    emit(state.copyWith(soundSuspended: suspended));
  }

  void setApplying(bool applying) => emit(state.copyWith(applying: applying));

  // ── Persistence (design cb_bg3) ────────────────────────────────────────────
  // Catalogue presets persist as a tiny id pointer, re-resolved from the
  // catalogue on load (stays valid as the catalogue grows). A user UPLOAD can't
  // be pointed at by id, so it persists its stable file copy + computed
  // ink/overlay instead (see [selectUploadedImage] / [_persistUploadCopy]).
  @override
  StudyThemeState? fromJson(Map<String, dynamic> json) {
    try {
      final catalog = _remoteCatalogSnapshot ?? const <StudyThemePreset>[];

      // New format: the FULL preset is stored, so it restores WITHOUT needing
      // the (not-yet-loaded) remote catalogue — this is what lets a DB-only
      // preset (e.g. 'autumn', absent from the bundled PresetCatalog) survive a
      // cold start instead of falling back to default.
      final presetJson = json['preset'];
      if (presetJson is Map<String, dynamic>) {
        final preset = _presetFromJson(presetJson);
        File? uploaded;
        if (preset.id == PresetCatalog.uploadPreset.id) {
          final path = json['uploadedPath'] as String?;
          // The copied file may have been cleared — fall back to stock.
          if (path == null || !File(path).existsSync()) return StudyThemeState.initial();
          uploaded = File(path);
        }
        return StudyThemeState(preset: preset, uploadedFile: uploaded, soundOn: json['soundOn'] as bool? ?? true, catalog: catalog);
      }

      // Legacy format: {presetId} — resolve by id from the bundled catalogue.
      final id = json['presetId'] as String?;
      final legacy = _byId(catalog, id) ?? PresetCatalog.byId(id);
      if (legacy == null) return StudyThemeState.initial();
      return StudyThemeState(preset: legacy, soundOn: json['soundOn'] as bool? ?? true, catalog: catalog);
    } catch (_) {
      return StudyThemeState.initial();
    }
  }

  @override
  Map<String, dynamic>? toJson(StudyThemeState state) {
    final preset = state.preset;
    // Persist the WHOLE preset (not just its id) so any preset — bundled,
    // DB-only, or a user upload — restores on next launch without depending on
    // the remote catalogue having loaded yet.
    final map = <String, dynamic>{'preset': _presetToJson(preset), 'soundOn': state.soundOn};
    if (preset.id == PresetCatalog.uploadPreset.id) {
      final file = state.uploadedFile;
      if (file == null) return null; // nothing to restore
      map['uploadedPath'] = file.path;
    }
    return map;
  }

  static Map<String, dynamic> _presetToJson(StudyThemePreset p) => {
    'id': p.id,
    'mode': p.mode.name,
    'category': p.category,
    'name': p.name,
    'gradient': p.gradient.map(_studyThemeColorToHex).whereType<String>().toList(),
    'imageAsset': p.imageAsset,
    'videoAsset': p.videoAsset,
    'audioAsset': p.audioAsset,
    'thumbAsset': p.thumbAsset,
    'imageUrl': p.imageUrl,
    'videoUrl': p.videoUrl,
    'audioUrl': p.audioUrl,
    'thumbUrl': p.thumbUrl,
    'overlay': _studyThemeColorToHex(p.overlay),
    'isDark': p.isDark,
    'isPremium': p.isPremium,
  };

  static StudyThemePreset _presetFromJson(Map<String, dynamic> j) => StudyThemePreset(
    id: j['id'] as String? ?? 'default',
    mode: StudyThemeMode.values.firstWhere((m) => m.name == j['mode'], orElse: () => StudyThemeMode.defaultMode),
    category: j['category'] as String? ?? '',
    name: j['name'] as String? ?? '',
    gradient: (j['gradient'] as List?)?.map((e) => _studyThemeColorFromHex(e as String?)).whereType<Color>().toList() ?? const [],
    imageAsset: j['imageAsset'] as String?,
    videoAsset: j['videoAsset'] as String?,
    audioAsset: j['audioAsset'] as String?,
    thumbAsset: j['thumbAsset'] as String?,
    imageUrl: j['imageUrl'] as String?,
    videoUrl: j['videoUrl'] as String?,
    audioUrl: j['audioUrl'] as String?,
    thumbUrl: j['thumbUrl'] as String?,
    overlay: _studyThemeColorFromHex(j['overlay'] as String?),
    isDark: j['isDark'] as bool? ?? false,
    isPremium: j['isPremium'] as bool? ?? false,
  );

  static StudyThemePreset? _byId(List<StudyThemePreset> catalog, String? id) {
    if (id == null) return null;
    for (final p in catalog) {
      if (p.id == id) return p;
    }
    return null;
  }
}

/// Whether a user-uploaded photo reads dark overall — decodes a tiny 24×24
/// thumbnail and averages perceived luminance so [StudyThemeCubit.selectUploadedImage]
/// can choose light vs dark ink. Safe default (dark → light ink) on any error.
Future<bool> _uploadedImageIsDark(File file) async {
  try {
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: 24, targetHeight: 24);
    final frame = await codec.getNextFrame();
    final data = await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
    frame.image.dispose();
    if (data == null) return true;
    final px = data.buffer.asUint8List();
    double sum = 0;
    var n = 0;
    for (var i = 0; i + 3 < px.length; i += 4) {
      if (px[i + 3] == 0) continue; // skip fully-transparent pixels
      sum += 0.299 * px[i] + 0.587 * px[i + 1] + 0.114 * px[i + 2];
      n++;
    }
    if (n == 0) return true;
    return (sum / n) < 140; // mean luminance < 140/255 → treat the photo as dark
  } catch (_) {
    return true;
  }
}
