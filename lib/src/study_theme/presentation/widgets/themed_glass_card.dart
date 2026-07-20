part of '../../study_theme.dart';

/// A card that adapts to the study theme (design items 10–12): a plain white
/// card when no custom background is set, and a frosted-glass card (translucent
/// white + backdrop blur) over a custom background so the personalized
/// background shows through while dark text on the card stays readable.
class ThemedGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final List<BoxShadow>? shadow;

  /// Frosted-white opacity when a custom background is active. Small cards look
  /// best fairly solid (~0.8, default); large screen-filling cards (e.g. the
  /// keypoint content panel) should pass a lower value so the background isn't
  /// almost entirely hidden ("trắng quá").
  final double opacity;

  const ThemedGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = 20,
    this.shadow,
    this.opacity = 0.8,
  });

  @override
  Widget build(BuildContext context) {
    final custom = context.watch<StudyThemeCubit>().state.preset.isCustom;
    final radii = BorderRadius.circular(radius.r);

    if (!custom) {
      return Container(
        padding: padding,
        decoration: BoxDecoration(
          color: AppCustomColor.backgroundWhite,
          borderRadius: radii,
          boxShadow: shadow,
        ),
        child: child,
      );
    }

    return ClipRRect(
      borderRadius: radii,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            // Mostly-opaque frosted white so dark text stays crisp — at 0.6 the
            // busy/dark background bled through and the card read as washed-out
            // ("mờ"). Still translucent enough to feel like glass over the bg.
            color: Colors.white.withValues(alpha: opacity),
            borderRadius: radii,
            border: Border.all(color: Colors.white.withValues(alpha: (opacity - 0.25).clamp(0.0, 1.0))),
          ),
          child: child,
        ),
      ),
    );
  }
}
