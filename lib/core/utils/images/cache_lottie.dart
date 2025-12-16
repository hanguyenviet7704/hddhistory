part of '../utils.dart';

/// Lottie loader that caches the remote JSON in the image cache manager.
///
/// - First emits a progress placeholder while downloading.
/// - Reuses cached file on subsequent builds (no extra network calls).
/// - Falls back to the provided `errorBuilder` on failure.
class CacheNetworkLottie extends StatefulWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Alignment alignment;
  final bool? animate;
  final bool? repeat;
  final bool? reverse;
  final FrameRate? frameRate;
  final Animation<double>? controller;
  final LottieDelegates? delegates;
  final LottieOptions? options;
  final void Function(LottieComposition)? onLoaded;
  final Widget Function(BuildContext, Object?, StackTrace?)? errorBuilder;
  final Widget? placeholder;
  final CacheManager? cacheManager;
  final FilterQuality? filterQuality;
  final bool? addRepaintBoundary;
  final bool? backgroundLoading;

  const CacheNetworkLottie({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.animate,
    this.repeat,
    this.reverse,
    this.frameRate,
    this.controller,
    this.delegates,
    this.options,
    this.onLoaded,
    this.errorBuilder,
    this.placeholder,
    this.cacheManager,
    this.filterQuality,
    this.addRepaintBoundary,
    this.backgroundLoading,
  });

  @override
  State<CacheNetworkLottie> createState() => _CacheNetworkLottieState();
}

class _CacheNetworkLottieState extends State<CacheNetworkLottie> {
  late Stream<FileResponse> _fileStream;

  CacheManager get _manager =>
      widget.cacheManager ?? AppDI.injector.get<CacheManager>(instanceName: DIKey.imageCacheManager);

  @override
  void initState() {
    super.initState();
    _fileStream = _buildStream(widget.url);
  }

  @override
  void didUpdateWidget(covariant CacheNetworkLottie oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _fileStream = _buildStream(widget.url);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.url.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<FileResponse>(
      stream: _fileStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return widget.errorBuilder?.call(context, snapshot.error!, snapshot.stackTrace) ?? _defaultError();
        }

        final data = snapshot.data;
        if (data is FileInfo) {
          return _buildLottie(data.file);
        }

        return widget.placeholder ?? _defaultPlaceholder(data is DownloadProgress ? data.progress : null);
      },
    );
  }

  Stream<FileResponse> _buildStream(String url) {
    return _manager.getFileStream(
      url,
      withProgress: true,
    );
  }

  Widget _buildLottie(File file) {
    return Lottie.file(
      file,
      controller: widget.controller,
      frameRate: widget.frameRate,
      animate: widget.animate,
      repeat: widget.repeat,
      reverse: widget.reverse,
      delegates: widget.delegates,
      options: widget.options,
      onLoaded: widget.onLoaded,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      alignment: widget.alignment,
      addRepaintBoundary: widget.addRepaintBoundary,
      filterQuality: widget.filterQuality,
      backgroundLoading: widget.backgroundLoading,
    );
  }

  Widget _defaultPlaceholder(double? progress) {
    final width = widget.width ?? 120.w;
    final height = widget.height ?? 120.w;

    return sk.Skeletonizer.zone(
      effect: sk.ShimmerEffect(
        duration: const Duration(milliseconds: 1400),
      ),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          alignment: Alignment.center,
          children: [
            sk.Bone(
              width: width,
              height: height,
              borderRadius: BorderRadius.circular(12),
            ),
            if (progress != null)
              AppText(
                '${(progress * 100).clamp(0, 100).toStringAsFixed(0)}%',
                style: AppStyle.textBold14,
              ),
          ],
        ),
      ),
    );
  }

  Widget _defaultError() {
    return Container(
      width: widget.width,
      height: widget.height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppCustomColor.textTertiary.op(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        FontAwesomeIcons.circleExclamation,
        color: AppCustomColor.textSecondary,
      ),
    );
  }
}
