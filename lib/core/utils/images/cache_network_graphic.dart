part of '../utils.dart';

class CacheNetworkGraphic extends StatelessWidget {
  const CacheNetworkGraphic({
    super.key,
    required this.url,
    this.thumbnailUrl,
    this.fit,
    this.borderRadius,
    this.decoration,
    this.width,
    this.height,
    this.color,
    this.alignment,
  });

  final String url;

  /// Optional lightweight thumbnail (e.g. a 600w WebP). When non-empty, it's
  /// loaded first for fast first paint, falling back to [url] on load error.
  /// Only applies to the raster (non-SVG/Lottie) path.
  final String? thumbnailUrl;
  final BoxFit? fit;
  final BorderRadiusGeometry? borderRadius;
  final BoxDecoration? decoration;
  final double? width;
  final double? height;
  final Color? color;
  final Alignment? alignment;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return const SizedBox.shrink();

    if (_isSvg(url)) return _buildSvg();
    if (_isLottie(url)) return _buildLottie();

    // Fallback to regular cached image (handles network/file/asset)
    return DCachedImage(
      url: url,
      thumbnailUrl: thumbnailUrl,
      fit: fit,
      borderRadius: borderRadius,
      decoration: decoration,
      width: width,
      height: height,
      color: color,
      alignment: alignment ?? Alignment.center,
    );
  }

  bool _isSvg(String value) => value.toLowerCase().endsWith('.svg');

  bool _isLottie(String value) {
    final lower = value.toLowerCase();
    return lower.endsWith('.json') || lower.endsWith('.lottie');
  }

  Widget _buildSvg() {
    final bool isNetwork = url.startsWith('http');
    Widget child = isNetwork
        ? SvgPicture.network(
            url,
            placeholderBuilder: (_) => const SizedBox.shrink(),
            width: width,
            height: height,
            fit: fit ?? BoxFit.contain,
          )
        : SvgPicture.asset(
            url,
            width: width,
            height: height,
            fit: fit ?? BoxFit.contain,
          );

    child = ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: child,
    );

    if (decoration != null) {
      child = Container(
        width: width,
        height: height,
        decoration: decoration,
        child: child,
      );
    }

    return child;
  }

  Widget _buildLottie() {
    final bool isNetwork = url.startsWith('http');

    Widget child = isNetwork
        ? CacheNetworkLottie(
            url: url,
            width: width,
            height: height,
            fit: fit,
          )
        : Lottie.asset(
            url,
            width: width,
            height: height,
            fit: fit ?? BoxFit.contain,
          );

    child = ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: child,
    );

    if (decoration != null) {
      child = Container(
        width: width,
        height: height,
        decoration: decoration,
        child: child,
      );
    }

    return child;
  }
}
