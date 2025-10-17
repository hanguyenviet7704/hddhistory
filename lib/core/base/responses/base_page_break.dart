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
  bool get isLastPage => totalPages == currentPage && currentPage > 0;
  int get nextPage => isLastPage ? currentPage : currentPage + 1;
}
