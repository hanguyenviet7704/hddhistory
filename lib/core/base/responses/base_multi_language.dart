part of '../base.dart';

@freezed
sealed class BaseMultiLanguage with _$BaseMultiLanguage {
  const factory BaseMultiLanguage({
    @Default('') String en,
    @Default('') String vi,
    @Default('') String zh,
    @Default('') String ja,
    @Default('') String ko,
  }) = _BaseMultiLanguage;

  factory BaseMultiLanguage.fromJson(Map<String, dynamic> json) => _$BaseMultiLanguageFromJson(json);
}

extension BaseMultiLanguageExtension on BaseMultiLanguage {
  String get text {
    AppLocale locale = AppDI.injector.get<LocaleCubit>().state;
    final preferred = switch (locale) {
      AppLocale.en => en,
      AppLocale.vi => vi,
      AppLocale.zh => zh,
      AppLocale.ja => ja,
      AppLocale.ko => ko,
    };

    if (preferred.isNotEmpty) return preferred;
    if (en.isNotEmpty) return en;
    if (vi.isNotEmpty) return vi;
    if (zh.isNotEmpty) return zh;
    if (ja.isNotEmpty) return ja;
    return ko;
  }
}
