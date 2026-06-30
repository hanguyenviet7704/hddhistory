part of '../../../common.dart';

@lazySingleton
class LocaleCubit extends HydratedCubit<AppLocale> {
  LocaleCubit() : super(AppLocale.en) {
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

  /// Server content (skillset/course titles & descriptions, roadmap) is fetched
  /// resolved to the request's `lang` header, so the already-loaded lists keep
  /// the PREVIOUS language until refetched. The slang UI strings update from
  /// [emit] above, but this API-sourced content must be reloaded explicitly.
  void _reloadLocalizedServerContent() {
    // Refreshes Home skillsets (also drives the Explore grid), suggested
    // courses, quote and my-courses progress.
    AppDI.injector.get<HomeCubit>().initializeData(isInit: true);
    // Refreshes the open roadmap, if any (no-op when no course is loaded).
    AppDI.injector.get<CourseRoadmapCubit>().loadRoadmap();
  }

  @override
  AppLocale fromJson(Map<String, dynamic> json) => AppLocaleUtils.parse(json['locale'] as String? ?? AppLocale.en.languageCode);

  @override
  Map<String, dynamic> toJson(AppLocale state) => {'locale': state.languageCode};
}

extension AppLocaleX on AppLocale {
  String get label => switch (this) {
    AppLocale.en => 'English',
    AppLocale.vi => 'Tiếng Việt',
    AppLocale.zh => '中文',
    AppLocale.ja => '日本語',
    AppLocale.ko => '한국어',
  };

  String get languageAISupport => switch (this) {
    AppLocale.en => 'English',
    AppLocale.vi => 'Vietnamese',
    AppLocale.zh => 'Chinese',
    AppLocale.ja => 'Japanese',
    AppLocale.ko => 'Korean',
  };

  Locale get localeData => flutterLocale;

  String get flagCircle => switch (this) {
    AppLocale.en => AppAsset.svg.common.icUsFlag,
    AppLocale.vi => AppAsset.svg.common.icVnFlag,
    AppLocale.zh => AppAsset.svg.common.icCnFlag,
    AppLocale.ja => AppAsset.svg.common.icJpFlag,
    AppLocale.ko => AppAsset.svg.common.icKrFlag,
  };

  static List<AppLocale> get displayLocales => [AppLocale.en, AppLocale.vi, AppLocale.zh, AppLocale.ja, AppLocale.ko];
}
