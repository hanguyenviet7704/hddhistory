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
    return switch (locale) {
      AppLocale.en => en,
      AppLocale.vi => vi.isNotEmpty ? vi : en,
      AppLocale.zh => zh.isNotEmpty ? zh : en,
    };
  }
}
