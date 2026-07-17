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
      return CachedNetworkImage(
        imageUrl: url,
        fit: fit,
        alignment: alignment,
        width: width,
        height: height,
        progressIndicatorBuilder: _buildProgressIndicator,
        color: color,
        // placeholder: (context, url) => _buildPlaceHolder(context, url),
        // colorBlendMode: colorBlendMode,
        errorWidget: (_, _, _) => _buildErrorPlaceholder(),
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
