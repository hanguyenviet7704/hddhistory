part of '../../habit.dart';

/// The picture shown beside a habit, in three tiers.
///
/// The habit's OWN image wins when it has one. Editors set it per habit, so it
/// is the most specific thing available and the whole point of the field.
/// Without one it falls back to the icon of the "Better" domain (skillset) the
/// habit belongs to (PRD §6), which is what every habit showed before pictures
/// existed — so a catalog only half filled in never renders a hole. Last resort
/// is a neutral tile with the domain glyph.
///
/// Either source may be raster (png/jpg) or SVG, and some URLs carry spaces, so
/// both are handled: `Image.network` cannot render SVG, and `.svg` routes
/// through flutter_svg instead.
class HabitDomainIcon extends StatelessWidget {
  /// The habit's own picture. Empty falls through to the skillset's.
  final String imageUrl;
  final String skillsetId;
  final double size;

  /// Corner rounding. 8 everywhere except the "Add a habit" rows, which the
  /// design draws at 10.
  final double radius;

  const HabitDomainIcon({
    super.key,
    required this.skillsetId,
    this.imageUrl = '',
    this.size = 28,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final ownImage = imageUrl.trim();
    final image = ownImage.isNotEmpty
        ? ownImage
        : (AppDI.injector.get<HomeCubit>().state.skillsets.where((s) => s.id == skillsetId).firstOrNull?.image ?? '').trim();
    // Permanent fallback (no image / load error): a neutral tile with the
    // domain glyph.
    final fallback = Container(
      width: size.w,
      height: size.w,
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundBrandSoft,
        borderRadius: BorderRadius.circular(radius.r),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.spa_rounded, size: (size * 0.55).w, color: AppCustomColor.streakActive),
    );
    if (image.isEmpty) return fallback;

    // Shown ONLY while the skillset image is loading — a plain, ICON-LESS tile
    // so the domain glyph never flashes before the real logo arrives (users
    // disliked seeing the placeholder icon pop in during load).
    final loadingPlaceholder = Container(
      width: size.w,
      height: size.w,
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundGray,
        borderRadius: BorderRadius.circular(radius.r),
      ),
    );

    final url = Uri.encodeFull(image);
    final isSvg = image.toLowerCase().endsWith('.svg');
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius.r),
      child: isSvg
          ? SvgPicture.network(
              url,
              width: size.w,
              height: size.w,
              fit: BoxFit.cover,
              placeholderBuilder: (_) => loadingPlaceholder,
            )
          : CachedNetworkImage(
              imageUrl: url,
              width: size.w,
              height: size.w,
              fit: BoxFit.cover,
              placeholder: (_, _) => loadingPlaceholder,
              errorWidget: (_, _, _) => fallback,
            ),
    );
  }
}
