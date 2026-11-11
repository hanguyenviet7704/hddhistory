part of '../../../common.dart';

@lazySingleton
class LocaleCubit extends HydratedCubit<AppLocale> {
  LocaleCubit() : super(AppLocale.vi) {
    LocaleSettings.setLocale(state);
  }

  void setLocale(AppLocale locale) {
    if (locale == state) return;
    LocaleSettings.setLocale(locale);
    emit(locale);
    LogDev.trace('Change locale to ${locale.languageCode}');
    HomeWidgetSyncTrigger.requestSync(localeCode: locale.languageCode);
    _reloadLocalizedServerContent();
  }

  /// Server content (category/course titles & descriptions, roadmap) is fetched
  /// resolved to the request's `lang` header, so the already-loaded lists keep
  /// the PREVIOUS language until refetched. The slang UI strings update from
  /// [emit] above, but this API-sourced content must be reloaded explicitly.
  void _reloadLocalizedServerContent() {
    // Refreshes Home categories (also drives the Explore grid), suggested
    // courses, quote and my-courses progress. `force` bypasses HomeCubit's
    // 45s freshness guard — without it, switching language right after Home
    // loaded skips the refetch and category/course titles (e.g. the roadmap's
    // category dropdown) stay in the previous language.
    AppDI.injector.get<HomeCubit>().initializeData(isInit: true, force: true);
    // Refreshes the open roadmap, if any (no-op when no course is loaded).
    AppDI.injector.get<CourseRoadmapCubit>().loadRoadmap();
  }

  /// Pinned so an obfuscated release build cannot rename the key this
  /// cubit's state is stored under — see [HydrateBlocService].
  @override
  String get storagePrefix => 'LocaleCubit';

  @override
  AppLocale fromJson(Map<String, dynamic> json) => AppLocaleUtils.parse(json['locale'] as String? ?? AppLocale.vi.languageCode);

  @override
  Map<String, dynamic> toJson(AppLocale state) => {'locale': state.languageCode};
}

extension AppLocaleX on AppLocale {
  /// App chỉ còn một ngôn ngữ nên các bảng tra theo locale trước đây (nhãn,
  /// cờ, danh sách chọn) thu về một giá trị. Giữ lại extension thay vì xoá vì
  /// [languageAISupport] đi vào prompt gửi cho AI, và [localeData] được
  /// MaterialApp dùng.
  String get label => 'Tiếng Việt';

  String get languageAISupport => 'Vietnamese';

  Locale get localeData => flutterLocale;
}
