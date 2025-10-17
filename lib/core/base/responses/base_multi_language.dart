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
