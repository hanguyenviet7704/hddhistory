part of '../blocs.dart';

@lazySingleton
class LocaleCubit extends HydratedCubit<AppLocale> {
  LocaleCubit() : super(AppLocale.en) {
    LocaleSettings.setLocale(state);
  }

  void changeLocale(AppLocale locale) {
    if (locale == state) return;
    LocaleSettings.setLocale(locale);
    emit(locale);
    LogDev.trace('Change locale to ${locale.languageCode}');
  }

  void setLocale(AppLocale locale) => changeLocale(locale);

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
  };

  String get languageAISupport => switch (this) {
    AppLocale.en => 'English',
    AppLocale.vi => 'Vietnamese',
    AppLocale.zh => 'Chinese',
  };

  Locale get localeData => flutterLocale;

  String get flagCircle => switch (this) {
    AppLocale.en => AppAsset.svg.common.icUsFlag,
    AppLocale.vi => AppAsset.svg.common.icVnFlag,
    AppLocale.zh => AppAsset.svg.common.icCnFlag,
  };
}
