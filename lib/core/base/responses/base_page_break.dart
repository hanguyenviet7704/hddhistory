part of '../base.dart';

@JsonSerializable(createFactory: false)
@Freezed(genericArgumentFactories: true)
sealed class BasePageBreak<T> with _$BasePageBreak<T> {
  const factory BasePageBreak({
    @Default(0) int totalPages,
    @Default(0) int currentPage,
    @Default(0) int itemsPerPage,
    @Default([]) List<T> items,
  }) = _BasePageBreakData;

  factory BasePageBreak.fromJson(Map<String, dynamic> json, T Function(Object?) fromJsonT) => _$BasePageBreakFromJson(json, fromJsonT);

  @override
  Map<String, dynamic> toJson(Object? Function(T) toJsonT) => _$BasePageBreakToJson(this, toJsonT);
}

extension BasePageBreakExtension on BasePageBreak {
  /// Check if current page is the last page
  /// Returns true when:
  /// - We've loaded at least one page (currentPage > 0)
  /// - AND (we're on the last page OR there are no results)
  bool get isLastPage => currentPage > 0 && (currentPage >= totalPages || totalPages == 0);

  /// Get the next page number
  /// Returns current page if already on last page, otherwise increments
  int get nextPage => isLastPage ? currentPage : currentPage + 1;
}
