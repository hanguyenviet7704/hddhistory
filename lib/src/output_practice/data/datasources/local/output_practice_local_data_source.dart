part of '../../../output_practice.dart';

abstract class OutputPracticeLocalDataSource {
  Future<List<OutputPracticeMessageModel>> getCachedMessages();
  Future<void> cacheMessages(List<OutputPracticeMessageModel> models);
  Future<OutputPracticeConversationModel?> getCachedConversation(String sectionId);
  Future<void> cacheConversation(OutputPracticeConversationModel model);
  Future<void> clearCache();
}

@LazySingleton(as: OutputPracticeLocalDataSource)
class OutputPracticeLocalDataSourceImpl implements OutputPracticeLocalDataSource {
  static const String _messagesListKey = 'output_practice_messages_cache';
  static const String _conversationKeyPrefix = 'output_practice_conversation_cache';

  final ILocalStoreService _localStoreService;

  OutputPracticeLocalDataSourceImpl(this._localStoreService);

  @override
  Future<List<OutputPracticeMessageModel>> getCachedMessages() async {
    try {
      final data = await _localStoreService.getMap(key: _messagesListKey);
      if (data.isEmpty) return [];
      final List<dynamic> jsonList = data['items'] ?? [];
      return jsonList
          .map((json) => OutputPracticeMessageModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> cacheMessages(List<OutputPracticeMessageModel> models) async {
    try {
      final jsonList = models.map((model) => model.toJson()).toList();
      await _localStoreService.setMap(
        key: _messagesListKey,
        value: {'items': jsonList},
      );
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Future<OutputPracticeConversationModel?> getCachedConversation(String sectionId) async {
    try {
      final cacheKey = '${_conversationKeyPrefix}_$sectionId';
      final data = await _localStoreService.getMap(key: cacheKey);
      if (data.isEmpty) return null;
      return OutputPracticeConversationModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheConversation(OutputPracticeConversationModel model) async {
    try {
      final cacheKey = '${_conversationKeyPrefix}_${model.sectionId}';
      await _localStoreService.setMap(
        key: cacheKey,
        value: model.toJson(),
      );
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await _localStoreService.remove(key: _messagesListKey);
    } catch (e) {
      // Handle error silently
    }
  }
}
