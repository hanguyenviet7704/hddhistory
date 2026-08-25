part of '../../community.dart';

/// The MeUp mark on a violet tile — the chat room's face (design `S-03`).
///
/// A "?" in Poppins rather than an asset: the design sets it as type, and the
/// family is already bundled. Bold (700) is the heaviest weight that ships, so
/// the design's 800 renders as 700 rather than as a synthesised fake bold.
class CommunityChatMark extends StatelessWidget {
  const CommunityChatMark({super.key, required this.size, required this.radius, this.glyphSize});

  final double size;
  final double radius;

  /// Defaults to a little under 3/5 of the tile, the design's ratio at both
  /// sizes it draws (21 in 36, 34 in 58).
  final double? glyphSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.w,
      height: size.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius.r),
        gradient: const LinearGradient(
          // 150deg in CSS runs top-left-ish to bottom-right-ish.
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppCustomColor.communityChatMarkStart,
            AppCustomColor.communityChatMarkEnd,
          ],
        ),
      ),
      child: ExcludeSemantics(
        child: Text(
          '?',
          style: TextStyle(
            fontFamily: AppFont.poppins,
            fontWeight: FontWeight.w700,
            fontSize: (glyphSize ?? size * 0.58).sp,
            height: 1,
            color: AppCustomColor.textWhite,
          ),
        ),
      ),
    );
  }
}
