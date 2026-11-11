part of 'di.dart';

@module
abstract class CacheModule {
  /// Default cache manager for general use
  @Named(DIKey.defaultCacheManager)
  @lazySingleton
  CacheManager get defaultCacheManager => DefaultCacheManager();

  /// Image cache manager with optimized settings for images
  @Named(DIKey.imageCacheManager)
  @lazySingleton
  CacheManager get imageCacheManager => CacheManager(
    Config(
      CacheKey.imageCache,
      stalePeriod: const Duration(days: 7), // Keep images for 7 days
      maxNrOfCacheObjects: 500, // Maximum 500 cached images
      repo: JsonCacheInfoRepository(databaseName: CacheKey.imageCache),
      fileSystem: IOFileSystem(CacheKey.imageCache),
      fileService: HttpFileService(),
    ),
  );

  /// Video cache manager with larger storage settings
  @Named(DIKey.videoCacheManager)
  @lazySingleton
  CacheManager get videoCacheManager => CacheManager(
    Config(
      CacheKey.videoCache,
      stalePeriod: const Duration(days: 7), // Keep videos for 7 days
      maxNrOfCacheObjects: 50, // Maximum 50 cached videos
      repo: JsonCacheInfoRepository(databaseName: CacheKey.videoCache),
      fileSystem: IOFileSystem(CacheKey.videoCache),
      fileService: HttpFileService(),
    ),
  );

  /// File cache manager for documents and other files
  @Named(DIKey.fileCacheManager)
  @lazySingleton
  CacheManager get fileCacheManager => CacheManager(
    Config(
      CacheKey.fileCache,
      stalePeriod: const Duration(days: 14), // Keep files for 14 days
      maxNrOfCacheObjects: 200, // Maximum 200 cached files
      repo: JsonCacheInfoRepository(databaseName: CacheKey.fileCache),
      fileSystem: IOFileSystem(CacheKey.fileCache),
      fileService: HttpFileService(),
    ),
  );
}
