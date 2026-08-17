part of '../../library.dart';

// ---------------------------------------------------------------------------
// Quote-card tokens (design `5b · Library` → Saved cards, and the recap card at
// the end of a keypoint — the same card in both places).
// ---------------------------------------------------------------------------

/// The oversized opening quote behind the title (design #F0EEFC).
const Color _kQuoteMark = Color(0xFFF0EEFC);

/// Short rule between title and course name (design #CFCBF2).
const Color _kQuoteDivider = Color(0xFFCFCBF2);

/// Course name under the rule (design #5F6F86).
const Color _kQuoteCourseText = Color(0xFF5F6F86);

/// Hexagon ring around the artwork (design #DCD7F7) and its inner well.
const Color _kQuoteHexRing = Color(0xFFDCD7F7);
const Color _kQuoteHexWell = Color(0xFFF0EEFC);

/// The card's back face (design #211B40) — the only dark surface in Library.
const Color _kQuoteBackFace = Color(0xFF211B40);

/// Toast pill behind "Saved"/"Removed" (design #0D121C).
const Color _kSavedToastBg = Color(0xFF0D121C);

/// Tinted tile behind an icon — the deck's action discs, the options sheet's
/// icon squares, the grid/deck toggle track (design #F2F3F8). A shade cooler
/// than [AppCustomColor.backgroundGray], which is the app's own page grey.
const Color _kSavedTileGrey = Color(0xFFF2F3F8);

/// The two sizes the card is drawn at.
///
/// Not one scaled by width: the design's grid tile is not a shrunk deck card —
/// it keeps a heavier title relative to its box and drops the padding that the
/// big card uses to hold the artwork clear of the text.
enum SavedQuoteCardSize {
  /// Two-up in the Saved cards grid.
  compact,

  /// The deck, the detail overlay, and the recap card at the end of a keypoint.
  full,
}

/// The front face: a quote card carrying one keypoint's title.
///
/// Shared by the grid, the deck and the detail overlay so the three cannot
/// drift; the back face is [SavedQuoteCardBack].
///
/// The recap card at the end of a keypoint draws the same design but keeps its
/// own implementation ([KeypointDoneCard]) — it is welded to that screen's
/// narration and auto-flip, and its artwork treatment predates this card.
class SavedQuoteCard extends StatelessWidget {
  const SavedQuoteCard({
    super.key,
    required this.title,
    required this.courseTitle,
    required this.imageUrl,
    this.size = SavedQuoteCardSize.full,
  });

  final String title;
  final String courseTitle;
  final String imageUrl;
  final SavedQuoteCardSize size;

  bool get _isCompact => size == SavedQuoteCardSize.compact;

  @override
  Widget build(BuildContext context) {
    final radius = (_isCompact ? 18.0 : 26.0).r;
    final artworkSize = (_isCompact ? 56.0 : 112.0).w;

    return Container(
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF141828).withValues(alpha: _isCompact ? 0.10 : 0.12),
            blurRadius: (_isCompact ? 26.0 : 34.0).r,
            offset: Offset(0, (_isCompact ? 10.0 : 14.0).h),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            top: (_isCompact ? 2.0 : 6.0).h,
            left: (_isCompact ? 7.0 : 14.0).w,
            child: _QuoteGlyph(fontSize: (_isCompact ? 64.0 : 130.0).sp, color: _kQuoteMark),
          ),
          Positioned(
            right: (_isCompact ? 9.0 : 18.0).w,
            bottom: (_isCompact ? 9.0 : 18.0).h,
            child: SavedQuoteArtwork(imageUrl: imageUrl, size: artworkSize),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              (_isCompact ? 15.0 : 26.0).w,
              (_isCompact ? 16.0 : 30.0).h,
              (_isCompact ? 15.0 : 26.0).w,
              // The deep bottom padding is what keeps the text block clear of
              // the artwork sitting in the corner.
              (_isCompact ? 48.0 : 108.0).h,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: AppText(
                    title,
                    maxLines: _isCompact ? 4 : 5,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppFont.mulish,
                      fontSize: (_isCompact ? 14.0 : 21.0).sp,
                      fontWeight: FontWeight.w700,
                      height: 1.28,
                      color: AppCustomColor.textPrimary,
                    ),
                  ),
                ),
                SizedBox(height: (_isCompact ? 9.0 : 11.0).h),
                Container(
                  width: (_isCompact ? 22.0 : 28.0).w,
                  height: 2.h,
                  decoration: BoxDecoration(
                    color: _kQuoteDivider,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(height: (_isCompact ? 7.0 : 8.0).h),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _isCompact ? 0.82 : 0.70,
                  child: AppText(
                    courseTitle.toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppFont.mulish,
                      fontSize: (_isCompact ? 8.0 : 8.5).sp,
                      fontWeight: FontWeight.w700,
                      height: 1.45,
                      letterSpacing: (_isCompact ? 8.0 : 8.5) * (_isCompact ? 0.07 : 0.08),
                      color: _kQuoteCourseText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The back face: the recap, on the design's one dark surface.
///
/// The text scrolls — a takeaway is authored prose and runs past the card on a
/// small phone. A fade at the foot says so without a scrollbar; a clipped
/// sentence with no cue reads as a truncation bug.
class SavedQuoteCardBack extends StatelessWidget {
  const SavedQuoteCardBack({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kQuoteBackFace,
        borderRadius: BorderRadius.circular(26.r),
        boxShadow: [
          BoxShadow(
            color: _kQuoteBackFace.withValues(alpha: 0.34),
            blurRadius: 38.r,
            offset: Offset(0, 16.h),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            top: 6.h,
            right: 22.w,
            child: _QuoteGlyph(
              fontSize: 64.sp,
              color: AppCustomColor.backgroundWhite.withValues(alpha: 0.12),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(26.w, 30.h, 26.w, 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.78,
                  child: AppText(
                    title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppFont.mulish,
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                      color: AppCustomColor.backgroundWhite,
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                Container(
                  height: 1,
                  color: AppCustomColor.backgroundWhite.withValues(alpha: 0.24),
                ),
                SizedBox(height: 14.h),
                Expanded(
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        padding: EdgeInsets.only(right: 4.w),
                        child: AppText(
                          body,
                          style: TextStyle(
                            fontFamily: AppFont.mulish,
                            fontSize: 14.5.sp,
                            fontWeight: FontWeight.w600,
                            height: 1.62,
                            color: AppCustomColor.backgroundWhite.withValues(alpha: 0.92),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 44.h,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  _kQuoteBackFace.withValues(alpha: 0),
                                  _kQuoteBackFace,
                                ],
                                stops: const [0, 0.88],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The keypoint artwork in its hexagon: a ring in the tint, a well behind it,
/// and the image clipped to the same shape.
///
/// The image is clipped by its OWN [ClipPath] rather than by a clipBehavior on
/// the parent — a decorated box with a non-rectangular shape leaks the image's
/// square corners at these sizes (the same trap the streak flame hit at 30px).
class SavedQuoteArtwork extends StatelessWidget {
  const SavedQuoteArtwork({super.key, required this.imageUrl, required this.size});

  final String imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final wellSize = size * (104 / 112);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipPath(
            clipper: const _HexagonClipper(),
            child: Container(width: size, height: size, color: _kQuoteHexRing),
          ),
          ClipPath(
            clipper: const _HexagonClipper(),
            child: Container(
              width: wellSize,
              height: wellSize,
              color: _kQuoteHexWell,
              child: imageUrl.trim().isEmpty
                  ? null
                  : CacheNetworkGraphic(
                      url: imageUrl,
                      width: wellSize,
                      height: wellSize,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pointy-top hexagon with rounded corners — the design's `clip-path`, whose
/// vertices sit at 0/28/84/112 percent of a 112 box with a 12 corner radius.
class _HexagonClipper extends CustomClipper<ui.Path> {
  const _HexagonClipper();

  /// Corner radius as a fraction of the box, from the design's 12 on 112.
  static const double _radiusFactor = 12 / 112;

  /// Horizontal inset of the vertical sides, from the design's 6 on 112.
  static const double _sideInsetFactor = 6 / 112;

  @override
  ui.Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final inset = w * _sideInsetFactor;
    final radius = w * _radiusFactor;

    final points = <Offset>[
      Offset(w / 2, 0),
      Offset(w - inset, h * 0.25),
      Offset(w - inset, h * 0.75),
      Offset(w / 2, h),
      Offset(inset, h * 0.75),
      Offset(inset, h * 0.25),
    ];

    return _roundedPolygon(points, radius);
  }

  /// Walks the polygon, cutting each corner back by [radius] along both of its
  /// edges and joining the two cut points with a quadratic through the vertex.
  /// The cut is clamped to half the shorter edge so a radius wider than an edge
  /// degenerates to a plain miter instead of folding the path inside out.
  ui.Path _roundedPolygon(List<Offset> points, double radius) {
    final path = ui.Path();
    final count = points.length;

    for (var i = 0; i < count; i++) {
      final current = points[i];
      final previous = points[(i - 1 + count) % count];
      final next = points[(i + 1) % count];

      final toPrevious = previous - current;
      final toNext = next - current;
      final cut = math.min(
        radius,
        math.min(toPrevious.distance, toNext.distance) / 2,
      );

      final start = current + toPrevious / toPrevious.distance * cut;
      final end = current + toNext / toNext.distance * cut;

      if (i == 0) {
        path.moveTo(start.dx, start.dy);
      } else {
        path.lineTo(start.dx, start.dy);
      }
      path.quadraticBezierTo(current.dx, current.dy, end.dx, end.dy);
    }

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<ui.Path> oldClipper) => false;
}

/// The opening quote mark. Its own widget only so the two faces cannot disagree
/// about the glyph or its line height.
class _QuoteGlyph extends StatelessWidget {
  const _QuoteGlyph({required this.fontSize, required this.color});

  final double fontSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppText(
      '“',
      style: TextStyle(
        fontFamily: AppFont.mulish,
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        height: 1,
        color: color,
      ),
    );
  }
}
