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

  /// Frosted-white opacity when a custom background is active. ~0.88 — a SUBTLE
  /// reduction from solid white (matching the theory-keypoint design): the card
  /// stays a clean light panel that just barely lets the background tint show,
  /// rather than a heavily see-through glass. Paired with a light blur so the
  /// hint of background that shows reads as a smooth frost, and dark card text
  /// stays legible over any background.
  final double opacity;

  /// Opt-in frosted-glass rendering (translucent white + backdrop blur) when a
  /// custom study background is active. OFF by default: a blanket frosted look
  /// read as muddy/inconsistent over busy or dark photos, so every other themed
  /// card stays a clean opaque white card and the background shows AROUND them.
  /// The theory keypoint content card opts in so the personalized background
  /// shows THROUGH the card, matching the design.
  final bool frosted;

  const ThemedGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = 20,
    this.shadow,
    this.opacity = 0.82,
    this.frosted = false,
  });

  @override
  Widget build(BuildContext context) {
    final isCustomBg = context.watch<StudyThemeCubit>().state.preset.isCustom;

    // Frosted-glass panel — only for opted-in cards ([frosted]) over a custom
    // background. The custom background shows through a translucent white +
    // strong backdrop blur, so even a busy photo reads as a smooth frost while
    // the dark card text stays legible. The drop shadow sits on an outer layer
    // because the blur's clip can't cast one itself.
    if (isCustomBg) {
      // Over a custom study background: a clean TRANSLUCENT white panel ("trắng
      // trong") — the background shows softly through, dark text stays legible.
      // Deliberately NO BackdropFilter blur: the blur haloed the card edges
      // ("loá viền") and, for stacked cards inside a scroll view, rendered the
      // scrolled-past cards solid white (the backdrop it samples gets clipped
      // away). A flat translucent fill is consistent, artifact-free, and needs
      // no drop shadow — a grey shadow reads as a glare rim over a photo.
      return Container(
        padding: padding,
        decoration: BoxDecoration(
          color: AppCustomColor.backgroundWhite.withValues(alpha: opacity),
          borderRadius: BorderRadius.circular(radius.r),
        ),
        child: child,
      );
    }

    // Default preset: SOLID white card — matching the Home cards. Consistent on
    // every screen and always readable; the study background shows around it.
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
