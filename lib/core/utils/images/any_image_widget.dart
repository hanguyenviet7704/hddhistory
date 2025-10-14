part of '../utils.dart';

class AnyImageWidget extends StatelessWidget {
  const AnyImageWidget({super.key, required this.url, this.fit, this.borderRadius, this.decoration, this.width, this.height});
  final String url;
  final BoxFit? fit;
  final BorderRadiusGeometry? borderRadius;
  final BoxDecoration? decoration;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return const SizedBox.shrink();
    return url.toLowerCase().contains('.svg')
        ? Container(
            decoration:
                decoration ??
                BoxDecoration(
                  borderRadius: borderRadius,
                ),
            child: SvgPicture.network(
              url,
              placeholderBuilder: (context) => const SizedBox.shrink(),
              width: width,
              height: height,
              fit: fit ?? BoxFit.contain,
            ),
          )
        : DCachedImage(
            url: url,
            fit: fit,
            borderRadius: borderRadius,
            decoration: decoration,
            width: width,
            height: height,
          );
  }
}
