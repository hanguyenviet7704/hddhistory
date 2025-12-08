part of '../services.dart';

/// Cache service that provides comprehensive caching capabilities
/// for images, videos, files and other content using flutter_cache_manager

abstract interface class ICacheService {
  Future<void> initialize();
  Future<void> preloadEssentialAssets();
  Future<void> preloadImages(List<String> imageUrls);
  Future<void> preloadVideos(List<String> videoUrls);
  Future<void> preloadFiles(List<String> fileUrls);
  Future<void> clearAllCache();
  Future<String> getCacheStatus();
  Future<File> getCachedImage(String imageUrl);
  Stream<FileResponse> getCachedImageStream(String imageUrl, {bool withProgress = false});
  Future<File> getCachedVideo(String videoUrl);
  Stream<FileResponse> getCachedVideoStream(String videoUrl, {bool withProgress = false});
  Future<File> getCachedFile(String fileUrl);
  Stream<FileResponse> getCachedFileStream(String fileUrl, {bool withProgress = false});
}

@LazySingleton(as: ICacheService)
class CacheService implements ICacheService {
  final CacheManager defaultCacheManager;
  final CacheManager imageCacheManager;
  final CacheManager videoCacheManager;
  final CacheManager fileCacheManager;

  CacheService({
    @Named(DIKey.defaultCacheManager) required this.defaultCacheManager,
    @Named(DIKey.imageCacheManager) required this.imageCacheManager,
    @Named(DIKey.videoCacheManager) required this.videoCacheManager,
    @Named(DIKey.fileCacheManager) required this.fileCacheManager,
  });

  /// Initialize cache service and preload essential assets
  Future<void> initialize() async {
    LogDev.info('CacheService: Initializing cache service...');

    try {
      // Preload essential images here
      await preloadEssentialAssets();
      LogDev.info('CacheService: Successfully initialized and preloaded essential assets');
    } catch (e, stackTrace) {
      LogDev.error('CacheService: Error during initialization: $e\r\n$stackTrace');
    }
  }

  /// Preload essential assets that should be available immediately
  Future<void> preloadEssentialAssets() async {
    // Define your essential image URLs here
    final essentialImageUrls = <String>[
      // Add your essential image URLs here
      // 'https://example.com/logo.png',
      // 'https://example.com/splash-background.jpg',
      // 'https://example.com/default-avatar.png',
    ];

    // Define your essential file URLs here
    final essentialFileUrls = <String>[
      // Add your essential file URLs here
      // 'https://example.com/config.json',
      // 'https://example.com/terms.pdf',
    ];

    if (essentialImageUrls.isNotEmpty) {
      LogDev.info('CacheService: Preloading ${essentialImageUrls.length} essential images...');
      await _preloadImages(essentialImageUrls);
    }

    if (essentialFileUrls.isNotEmpty) {
      LogDev.info('CacheService: Preloading ${essentialFileUrls.length} essential files...');
      await _preloadFiles(essentialFileUrls);
    }
  }

  /// Preload a list of image URLs
  Future<void> _preloadImages(List<String> imageUrls) async {
    await Future.wait(
      imageUrls.map((url) => _safePreloadImage(url)),
      eagerError: false,
    );
  }

  /// Preload a list of file URLs
  Future<void> _preloadFiles(List<String> fileUrls) async {
    await Future.wait(
      fileUrls.map((url) => _safePreloadFile(url)),
      eagerError: false,
    );
  }

  /// Safely preload a single image with error handling
  Future<void> _safePreloadImage(String imageUrl) async {
    try {
      LogDev.info('CacheService: Preloading image: $imageUrl');
      await imageCacheManager.downloadFile(imageUrl);
      LogDev.info('CacheService: Successfully preloaded image: $imageUrl');
    } catch (e) {
      LogDev.error('CacheService: Failed to preload image $imageUrl: $e');
    }
  }

  /// Safely preload a single file with error handling
  Future<void> _safePreloadFile(String fileUrl) async {
    try {
      LogDev.info('CacheService: Preloading file: $fileUrl');
      await fileCacheManager.downloadFile(fileUrl);
      LogDev.info('CacheService: Successfully preloaded file: $fileUrl');
    } catch (e) {
      LogDev.error('CacheService: Failed to preload file $fileUrl: $e');
    }
  }

  /// Get cached image file - returns immediately if cached
  Future<File> getCachedImage(String imageUrl) async {
    return await imageCacheManager.getSingleFile(imageUrl);
  }

  /// Get cached image file stream - returns cached version first, then downloads if needed
  Stream<FileResponse> getCachedImageStream(String imageUrl, {bool withProgress = false}) {
    return imageCacheManager.getFileStream(imageUrl, withProgress: withProgress);
  }

  /// Get cached video file
  Future<File> getCachedVideo(String videoUrl) async {
    return await videoCacheManager.getSingleFile(videoUrl);
  }

  /// Get cached video file stream
  Stream<FileResponse> getCachedVideoStream(String videoUrl, {bool withProgress = false}) {
    return videoCacheManager.getFileStream(videoUrl, withProgress: withProgress);
  }

  /// Get cached file
  Future<File> getCachedFile(String fileUrl) async {
    return await fileCacheManager.getSingleFile(fileUrl);
  }

  /// Get cached file stream
  Stream<FileResponse> getCachedFileStream(String fileUrl, {bool withProgress = false}) {
    return fileCacheManager.getFileStream(fileUrl, withProgress: withProgress);
  }

  /// Check if image is cached
  Future<bool> isImageCached(String imageUrl) async {
    final fileInfo = await imageCacheManager.getFileFromCache(imageUrl);
    return fileInfo != null;
  }

  /// Check if video is cached
  Future<bool> isVideoCached(String videoUrl) async {
    final fileInfo = await videoCacheManager.getFileFromCache(videoUrl);
    return fileInfo != null;
  }

  /// Check if file is cached
  Future<bool> isFileCached(String fileUrl) async {
    final fileInfo = await fileCacheManager.getFileFromCache(fileUrl);
    return fileInfo != null;
  }

  /// Preload specific images (can be called anytime during app usage)
  Future<void> preloadImages(List<String> imageUrls) async {
    LogDev.info('CacheService: Preloading ${imageUrls.length} images...');
    await _preloadImages(imageUrls);
  }

  /// Preload specific videos
  Future<void> preloadVideos(List<String> videoUrls) async {
    LogDev.info('CacheService: Preloading ${videoUrls.length} videos...');
    await Future.wait(
      videoUrls.map((url) => _safePreloadVideo(url)),
      eagerError: false,
    );
  }

  /// Safely preload a single video with error handling
  Future<void> _safePreloadVideo(String videoUrl) async {
    try {
      LogDev.info('CacheService: Preloading video: $videoUrl');
      await videoCacheManager.downloadFile(videoUrl);
      LogDev.info('CacheService: Successfully preloaded video: $videoUrl');
    } catch (e) {
      LogDev.error('CacheService: Failed to preload video $videoUrl: $e');
    }
  }

  /// Preload specific files
  Future<void> preloadFiles(List<String> fileUrls) async {
    LogDev.info('CacheService: Preloading ${fileUrls.length} files...');
    await _preloadFiles(fileUrls);
  }

  /// Put a file into cache manually
  Future<File> putImageInCache(String imageUrl, Uint8List bytes) async {
    return await imageCacheManager.putFile(imageUrl, bytes);
  }

  /// Put a video into cache manually
  Future<File> putVideoInCache(String videoUrl, Uint8List bytes) async {
    return await videoCacheManager.putFile(videoUrl, bytes);
  }

  /// Put a file into cache manually
  Future<File> putFileInCache(String fileUrl, Uint8List bytes) async {
    return await fileCacheManager.putFile(fileUrl, bytes);
  }

  /// Remove specific image from cache
  Future<void> removeImageFromCache(String imageUrl) async {
    await imageCacheManager.removeFile(imageUrl);
    LogDev.info('CacheService: Removed image from cache: $imageUrl');
  }

  /// Remove specific video from cache
  Future<void> removeVideoFromCache(String videoUrl) async {
    await videoCacheManager.removeFile(videoUrl);
    LogDev.info('CacheService: Removed video from cache: $videoUrl');
  }

  /// Remove specific file from cache
  Future<void> removeFileFromCache(String fileUrl) async {
    await fileCacheManager.removeFile(fileUrl);
    LogDev.info('CacheService: Removed file from cache: $fileUrl');
  }

  /// Clear all image cache
  Future<void> clearImageCache() async {
    await imageCacheManager.emptyCache();
    LogDev.info('CacheService: Cleared all image cache');
  }

  /// Clear all video cache
  Future<void> clearVideoCache() async {
    await videoCacheManager.emptyCache();
    LogDev.info('CacheService: Cleared all video cache');
  }

  /// Clear all file cache
  Future<void> clearFileCache() async {
    await fileCacheManager.emptyCache();
    LogDev.info('CacheService: Cleared all file cache');
  }

  /// Clear all caches
  Future<void> clearAllCache() async {
    await Future.wait([
      clearImageCache(),
      clearVideoCache(),
      clearFileCache(),
      defaultCacheManager.emptyCache(),
    ]);
    LogDev.info('CacheService: Cleared all caches');
  }

  /// Clear all caches and get a simple status
  Future<String> getCacheStatus() async {
    try {
      return 'Cache service is running successfully';
    } catch (e) {
      return 'Cache service error: $e';
    }
  }
}
