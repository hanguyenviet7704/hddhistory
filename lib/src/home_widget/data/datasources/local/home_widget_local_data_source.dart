part of '../../../home_widget.dart';

abstract class HomeWidgetLocalDataSource {
  Future<HomeWidgetPayload?> getCachedPayload(String key);

  Future<void> cachePayload(HomeWidgetPayload payload);

  Future<String> getSuggestionDate();

  Future<void> setSuggestionDate(String value);

  Future<void> clearCache();
}

@LazySingleton(as: HomeWidgetLocalDataSource)
class HomeWidgetLocalDataSourceImpl implements HomeWidgetLocalDataSource {
  final ILocalStoreService _localStoreService;

  HomeWidgetLocalDataSourceImpl(this._localStoreService);

  @override
  Future<HomeWidgetPayload?> getCachedPayload(String key) async {
    try {
      final raw = await _localStoreService.getString(key: key);
      if (raw.isEmpty) return null;
      return HomeWidgetPayload.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> cachePayload(HomeWidgetPayload payload) async {
    await _localStoreService.setString(
      key: payload.storageKey,
      value: payload.toJsonString(),
    );
  }

  @override
  Future<String> getSuggestionDate() {
    return _localStoreService.getString(key: HomeWidgetStorageKeys.suggestionDate);
  }

  @override
  Future<void> setSuggestionDate(String value) {
    return _localStoreService.setString(key: HomeWidgetStorageKeys.suggestionDate, value: value);
  }

  @override
  Future<void> clearCache() async {
    for (final key in HomeWidgetStorageKeys.allKeys) {
      try {
        await _localStoreService.remove(key: key);
      } catch (_) {}
    }
  }
}
