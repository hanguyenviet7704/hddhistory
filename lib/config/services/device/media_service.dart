part of '../services.dart';

abstract interface class IMediaService {
  Future<void> saveImageToGallery(Uint8List imageBytes);
  Future<Uint8List?> captureWidget(ScreenshotController controller, {Duration delay = const Duration(milliseconds: 10), double? pixelRatio});
  Future<Uint8List?> captureWidgetWithScreenshot(ScreenshotController controller, {Duration delay = const Duration(milliseconds: 100), double? pixelRatio});
  /// [targetWidth] là chiều rộng PIXEL tối thiểu mà ảnh phải đạt, dùng khi kích
  /// thước ảnh do bên NHẬN quy định chứ không do màn hình (canvas story của
  /// Instagram/Facebook là 1080×1920). Bỏ trống thì giữ nguyên hành vi cũ.
  Future<Uint8List?> captureWidgetWithRepaintBoundary(GlobalKey globalKey, {double? pixelRatio, double? targetWidth});
  Future<void> captureAndSaveWidget(ScreenshotController controller, {Duration delay = const Duration(milliseconds: 10), double? pixelRatio});
  Future<void> shareWidget(ScreenshotController controller, {Duration delay = const Duration(milliseconds: 10), double? pixelRatio, String fileName = 'share_image.png'});
  Future<void> shareImageFile(File imageFile, {String? shareText, Rect? sharePositionOrigin});
  Future<void> shareImageBytes(Uint8List imageBytes, {String? shareText, String fileName = 'shared_image.png', Rect? sharePositionOrigin});
  Future<void> captureAndShareWithScreenshot(
    ScreenshotController controller, {
    String? shareText,
    String fileName = 'shared_widget.png',
    Duration delay = const Duration(milliseconds: 100),
    double? pixelRatio,
    Rect? sharePositionOrigin,
  });
  Future<void> captureAndShareWithRepaintBoundary(GlobalKey globalKey, {String? shareText, String fileName = 'shared_widget.png', double? pixelRatio, Rect? sharePositionOrigin});
  Rect? getSharePositionOrigin(BuildContext context);
  Future<void> saveVideoToGallery(String videoPath);
  Future<void> shareVideo({required String videoPath, String fileName = 'share_video.mp4'});
  Future<void> saveVideoFromNetwork(String url, {void Function(int received, int total)? onProgress, void Function(String message)? onError, void Function()? onSuccess});
}

@LazySingleton(as: IMediaService)
class MediaService implements IMediaService {
  /// Save image bytes to device gallery
  @override
  Future<void> saveImageToGallery(Uint8List imageBytes) async {
    try {
      // Save to temporary file first
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/temp_image.png');
      await file.writeAsBytes(imageBytes);

      // Check and request permissions if needed
      if (!await Gal.hasAccess()) {
        await Gal.requestAccess();
      }

      // Save to gallery using gal
      await Gal.putImage(file.path);
    } catch (e) {
      rethrow;
    }
  }

  /// Capture widget using ScreenshotController
  @override
  Future<Uint8List?> captureWidget(
    ScreenshotController controller, {
    Duration delay = const Duration(milliseconds: 10),
    double? pixelRatio,
  }) async {
    try {
      return await controller.capture(
        delay: delay,
        pixelRatio: pixelRatio,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Enhanced capture widget using the screenshot package with better defaults
  @override
  Future<Uint8List?> captureWidgetWithScreenshot(
    ScreenshotController controller, {
    Duration delay = const Duration(milliseconds: 100),
    double? pixelRatio,
  }) async {
    try {
      return await controller.capture(
        delay: delay,
        pixelRatio: pixelRatio ?? WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Capture a widget using Flutter's built-in RepaintBoundary
  ///
  /// [targetWidth] tồn tại vì device pixel ratio là con số ĐÚNG cho ảnh chụp
  /// màn hình và SAI cho một canvas mà bên nhận quy định kích thước. Thẻ story
  /// chỉ rộng ~230pt trên máy, nên ×3 ra ~690px trong khi Instagram cần 1080px
  /// — composer phóng lên và ảnh mờ. Truyền targetWidth thì tỉ lệ được suy ra
  /// từ chiều rộng thật của boundary, không phải từ mật độ điểm ảnh màn hình.
  @override
  Future<Uint8List?> captureWidgetWithRepaintBoundary(
    GlobalKey globalKey, {
    double? pixelRatio,
    double? targetWidth,
  }) async {
    try {
      final RenderRepaintBoundary boundary = globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      final double basePixelRatio =
          pixelRatio ?? WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
      // Lấy giá trị LỚN HƠN, không phải gán thẳng: nếu boundary đã rộng hơn mức
      // cần thì tỉ lệ suy ra sẽ nhỏ hơn base, và hạ nó xuống là tự làm ảnh tệ
      // hơn hôm nay.
      final double scaledPixelRatio =
          (targetWidth != null && boundary.size.width > 0) ? targetWidth / boundary.size.width : 0;
      final double effectivePixelRatio =
          scaledPixelRatio > basePixelRatio ? scaledPixelRatio : basePixelRatio;

      final ui.Image image = await boundary.toImage(pixelRatio: effectivePixelRatio);

      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      rethrow;
    }
  }

  /// Capture widget and save to gallery
  @override
  Future<void> captureAndSaveWidget(
    ScreenshotController controller, {
    Duration delay = const Duration(milliseconds: 10),
    double? pixelRatio,
  }) async {
    try {
      final imageBytes = await captureWidget(
        controller,
        delay: delay,
        pixelRatio: pixelRatio,
      );

      if (imageBytes == null) {
        throw Exception('Failed to capture widget');
      }

      await saveImageToGallery(imageBytes);
    } catch (e) {
      rethrow;
    }
  }

  /// Capture widget and share it
  @override
  Future<void> shareWidget(
    ScreenshotController controller, {
    Duration delay = const Duration(milliseconds: 10),
    double? pixelRatio,
    String fileName = 'share_image.png',
  }) async {
    try {
      final imageBytes = await captureWidget(
        controller,
        delay: delay,
        pixelRatio: pixelRatio,
      );

      if (imageBytes == null) {
        throw Exception('Failed to capture widget');
      }

      // Create temporary file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(imageBytes);

      await shareImageFile(
        file,
        shareText: 'Share QR Code',
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> shareImageFile(
    File imageFile, {
    String? shareText,
    Rect? sharePositionOrigin,
  }) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: shareText ?? 'Check out this amazing artwork!',
          files: [XFile(imageFile.path)],
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Share captured image bytes directly
  @override
  Future<void> shareImageBytes(
    Uint8List imageBytes, {
    String? shareText,
    String fileName = 'shared_image.png',
    Rect? sharePositionOrigin,
  }) async {
    try {
      // Create temporary file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(imageBytes);

      await shareImageFile(
        file,
        shareText: shareText,
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Capture and share widget using screenshot package
  @override
  Future<void> captureAndShareWithScreenshot(
    ScreenshotController controller, {
    String? shareText,
    String fileName = 'shared_widget.png',
    Duration delay = const Duration(milliseconds: 100),
    double? pixelRatio,
    Rect? sharePositionOrigin,
  }) async {
    try {
      final imageBytes = await captureWidgetWithScreenshot(
        controller,
        delay: delay,
        pixelRatio: pixelRatio,
      );

      if (imageBytes != null) {
        await shareImageBytes(
          imageBytes,
          shareText: shareText,
          fileName: fileName,
          sharePositionOrigin: sharePositionOrigin,
        );
      } else {
        throw Exception('Failed to capture widget');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Capture and share widget using RepaintBoundary
  @override
  Future<void> captureAndShareWithRepaintBoundary(
    GlobalKey globalKey, {
    String? shareText,
    String fileName = 'shared_widget.png',
    double? pixelRatio,
    Rect? sharePositionOrigin,
  }) async {
    try {
      // Add a small delay to ensure the widget is fully rendered
      await Future.delayed(const Duration(milliseconds: 100));

      final imageBytes = await captureWidgetWithRepaintBoundary(
        globalKey,
        pixelRatio: pixelRatio,
      );

      if (imageBytes != null) {
        await shareImageBytes(
          imageBytes,
          shareText: shareText,
          fileName: fileName,
          sharePositionOrigin: sharePositionOrigin,
        );
      } else {
        throw Exception('Failed to capture widget');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get share position origin for iOS compatibility
  @override
  Rect? getSharePositionOrigin(BuildContext context) {
    try {
      final RenderBox? box = context.findRenderObject() as RenderBox?;
      if (box != null) {
        return box.localToGlobal(Offset.zero) & box.size;
      }
      return null;
    } catch (e) {
      // Fallback position for iOS
      return const Rect.fromLTWH(0, 0, 1, 1);
    }
  }

  /// Save video file to device gallery
  @override
  Future<void> saveVideoToGallery(String videoPath) async {
    try {
      // Check and request permissions if needed
      if (!await Gal.hasAccess()) {
        await Gal.requestAccess();
      }

      // Save to gallery using gal
      await Gal.putVideo(videoPath);
    } catch (e) {
      rethrow;
    }
  }

  /// Share video file
  @override
  Future<void> shareVideo({
    required String videoPath,
    String fileName = 'share_video.mp4',
  }) async {
    try {
      // Share the file directly since we already have the path
      await SharePlus.instance.share(
        ShareParams(
          text: 'Share Video',
          files: [XFile(videoPath)],
        ),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Download video from network URL and save to gallery
  @override
  Future<void> saveVideoFromNetwork(
    String url, {
    void Function(int received, int total)? onProgress,
    void Function(String message)? onError,
    void Function()? onSuccess,
  }) async {
    try {
      final tempPath = await _downloadFile(url, 'downloaded_video.mp4', onProgress: onProgress);
      final file = File(tempPath);

      // Save to gallery
      await saveVideoToGallery(file.path);

      // Clean up temporary file
      if (await file.exists()) {
        await file.delete();
      }

      onSuccess?.call();
    } catch (e) {
      onError?.call(e.toString());
      rethrow;
    }
  }

  static Future<String> _downloadFile(
    String url,
    String fileName, {
    void Function(int received, int total)? onProgress,
  }) async {
    try {
      final dio = Dio();
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/$fileName';

      await dio.download(
        url,
        tempPath,
        onReceiveProgress: onProgress,
      );

      return tempPath;
    } catch (e) {
      rethrow;
    }
  }
}
