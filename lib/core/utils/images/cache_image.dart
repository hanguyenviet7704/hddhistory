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
    Widget child = _buildImage();

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

  Widget _buildImage() {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      // Decode at DISPLAY size, not source size. Course art is 1024×1024, so
      // full-resolution decoding costs 4MB of RGBA per image — Home alone
      // shows ~8 of them in tiles 96–170px wide, i.e. tens of MB of bitmaps
      // and the frame drops that come with it (measured 2026-08-04).
      return LayoutBuilder(
        builder: (context, constraints) {
          return CachedNetworkImage(
            imageUrl: url,
            fit: fit,
            alignment: alignment,
            width: width,
            height: height,
            memCacheWidth: _memCacheWidth(context, constraints),
            progressIndicatorBuilder: _buildProgressIndicator,
            color: color,
            // placeholder: (context, url) => _buildPlaceHolder(context, url),
            // colorBlendMode: colorBlendMode,
            errorWidget: (_, _, _) => _buildErrorPlaceholder(),
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

  /// Physical-pixel width to decode a network image at, or null to keep the
  /// source resolution.
  ///
  /// Only the width is capped: [ResizeImage] given BOTH axes resizes to those
  /// exact dimensions and would squash the bitmap, so the height follows the
  /// source aspect ratio. The cap is the LARGER display axis (× device pixel
  /// ratio) because `BoxFit.cover` on a portrait box needs the source scaled
  /// by the taller side; using the width alone there would visibly soften it.
  /// Never upscales — [ResizeImage] leaves an already-smaller image alone.
  ///
  /// Returns null when the size can't be known (both fields null and the
  /// parent offers unbounded space) or when this image can be opened in the
  /// full-screen viewer, where the source resolution is the point.
  int? _memCacheWidth(BuildContext context, BoxConstraints constraints) {
    if (enablePhotoView) return null;

    final double? displayWidth = width ?? (constraints.hasBoundedWidth ? constraints.maxWidth : null);
    final double? displayHeight = height ?? (constraints.hasBoundedHeight ? constraints.maxHeight : null);

    final double longestSide = max(displayWidth ?? 0, displayHeight ?? 0);
    if (longestSide <= 0) return null;

    final double dpr = MediaQuery.devicePixelRatioOf(context);
    return (longestSide * dpr).round();
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
