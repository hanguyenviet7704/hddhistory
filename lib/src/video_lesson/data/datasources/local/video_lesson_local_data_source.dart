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
  Future<List<UserVideoLessonNoteModel>> getCachedUserVideoLessonNotes(VideoLessonNoteFilterEntity filter);

  /// Cache multiple user_video_lesson_notes
  ///
  /// For paginated APIs, the repository passes `pageData.items` (not the entire BasePageBreak).
  /// This keeps the cache simple and avoids stale pagination metadata.
  Future<void> cacheUserVideoLessonNotes(VideoLessonNoteFilterEntity filter, List<UserVideoLessonNoteModel> models);

  /// Get cached user_video_lesson_note by id
  Future<UserVideoLessonNoteModel?> getCachedUserVideoLessonNote(VideoLessonNoteFilterEntity filter, String id);

  /// Cache single user_video_lesson_note
  ///
  /// Used for caching individual items from GET, POST, PUT responses.
  Future<void> cacheUserVideoLessonNote(UserVideoLessonNoteModel model);

  /// Delete cached user_video_lesson_note
  Future<void> deleteCachedUserVideoLessonNote(UserVideoLessonNoteModel model);

  /// Clear all cached data
  Future<void> clearCache(VideoLessonNoteFilterEntity filter);
}

@LazySingleton(as: VideoLessonLocalDataSource)
class VideoLessonLocalDataSourceImpl implements VideoLessonLocalDataSource {
  static const String _cacheKey = 'video_lesson_cache';
  static const String _cacheListKey = 'video_lesson_list_cache';

  final ILocalStoreService _localStoreService;

  VideoLessonLocalDataSourceImpl(this._localStoreService);

  String _scopeKey(VideoLessonNoteFilterEntity filter) => filter.scopeKey.replaceAll(RegExp(r'[^a-zA-Z0-9:_-]'), '_');

  String _scopedListKey(VideoLessonNoteFilterEntity filter) => '${_cacheListKey}_${_scopeKey(filter)}';

  String _scopedItemKey({
    required String id,
    required VideoLessonNoteFilterEntity filter,
  }) => '${_cacheKey}_${_scopeKey(filter)}_$id';

  VideoLessonNoteFilterEntity _filterFromModel(UserVideoLessonNoteModel model) => VideoLessonNoteFilterEntity(
    courseId: model.courseId,
    nodeId: model.nodeId,
    lessonId: model.lessonId,
  );

  @override
  Future<List<UserVideoLessonNoteModel>> getCachedUserVideoLessonNotes(VideoLessonNoteFilterEntity filter) async {
    try {
      final data = await _localStoreService.getMap(key: _scopedListKey(filter));
      if (data.isEmpty) return [];

      final List<dynamic> jsonList = data['items'] ?? [];
      return jsonList.map((json) => UserVideoLessonNoteModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> cacheUserVideoLessonNotes(VideoLessonNoteFilterEntity filter, List<UserVideoLessonNoteModel> models) async {
    try {
      final jsonList = models.map((model) => model.toJson()).toList();
      await _localStoreService.setMap(
        key: _scopedListKey(filter),
        value: {'items': jsonList},
      );
    } catch (e) {
      // Handle error silently or log
    }
  }

  @override
  Future<UserVideoLessonNoteModel?> getCachedUserVideoLessonNote(VideoLessonNoteFilterEntity filter, String id) async {
    try {
      final cacheKey = _scopedItemKey(id: id, filter: filter);
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
      final filter = _filterFromModel(model);
      final cacheKey = _scopedItemKey(id: model.id, filter: filter);
      await _localStoreService.setMap(
        key: cacheKey,
        value: model.toJson(),
      );
    } catch (e) {
      // Handle error silently or log
    }
  }

  @override
  Future<void> deleteCachedUserVideoLessonNote(UserVideoLessonNoteModel model) async {
    try {
      final filter = _filterFromModel(model);
      final cacheKey = _scopedItemKey(id: model.id, filter: filter);
      await _localStoreService.remove(key: cacheKey);

      final cachedList = await getCachedUserVideoLessonNotes(filter);
      final updatedList = cachedList.where((item) => item.id != model.id).toList();
      await cacheUserVideoLessonNotes(filter, updatedList);
    } catch (e) {
      // Handle error silently or log
    }
  }

  @override
  Future<void> clearCache(VideoLessonNoteFilterEntity filter) async {
    try {
      await _localStoreService.remove(key: _scopedListKey(filter));
    } catch (e) {
      // Handle error silently or log
    }
  }
}
