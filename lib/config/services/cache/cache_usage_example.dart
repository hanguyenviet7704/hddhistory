/// Example usage of the CacheService for preloading and accessing cached content
///
/// This file demonstrates how to:
/// 1. Add essential image URLs for preloading during app initialization
/// 2. Use the cache service to get cached images immediately
/// 3. Preload additional content during app usage
/// 4. Manage cache storage
library;

import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/constants/constants.dart';
import '../../di/di.dart';
import '../services.dart';

class CacheUsageExample {
  /// Example of how to preload essential images during app initialization
  static Future<void> preloadEssentialImages() async {
    final cacheService = AppDI.injector.get<CacheService>(instanceName: DIKey.cacheService);

    // Add your essential image URLs here
    final essentialImages = [
      'https://your-cdn.com/logo.png',
      'https://your-cdn.com/splash-background.jpg',
      'https://your-cdn.com/default-avatar.png',
      'https://your-cdn.com/app-icon.png',
      // Add more URLs as needed
    ];

    await cacheService.preloadImages(essentialImages);
  }

  /// Example of how to get a cached image (returns immediately if cached)
  static Future<File> getCachedImageExample(String imageUrl) async {
    final cacheService = AppDI.injector.get<CacheService>(instanceName: DIKey.cacheService);
    return await cacheService.getCachedImage(imageUrl);
  }

  /// Example of how to check if an image is already cached
  static Future<bool> isImageCachedExample(String imageUrl) async {
    final cacheService = AppDI.injector.get<CacheService>(instanceName: DIKey.cacheService);
    return await cacheService.isImageCached(imageUrl);
  }

  /// Example of how to preload images for a specific screen/feature
  static Future<void> preloadImagesForFeature() async {
    final cacheService = AppDI.injector.get<CacheService>(instanceName: DIKey.cacheService);

    // Preload images for a specific feature (e.g., user profiles, product gallery)
    final featureImages = [
      'https://your-api.com/user/123/avatar.jpg',
      'https://your-api.com/product/456/image1.jpg',
      'https://your-api.com/product/456/image2.jpg',
    ];

    await cacheService.preloadImages(featureImages);
  }

  /// Example of how to use cached images in a widget
  static Widget buildCachedImageWidget(String imageUrl) {
    return FutureBuilder<File>(
      future: getCachedImageExample(imageUrl),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Image.file(
            snapshot.data!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.error);
            },
          );
        } else if (snapshot.hasError) {
          return const Icon(Icons.error);
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }

  /// Example of how to clear specific cache when needed
  static Future<void> clearImageCacheExample() async {
    final cacheService = AppDI.injector.get<CacheService>(instanceName: DIKey.cacheService);
    await cacheService.clearImageCache();
  }

  /// Example of how to get cache status
  static Future<String> getCacheStatusExample() async {
    final cacheService = AppDI.injector.get<CacheService>(instanceName: DIKey.cacheService);
    return await cacheService.getCacheStatus();
  }
}
