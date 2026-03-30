part of '../../../output_practice.dart';

abstract class OutputPracticeLocalDataSource {
  Future<List<OutputPracticeMessageModel>> getCachedMessages(String conversationId);
  Future<void> cacheMessages(String conversationId, List<OutputPracticeMessageModel> models);
  Future<OutputPracticeConversationModel?> getCachedConversation(String sectionId);
  Future<void> cacheConversation(String sectionId, OutputPracticeConversationModel model);
  Future<void> clearConversation(String sectionId);
  Future<void> clearMessages(String conversationId);
}

@LazySingleton(as: OutputPracticeLocalDataSource)
class OutputPracticeLocalDataSourceImpl implements OutputPracticeLocalDataSource {
  static const String _messagesKeyPrefix = 'output_practice_messages_cache';
  static const String _conversationKeyPrefix = 'output_practice_conversation_cache';

  final ILocalStoreService _localStoreService;

  OutputPracticeLocalDataSourceImpl(this._localStoreService);

  @override
  Future<List<OutputPracticeMessageModel>> getCachedMessages(String conversationId) async {
    try {
      final data = await _localStoreService.getMap(key: _messagesKey(conversationId));
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
  Future<void> cacheMessages(String conversationId, List<OutputPracticeMessageModel> models) async {
    try {
      final jsonList = models.map((model) => model.toJson()).toList();
      await _localStoreService.setMap(
        key: _messagesKey(conversationId),
        value: {'items': jsonList},
      );
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Future<OutputPracticeConversationModel?> getCachedConversation(String sectionId) async {
    try {
      final cacheKey = _conversationKey(sectionId);
      final data = await _localStoreService.getMap(key: cacheKey);
      if (data.isEmpty) return null;
      return OutputPracticeConversationModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheConversation(String sectionId, OutputPracticeConversationModel model) async {
    try {
      final cacheKey = _conversationKey(sectionId);
      await _localStoreService.setMap(
        key: cacheKey,
        value: model.toJson(),
      );
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Future<void> clearConversation(String sectionId) async {
    try {
      await _localStoreService.remove(key: _conversationKey(sectionId));
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Future<void> clearMessages(String conversationId) async {
    try {
      await _localStoreService.remove(key: _messagesKey(conversationId));
    } catch (e) {
      // Handle error silently
    }
  }

  String _messagesKey(String conversationId) => '${_messagesKeyPrefix}_$conversationId';

  String _conversationKey(String sectionId) => '${_conversationKeyPrefix}_$sectionId';
}
