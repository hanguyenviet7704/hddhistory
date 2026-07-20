part of '../../study_theme.dart';

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
        final ImageProvider? provider = state.uploadedFile != null
            ? FileImage(state.uploadedFile!)
            : (preset.imageAsset != null ? AssetImage(preset.imageAsset!) : null);
        if (provider == null) return const ColoredBox(color: Color(0xFFEFEEF9));
        return Image(image: provider, fit: BoxFit.cover);
      case StudyThemeMode.video:
        // Live video is wired in a later phase; until then a solid fill keeps
        // the app rendering if a video preset is somehow active.
        return const ColoredBox(color: Color(0xFF141733));
    }
  }

  /// A LinearGradient needs ≥2 stops — expand a solid (1-colour) preset and
  /// guard the empty case so a malformed preset can never crash the paint.
  List<Color> _gradientColors(List<Color> gradient) {
    if (gradient.isEmpty) return const [Color(0xFFEFEEF9), Color(0xFFE6EBDE)];
    if (gradient.length == 1) return [gradient.first, gradient.first];
    return gradient;
  }
}
