part of '../../../video_lesson.dart';

/// Local data source for Video Lesson
///
/// Handles caching of User Video Lesson Note data for offline support.
/// Note: For paginated APIs, only the items are cached, not pagination metadata.
/// Pagination info (currentPage, totalPages, etc.) should always come fresh from the API.
abstract class VideoLessonLocalDataSource {
  /// Get all cached user_video_lesson_notes
  ///
  /// Used as fallback when API fails. The repository will construct
  /// a BasePageBreak with these items for offline support.
  Future<List<UserVideoLessonNoteModel>> getCachedUserVideoLessonNotes();

  /// Cache multiple user_video_lesson_notes
  ///
  /// For paginated APIs, the repository passes `pageData.items` (not the entire BasePageBreak).
  /// This keeps the cache simple and avoids stale pagination metadata.
  Future<void> cacheUserVideoLessonNotes(List<UserVideoLessonNoteModel> models);

  /// Get cached user_video_lesson_note by id
  Future<UserVideoLessonNoteModel?> getCachedUserVideoLessonNote(String id);

  /// Cache single user_video_lesson_note
  ///
  /// Used for caching individual items from GET, POST, PUT responses.
  Future<void> cacheUserVideoLessonNote(UserVideoLessonNoteModel model);

  /// Delete cached user_video_lesson_note
  Future<void> deleteCachedUserVideoLessonNote(String id);

  /// Clear all cached data
  Future<void> clearCache();
}

@LazySingleton(as: VideoLessonLocalDataSource)
class VideoLessonLocalDataSourceImpl implements VideoLessonLocalDataSource {
  static const String _cacheKey = 'video_lesson_cache';
  static const String _cacheListKey = 'video_lesson_list_cache';

  final ILocalStoreService _localStoreService;

  VideoLessonLocalDataSourceImpl(this._localStoreService);

  @override
  Future<List<UserVideoLessonNoteModel>> getCachedUserVideoLessonNotes() async {
    try {
      final data = await _localStoreService.getMap(key: _cacheListKey);
      if (data.isEmpty) return [];

      final List<dynamic> jsonList = data['items'] ?? [];
      return jsonList
          .map((json) => UserVideoLessonNoteModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> cacheUserVideoLessonNotes(List<UserVideoLessonNoteModel> models) async {
    try {
      final jsonList = models.map((model) => model.toJson()).toList();
      await _localStoreService.setMap(
        key: _cacheListKey,
        value: {'items': jsonList},
      );
    } catch (e) {
      // Handle error silently or log
    }
  }

  @override
  Future<UserVideoLessonNoteModel?> getCachedUserVideoLessonNote(String id) async {
    try {
      final cacheKey = '${_cacheKey}_$id';
      final data = await _localStoreService.getMap(key: cacheKey);
      if (data.isEmpty) return null;

      return UserVideoLessonNoteModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheUserVideoLessonNote(UserVideoLessonNoteModel model) async {
    try {
      final cacheKey = '${_cacheKey}_${model.id}';
      await _localStoreService.setMap(
        key: cacheKey,
        value: model.toJson(),
      );
    } catch (e) {
      // Handle error silently or log
    }
  }

  @override
  Future<void> deleteCachedUserVideoLessonNote(String id) async {
    try {
      final cacheKey = '${_cacheKey}_$id';
      await _localStoreService.remove(key: cacheKey);

      // Also remove from cached list if exists
      final cachedList = await getCachedUserVideoLessonNotes();
      final updatedList = cachedList.where((item) => item.id != id).toList();
      await cacheUserVideoLessonNotes(updatedList);
    } catch (e) {
      // Handle error silently or log
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await _localStoreService.remove(key: _cacheListKey);
      // Note: Individual item caches (_cacheKey_id) are kept for specific item lookups
      // To clear everything, you could track all keys or implement prefix-based deletion
    } catch (e) {
      // Handle error silently or log
    }
  }
}

