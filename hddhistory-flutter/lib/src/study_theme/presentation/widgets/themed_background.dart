part of '../../study_theme.dart';

/// Scaffold background colour that follows the study theme: transparent when a
/// custom background is active (so the shell's [ThemedBackground] shows
/// through), otherwise the screen's own [fallback]. Reactive — the caller
/// rebuilds when the selected preset changes. Screens that want to participate
/// pass their stock colour here instead of a literal.
Color studyThemeScaffoldColor(BuildContext context, Color fallback) =>
    context.watch<StudyThemeCubit>().state.preset.isCustom ? Colors.transparent : fallback;

/// Card fill that follows the study theme: a TRANSLUCENT white panel ("trắng
/// trong", ~0.82) over a custom background — the same look as the keypoint /
/// [ThemedGlassCard] card so the personalized background shows softly through —
/// otherwise a solid white card. For screens that build their own card
/// Containers (e.g. Home) instead of using [ThemedGlassCard].
Color studyThemeCardColor(BuildContext context, {double opacity = 0.82}) =>
    context.watch<StudyThemeCubit>().state.preset.isCustom
        ? AppCustomColor.backgroundWhite.withValues(alpha: opacity)
        : AppCustomColor.backgroundWhite;

/// True when ANY custom study background is active (a preset that isn't the
/// stock light default). Loading veils / bottom fades that default to opaque
/// white must switch to a theme-aware scrim here, or they flash white over the
/// personalized (often dark) background.
bool studyThemeHasCustomBg(BuildContext context) =>
    context.watch<StudyThemeCubit>().state.preset.isCustom;

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

/// Accent (brand-purple) ink for text/links drawn directly ON the study
/// background — eyebrows, ghost/text buttons, etc. The stock deep purple
/// (#4B44CA / #554FF0) sinks into a dark custom background, so lift it to a
/// light lavender there; otherwise keep [fallback]. Use this (not
/// [studyThemeOnBg]) for coloured accent text that must stay recognisably
/// "brand" while remaining legible on any background.
Color studyThemeAccentOnBg(BuildContext context, Color fallback) =>
    studyThemeIsDarkBg(context) ? const Color(0xFFFFF0CB) : fallback;

/// Muted/secondary ink for text or icons INSIDE a glass card (a card filled
/// with [studyThemeCardColor] / [ThemedGlassCard]). On the stock opaque-white
/// card the design's own muted slate ([fallback], e.g. #5F6F86 / #9AA4B2) reads
/// fine, but over a custom study background the translucent card lets the
/// (often dark) background bleed through and that pale muted slate loses
/// contrast — darken it to a readable slate there. Use this for the small
/// labels/captions that sit next to a bold value inside a themed card.
Color studyThemeCardMuted(BuildContext context, Color fallback) =>
    studyThemeHasCustomBg(context) ? AppCustomColor.textSecondary : fallback;

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
        if (provider == null) return const ColoredBox(color: Color(0xFFF9F6EE));
        return Image(image: provider, fit: BoxFit.cover);
      case StudyThemeMode.video:
        // "Live" preset — a looping muted video (+ optional ambient audio).
        // Keyed by preset id so switching presets tears down the old players.
        return _LiveBackgroundLayer(
          key: ValueKey('live-${preset.id}'),
          preset: preset,
          soundOn: state.soundAudible,
        );
    }
  }

  /// A LinearGradient needs ≥2 stops — expand a solid (1-colour) preset and
  /// guard the empty case so a malformed preset can never crash the paint.
  List<Color> _gradientColors(List<Color> gradient) {
    if (gradient.isEmpty) return const [Color(0xFFF9F6EE), Color(0xFFE6EBDE)];
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

/// A THIN view over the shared [_LiveBackground] player — it owns no controller
/// itself. It retains the shared player while mounted and renders that ONE
/// controller through [VideoPlayer] (a texture view), so every mount (the
/// shell's background + any full-screen page pushed opaque over it) shares a
/// single decode. Each mount owning its own controller meant two decoders of
/// the same clip ran at once (flicker) and each covering page re-initialised on
/// entry (a dark "Applying theme…" flash on every navigation into it).
class _LiveBackgroundLayerState extends State<_LiveBackgroundLayer> with SingleTickerProviderStateMixin {
  final _LiveBackground _bg = _LiveBackground.instance;

  // Drives the per-frame repaint that keeps the Android video background moving
  // (see [_motionOverlay]). Created STOPPED and only run once the video is
  // actually playing — never during warm-up: a 60fps rebuild loop on a slower
  // device competes with the platform-channel callbacks that complete
  // VideoPlayerController.initialize(), which could leave the theme stuck on
  // "Applying theme…". Gated on [_LiveBackground.isReady] via [_syncPump].
  late final AnimationController _repaintPump = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );
  bool _overlayFlip = false;

  @override
  void initState() {
    super.initState();
    _bg.retain();
    _bg.addListener(_syncPump);
    _bg.sync(widget.preset, soundOn: widget.soundOn);
  }

  /// Run the repaint pump only while the video is ready+playing; stop it during
  /// warm-up/failure so it can't starve initialization or burn frames on a
  /// static poster.
  void _syncPump() {
    if (!mounted) return;
    if (_bg.isReady) {
      if (!_repaintPump.isAnimating) _repaintPump.repeat();
    } else if (_repaintPump.isAnimating) {
      _repaintPump.stop();
    }
  }

  @override
  void didUpdateWidget(covariant _LiveBackgroundLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.preset.id != widget.preset.id || oldWidget.soundOn != widget.soundOn) {
      _bg.sync(widget.preset, soundOn: widget.soundOn);
    }
  }

  @override
  void dispose() {
    _bg.removeListener(_syncPump);
    _repaintPump.dispose();
    _bg.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bg,
      builder: (context, _) {
        final video = _bg.video;
        if (_bg.isReady && video != null) {
          return Stack(
            fit: StackFit.expand,
            children: [
              FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: video.value.size.width,
                  height: video.value.size.height,
                  child: VideoPlayer(video),
                ),
              ),
              _motionOverlay(),
            ],
          );
        }
        return _warmUp(context);
      },
    );
  }

  /// The Android "no motion" fix. video_player draws the background through an
  /// external texture but — unlike iOS's AVFoundation path — does NOT invalidate
  /// the Flutter scene when the decoder produces a new frame. So on an otherwise
  /// idle screen the engine stops compositing and the video freezes on its last
  /// frame while the decoder (and the separate ambient audio) keep running. Any
  /// real repaint of the background region re-composites the scene and re-samples
  /// the live texture — proven on device: the video animates the instant a scroll
  /// or spinner drives repaints, and freezes otherwise. This full-bleed overlay
  /// flips an imperceptible alpha (0↔1/255 ≈ 0.4% black) every vsync, forcing
  /// exactly that repaint so the background animates like iOS. It shares the
  /// video's repaint boundary (a plain [Stack]) so repainting it repaints the
  /// video texture too. [IgnorePointer] keeps it inert to touches.
  Widget _motionOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _repaintPump,
          builder: (context, _) {
            _overlayFlip = !_overlayFlip;
            return ColoredBox(color: Color.fromARGB(_overlayFlip ? 1 : 0, 0, 0, 0));
          },
        ),
      ),
    );
  }

  /// Shown until the video is ready — and kept if it ultimately fails/times out,
  /// so a slow or dead network degrades to the theme's poster (or its gradient)
  /// instead of an endless "Applying theme…" spinner.
  Widget _warmUp(BuildContext context) {
    final poster = _posterProvider(widget.preset);
    if (poster != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image(image: poster, fit: BoxFit.cover),
          if (!_bg.hasFailed)
            const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            ),
        ],
      );
    }
    if (_bg.hasFailed) {
      // No poster to fall back on: settle on the preset's own gradient rather
      // than a stuck spinner.
      final colors = widget.preset.gradient;
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors.length >= 2
                ? colors
                : (colors.length == 1
                    ? [colors.first, colors.first]
                    : const [Color(0xFF1B1E3B), Color(0xFF141733)]),
          ),
        ),
      );
    }
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

  /// A static poster for the warm-up/failed state: the video preset's own
  /// thumbnail (remote thumbUrl → bundled thumbAsset → image fields).
  ImageProvider? _posterProvider(StudyThemePreset preset) {
    final thumbUrl = preset.thumbUrl ?? preset.imageUrl;
    if (thumbUrl != null && thumbUrl.trim().isNotEmpty) return CachedNetworkImageProvider(thumbUrl);
    final thumbAsset = preset.thumbAsset ?? preset.imageAsset;
    if (thumbAsset != null) return AssetImage(thumbAsset);
    return null;
  }
}

/// App-wide single owner of the "live" (video) study-background players.
///
/// Only one study preset is ever active, so one shared [VideoPlayerController]
/// (+ ambient [ja.AudioPlayer]) serves every [ThemedBackground] mount. The
/// [_LiveBackgroundLayer]s render this controller via [VideoPlayer], so N
/// mounts cost ONE decode (the texture is shared, not re-decoded). Lifetime is
/// ref-counted by mount: players are torn down when the last live layer leaves
/// the tree (preset switched to a non-video mode, or app teardown) and rebuilt
/// when a different video preset is [sync]'d in. All player calls are guarded so
/// a bad/missing source degrades to the warm-up fill; playback pauses while the
/// app is backgrounded.
class _LiveBackground extends ChangeNotifier with WidgetsBindingObserver {
  _LiveBackground._();
  static final _LiveBackground instance = _LiveBackground._();

  StudyThemePreset? _preset;
  VideoPlayerController? _video;
  ja.AudioPlayer? _audio;
  StreamSubscription<ja.ProcessingState>? _audioLoopSub;
  bool _audioLoaded = false;
  bool _ready = false;
  bool _failed = false;
  bool _soundOn = false;
  int _mounts = 0;
  bool _observing = false;

  VideoPlayerController? get video => _video;
  bool get isReady => _ready && (_video?.value.isInitialized ?? false);

  /// True once the video load has given up (download/init error or timeout), so
  /// the layer can settle on a poster/gradient instead of a forever spinner.
  bool get hasFailed => _failed;

  void retain() => _mounts++;

  void release() {
    if (_mounts > 0) _mounts--;
    if (_mounts == 0) _teardown();
  }

  /// Make the shared players match [preset]/[soundOn]. Idempotent for the same
  /// preset id, so every mount can safely call it on init/update. A preset
  /// change re-keys the [_LiveBackgroundLayer]s (fresh warm-up frame), so this
  /// only resets state + kicks off [_start]; the async ready transition is what
  /// notifies listeners (never synchronously during a mount's build).
  void sync(StudyThemePreset preset, {required bool soundOn}) {
    if (!_observing) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
    }
    final soundChanged = _soundOn != soundOn;
    _soundOn = soundOn;
    if (_preset?.id == preset.id) {
      if (soundChanged) _syncAudio();
      return;
    }
    _preset = preset;
    _disposePlayers(); // drop the previous preset's players
    _ready = false;
    _failed = false;
    _start();
  }

  Future<void> _start() async {
    final preset = _preset;
    if (preset == null) return;
    // Resolve the video source (bundled asset first, then a remote R2/DB url —
    // same order as the image mode's _imageProvider).
    final asset = preset.videoAsset;
    final url = preset.videoUrl;
    // The background video is muted, so it must NOT contest the Android audio
    // focus: with the default (mixWithOthers: false) its ExoPlayer registers a
    // focus handler, and the moment the ambient just_audio track (or any other
    // app) takes focus the video is silently paused — a frozen background with
    // the ambience still playing. iOS never exhibited this (no focus contest).
    final opts = VideoPlayerOptions(mixWithOthers: true);
    VideoPlayerController? controller;
    if (asset != null && asset.trim().isNotEmpty) {
      controller = VideoPlayerController.asset(asset, videoPlayerOptions: opts);
    } else if (url != null && url.trim().isNotEmpty) {
      // Remote video: resolve to an on-disk cached FILE. First open downloads +
      // caches; every open after plays straight from disk — no network
      // re-buffer / "Applying theme…" flash on each cold start. Shares the
      // flutter_cache_manager store the image presets already use. Falls back to
      // streaming if the cache/download fails (offline, bad url).
      try {
        // Bound the download so a slow/dead network can't spin "Applying theme…"
        // forever — on timeout we fall through to progressive streaming below.
        final file = await DefaultCacheManager().getSingleFile(url).timeout(const Duration(seconds: 25));
        if (!identical(_preset, preset)) return; // preset switched while awaiting
        controller = VideoPlayerController.file(file, videoPlayerOptions: opts);
      } catch (_) {
        if (!identical(_preset, preset)) return;
        controller = VideoPlayerController.networkUrl(Uri.parse(url), videoPlayerOptions: opts);
      }
    }
    if (controller == null) {
      await _syncAudio();
      return;
    }
    _video = controller;
    try {
      // Bound init too: on some Android devices/networks initialize() can hang;
      // a timeout turns that into a graceful failure (poster/gradient) instead of
      // an endless spinner.
      await controller.initialize().timeout(const Duration(seconds: 15));
      // A newer sync() (preset switch) or a teardown may have replaced/cleared
      // the controller while we awaited — if so this one is orphaned: drop it.
      if (!identical(_video, controller)) {
        await controller.dispose();
        return;
      }
      await controller.setLooping(true);
      await controller.setVolume(0); // video is muted; ambient audio is separate
      await controller.play();
      _ready = true;
      _failed = false;
      notifyListeners();
    } catch (_) {
      if (identical(_video, controller)) {
        _ready = false;
        _failed = true; // give up gracefully → layer shows the poster/gradient
        notifyListeners();
      }
    }
    await _syncAudio();
  }

  Future<void> _syncAudio() async {
    final preset = _preset;
    if (preset == null) return;
    final asset = preset.audioAsset;
    final url = preset.audioUrl;
    final hasAsset = asset != null && asset.trim().isNotEmpty;
    final hasUrl = url != null && url.trim().isNotEmpty;
    final wantAudio = _soundOn && (hasAsset || hasUrl);
    if (!wantAudio) {
      await _audio?.pause();
      return;
    }
    _audio ??= ja.AudioPlayer();
    try {
      if (!_audioLoaded) {
        hasAsset ? await _audio!.setAsset(asset) : await _audio!.setUrl(url!);
        await _audio!.setLoopMode(ja.LoopMode.one);
        await _audio!.setVolume(0.6);
        // Safety net: LoopMode.one can fail to restart a short clip on some
        // platforms/sources (the player parks at `completed` and ambient audio
        // falls silent — the "audio doesn't loop" case). Force the loop
        // ourselves whenever completion is reached so it always keeps going.
        _audioLoopSub ??= _audio!.processingStateStream.listen((s) {
          if (s == ja.ProcessingState.completed) {
            _audio?.seek(Duration.zero);
            _audio?.play();
          }
        });
        _audioLoaded = true;
      }
      await _audio!.play();
    } catch (_) {}
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

  void _disposePlayers() {
    _video?.dispose();
    _video = null;
    _audioLoopSub?.cancel();
    _audioLoopSub = null;
    _audio?.dispose();
    _audio = null;
    _audioLoaded = false;
  }

  void _teardown() {
    _disposePlayers();
    _preset = null;
    _ready = false;
    if (_observing) {
      WidgetsBinding.instance.removeObserver(this);
      _observing = false;
    }
  }
}
