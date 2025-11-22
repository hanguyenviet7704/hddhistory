part of '../blocs.dart';

@lazySingleton
class LocaleCubit extends HydratedCubit<LocaleType> {
  LocaleCubit() : super(LocaleType.en) {
    LocaleSettings.setLocale(state.appLocale);
  }

  void changeLocale(LocaleType locale) {
    if (locale == state) return;
    LocaleSettings.setLocale(locale.appLocale);
    emit(locale);
    LogDev.trace('Change locale to ${locale.value}');
  }

  void setLocale(AppLocale locale) {
    LocaleType localeType = switch (locale) {
      AppLocale.en => LocaleType.en,
      AppLocale.vi => LocaleType.vi,
      AppLocale.zh => LocaleType.zh,
    };
    changeLocale(localeType);
  }

  @override
  LocaleType fromJson(Map<String, dynamic> json) => LocaleType.fromString(json['locale'] as String);

  @override
  Map<String, dynamic> toJson(LocaleType state) => {'locale': state.value};
}

enum LocaleType {
  en('en', 'English'),
  vi('vi', 'Tiếng Việt'),
  zh('zh', '中文');

  final String value;
  final String label;

  const LocaleType(this.value, this.label);

  AppLocale get appLocale {
    return switch (this) {
      LocaleType.en => AppLocale.en,
      LocaleType.vi => AppLocale.vi,
      LocaleType.zh => AppLocale.zh
    };
  }

  static LocaleType fromString(String name) {
    return switch (name) {
      'en' => LocaleType.en,
      'vi' => LocaleType.vi,
      'zh' => LocaleType.zh,
      _ => LocaleType.en,
    };
  }

  String get languageAISupport => switch (this) {
    LocaleType.en => 'English',
    LocaleType.vi => 'Vietnamese',
    LocaleType.zh => 'Chinese',
  };

  Locale get localeData {
    return switch (this) {
      LocaleType.en => const Locale.fromSubtags(languageCode: 'en'),
      LocaleType.vi => const Locale.fromSubtags(languageCode: 'vi'),
      LocaleType.zh => const Locale.fromSubtags(languageCode: 'zh'),
    };
  }

  String get flagCircle => switch (this) {
    LocaleType.en => AppAsset.svg.common.icUsFlag,
    LocaleType.vi => AppAsset.svg.common.icVnFlag,
    LocaleType.zh => AppAsset.svg.common.icCnFlag,
  };
}
