part of '../../home_widget.dart';

@LazySingleton(as: IHomeWidgetRepository)
class HomeWidgetRepository implements IHomeWidgetRepository {
  final HomeWidgetApi _api;
  final HomeWidgetLocalDataSource _localDataSource;
  final HomeWidgetBridge _bridge;
  Future<HomeWidgetSyncResult>? _suggestSyncInFlight;

  HomeWidgetRepository(
    this._api,
    this._localDataSource,
    this._bridge,
  );

  @override
  TaskEither<AppException, List<HomeWidgetSyncResult>> syncAll(HomeWidgetSyncParams params) {
    return TaskEither(() async {
      final localizedParams = params.withTextDefaults(await params.resolveTextDefaults());
      final results = <HomeWidgetSyncResult>[];
      results.add(
        (await syncInProgress(
          localizedParams,
        ).run()).getOrElse((error) => HomeWidgetSyncResult(widgetType: HomeWidgetType.inProgressCourse, status: HomeWidgetSyncStatus.failed, message: error.message ?? '')),
      );
      results.add(
        (await syncStreak(
          localizedParams,
        ).run()).getOrElse((error) => HomeWidgetSyncResult(widgetType: HomeWidgetType.weeklyStreak, status: HomeWidgetSyncStatus.failed, message: error.message ?? '')),
      );
      results.add(
        (await syncSuggestCourse(
          localizedParams,
        ).run()).getOrElse((error) => HomeWidgetSyncResult(widgetType: HomeWidgetType.suggestCourse, status: HomeWidgetSyncStatus.failed, message: error.message ?? '')),
      );
      return right(results);
    });
  }

  @override
  TaskEither<AppException, HomeWidgetSyncResult> syncInProgress(HomeWidgetSyncParams params) {
    return _bestEffort(() async {
      final textDefaults = await params.resolveTextDefaults();
      final response = await _api.getInProgressWidget();
      final payload = HomeWidgetPayloadBuilder.buildInProgress(
        response.data?.toEntity(),
        localeCode: params.localeCode,
        updatedAt: params.currentTime,
        textDefaults: textDefaults,
      );
      return _savePayloadOrPreserve(payload);
    }, HomeWidgetType.inProgressCourse);
  }

  @override
  TaskEither<AppException, HomeWidgetSyncResult> syncStreak(HomeWidgetSyncParams params) {
    return _bestEffort(() async {
      final textDefaults = await params.resolveTextDefaults();
      final response = await _api.getLearningStreak();
      if (response.data == null) {
        throw StateError('Streak widget response data is null');
      }
      final payload = HomeWidgetPayloadBuilder.buildStreak(
        response.data!.toEntity(),
        localeCode: params.localeCode,
        updatedAt: params.currentTime,
        textDefaults: textDefaults,
      );
      return _savePayloadOrPreserve(payload);
    }, HomeWidgetType.weeklyStreak);
  }

  @override
  TaskEither<AppException, HomeWidgetSyncResult> syncSuggestCourse(HomeWidgetSyncParams params) {
    final existing = _suggestSyncInFlight;
    if (existing != null) {
      return TaskEither(() async => right(await existing));
    }

    return TaskEither(() async {
      final future = _runBestEffort(
        () => _syncSuggestCourse(params),
        HomeWidgetType.suggestCourse,
      );
      _suggestSyncInFlight = future;
      try {
        return right(await future);
      } finally {
        if (identical(_suggestSyncInFlight, future)) {
          _suggestSyncInFlight = null;
        }
      }
    });
  }

  @override
  TaskEither<AppException, HomeWidgetSyncResult> clearStoredWidgets() {
    return TaskEither(() async {
      for (final key in HomeWidgetStorageKeys.allKeys) {
        try {
          await _bridge.clearKey(key);
        } catch (_) {}
      }
      await _localDataSource.clearCache();
      await _updateWidgetQuietly(HomeWidgetType.inProgressCourse);
      await _updateWidgetQuietly(HomeWidgetType.weeklyStreak);
      await _updateWidgetQuietly(HomeWidgetType.suggestCourse);
      return right(const HomeWidgetSyncResult(widgetType: null, status: HomeWidgetSyncStatus.cleared));
    });
  }

  TaskEither<AppException, HomeWidgetSyncResult> _bestEffort(
    Future<HomeWidgetSyncResult> Function() action,
    HomeWidgetType widgetType,
  ) {
    return TaskEither(() async => right(await _runBestEffort(action, widgetType)));
  }

  Future<HomeWidgetSyncResult> _runBestEffort(
    Future<HomeWidgetSyncResult> Function() action,
    HomeWidgetType widgetType,
  ) async {
    try {
      return await action();
    } catch (error) {
      final cached = await _localDataSource.getCachedPayload(widgetType.storageKey);
      await _updateWidgetQuietly(widgetType);
      if (cached != null) {
        return HomeWidgetSyncResult(widgetType: widgetType, status: HomeWidgetSyncStatus.preserved, payload: cached, message: error.toString());
      }
      return HomeWidgetSyncResult(widgetType: widgetType, status: HomeWidgetSyncStatus.failed, message: error.toString());
    }
  }

  Future<HomeWidgetSyncResult> _savePayloadOrPreserve(HomeWidgetPayload payload) async {
    try {
      String? nonBlockingMessage;
      try {
        await _bridge.prepareStaticAssets();
      } catch (error) {
        nonBlockingMessage = error.toString();
      }

      if (payload.imageUrl != null && payload.imageKey != null) {
        try {
          await _bridge.saveImage(key: payload.imageKey!, imageUrl: payload.imageUrl!);
        } catch (error) {
          nonBlockingMessage = [nonBlockingMessage, '${payload.imageKey}: $error'].where((message) => message?.isNotEmpty == true).join('; ');
        }
      }
      await _bridge.savePayload(payload);
      await _localDataSource.cachePayload(payload);
      await _bridge.updateWidget(payload.widgetType);
      return HomeWidgetSyncResult(widgetType: payload.widgetType, status: HomeWidgetSyncStatus.updated, payload: payload, message: nonBlockingMessage ?? '');
    } catch (error) {
      final cached = await _localDataSource.getCachedPayload(payload.storageKey);
      await _updateWidgetQuietly(payload.widgetType);
      if (cached != null) {
        return HomeWidgetSyncResult(widgetType: payload.widgetType, status: HomeWidgetSyncStatus.preserved, payload: cached, message: error.toString());
      }

      await _bridge.savePayload(payload);
      await _localDataSource.cachePayload(payload);
      await _updateWidgetQuietly(payload.widgetType);
      return HomeWidgetSyncResult(widgetType: payload.widgetType, status: HomeWidgetSyncStatus.updated, payload: payload, message: error.toString());
    }
  }

  Future<HomeWidgetSyncResult> _syncSuggestCourse(HomeWidgetSyncParams params) async {
    final textDefaults = await params.resolveTextDefaults();
    final today = params.localDateKey;
    final cachedDate = await _localDataSource.getSuggestionDate();
    final cachedPayload = await _localDataSource.getCachedPayload(HomeWidgetStorageKeys.suggestCoursePayload);
    if (cachedDate == today && cachedPayload != null && _payloadLocaleMatches(cachedPayload, params.localeCode)) {
      await _bridge.updateWidget(HomeWidgetType.suggestCourse);
      return HomeWidgetSyncResult(widgetType: HomeWidgetType.suggestCourse, status: HomeWidgetSyncStatus.preserved, payload: cachedPayload);
    }

    final response = await _api.getSuggestCourseWidget();
    final payload = HomeWidgetPayloadBuilder.buildSuggestCourse(
      response.data?.toEntity(),
      localeCode: params.localeCode,
      updatedAt: params.currentTime,
      suggestionDate: params.now,
      textDefaults: textDefaults,
    );
    final result = await _savePayloadOrPreserve(payload);
    if (result.status == HomeWidgetSyncStatus.updated) {
      await _localDataSource.setSuggestionDate(today);
    }
    return result;
  }

  Future<void> _updateWidgetQuietly(HomeWidgetType widgetType) async {
    try {
      await _bridge.updateWidget(widgetType);
    } catch (_) {}
  }

  static bool _payloadLocaleMatches(HomeWidgetPayload payload, String localeCode) {
    return payload.data['localeCode']?.toString() == localeCode;
  }
}
