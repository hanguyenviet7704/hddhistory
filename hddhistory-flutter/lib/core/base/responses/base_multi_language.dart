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
    // App chỉ còn tiếng Việt, nhưng server vẫn trả đủ các trường ngôn ngữ —
    // giữ nguyên chuỗi dự phòng bên dưới để nội dung mới backfill một nửa vẫn
    // hiện được chữ nào đó thay vì để trống.
    if (vi.isNotEmpty) return vi;
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
