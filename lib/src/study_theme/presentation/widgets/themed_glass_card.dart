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

  /// Frosted-white opacity when a custom background is active. Consistent
  /// across all cards (~0.7) — paired with a strong blur so a busy photo
  /// background reads as a smooth soft frost (not muddy) while dark text stays
  /// legible on both light and dark backgrounds.
  final double opacity;

  const ThemedGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = 20,
    this.shadow,
    this.opacity = 0.7,
  });

  @override
  Widget build(BuildContext context) {
    // Always a SOLID white card — matching the Home cards. A semi-transparent
    // frosted look read as muddy/inconsistent over busy or dark photo
    // backgrounds, so every themed card stays a clean opaque white card and the
    // study background shows AROUND the cards (margins, gaps, bare text) rather
    // than through them. Consistent on every screen and always readable.
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.circular(radius.r),
        boxShadow: shadow,
      ),
      child: child,
    );
  }
}
