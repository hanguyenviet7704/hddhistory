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

  const ThemedGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = 20,
    this.shadow,
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
            color: Colors.white.withValues(alpha: 0.6),
            borderRadius: radii,
            border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
          ),
          child: child,
        ),
      ),
    );
  }
}
