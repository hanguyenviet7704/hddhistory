part of '../../home_widget.dart';

abstract class HomeWidgetBridge {
  Future<void> saveLocaleCode(String localeCode);

  Future<void> savePayload(HomeWidgetPayload payload);

  Future<void> saveImage({required String key, required String imageUrl});

  /// Same download as [saveImage], but returns the saved file's local path —
  /// for callers (e.g. Live Activity) that need the raw path once, rather
  /// than a UserDefaults-key indirection meant for repeated timeline refreshes.
  Future<String?> saveImageAndGetPath({required String key, required String imageUrl});

  Future<void> prepareStaticAssets();

  Future<void> updateWidget(HomeWidgetType type);

  Future<void> clearKey(String key);
}

@LazySingleton(as: HomeWidgetBridge)
class HomeWidgetBridgeImpl implements HomeWidgetBridge {
  HomeWidgetBridgeImpl(@Named(DIKey.thirdPartyDio) this._dio);

  final Dio _dio;

  String get _appGroupId => HomeWidgetAppGroups.current();

  @override
  Future<void> saveLocaleCode(String localeCode) async {
    await home_widget_plugin.HomeWidget.setAppGroupId(_appGroupId);
    await home_widget_plugin.HomeWidget.saveWidgetData<String>(
      HomeWidgetStorageKeys.localeCode,
      localeCode,
      appGroupId: _appGroupId,
    );
  }

  @override
  Future<void> savePayload(HomeWidgetPayload payload) async {
    await home_widget_plugin.HomeWidget.setAppGroupId(_appGroupId);
    await home_widget_plugin.HomeWidget.saveWidgetData<String>(
      payload.storageKey,
      payload.toJsonString(),
      appGroupId: _appGroupId,
    );
  }

  @override
  Future<void> saveImage({required String key, required String imageUrl}) async {
    await home_widget_plugin.HomeWidget.setAppGroupId(_appGroupId);

    // Download the bytes explicitly instead of resolving a NetworkImage.
    // On iOS the plugin's NetworkImage resolution can fail silently (never
    // firing onError) and write no file, so the widget loses its remote image
    // while Android works. A direct, timeout-bounded fetch writes a real file
    // the widget extension can read. AssetImage stays on the plugin path.
    final response = await _dio.get<List<int>>(
      imageUrl,
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) {
      throw StateError('Empty image bytes for "$imageUrl"');
    }

    await home_widget_plugin.HomeWidget.saveFile(
      key,
      Uint8List.fromList(bytes),
      extension: 'png',
      appGroupId: _appGroupId,
    );
  }

  @override
  Future<String?> saveImageAndGetPath({required String key, required String imageUrl}) async {
    await home_widget_plugin.HomeWidget.setAppGroupId(_appGroupId);

    final response = await _dio.get<List<int>>(
      imageUrl,
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) return null;

    return home_widget_plugin.HomeWidget.saveFile(
      key,
      Uint8List.fromList(bytes),
      extension: 'png',
      appGroupId: _appGroupId,
    );
  }

  @override
  Future<void> prepareStaticAssets() async {
    await home_widget_plugin.HomeWidget.setAppGroupId(_appGroupId);
    await _saveAsset(HomeWidgetStorageKeys.bookAsset, const AssetImage('assets/images/app/book.png'));
    await _saveAsset(HomeWidgetStorageKeys.certificateAsset, const AssetImage('assets/images/app/certificate.png'));
    await _saveAsset(HomeWidgetStorageKeys.flameAsset, const AssetImage('assets/images/app/flame_star.png'));
  }

  @override
  Future<void> updateWidget(HomeWidgetType type) async {
    await home_widget_plugin.HomeWidget.updateWidget(
      iOSName: HomeWidgetNativeNames.iOSName(type),
      qualifiedAndroidName: HomeWidgetNativeNames.androidName(type),
    );
  }

  @override
  Future<void> clearKey(String key) async {
    await home_widget_plugin.HomeWidget.saveWidgetData<String>(
      key,
      null,
      appGroupId: _appGroupId,
    );
  }

  Future<void> _saveAsset(String key, ImageProvider provider) async {
    await home_widget_plugin.HomeWidget.saveImage(
      key,
      provider,
      appGroupId: _appGroupId,
    );
  }
}
