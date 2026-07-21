part of '../../study_theme.dart';

/// Scaffold background colour that follows the study theme: transparent when a
/// custom background is active (so the shell's [ThemedBackground] shows
/// through), otherwise the screen's own [fallback]. Reactive — the caller
/// rebuilds when the selected preset changes. Screens that want to participate
/// pass their stock colour here instead of a literal.
Color studyThemeScaffoldColor(BuildContext context, Color fallback) =>
    context.watch<StudyThemeCubit>().state.preset.isCustom ? Colors.transparent : fallback;

/// True when a DARK custom background is active — text/icons sitting directly on
/// the background must switch to light ink to stay readable.
bool studyThemeIsDarkBg(BuildContext context) {
  final preset = context.watch<StudyThemeCubit>().state.preset;
  return preset.isCustom && preset.isDark;
}

/// Ink colour for text/icons drawn directly ON the study background (NOT inside
/// a card — cards stay opaque/glass and keep their own dark ink). Light on a
/// dark custom background, otherwise [fallback].
Color studyThemeOnBg(BuildContext context, Color fallback) =>
    studyThemeIsDarkBg(context) ? const Color(0xFFF3F4FA) : fallback;

/// Paints the user's selected study background (+ optional readability overlay)
/// behind [child]. Mounted at the shell level (behind every tab) and by
/// full-screen surfaces that cover the shell; all mounts read the same
/// [StudyThemeCubit] singleton so the background stays consistent everywhere.
class ThemedBackground extends StatelessWidget {
  final Widget child;

  const ThemedBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StudyThemeCubit, StudyThemeState>(
      bloc: AppDI.injector.get<StudyThemeCubit>(),
      builder: (context, state) {
        // Default preset paints nothing — every screen keeps its own stock
        // background. Only a custom preset takes over (screens go transparent).
        if (!state.preset.isCustom) return child;
        final overlay = state.preset.overlay;
        return Stack(
          children: [
            Positioned.fill(child: _StudyBackgroundLayer(state: state)),
            if (state.scrimOn && overlay != null)
              Positioned.fill(child: IgnorePointer(child: ColoredBox(color: overlay))),
            child,
          ],
        );
      },
    );
  }
}

/// The raw background fill for the active preset (no overlay). Split out so the
/// overlay in [ThemedBackground] can sit above it but below the app content.
class _StudyBackgroundLayer extends StatelessWidget {
  final StudyThemeState state;

  const _StudyBackgroundLayer({required this.state});

  @override
  Widget build(BuildContext context) {
    final preset = state.preset;
    switch (preset.mode) {
      case StudyThemeMode.defaultMode:
      case StudyThemeMode.color:
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _gradientColors(preset.gradient),
            ),
          ),
        );
      case StudyThemeMode.image:
        final ImageProvider? provider = _imageProvider(preset, state.uploadedFile);
        if (provider == null) return const ColoredBox(color: Color(0xFFEFEEF9));
        return Image(image: provider, fit: BoxFit.cover);
      case StudyThemeMode.video:
        // "Live" preset — a looping muted video (+ optional ambient audio).
        // Keyed by preset id so switching presets tears down the old players.
        return _LiveBackgroundLayer(
          key: ValueKey('live-${preset.id}'),
          preset: preset,
          soundOn: state.soundOn,
        );
    }
  }

  /// A LinearGradient needs ≥2 stops — expand a solid (1-colour) preset and
  /// guard the empty case so a malformed preset can never crash the paint.
  List<Color> _gradientColors(List<Color> gradient) {
    if (gradient.isEmpty) return const [Color(0xFFEFEEF9), Color(0xFFE6EBDE)];
    if (gradient.length == 1) return [gradient.first, gradient.first];
    return gradient;
  }

  /// Resolution order: the user's just-picked upload (never persisted) →
  /// the preset's DB-managed remote photo (cached network provider) → the
  /// preset's bundled asset (offline fallback catalogue).
  ImageProvider? _imageProvider(StudyThemePreset preset, File? uploadedFile) {
    if (uploadedFile != null) return FileImage(uploadedFile);
    final url = preset.imageUrl;
    if (url != null && url.trim().isNotEmpty) return CachedNetworkImageProvider(url);
    final asset = preset.imageAsset;
    if (asset != null) return AssetImage(asset);
    return null;
  }
}

/// "Live" background — a looping, muted video with optional looping ambient
/// audio ([StudyThemeMode.video], design item 5). videoUrl/audioUrl may be a
/// bundled `assets/...` path or a remote (R2) url from the DB catalogue. All
/// player calls are guarded so a bad/missing source degrades to a solid fill;
/// playback pauses when the app backgrounds and everything is disposed when the
/// preset changes (the parent keys this widget by preset id) or unmounts.
class _LiveBackgroundLayer extends StatefulWidget {
  final StudyThemePreset preset;
  final bool soundOn;

  const _LiveBackgroundLayer({super.key, required this.preset, required this.soundOn});

  @override
  State<_LiveBackgroundLayer> createState() => _LiveBackgroundLayerState();
}

class _LiveBackgroundLayerState extends State<_LiveBackgroundLayer> with WidgetsBindingObserver {
  VideoPlayerController? _video;
  ja.AudioPlayer? _audio;
  bool _audioLoaded = false;
  bool _ready = false;

  static bool _isAssetPath(String? url) => (url ?? '').startsWith('assets/');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  Future<void> _start() async {
    final videoUrl = widget.preset.videoUrl;
    if (videoUrl != null && videoUrl.trim().isNotEmpty) {
      final controller = _isAssetPath(videoUrl)
          ? VideoPlayerController.asset(videoUrl)
          : VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      _video = controller;
      try {
        await controller.initialize();
        await controller.setLooping(true);
        await controller.setVolume(0); // video is muted; ambient audio is separate
        await controller.play();
        if (mounted) setState(() => _ready = true);
      } catch (_) {
        if (mounted) setState(() => _ready = false);
      }
    }
    await _syncAudio();
  }

  Future<void> _syncAudio() async {
    final audioUrl = widget.preset.audioUrl;
    final wantAudio = widget.soundOn && audioUrl != null && audioUrl.trim().isNotEmpty;
    if (!wantAudio) {
      await _audio?.pause();
      return;
    }
    _audio ??= ja.AudioPlayer();
    try {
      if (!_audioLoaded) {
        _isAssetPath(audioUrl) ? await _audio!.setAsset(audioUrl) : await _audio!.setUrl(audioUrl);
        await _audio!.setLoopMode(ja.LoopMode.one);
        await _audio!.setVolume(0.6);
        _audioLoaded = true;
      }
      await _audio!.play();
    } catch (_) {}
  }

  @override
  void didUpdateWidget(covariant _LiveBackgroundLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.soundOn != widget.soundOn) _syncAudio();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _video?.play();
      _syncAudio();
    } else {
      _video?.pause();
      _audio?.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _video?.dispose();
    _audio?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final video = _video;
    if (video != null && _ready && video.value.isInitialized) {
      return FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: video.value.size.width,
          height: video.value.size.height,
          child: VideoPlayer(video),
        ),
      );
    }
    // Warming up (or no/failed video): dark fill + "Applying theme…" (item 5).
    return ColoredBox(
      color: const Color(0xFF141733),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
            ),
            12.verticalSpace,
            AppText(
              context.l10n.studyTheme.applyingTheme,
              style: AppStyle.text14.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
