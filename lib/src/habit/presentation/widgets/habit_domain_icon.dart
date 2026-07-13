part of '../../habit.dart';

/// Habit icon = the icon/illustration of the "Better" domain (skillset) the
/// habit belongs to (PRD §6), not a per-habit glyph. Skillset images come as
/// either raster (png/jpg) or SVG, and some URLs contain spaces — this handles
/// both (Image.network can't render SVG, so `.svg` routes through flutter_svg).
/// Habits no longer carry their own emoji; when the skillset has no image we
/// fall back to a neutral domain placeholder.
class HabitDomainIcon extends StatelessWidget {
  final String skillsetId;
  final double size;

  const HabitDomainIcon({
    super.key,
    required this.skillsetId,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    final image = (AppDI.injector.get<HomeCubit>().state.skillsets.where((s) => s.id == skillsetId).firstOrNull?.image ?? '').trim();
    // Permanent fallback (no image / load error): a neutral tile with the
    // domain glyph.
    final fallback = Container(
      width: size.w,
      height: size.w,
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundBrandSoft,
        borderRadius: BorderRadius.circular(8.r),
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
        borderRadius: BorderRadius.circular(8.r),
      ),
    );

    final url = Uri.encodeFull(image);
    final isSvg = image.toLowerCase().endsWith('.svg');
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.r),
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
