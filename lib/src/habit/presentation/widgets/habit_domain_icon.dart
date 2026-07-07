part of '../../habit.dart';

/// Habit icon = the icon/illustration of the "Better" domain (skillset) the
/// habit belongs to (PRD §6), not a per-habit glyph. Falls back to the habit's
/// own emoji when the skillset has no image (or it fails to load), so it always
/// renders something sensible.
class HabitDomainIcon extends StatelessWidget {
  final String skillsetId;
  final String fallbackEmoji;
  final double size;

  const HabitDomainIcon({
    super.key,
    required this.skillsetId,
    required this.fallbackEmoji,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    final image = AppDI.injector.get<HomeCubit>().state.skillsets
            .where((s) => s.id == skillsetId)
            .firstOrNull
            ?.image ??
        '';
    final fallback = AppText(fallbackEmoji, style: AppStyle.text24);
    if (image.isEmpty) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.r),
      child: Image.network(
        image,
        width: size.w,
        height: size.w,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : SizedBox(width: size.w, height: size.w, child: fallback),
      ),
    );
  }
}
