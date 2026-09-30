part of '../../library.dart';

/// The 9:16 card a shared course becomes (design `12 · Share course` →
/// `_Course Share.dc.html`).
///
/// Public because it is the thing captured: [CourseShareSheet] wraps it in a
/// RepaintBoundary and the PNG that reaches Instagram is literally this widget.
/// Nothing here may depend on scroll offset or animation — whatever is on screen
/// at capture time is what ships.
///
/// Every number below is transcribed from that component's markup at the 390pt
/// frame it was drawn in. The theme picks the LAYOUT as well as the colours
/// (`Lavender` → classic, `Sky` → cover), which is why this dispatches instead
/// of just recolouring.
class CourseStoryCard extends StatelessWidget {
  const CourseStoryCard({
    super.key,
    required this.palette,
    required this.title,
    required this.description,
    required this.coverUrl,
  });

  final CourseSharePalette palette;
  final String title;
  final String description;
  final String coverUrl;

  /// Fixed in the design's markup, not a localized string.
  static const String kFooter = 'MeUp · Daily Growth Trainer';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230.w,
      child: AspectRatio(
        aspectRatio: 9 / 16,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0x383C3114), // rgba(20,20,60,.22)
                offset: Offset(0, 16.h),
                blurRadius: 40.r,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24.r),
            child: palette.layout == CourseStoryLayout.classic
                ? _ClassicBody(
                    palette: palette,
                    title: title,
                    description: description,
                    coverUrl: coverUrl,
                  )
                : _CoverBody(
                    palette: palette,
                    title: title,
                    description: description,
                    coverUrl: coverUrl,
                  ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Classic — the Lavender theme
// ───────────────────────────────────────────────────────────────────────────

class _ClassicBody extends StatelessWidget {
  const _ClassicBody({
    required this.palette,
    required this.title,
    required this.description,
    required this.coverUrl,
  });

  final CourseSharePalette palette;
  final String title;
  final String description;
  final String coverUrl;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(decoration: BoxDecoration(gradient: palette.background)),
        if (palette.overlay != null)
          DecoratedBox(decoration: BoxDecoration(gradient: palette.overlay)),
        Padding(
          padding: EdgeInsets.fromLTRB(20.w, 34.h, 20.w, 42.h),
          child: Column(
            children: [
              // The big headline, in the accent colour — the card's own voice,
              // separate from the title repeated inside the white panel below.
              AppText(
                title,
                maxLines: 3,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppFont.mulish,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  height: 1.08,
                  letterSpacing: -0.4,
                  color: palette.buttonBackground,
                ),
              ),
              // The cover absorbs the slack. In the design this column is a CSS
              // flex box, so an over-tall stack simply shrinks; a Flutter Column
              // overflows instead (it did, by 75px). Letting the cover take the
              // leftover — capped at the design's 80% width — reproduces the
              // shrink without pinning a height the card may not have.
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) {
                    final side = math.min(box.maxWidth * 0.8, box.maxHeight);
                    return Center(
                      child: SizedBox(
                        width: side,
                        height: side,
                        child: _CoverBlob(coverUrl: coverUrl, palette: palette),
                      ),
                    );
                  },
                ),
              ),
              22.verticalSpace,
              _PanelWithBrandDisc(
                palette: palette,
                title: title,
                description: description,
              ),
            ],
          ),
        ),
        // Scallop strips last so they sit over the artwork, as in the design.
        Align(
          alignment: Alignment.topCenter,
          child: _ScallopStrip(color: palette.buttonBackground, pointsUp: true),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: _ScallopStrip(color: palette.buttonBackground, pointsUp: false),
        ),
      ],
    );
  }
}

/// One 10px band of half-discs along an edge — the card's scalloped border.
///
/// The design draws it as a repeating `radial-gradient(circle 8px at 8px 10px,
/// accent 7.5px, transparent 8.2px)` on a 16×10 tile, centred on the band's far
/// edge so only the outer half shows.
///
/// The radius is **8**, matching the gradient's circle, NOT the 7.5 solid stop:
/// diameter 16 equals the tile pitch, so neighbouring bumps meet and the edge
/// reads as one continuous scallop. Taking 7.5 leaves a 1pt gap at each joint
/// and it degenerates into a row of loose dots.
///
/// Painted rather than faked with a border because the colour is the theme's
/// ACCENT, not the card's fill.
class _ScallopStrip extends StatelessWidget {
  const _ScallopStrip({required this.color, required this.pointsUp});

  final Color color;

  /// Top strip bulges up, bottom strip bulges down.
  final bool pointsUp;

  @override
  Widget build(BuildContext context) {
    // ClipRect is load-bearing: CustomPaint does NOT clip to its own size, so
    // without it the discs draw whole and the edge renders as a row of full
    // circles floating inside the card. The design's strip is a 10px-tall
    // background, i.e. clipped — only the outer half of each disc shows.
    return ClipRect(
      child: SizedBox(
        height: 10.h,
        width: double.infinity,
        child: CustomPaint(painter: _ScallopPainter(color: color, pointsUp: pointsUp)),
      ),
    );
  }
}

class _ScallopPainter extends CustomPainter {
  const _ScallopPainter({required this.color, required this.pointsUp});

  final Color color;
  final bool pointsUp;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    // Scaled like every other dimension on the card, so the bump count tracks
    // the card's width instead of drifting on a wider device.
    final radius = 8.r;
    final pitch = radius * 2;
    // Centres sit on the band's outer edge: y = height for the top strip (so
    // the visible half points up), y = 0 for the bottom one.
    final cy = pointsUp ? size.height : 0.0;
    for (var x = radius; x < size.width + pitch; x += pitch) {
      canvas.drawCircle(Offset(x, cy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ScallopPainter old) => old.color != color || old.pointsUp != pointsUp;
}

/// The cover, in the design's asymmetric blob mask, flanked by two flowers.
class _CoverBlob extends StatelessWidget {
  const _CoverBlob({required this.coverUrl, required this.palette});

  final String coverUrl;
  final CourseSharePalette palette;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          // CSS `62% 38% 55% 45% / 58% 52% 48% 42%` — the slash form gives each
          // corner a horizontal and a vertical radius, which is exactly what
          // Radius.elliptical takes.
          final blob = BorderRadius.only(
            topLeft: Radius.elliptical(w * 0.62, h * 0.58),
            topRight: Radius.elliptical(w * 0.38, h * 0.52),
            bottomRight: Radius.elliptical(w * 0.55, h * 0.48),
            bottomLeft: Radius.elliptical(w * 0.45, h * 0.42),
          );

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: w,
                height: h,
                decoration: BoxDecoration(
                  color: palette.chip,
                  borderRadius: blob,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x38000000), // rgba(0,0,0,.22)
                      offset: Offset(0, 14.h),
                      blurRadius: 30.r,
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: coverUrl.isEmpty
                    ? const SizedBox.shrink()
                    : DCachedImage(url: coverUrl, width: w, height: h, fit: BoxFit.cover),
              ),
              // Design gives these 44 and 56 against a 184-wide cover — ratios,
              // not fixed sizes. Kept proportional because the cover shrinks to
              // fit the card, and absolute flowers swallowed the artwork.
              Positioned(
                left: -w * 0.11,
                top: h * 0.30,
                child: SvgPicture.asset(
                  AppAsset.svg.app.storyFlowerMark,
                  width: w * 0.24,
                  height: w * 0.24,
                ),
              ),
              Positioned(
                right: -w * 0.12,
                bottom: h * 0.10,
                child: SvgPicture.asset(
                  AppAsset.svg.app.storyFlowerMark,
                  width: w * 0.30,
                  height: w * 0.30,
                ),
              ),
            ],
          );
        },
    );
  }
}

/// White panel with the 40px brand disc straddling its top edge.
class _PanelWithBrandDisc extends StatelessWidget {
  const _PanelWithBrandDisc({
    required this.palette,
    required this.title,
    required this.description,
  });

  final CourseSharePalette palette;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          width: double.infinity,
          // 26 top clears the disc that overlaps this edge.
          padding: EdgeInsets.fromLTRB(16.w, 26.h, 16.w, 16.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0x1F000000), // rgba(0,0,0,.12)
                offset: Offset(0, 10.h),
                blurRadius: 26.r,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                title,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppFont.mulish,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  color: const Color(0xFF403823),
                ),
              ),
              if (description.isNotEmpty) ...[
                7.verticalSpace,
                AppText(
                  description,
                  maxLines: 3,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppFont.mulish,
                    fontSize: 8.5.sp,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
              14.verticalSpace,
              AppText(
                CourseStoryCard.kFooter,
                maxLines: 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppFont.mulish,
                  fontSize: 7.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 7 * 0.02,
                  color: const Color(0xFF9AA0AC),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: -18.h,
          child: Container(
            width: 40.r,
            height: 40.r,
            decoration: BoxDecoration(
              color: palette.buttonBackground,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x2E000000), // rgba(0,0,0,.18)
                  offset: Offset(0, 4.h),
                  blurRadius: 10.r,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                AppAsset.images.common.mainIcon.path,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Cover — the Sky theme
// ───────────────────────────────────────────────────────────────────────────

/// No scallops and no white panel: a flat accent field with the copy set left,
/// scattered decor, and the cover as a disc in the bottom-right.
class _CoverBody extends StatelessWidget {
  const _CoverBody({
    required this.palette,
    required this.title,
    required this.description,
    required this.coverUrl,
  });

  final CourseSharePalette palette;
  final String title;
  final String description;
  final String coverUrl;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(decoration: BoxDecoration(gradient: palette.background)),
        Positioned(
          top: 30.h,
          left: -140.w,
          child: Transform.rotate(
            angle: 9 * math.pi / 180,
            child: SvgPicture.asset(AppAsset.svg.app.storyFlowerWhite, width: 400.w, height: 400.w),
          ),
        ),
        Positioned(
          top: 26.h,
          right: 14.w,
          child: SvgPicture.asset(AppAsset.svg.app.decorStar, width: 30.r, height: 30.r),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20.w, 30.h, 20.w, 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              52.verticalSpace,
              AppText(
                title,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppFont.mulish,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                  letterSpacing: -0.5,
                  color: const Color(0xFF111111),
                ),
              ),
              if (description.isNotEmpty) ...[
                12.verticalSpace,
                AppText(
                  description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppFont.mulish,
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                    color: palette.foregroundSoft,
                  ),
                ),
              ],
            ],
          ),
        ),
        Positioned(
          top: 208.h,
          left: -10.w,
          child: SvgPicture.asset(AppAsset.svg.app.decorSquiggle, width: 62.w),
        ),
        Positioned(
          bottom: 126.h,
          right: 66.w,
          child: Transform.rotate(
            angle: -10 * math.pi / 180,
            child: SvgPicture.asset(AppAsset.svg.app.decorWorm, width: 74.w),
          ),
        ),
        Positioned(
          bottom: 40.h,
          right: 6.w,
          child: Container(
            width: 112.r,
            height: 112.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0x47000000), // rgba(0,0,0,.28)
                  offset: Offset(0, 8.h),
                  blurRadius: 22.r,
                ),
              ],
            ),
            child: ClipOval(
              child: coverUrl.isEmpty
                  ? const SizedBox.shrink()
                  : DCachedImage(url: coverUrl, width: 112.r, height: 112.r, fit: BoxFit.cover),
            ),
          ),
        ),
        Positioned(
          bottom: 64.h,
          left: 26.w,
          child: SvgPicture.asset(AppAsset.svg.app.decorStar, width: 18.r, height: 18.r),
        ),
        // Brand lockup as a pill instead of the classic layout's disc.
        Positioned(
          bottom: 12.h,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: EdgeInsets.fromLTRB(4.w, 3.h, 9.w, 3.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(99.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x29000000), // rgba(0,0,0,.16)
                    offset: Offset(0, 4.h),
                    blurRadius: 12.r,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipOval(
                    child: Image.asset(
                      AppAsset.images.common.mainIcon.path,
                      width: 14.r,
                      height: 14.r,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => SizedBox(width: 14.r, height: 14.r),
                    ),
                  ),
                  5.horizontalSpace,
                  AppText(
                    CourseStoryCard.kFooter,
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: AppFont.mulish,
                      fontSize: 7.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 7 * 0.01,
                      color: const Color(0xFF403823),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
