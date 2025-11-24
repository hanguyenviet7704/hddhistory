part of '../base.dart';

@freezed
sealed class BaseMultiLanguage with _$BaseMultiLanguage {
  const factory BaseMultiLanguage({
    @Default('') String en,
    @Default('') String vi,
    @Default('') String zh,
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
    };

    if (preferred.isNotEmpty) return preferred;
    if (en.isNotEmpty) return en;
    if (vi.isNotEmpty) return vi;
    return zh;
  }
}
