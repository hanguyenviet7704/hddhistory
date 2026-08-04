part of '../utils.dart';

class DCachedImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BorderRadiusGeometry? borderRadius;
  final BoxDecoration? decoration;
  final Alignment alignment;
  final BoxFit? fit;
  final bool enablePhotoView;
  final EdgeInsets margin;
  final EdgeInsets padding;
  final Color? color;
  final void Function()? onTap;
  final void Function()? onDoubleTap;

  const DCachedImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.borderRadius,
    this.alignment = Alignment.center,
    this.fit = BoxFit.cover,
    this.decoration,
    this.enablePhotoView = false,
    this.margin = EdgeInsets.zero,
    this.padding = EdgeInsets.zero,
    this.color,
    this.onTap,
    this.onDoubleTap,
  });

  void _showImageViewer(BuildContext context) {
    context.pushNamed(RouteNamed.imageView, extra: url);
  }

  void _onTap(BuildContext context) {
    if (enablePhotoView) {
      _showImageViewer(context);
      return;
    }
    onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = _buildImage(context);

    child = ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: child,
    );

    if (margin != EdgeInsets.zero || padding != EdgeInsets.zero || decoration != null) {
      child = Container(
        margin: margin,
        padding: padding,
        decoration: decoration,
        child: child,
      );
    }

    if (onTap != null || enablePhotoView) {
      child = InkWell(
        onTap: () {
          AppHaptic.select();
          _onTap(context);
        },
        child: child,
      );
    }

    if (onDoubleTap != null) {
      child = InkWell(
        onDoubleTap: onDoubleTap,
        child: child,
      );
    }

    return child;
  }

  Widget _buildImage(BuildContext context) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      // Decode at DISPLAY size, not source size. Course art is 1024×1024, so
      // full-resolution decoding costs 4MB of RGBA per image — Home alone
      // shows ~8 of them in tiles 96–170px wide, i.e. tens of MB of bitmaps
      // and the frame drops that come with it (measured 2026-08-04).
      //
      // The size is read from [width]/[height] when the caller gave a usable
      // one, and only otherwise from the parent's constraints — a LayoutBuilder
      // changes how intrinsic sizing propagates, so it is not put in the tree
      // unless it is the only way to learn the size.
      final double? declaredSide = _largestFiniteSide(width, height);
      if (declaredSide != null) {
        return _networkImage(_memCacheWidthFor(context, declaredSide));
      }
      return LayoutBuilder(
        builder: (context, constraints) {
          final double? constrainedSide = _largestFiniteSide(
            constraints.hasBoundedWidth ? constraints.maxWidth : null,
            constraints.hasBoundedHeight ? constraints.maxHeight : null,
          );
          return _networkImage(
            constrainedSide == null ? null : _memCacheWidthFor(context, constrainedSide),
          );
        },
      );
    }

    if (url.startsWith('/')) {
      return Image.file(
        File(url),
        fit: fit,
        width: width,
        height: height,
        color: color,
        errorBuilder: (_, _, _) => _buildErrorPlaceholder(),
      );
    }

    return Image.asset(
      url,
      fit: fit,
      width: width,
      height: height,
      alignment: Alignment.center,
      color: color,
      errorBuilder: (_, _, _) => _buildErrorPlaceholder(),
    );
  }

  Widget _networkImage(int? memCacheWidth) => CachedNetworkImage(
    imageUrl: url,
    fit: fit,
    alignment: alignment,
    width: width,
    height: height,
    memCacheWidth: memCacheWidth,
    progressIndicatorBuilder: _buildProgressIndicator,
    color: color,
    // placeholder: (context, url) => _buildPlaceHolder(context, url),
    // colorBlendMode: colorBlendMode,
    errorWidget: (_, _, _) => _buildErrorPlaceholder(),
  );

  /// Largest usable side out of [a]/[b], or null when neither is usable.
  ///
  /// Callers routinely pass `width: double.infinity` ("fill the parent") and a
  /// parent can offer an unbounded axis, so a side is only usable when it is
  /// finite and positive. Missing this is what made `infinity.round()` throw
  /// `Unsupported operation: Infinity or NaN toInt` mid-layout, which blanked
  /// every card holding an image and left the page unable to lay out or be
  /// swiped (found on the 1.4.4+106 build, 2026-08-05).
  static double? _largestFiniteSide(double? a, double? b) {
    final bool aOk = a != null && a.isFinite && a > 0;
    final bool bOk = b != null && b.isFinite && b > 0;
    if (!aOk && !bOk) return null;
    if (aOk && bOk) return max(a, b);
    return aOk ? a : b;
  }

  /// Physical-pixel width to decode a network image at, or null to keep the
  /// source resolution.
  ///
  /// Only the width is capped: [ResizeImage] given BOTH axes resizes to those
  /// exact dimensions and would squash the bitmap, so the height follows the
  /// source aspect ratio. The cap comes from the LARGER display axis because
  /// `BoxFit.cover` on a portrait box needs the source scaled by the taller
  /// side; using the width alone there would visibly soften it. Never upscales
  /// — [ResizeImage] leaves an already-smaller image alone.
  ///
  /// Returns null when this image can be opened in the full-screen viewer
  /// (source resolution is the point there) or when the maths can't produce a
  /// sane pixel count.
  int? _memCacheWidthFor(BuildContext context, double displaySide) {
    if (enablePhotoView) return null;

    final double dpr = MediaQuery.devicePixelRatioOf(context);
    if (!dpr.isFinite || dpr <= 0) return null;

    final double pixels = displaySide * dpr;
    if (!pixels.isFinite || pixels < 1) return null;

    // 4096 is comfortably above any full-screen image on a phone and keeps a
    // stray huge constraint from asking for an absurd decode.
    return pixels.round().clamp(1, 4096);
  }

  /// Icon-less fallback for a failed (or briefly mid-load) image — a plain tonal
  /// box (the ClipRRect ancestor rounds it), NOT the alarming exclamation icon
  /// users disliked seeing flash on cards while thumbnails were still loading.
  Widget _buildErrorPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: AppCustomColor.backgroundGray,
    );
  }

  /// Builds a progress indicator for image loading.
  ///
  /// When download progress is available, shows percentage text.
  /// When no progress is available, displays a skeleton loader using Skeletonizer
  /// that matches the expected image dimensions and border radius.
  Widget _buildProgressIndicator(BuildContext context, String url, DownloadProgress download) {
    // if (download.progress != null) {
    //   return Center(
    //     child: AppText(
    //       '${(download.progress! * 100).toStringAsFixed(0)}%',
    //       style: AppStyle.textBold16,
    //     ),
    //   );
    // }

    // Many callers size the image through their PARENT rather than these fields
    // (`Positioned.fill`, `StackFit.expand`, a fixed-height SizedBox…) and pass
    // no width/height. [sk.Bone] renders a `SizedBox(width: …, height: …)`, so
    // with both null it received loose constraints and collapsed to 0×0 — the
    // shimmer was built but invisible, leaving a blank box until the thumbnail
    // landed (seen on the Explore course cards and the "Background" theme
    // tiles). Fall back to the space the parent actually offers, and only when
    // that axis is bounded so an unbounded parent can never throw.
    return sk.Skeletonizer.zone(
      effect: sk.ShimmerEffect(
        duration: const Duration(milliseconds: 1500), // Slower, gentler animation
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double? boneWidth = width ?? (constraints.hasBoundedWidth ? constraints.maxWidth : null);
          final double? boneHeight = height ?? (constraints.hasBoundedHeight ? constraints.maxHeight : null);
          return Container(
            alignment: Alignment.center,
            child: sk.Bone(
              width: boneWidth,
              height: boneHeight,
              borderRadius: borderRadius ?? BorderRadius.circular(8),
            ),
          );
        },
      ),
    );
  }

  // Widget _buildPlaceHolder(BuildContext context, String url) {
  //   return sk.Skeletonizer.zone(
  //     effect: sk.ShimmerEffect(
  //       duration: const Duration(milliseconds: 1500),
  //     ),
  //     child: Container(
  //       alignment: Alignment.center,
  //       child: sk.Bone(
  //         width: width ?? 200,
  //         height: height ?? 200,
  //         borderRadius: borderRadius ?? BorderRadius.circular(8),
  //       ),
  //     ),
  //   );
  // }
}
