part of '../../../output_practice.dart';

/// Local data source for Output Practice
///
/// Handles caching of Output Practice Conversation data for offline support.
/// Note: For paginated APIs, only the items are cached, not pagination metadata.
/// Pagination info (currentPage, totalPages, etc.) should always come fresh from the API.
abstract class OutputPracticeLocalDataSource {
  /// Get all cached output_practice_conversations
  ///
  /// Used as fallback when API fails. The repository will construct
  /// a BasePageBreak with these items for offline support.
  Future<List<OutputPracticeConversationModel>> getCachedOutputPracticeConversations();

  /// Cache multiple output_practice_conversations
  ///
  /// For paginated APIs, the repository passes `pageData.items` (not the entire BasePageBreak).
  /// This keeps the cache simple and avoids stale pagination metadata.
  Future<void> cacheOutputPracticeConversations(List<OutputPracticeConversationModel> models);

  /// Get cached output_practice_conversation by id
  Future<OutputPracticeConversationModel?> getCachedOutputPracticeConversation(String id);

  /// Cache single output_practice_conversation
  ///
  /// Used for caching individual items from GET, POST, PUT responses.
  Future<void> cacheOutputPracticeConversation(OutputPracticeConversationModel model);

  /// Delete cached output_practice_conversation
  Future<void> deleteCachedOutputPracticeConversation(String id);

  /// Clear all cached data
  Future<void> clearCache();
}

@LazySingleton(as: OutputPracticeLocalDataSource)
class OutputPracticeLocalDataSourceImpl implements OutputPracticeLocalDataSource {
  static const String _cacheKey = 'output_practice_cache';
  static const String _cacheListKey = 'output_practice_list_cache';

  final ILocalStoreService _localStoreService;

  OutputPracticeLocalDataSourceImpl(this._localStoreService);

  @override
  Future<List<OutputPracticeConversationModel>> getCachedOutputPracticeConversations() async {
    try {
      final data = await _localStoreService.getMap(key: _cacheListKey);
      if (data.isEmpty) return [];

      final List<dynamic> jsonList = data['items'] ?? [];
      return jsonList
          .map((json) => OutputPracticeConversationModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> cacheOutputPracticeConversations(List<OutputPracticeConversationModel> models) async {
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
  Future<OutputPracticeConversationModel?> getCachedOutputPracticeConversation(String id) async {
    try {
      final cacheKey = '${_cacheKey}_$id';
      final data = await _localStoreService.getMap(key: cacheKey);
      if (data.isEmpty) return null;

      return OutputPracticeConversationModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheOutputPracticeConversation(OutputPracticeConversationModel model) async {
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
  Future<void> deleteCachedOutputPracticeConversation(String id) async {
    try {
      final cacheKey = '${_cacheKey}_$id';
      await _localStoreService.remove(key: cacheKey);

      // Also remove from cached list if exists
      final cachedList = await getCachedOutputPracticeConversations();
      final updatedList = cachedList.where((item) => item.id != id).toList();
      await cacheOutputPracticeConversations(updatedList);
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

