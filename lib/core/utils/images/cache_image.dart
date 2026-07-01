part of '../utils.dart';

class DCachedImage extends StatelessWidget {
  final String url;

  /// Optional lightweight thumbnail (e.g. a 600w WebP). When non-empty, it's
  /// loaded as the primary image for fast first paint; on load error we fall
  /// back to the full-resolution [url].
  final String? thumbnailUrl;
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
    this.thumbnailUrl,
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
        onTap: () => _onTap(context),
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

  bool _isNetwork(String value) =>
      value.startsWith('http://') || value.startsWith('https://');

  /// Builds a [CachedNetworkImage] for [imageUrl] with the shared decode/cache
  /// sizing. [errorFallback] renders in place of the error icon (used to fall
  /// back from a thumbnail to the full-resolution image).
  Widget _buildNetworkImage(
    BuildContext context,
    String imageUrl, {
    Widget Function(BuildContext context)? errorFallback,
  }) {
    // Decode + cache at display resolution (physical px), not the source's
    // full resolution. A 160px thumbnail otherwise decodes a ~1000px+ image
    // into memory and stores it full-size on disk — slow first paint, heavy
    // RAM, and scroll jank. Cap at the screen width when no explicit width is
    // given (full-bleed images), and clamp so we never over-shrink or blow up.
    final media = MediaQuery.maybeOf(context);
    final dpr = media?.devicePixelRatio ?? 2.0;
    final logicalWidth =
        (width != null && width!.isFinite) ? width! : (media?.size.width ?? 430.0);
    final cacheWidth = (logicalWidth * dpr).round().clamp(1, 2000);
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      alignment: alignment,
      width: width,
      height: height,
      // Downscale the in-memory decode and the on-disk copy to the display
      // size. (Network bytes are still full-size — that needs a CDN/server
      // resize; see the audit follow-up.)
      memCacheWidth: cacheWidth,
      maxWidthDiskCache: cacheWidth,
      progressIndicatorBuilder: _buildProgressIndicator,
      color: color,
      errorWidget: (ctx, _, _) => errorFallback != null
          ? errorFallback(ctx)
          : const FaIcon(FontAwesomeIcons.circleExclamation),
    );
  }

  Widget _buildImage(BuildContext context) {
    if (_isNetwork(url)) {
      final thumb = thumbnailUrl;
      // Prefer the lightweight thumbnail for first paint, but fall back to the
      // full-resolution [url] if the thumbnail fails to load.
      if (thumb != null && thumb.isNotEmpty && _isNetwork(thumb)) {
        return _buildNetworkImage(
          context,
          thumb,
          errorFallback: (ctx) => _buildNetworkImage(ctx, url),
        );
      }
      return _buildNetworkImage(context, url);
    }

    if (url.startsWith('/')) {
      return Image.file(
        File(url),
        fit: fit,
        width: width,
        height: height,
        color: color,
        errorBuilder: (_, _, _) => const FaIcon(FontAwesomeIcons.circleExclamation),
      );
    }

    return Image.asset(
      url,
      fit: fit,
      width: width,
      height: height,
      alignment: Alignment.center,
      color: color,
      errorBuilder: (_, _, _) => const FaIcon(FontAwesomeIcons.circleExclamation),
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

    return sk.Skeletonizer.zone(
      effect: sk.ShimmerEffect(
        duration: const Duration(milliseconds: 1500), // Slower, gentler animation
      ),
      child: Container(
        alignment: Alignment.center,
        child: sk.Bone(
          width: width,
          height: height,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
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
