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

  /// Có chữ ở BẤT KỲ ngôn ngữ nào chưa.
  ///
  /// Khác `text.isNotEmpty` ở chỗ không phụ thuộc ngôn ngữ đang bật — dùng khi
  /// cần biết "object này có nội dung để gửi/lưu không", chứ không phải "có gì
  /// để hiện cho người đang xem không".
  bool get hasAnyText => en.isNotEmpty || vi.isNotEmpty || zh.isNotEmpty || ja.isNotEmpty || ko.isNotEmpty;
}
