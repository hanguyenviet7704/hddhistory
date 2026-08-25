part of '../../community.dart';

/// One of the forum's own icons (design `13 · Confession`), tinted to [color].
///
/// The design does NOT use Material's icon set here, and at these sizes the
/// difference is visible rather than academic: its speech bubble is a rounded
/// OVAL with a tail where `Icons.mode_comment_outlined` is a rounded rectangle,
/// and its bell has a flat foot where Material's is a dome. The bubble alone
/// appears four times on a single post, so an approximation reads as a
/// different screen.
///
/// The assets are the design's own paths on a 24×24 box, painted black and
/// recoloured here — so [size] is the design's own number, not a value adjusted
/// for a glyph that fills its box differently.
class CommunityGlyph extends StatelessWidget {
  const CommunityGlyph(this.asset, {super.key, required this.size, required this.color});

  /// A path from `AppAsset.svg.app.icCommunity*`.
  final String asset;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      width: size.sp,
      height: size.sp,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
