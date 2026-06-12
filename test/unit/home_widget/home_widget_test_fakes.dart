import 'package:meup/meup.dart';

class FakeHomeWidgetApi implements HomeWidgetApi {
  FakeHomeWidgetApi({
    this.inProgress,
    this.suggest,
    this.streak,
    this.inProgressError,
    this.suggestError,
    this.streakError,
    this.suggestDelay = Duration.zero,
    this.streakReturnsNull = false,
  });

  final HomeWidgetCourseModel? inProgress;
  final HomeWidgetCourseModel? suggest;
  final HomeWidgetStreakModel? streak;
  final Object? inProgressError;
  final Object? suggestError;
  final Object? streakError;
  final Duration suggestDelay;
  final bool streakReturnsNull;

  int inProgressCalls = 0;
  int suggestCalls = 0;
  int streakCalls = 0;

  @override
  Future<BaseResponse<HomeWidgetCourseModel>> getInProgressWidget() async {
    inProgressCalls += 1;
    if (inProgressError != null) throw inProgressError!;
    return BaseResponse(data: inProgress);
  }

  @override
  Future<BaseResponse<HomeWidgetCourseModel>> getSuggestCourseWidget() async {
    suggestCalls += 1;
    if (suggestDelay > Duration.zero) {
      await Future<void>.delayed(suggestDelay);
    }
    if (suggestError != null) throw suggestError!;
    return BaseResponse(data: suggest);
  }

  @override
  Future<BaseResponse<HomeWidgetStreakModel>> getLearningStreak() async {
    streakCalls += 1;
    if (streakError != null) throw streakError!;
    if (streakReturnsNull) return const BaseResponse(data: null);
    return BaseResponse(data: streak ?? const HomeWidgetStreakModel());
  }
}

class FakeHomeWidgetLocalDataSource implements HomeWidgetLocalDataSource {
  FakeHomeWidgetLocalDataSource({
    this.suggestionDate = '',
    Map<String, HomeWidgetPayload>? cachedPayloads,
  }) : cachedPayloads = cachedPayloads ?? {};

  String suggestionDate;
  final Map<String, HomeWidgetPayload> cachedPayloads;
  bool clearCalled = false;

  @override
  Future<HomeWidgetPayload?> getCachedPayload(String key) async => cachedPayloads[key];

  @override
  Future<void> cachePayload(HomeWidgetPayload payload) async {
    cachedPayloads[payload.storageKey] = payload;
  }

  @override
  Future<String> getSuggestionDate() async => suggestionDate;

  @override
  Future<void> setSuggestionDate(String value) async {
    suggestionDate = value;
  }

  @override
  Future<void> clearCache() async {
    clearCalled = true;
    cachedPayloads.clear();
    suggestionDate = '';
  }
}

class FakeHomeWidgetBridge implements HomeWidgetBridge {
  FakeHomeWidgetBridge({
    this.failImageKeys = const {},
    this.failClearKeys = const {},
  });

  final Set<String> failImageKeys;
  final Set<String> failClearKeys;
  final List<HomeWidgetPayload> savedPayloads = [];
  final List<String> savedImageKeys = [];
  final List<HomeWidgetType> updatedTypes = [];
  final List<String> clearedKeys = [];

  @override
  Future<void> saveLocaleCode(String localeCode) async {}

  @override
  Future<void> savePayload(HomeWidgetPayload payload) async {
    savedPayloads.add(payload);
  }

  @override
  Future<void> saveImage({required String key, required String imageUrl}) async {
    savedImageKeys.add(key);
    if (failImageKeys.contains(key)) throw StateError('image failed');
  }

  @override
  Future<void> prepareStaticAssets() async {}

  @override
  Future<void> updateWidget(HomeWidgetType type) async {
    updatedTypes.add(type);
  }

  @override
  Future<void> clearKey(String key) async {
    clearedKeys.add(key);
    if (failClearKeys.contains(key)) throw StateError('clear failed');
  }
}
