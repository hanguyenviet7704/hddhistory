part of '../blocs.dart';

@lazySingleton
class LocaleCubit extends HydratedCubit<LocaleType> {
  LocaleCubit() : super(LocaleType.en) {
    LocaleSettings.setLocale(state.appLocale);
  }

  Future<void> changeLocale(LocaleType locale) async {
    if (locale == state) return;
    await LocaleSettings.setLocale(locale.appLocale);
    emit(locale);
    LogDev.trace('Change locale to ${locale.value}');
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
    switch (this) {
      case LocaleType.en:
        return AppLocale.en;
      case LocaleType.vi:
        return AppLocale.vi;
      case LocaleType.zh:
        return AppLocale.zh;
    }
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
